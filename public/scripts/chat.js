/* ******************************
Initial Websocket Setup
****************************** */
//	'ws' is a URL with a handler for all chat messages
var pathArray = window.location.pathname.split( '/' );
var ws = new WebSocket( 'ws://' + window.location.host + '/chat/' + pathArray[2] + '/send/' );

ws.onopen = function() {
	//Send a name packet to the server with the current name.
	nameUpdate( $( '#name' ).val() );
	//Send a backlogRequest packet to the server 
	backlogRequest(128);
};

//	when ws recieves a message, append some html with the contents of the message
ws.onmessage = function ( event ) {
	messageJSON = JSON.parse(event.data);
	printMessage(messageJSON);
	//	this makes #chatLog scroll to the bottom after each new message is received.
	$( '#chatLog' ).scrollTop( $( '#chatLog' )[0].scrollHeight );
}

/* ******************************
Window isActive Setup [for notification sounds]
****************************** */
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

/* ******************************
Functions to communicate with the server
****************************** */

//Normal message sending
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

//Username change reporting
function nameUpdate(name) {
	ws.send( JSON.stringify({
		type: "name",
		name: name,
	}));
}

//Backlog requesting
function backlogRequest(amount) {
	ws.send( JSON.stringify({
		type: "backlog",
		amount: amount,
	}));
}
/* ******************************
Functions to display messages
****************************** */

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

//Function to convert Perl's verbose timestring into simple, user-readable timestamps.
function timeCalc( timeString ) {
	var serverTime = new Date(timeString + " GMT");
	var localTimeString = serverTime.toLocaleTimeString( );
	return localTimeString;
}

function formatMessage( messageJSON ) {
	
	var localTimeString = timeCalc(messageJSON.time);
	var messageArray;
	
	if ( messageJSON.type == "server" ) {
		messageArray = [
			'<div class="message">',
				'<span class="server name">[Server]: </span>' +
				'<span class="server text">' + messageJSON.text + '</span>' ,
				'<span class="server time">' + localTimeString + '</span>',
			'</div>',
		];
	} else if ( messageJSON.type == "user" ) {
		
		var colorString = colorStringCalc( messageJSON.rand );
		var nameSpan;
		
		if ( messageJSON.name === "" ) {
			nameSpan = '<span class="name"></span>';
		} else {
			nameSpan = '<span class="name" style="color:' + colorString + ';">[' + messageJSON.name + ']:&nbsp;</span>';
		}
		
		messageArray = [
			'<div class="message">',
				'<span class="rand" '+ 'style="color:' + colorString + ';">' + messageJSON.rand + '</span>' +
				nameSpan +
				'<span class="text">' + messageJSON.text + '</span>' +
				'<span class="time">' + localTimeString + '</span>',
			'</div>',
		];
	}
			
	messageHTML = messageArray.join( "\n" );
	return messageHTML;
}

function printMessage( messageJSON ) {
	if ( messageJSON.type == "userList" ) {
			//	Remove all current entries from the user list.
			$( "#nameList>ul").empty();
			//	Split the received JSON into an array of lines. 
			nameArray = messageJSON.users.split("\n");
			//	Count the number of lines [number of users] and update the user counter to match
			$( "#userCounter" ).html(nameArray.length.toString());
			//	Add each line to the names list as an li
			for (var i = 0; i < nameArray.length; i++) {
				var colorString = colorStringCalc(nameArray[i]);
				$( '#nameList>ul' ).append("<li style='color:" + colorString + "'>" + nameArray[i] + "</li>");
			}
	} else {
		var messageHTML = formatMessage( messageJSON );
		
		if ( messageJSON.backlog ) {
			$( '#chatLog' ).prepend( messageHTML );
		} else {
			$( '#chatLog' ).append( messageHTML );
			//Play notification sounds
			var messageSoundName = "";
			if (messageJSON.type == "server") {
				if (/disconnected/.test(messageJSON.text)) {
					messageSoundName = "userLeftTone";
					console.log("userLeftTone");
				} else if (/connected/.test(messageJSON.text)) {
					messageSoundName = "userJoinedTone";
					console.log("userJoinedTone");
				}
			} else if (messageJSON.type == "user") {
				messageSoundName = "notificationTone";
			}
			if (!isActive && !!$('#notificationSounds').val() ) {
				document.getElementById(messageSoundName).play();
			}
		}
	}
}

/* ******************************
Message history cycling
****************************** */

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

/* ******************************
Initialization & function assignment
****************************** */

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
