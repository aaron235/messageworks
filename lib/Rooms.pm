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
	
	return $self;
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
	
	sub prepareText {
		my $text = shift;
	
		$text = htmlEscape( $text );
		$text = formattingCheck( $text );
		$text = autoLinker( $text );
		
		return $text;
	};
	
	##	checks for any of '&', '<', '>', ''', and '"', and converts them to their escaped HTML equivalents
	sub htmlEscape {
		my $string = shift;
		$string =~ s/&/&amp;/g;
		$string =~ s/</&lt;/g;
		$string =~ s/>/&gt;/g;
		$string =~ s/'/&#39;/g;
		$string =~ s/"/&quot;/g;
		return $string;
	};
	
	##	italicizes text surrounded by '**' and bolds text surrounded by '*'
	sub formattingCheck {
		my $string = shift;
		
		$string =~ s{\*\*(.+?)\*\*}{<i>$1</i>}g;
		$string =~ s{\*(.+?)\*}{<b>$1</b>}g;
		return $string;
	};
	
	##	replaces URLs with <a>s and image URLs with <img>s inside of <a>s
	sub autoLinker {
		my $string = shift;
		
		#Replaces all URLs with <a> links
		$string =~ 
			s!
			((https?://)(www\.)?([^\.\s'"<>]+?\.)+[^\.\s'"<>]+(/\S+)?[^\s'"<>]+)
			!<a\ href="$1">$1</a>!gix;
		#Finds <a> links where href points to an image, replaces them with an <a><img /></a> setup
		$string =~ 
			s!
			(<a\ href=")
			((https?:\/\/)?(www\.)?([^\.\/'"]+\.)+([^\./'"])+\/[^\s]+\.(gif|jpg|jpeg|jpe|png|webp|apng))
			(")(\ )?((title="")?>)[^<]+(</a>)
			!<a\ href="$2"><img\ src="$2"\ /></a>!gix;
		return $string;
	};
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

sub sendUserList {
	my $self = shift;
	
	my @users;
	
	for ( keys $self->{clients} ) {
		push( @users, $_ );
	};
	
	my $hashOut = {
		users => @users,
		type  => "userList",
	};
	
	for ( values $self->{clients} ) {
		$_->{controller}->tx->send( {json => $hashOut} );
	};
};

sub addUser {
	my $self = shift;
	my $user = shift;
	
	my $userID = $user->{randString};
	$self->{clients}->{$userID} = $user;
	$self->sendUserList;
};

sub removeUser {
	my $self = shift;
	my $user = shift;
	
	my $userID = $user->{randString};
	delete $self->{clients}->{$userID};
	$self->sendUserList;
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
