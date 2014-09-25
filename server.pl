#!/usr/bin/env perl

=encoding utf8

=head1 MessageWorks

=over 1

This is a chat server built to allow completely anonymous and secure chat rooms, without the requirement of a user
account. Rooms are intended to be disposable. The http/s and WebSocket communication is controlled by Mojolicious, the
storage of chat logs, user IDs and room names is handled by MongoDB and a separate running database, and the time of
messages, room creation, and server events is handled by DateTime. $debugMode is a flag that enables printing of certain
outputs of functions if it is set to 1 or higher. 'lib/Users.pm' and 'lib/Rooms.pm' are separate files that define the
User and Room objects.

=back

=cut

my $debugMode = 1;

use Mojolicious::Lite;
use MongoDB;
use DateTime;

require 'lib/Users.pm';
require 'lib/Rooms.pm';

##	This is our connection to mongo
my $mongoClient = MongoDB::MongoClient->new;
# This is the one database we're using from that client connection
my $roomsDB = $mongoClient->get_database( 'rooms' );
# This is the test room collection inside the database
my $defaultRoom = $roomsDB->get_collection( 'default' );
##	This creates a list of all pre-existing rooms
my %rooms;

##	this loop initializes all of the pre-existing databases
foreach ( $roomsDB->collection_names ) {
	unless ( $_ eq "system.indexes" ) {
		$rooms{$_} = Rooms->new(
			id			=> $_,
			collection	=> $roomsDB->get_collection( $_ ),
		);
	};
};

for ( keys %rooms ) {
	debugLog("Room '$_' initialized.");
};

=head2 Controllers

=head3 '/echo'

=over 1

'/send' is where the entirety of the WebSocket communication happens. The client sends a JSON-formatted message to /echo
and the handler listed here formats, reroutes, and sends it to the proper recipients.

=back

=cut



##	For every GET request to '/':
get '/' => sub {
	my $controller = shift;
	##	simply render "templates/index.html.ep"
	$controller->stash(
		page => $controller->render_to_string( 'pages/home' ),
		title => "Home",
	);
	$controller->render( 'frame' );
};

get '/about' => sub {
	my $controller = shift;
	
	$controller->stash(
		page => $controller->render_to_string( 'pages/about' ),
		title => "About",
	);
	$controller->render( 'frame' );
};

get '/new' => sub {
	my $controller = shift;
	
	$controller->stash(
		page => $controller->render_to_string( 'pages/new' ),
		title => "Create a New Room",
	);
	$controller->render( 'frame' );
};

post '/create' => sub {
	my $controller = shift;
	
	## $private is a boolean, $requestedURL only exists if private is 0
	my $private = $controller->param( 'private' );
	my $requestedURL = $controller->param( 'roomURLInput' );
	##Check if the URL is valid; if it's not, redirect back to /new. This is a failsafe in case the JS filter doesn't work.
	
	if ((not defined($requestedURL)) || ($requestedURL eq "") || ($private == 1)) {
		$requestedURL = generateSecureURL();
	};
	
	if (!($requestedURL =~ m/[a-zA-Z][\w]{0,31}/ )) {
		debugLog("Regex failed, invalid name\n");
		$controller->redirect_to( '/new' );
		return;
	} else {
		my $newRoom = addRoom($controller, $requestedURL);
		$controller->redirect_to( 'chat/' . $newRoom->{id} );
	};
	
	sub generateSecureURL {
		my @chars = ( 
			'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
			'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
			'0', '1' , '2', '3', '4', '5', '6', '7', '8', '9'
		);
		my $string = $chars[ int( rand( 51 ) ) ];
		foreach ( 1 .. 31 ) {
			$string .= $chars[ int( rand( @chars ) ) ];
		};
		
		return $string;
	};
	
	sub addRoom {
		my $controller = shift;
		my $roomName = shift;
		##	Stop if the room already exists (to be replaced with an error template)
		if ( $roomName ~~ %rooms ) {
			$controller->redirect_to( 'error/room_already_exists' );
			last;
		};
		##	Create a new room with the following attributes
		my $room = Rooms->new(
			id			=> $roomName,
			collection	=> $roomsDB->get_collection( $roomName ),
		);
		##	Adds this room to the global hash of all open rooms
		$rooms{$roomName} = $room;
		
		$room->{collection}->insert({ hello => "world" });
		
		return $room;
	};
};

get '/chat/' => sub {
	my $controller = shift;
	$controller->redirect_to("/chat/default");
};

get '/chat/:roomName' => sub {
	my $controller = shift;
	my $roomQuery = $controller->stash( 'roomName' );
	
	if ( $roomQuery ~~ %rooms ) {
		$controller->stash(
			page => $controller->render_to_string( 'pages/chat', title => $roomQuery ),
			title => $roomQuery,
		);
		
		$controller->render( 'frame' );
	} else {
		$controller->redirect_to( '/error/room_not_found' );
	};
};

get '/error/:error' => sub {
	my $controller = shift;
	my $error = $controller->stash( 'error' );
	
	my $title = join ( " ", split( "_", $error) );
	
	$title =~ s/(\w+)/\u\L$1/g;
	
	$controller->stash (
		page => $controller->render_to_string( 'errors/' . $error ),
		title => "Error: " . $title,
	);
	
	$controller->render( 'frame' );
};

websocket '/chat/:roomName/send' => sub {
	my $controller = shift;
	my $roomName = $controller->stash( 'roomName' );
	
	my $room = $rooms{$roomName};
	
	my $user = Users->new(
		controller	=> $controller,
	);
	
	$rooms{$roomName}->addUser($user);
	
	$rooms{$roomName}->serverMessage("Client " . $user->{randString} . " has connected.");
	
	##	set the timeout for each websocket connection to indefinite
	$user->{controller}->inactivity_timeout( 0 );

	$user->{controller}->on( json => sub {
		my ($controller, $hashIn) = @_;
		
		given( $hashIn->{type} ) {
			when( "message" ) {
				my $hash = $user->signMessage( $hashIn );
				$hash = $room->prepareMessage( $hash );
				$room->deliverMessage( $hash );
			}
			when ( "name" ) {
				$user->setName( $hashIn->{name} );
				$room->sendUserList;
			} 
			when ( "keepalive" ) {
				
			} 
			default {
				
			};
		};
	});

	##	Whenever a client disconnects...
	$user->{controller}->on( finish => sub {
		##Write it down in the log, console, and room chat
		app->log->debug( "Client disconnected" );
		
		#Remove the user
		$rooms{$roomName}->removeUser($user);
	
		$room->serverMessage("Client " . $user->{randString} . " has disconnected.");
		
		## If the room is empty, delete the room.
		if ( !keys $room->{clients} && $roomName ne "default" ) {
			delete( $rooms{$roomName} );
			$room->remove;
		};
	});
}; 


######  FUNCTIONS  ######


##	A quick function to print all arguments given to it if $debug is 1
sub debugPrint {
	if ( $debugMode ) {
		foreach ( @_ ) {
			print( "$_" );
		}
		print( "\n" );
	};
}

sub debugLog {
	if ( $debugMode ) {
		foreach ( @_ ) {
			app->log->debug( "$_" );
		};
	};
}

app->start;

__END__
