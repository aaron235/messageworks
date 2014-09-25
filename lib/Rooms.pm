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

do 'lib/Parsing.pl';

##	This is our connection to mongo
my $mongoClient = MongoDB::MongoClient->new;
# This is the one database we're using from that client connection
my $roomsDB = $mongoClient->get_database( 'rooms' );

sub new {
	my ( $class, %options ) = @_;
	
	my $self = {
		%options,
	};
	
	my $collectionName = $self->{id};
	
	$self->{collection} = $roomsDB->get_collection( $collectionName );
	
	bless( $self, $class );
	
	app->log->debug( "Rooms->new: created new room with name $self->{name}" );
	
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
	
	app->log->debug( "Rooms->prepareMessage: message prepared from user $hashOut->{name}" );
	
	return( $hashOut );
};

sub deliverMessage {
	my $self = shift;
	my $hashOut = shift;
	for ( values $self->{clients} ) {
		$_->{controller}->tx->send( {json => $hashOut} );
	};
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
	
	app->log->debug( "Rooms->serverMessage: server message sent" );
};

sub sendUserList {
	my $self = shift;
	
	my @users;
	
	for ( values $self->{clients} ) {
		if ( $_->{name} ) {
			push( @users, "$_->{randString} [$_->{name}]" );
		} else {
			push( @users, "$_->{randString}" );
		};
	};
	
	my $hashOut = {
		type  => "userList",
		users => join( "\n", @users ),
	};
	
	for ( values $self->{clients} ) {
		$_->{controller}->tx->send( {json => $hashOut} );
	};
	
	app->log->debug( "Rooms->sendUserList: user list sent" );
};

sub addUser {
	my $self = shift;
	my $user = shift;
	
	my $userID = $user->{randString};
	$self->{clients}->{$userID} = $user;
	$self->sendUserList;
	
	app->log->debug( "Rooms->addUser: user $user->{randString} added" );
}; 

sub removeUser {
	my $self = shift;
	my $user = shift;
	
	my $userID = $user->{randString};
	delete $self->{clients}->{$userID};
	$self->sendUserList;
	
	app->log->debug( "Rooms->removeUser: user $user->{randString} removed" );
};

sub remove {
	my $self = shift;
	
	$self->{collection}->drop;
	
	for ( values $self->{clients} ) {
		undef $_;
	};
	
	app->log->debug( "Rooms->remove: room $self->{name} removed" );
	
	undef $self;
}

1;

__END__
