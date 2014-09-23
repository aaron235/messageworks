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
};

##sub sendUserList {
##	my $self = shift;
##	
##	my @users;
##	
##	for ( keys $self->{clients} ) {
##		push( @users, $_ );
##	};
##	
##	my $hashOut = {
##		users => @users,
##		type  => "userList",
##	};
##	
##	for ( values $self->{clients} ) {
##		$_->{controller}->tx->send( {json => $hashOut} );
##	};
##};

sub addUser {
	my $self = shift;
	my $user = shift;
	
	my $userID = $user->{randString};
	$self->{clients}->{$userID} = $user;
##	$self->sendUserList;
};

sub removeUser {
	my $self = shift;
	my $user = shift;
	
	my $userID = $user->{randString};
	delete $self->{clients}->{$userID};
##	$self->sendUserList;
};

sub remove {
	my $self = shift;
	
	$self->{collection}->drop;
	
	for ( values $self->{clients} ) {
		undef $_;
	};
	
	undef $self;
}

1;

__END__
