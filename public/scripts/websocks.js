//	'ws' is a URL with a handler for all chat messages
var pathArray = window.location.pathname.split( '/' );
var ws = new WebSocket( 'ws://' + window.location.host + '/chat/' + pathArray[2] + '/send/' );

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

//For up-down picking of previous messages
var sentMessages = [];
var sentMessagesIndex = -1;

//	when ws recieves a message, append some html with the contents of the message
ws.onmessage = function ( event ) {
	//Date calculation into local time
	var serverTimeString = JSON.parse(event.data).time + " GMT";
	var serverTime = new Date(serverTimeString);
	var localTimeString = serverTime.toLocaleTimeString( );
	
	//Function to derive the rand & nick hue from the randString
	function hueCalc( randString ) {
		var hueNum = 0;
		if ( randString ) {
			hueNum = Math.floor( randString.substr( 3, 5 ) * 359/999 );	
		} 
		return hueNum;
	}
	//Generate an HSL color from the randstring of this message
	var colorString = 'hsl(' + hueCalc( JSON.parse( event.data ).rand ) + ',60%,40%)';
	
	
	//	When a message is recieved, check the type of the message, and handle it accordingly
	switch ( JSON.parse(event.data).type ) {
		//	Server message format
		case "server":
			$( '#chatLog' ).append([
				'<div class="message">',
					'<span class="server name">[Server]: </span>' +
					'<span class="server text">' + JSON.parse(event.data).text + '</span>' ,
				'</div>',
			].join( "\n" ));
		break;
		
		//	User message format
		case "user":
			//	If the user left their name blank:
			if ( JSON.parse(event.data).name === "" ) {
				$( '#chatLog' ).append([
					'<div class="message">',
						'<span class="rand" '+ 'style="color:' + colorString + ';">' + JSON.parse(event.data).rand + '</span>' +
						'<span class="name" '+ 'style="color:' + colorString + ';">' + '' + '</span>' +
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
		break;
		case "userList":
		
		break;
		case "keepalive":
		
		break;
		default:
		
		break;
	};
	
	
	//	this makes #chatLog scroll to the bottom after each new message
	$( '#chatLog' ).scrollTop( $( '#chatLog' )[0].scrollHeight );
	
	if ( !isActive && !!$('#notificationSounds').val() ) {
		document.getElementById('notificationTone').play();
	};
};

function websockSend(message) {
	
	//	If the outgoing message is blank, don't send
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
		display: 1,
	}));
	sentMessages.unshift( $( '#outgoing' ).val() );
	
	//	blank the outgoing message field
	$( '#outgoing' ).val( "" );
}

function getBacklog() {
	
}

//function to change the current message index without going too far in either direction
function changeMessageIndex(increment) {
	sentMessagesIndex += increment;
	
	if (sentMessagesIndex >= (sentMessages.length-1)) {
		sentMessagesIndex = sentMessages.length-1;
	}
	if (sentMessagesIndex <= 0) {
		sentMessagesIndex = 0;
	}
};

$( document ).ready(function() {
	$( '#outgoing' ).keyup( function( e ) {
		//	run a websockSend on a keypress of Enter (keycode 13)
		switch (e.which) {
			case 13:
				websockSend( $( '#outgoing' ).val() );
				sentMessagesIndex = -1;
				break;
			//	So up/down arrows cycle through message history
			case 38:
				changeMessageIndex(1);
				console.log("Current value of sentMessagesIndex is:",sentMessagesIndex);
				$( '#outgoing' ).val( sentMessages[sentMessagesIndex] );
				break;
			case 40:
				changeMessageIndex(-1);
				$( '#outgoing' ).val( sentMessages[sentMessagesIndex] );
				break;
		}
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
			display: 0,
		}));
	}, 20000 );
})
