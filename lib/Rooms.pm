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

do 'lib/Parsing.pl';

##	This is our connection to mongo
my $mongoClient = MongoDB::MongoClient->new;
# This is the one database we're using from that client connection
my $roomLogDB = $mongoClient->get_database( 'roomLog' );
my $roomInfoDB = $mongoClient->get_database( 'roomInfo' );

sub new {
	my ( $class, %options ) = @_;
	
	my $self = {
		%options,
	};
	
	my $collectionName = $self->{id};
	
	$self->{logCollection} = $roomLogDB->get_collection( $collectionName );
	$self->{infoCollection} = $roomInfoDB->get_collection( $collectionName );
	
	bless( $self, $class );
	
	$self->{infoCollection}->insert({
		name    => $self->{id},
		private => $self->{private},
	});
	
	app->log->debug( "Rooms->new: created new room with name '$self->{id}'" );
	
	return( $self );
};


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

sub deliverMessage {
	my $self = shift;
	my $hashOut = shift;
	for ( values $self->{clients} ) {
		$_->{controller}->tx->send( {json => $hashOut} );
	};
	
	app->log->debug( "Rooms->deliverMessage: message delivered in room '$self->{id}' from user '$hashOut->{rand}'" );
};

sub logMessage {
	my $self = shift;
	my $messageHash = shift;
	
	$self->{logCollection}->insert({
		type => $messageHash->{type},
		rand => $messageHash->{rand},
		name => $messageHash->{name},
		text => $messageHash->{text},
		time => $messageHash->{time},
		
		logTime => time(),
	});
	
	app->log->debug( "Rooms->logMessage: message logged in room '$self->{id}' from user '$messageHash->{rand}'" );
};

sub serverMessage {
	my $self = shift;
	my $string = shift;
	
	my $timeString = localtime();
	
	my $hashOut = {
		name => "Server",
		time => $timeString,
		text => $string,
		type => "server",
	};
	
	$self->deliverMessage($hashOut);
	
	app->log->debug( "Rooms->serverMessage: server message sent from room '$self->{id}'" );
};

sub sendUserList {
	my $self = shift;
	
	my @users;
	
	for ( values $self->{clients} ) {
		if ( $_->{name} ) {
			push( @users, "$_->{rand} [$_->{name}]" );
		} else {
			push( @users, "$_->{rand}" );
		};
	};
	
	my $hashOut = {
		type  => "userList",
		users => join( "\n", @users ),
	};
	
	for ( values $self->{clients} ) {
		$_->{controller}->tx->send( {json => $hashOut} );
	};
	
	app->log->debug( "Rooms->sendUserList: user list sent from room '$self->{id}'" );
};

sub addUser {
	my $self = shift;
	my $user = shift;
	
	my $userID = $user->{rand};
	
	while ( $userID ~~ $self->{clients} ) {
		$user->newRandString();
	};
	
	$user->{backlogIndex} = $self->{logCollection}->query( { logTime => 1 } )->sort({ logTime => 1 })->limit(1)->next; ## oh god, the horror
	
	print( ">>>>>>>>>> $user->{backlogIndex} \n" );
	
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
