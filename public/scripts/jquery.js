$( document ).ready(function() {
	/*Adding "selected" to the correct navbar link*/
	var path = window.location.pathname;
	//console.log("Current path is:",path);
	$( '#navbar li a').each(function() {
		//console.log("- Testing if matched by",$(this).attr( 'href' ));
		if ( $(this).attr( 'href' ) == path ) {
			$(this).addClass( "selected" );
			//console.log("  • Match found!");
			return false;
		}
		else {
			//console.log("  • No match.");
		}
	});
});