=encoding utf8

=head2 Rooms

=over 1

This is the module containing all of the methods and attributes of the Room object.

=back

=cut

package Rooms;

use Mojolicious::Lite;
use MongoDB;
use DateTime;
use Time::HiRes qw(time);
use Data::Dumper;

do 'lib/Parsing.pl';

##	This is our connection to mongo
my $mongoClient = MongoDB::MongoClient->new;
## These are the room databases we're using from that connection
my $roomLogDB = $mongoClient->get_database( 'roomLog' );
my $roomInfoDB = $mongoClient->get_database( 'roomInfo' );

## Creates a new room object and a corresponding roomInfo entry.
sub new {
	my ( $class, %options ) = @_;

	my $self = {
		%options,
	};

	my $collectionName = $self->{id};

	$self->{logCollection} = $roomLogDB->get_collection( $collectionName );
	$self->{infoCollection} = $roomInfoDB->get_collection( $collectionName );

	bless( $self, $class );

	## Write room info to the roomInfoDB Database
	$self->{infoCollection}->insert({
		name    => $self->{id},
		private => $self->{private},
	});

	app->log->debug( "Rooms->new: created new room with name '$self->{id}'" );

	return( $self );
};

## Prepares user message JSON by escaping special chars, adding autolink/embed codes, and adding the user type.
sub prepareMessage {
	my $self = shift;
	my $hashIn = shift;

	my $hashOut = {
		rand => $hashIn->{rand},
		name => htmlEscape( $hashIn->{name} ),
		text => prepareText( $hashIn->{text} ),
		time => $hashIn->{time},
		type => "user",
	};

	app->log->debug( "Rooms->prepareMessage: message prepared in room '$self->{id}' from user '$hashOut->{rand}'" );

	return( $hashOut );
};

## Send a message to all users in the current room object.
sub deliverMessage {
	my $self = shift;
	my $hashOut = shift;
	for ( values $self->{clients} ) {
		$_->{controller}->tx->send( {json => $hashOut} );
	};

	$self->logMessage( $hashOut );

	if ( $hashOut->{type} eq "server" ) {
		app->log->debug( "Rooms->deliverMessage: message delivered in room '$self->{id}' from server" );
	} elsif ( $hashOut->{type} eq "user" ) {
		app->log->debug( "Rooms->deliverMessage: message delivered in room '$self->{id}' from user '$hashOut->{rand}'" );
	}
};

## Record a message in the current room collection in the mongo roomLog database.
sub logMessage {
	my $self = shift;
	my $messageHash = shift;

	if ( $messageHash->{type} eq "server" ) {
		$self->{logCollection}->insert({
			type => $messageHash->{type},
			name => $messageHash->{name},
			text => $messageHash->{text},
			time => $messageHash->{time},

			logTime => time(),
		});
	} elsif ( $messageHash->{type} eq "user" ) {
		$self->{logCollection}->insert({
			type => $messageHash->{type},
			rand => $messageHash->{rand},
			name => $messageHash->{name},
			text => $messageHash->{text},
			time => $messageHash->{time},

			logTime => time(),
		});
	}

	if ( $messageHash->{type} eq "server" ) {
		app->log->debug( "Rooms->logMessage: message logged in room '$self->{id}' from server" );
	} elsif ( $messageHash->{type} eq "user" ) {
		app->log->debug( "Rooms->logMessage: message logged in room '$self->{id}' from user '$messageHash->{rand}'" );
	}
};

## Prepare and deliver a server message.
sub serverMessage {
	my $self = shift;
	my $string = shift;
	my $event = shift;

	my $timeString = localtime();

	my $hashOut = {
		name => "Server",
		time => $timeString,
		text => $string,
		type => "server",
		event => $event,
	};

	$self->deliverMessage($hashOut);

	app->log->debug( "Rooms->serverMessage: server message sent from room '$self->{id}'" );
};

sub sendUserList {
	my $self = shift;

	my @users;
	## This needs to be improved
	for ( values $self->{clients} ) {
		push( @users, {
			name => $_->{name},
			rand => $_->{rand},
		});
	};

	print( @users );

	my $hashOut = {
		type  => "userList",
	};

	for ( my $i = 0; $i < @users; ++$i ) {
		$hashOut->{users}[$i] = $users[$i];
	};

	foreach ( values $self->{clients} ) {
		$_->{controller}->tx->send( {json => $hashOut} );
	};

	app->log->debug( "Rooms->sendUserList: user list sent from room '$self->{id}'" );
};

sub sendBacklog {
	my $self = shift;
	my $user = shift;
	my $amount = shift;

	my $backlogIndexTime = $user->{backlogIndex}->{logTime};
	my @messages;

	##	This line sets @messages to a hash of $amount number of messages before the user entered the room

	foreach ( $self->{logCollection}->query( { logTime => { '$lte' => $backlogIndexTime } } )->limit( $amount )->all ) {
		print( $_ );
		unshift( @messages, $_ );
	};
	##	ugh.

	foreach ( @messages ) {
		if ( $_->{logTime} == $messages[ -1 ]->{logTime} ) {
			$user->{backlogIndex} = $_;
		};

		## Add the "backlog" property to sent message JSONs.
		$_->{backlog} = 1;

		$user->{controller}->tx->send( {json => $_} );
	};
};

sub addUser {
	my $self = shift;
	my $user = shift;

	my $userID = $user->{rand};

	while ( $userID ~~ $self->{clients} ) {
		$user->newRandString();
	};

	##	This line sets $user->{backlogIndex} to a hash of the most recent message before they entered the room.
	$user->{backlogIndex} = $self->{logCollection}->query->sort({ logTime => -1 })->limit(1)->next;
	##	oh god, the horror

	$self->{clients}->{$userID} = $user;
	$self->sendUserList;

	app->log->debug( "Rooms->addUser: user '$user->{rand}' added to room '$self->{id}'" );
};

sub removeUser {
	my $self = shift;
	my $user = shift;

	my $userID = $user->{rand};
	delete $self->{clients}->{$userID};
	$self->sendUserList;

	app->log->debug( "Rooms->removeUser: user '$user->{rand}' removed from room '$self->{id}'" );
};

sub remove {
	my $self = shift;

	$self->{logCollection}->drop;
	$self->{infoCollection}->drop;

	for ( values $self->{clients} ) {
		undef $_;
	};

	app->log->debug( "Rooms->remove: room '$self->{id}' removed" );

	undef $self;
};

1;

__END__
