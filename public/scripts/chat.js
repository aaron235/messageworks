//	'ws' is a URL with a handler for all chat messages
var pathArray = window.location.pathname.split( '/' );
var ws = new WebSocket( 'ws://' + window.location.host + '/chat/' + pathArray[2] + '/send/' );

ws.onopen = function() {
	ws.send( JSON.stringify({
		type: "name",
		name: $( '#name' ).val(),
	}));
};

//	Starts off as the active window
var isActive = true;

//	Set as active window when focused
window.onfocus = function () { 
  isActive = true; 
}; 

//	Unset as active window when unfocused
window.onblur = function () { 
  isActive = false; 
}; 

//Function to derive the rand & nick hue from the randString
function hueCalc( randString ) {
	var hueNum = 0;
	if ( randString ) {
		hueNum = Math.floor( randString.slice( 3, 6 ) * 359/999 );	
	} 
	return hueNum;
}
function colorStringCalc( randString ) {
	return 'hsl(' + hueCalc( randString ) + ',60%,40%)';
}

//	when ws recieves a message, append some html with the contents of the message
ws.onmessage = function ( event ) {
	//Date calculation into local time
	var serverTimeString = JSON.parse(event.data).time + " GMT";
	var serverTime = new Date(serverTimeString);
	var localTimeString = serverTime.toLocaleTimeString( );
	
	
	//	When a message is recieved, check the type of the message, and handle it accordingly
	switch ( JSON.parse(event.data).type ) {
		//	Server message format
		case "server":
			$( '#chatLog' ).append([
				'<div class="message">',
					'<span class="server name">[Server]: </span>' +
					'<span class="server text">' + JSON.parse(event.data).text + '</span>' ,
					'<span class="server time">' + localTimeString + '</span>',
				'</div>',
			].join( "\n" ));
			
			//	Play notification sound
			if ( !isActive && !!$('#notificationSounds').val() ) {
				document.getElementById('notificationTone').play();
			};
		break;
		
		//	User message format
		case "user":
			//Generate an HSL color from the randstring of this message
			var colorString = colorStringCalc( JSON.parse( event.data ).rand );
				
			//	If the user left their name blank:
			if ( JSON.parse(event.data).name === "" ) {
				$( '#chatLog' ).append([
					'<div class="message">',
						'<span class="rand" '+ 'style="color:' + colorString + ';">' + JSON.parse(event.data).rand + '</span>' +
						'<span class="name" '+ 'style="color:' + colorString + ';"></span>' +
						'<span class="text">' + JSON.parse(event.data).text + '</span>' +
						'<span class="time">' + localTimeString + '</span>',
					'</div>',
				].join( "\n" ));
			//	If the user has a name:
			} else {
				$( '#chatLog' ).append([
					'<div class="message">',
						'<span class="rand" '+ 'style="color:' + colorString + ';">'  + JSON.parse(event.data).rand + '</span>' +
						'<span class="name" '+ 'style="color:' + colorString + ';">'  + '[' + JSON.parse(event.data).name + ']:&nbsp;' + '</span>' +
						'<span class="text">' + JSON.parse(event.data).text + '</span>' +
						'<span class="time">' + localTimeString + '</span>',
					'</div>',
				].join( "\n" ));
			};
			
			//	Play notification sound
			if ( !isActive && !!$('#notificationSounds').val() ) {
				document.getElementById('notificationTone').play();
			};
		break;
		case "userList":
			//	Remove all current entries from the user list.
			$( "#nameList>ul").empty();
			//	Split the received JSON into an array of lines. 
			nameArray = JSON.parse(event.data).users.split("\n");
			//	Count the number of lines [number of users] and update the user counter to match
			$( "#userCounter" ).html(nameArray.length.toString());
			//	Add each line to the names list as an li
			for (var i = 0; i < nameArray.length; i++) {
				var colorString = colorStringCalc(nameArray[i]);
				$( "#nameList>ul").append("<li style='color:" + colorString + "'>" + nameArray[i] + "</li>");
			}
		break;
		case "keepalive":
			//	do nothing
		break;
		default:
			//	do nothing
		break;
	};
	
	
	//	this makes #chatLog scroll to the bottom after each new message is received.
	$( '#chatLog' ).scrollTop( $( '#chatLog' )[0].scrollHeight );
};

function websockSend(message) {
	
	//	If the outgoing message is blank, don't send anything.
	if ( message == "" ) {
		return;
	};
	
	//	get a new date
	var date = new Date();
	//	send a JSON of name, text, and time (date) to ws
	ws.send( JSON.stringify({
		name: $( '#name' ).val(),
		text: message,
		time: date.toString(),
		type: "message",
	}));
	// Add the sent message to your message history array so you can access it via arrow keys
	sentMessages.unshift( $( '#outgoing' ).val() );
	
	//	blank the outgoing message field
	$( '#outgoing' ).val( "" );
}

function getBacklog() {
	
}

//For up-down picking of previous messages
var sentMessages = [];
var messageInProgress = [];
var sentMessagesIndex = -1;

//Function to cycle through message history
function changeMessageIndex(increment) {
	sentMessages[sentMessagesIndex] = $( '#outgoing' ).val();
	sentMessagesIndex += increment;
	if (sentMessagesIndex >= (sentMessages.length-1)) {
		sentMessagesIndex = sentMessages.length-1;
	}
	if (sentMessagesIndex <= -1) {
		sentMessagesIndex = -1;
	}
};
	
$( document ).ready(function() {
	$( '#outgoing' ).keyup( function( e ) {
		// Process keystrokes in the chat input box
		switch (e.which) {
			//If it's an enter keystroke, send the message and return to the default message index.
			case 13:
				websockSend( $( '#outgoing' ).val() );
				sentMessagesIndex = -1;
				break;
			// If it's an up keystroke, try to increase the message index, and show the corresponding message in the chat box.
			case 38:
				changeMessageIndex(1);
				$( '#outgoing' ).val( sentMessages[sentMessagesIndex] );
				break;
			// If it's a down keystroke, try to decrease the message index, and show the corresponding message in the chat box.
			case 40:
				changeMessageIndex(-1);
				$( '#outgoing' ).val( sentMessages[sentMessagesIndex] );
				break;
		}
	});
	// Show/hide the list of users when you click the users counter.
	$( '#toggleNameList' ).click(function() {
		$( "#chatLog" ).toggleClass("chatLogShrunk");
		$( '#toggleNameList' ).toggleClass("active");
	});
	//	Every time #name changes, send a name message to the server so it can update user lists with the new name.
	$( '#name' ).change( function() {
		ws.send( JSON.stringify({
			type: "name",
			name: $( '#name' ).val(),
		}));
	});
	
	//	Check if the server is alive every second (all clientside)
	var serverStatusCheck = setInterval( function() {
		if ( ws.readyState === undefined || ws.readyState > 1 ) {
			$( '#disconnectOverlay' ).fadeIn( 350 );
			clearInterval( serverStatusCheck );
			clearInterval( keepalivePing );
		}
	}, 1000 );
	
	//	Ping the server to keep your WS alive every 20 seconds
	var keepalivePing = setInterval( function() {
		ws.send(JSON.stringify({
			type: "keepalive",
		}));
	}, 20000 );
});
