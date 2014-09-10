$(function() {
	// Filters out any *real* keystroke that does not match the regex
	$('#roomURLInput').on('keypress', function (event) {
		var regex = new RegExp("[a-zA-Z0-9_]+");
		var key = String.fromCharCode(!event.charCode ? event.which : event.charCode);
		
		if (!regex.test(key)) {
		   event.preventDefault();
		   return false;
		}
	});
	// Adds or removes error messages, depending on the contents of roomURLInput. Updated every key-press.
	$('#roomURLInput').on('input', function (event) {
		var string = $( "#roomURLInput" ).val();
		//If the field is blank, DON'T show an error. The user is probably still thinking of a name.
		if (string == "") {
			$("#URLInputError").text("");
		}
		else {
			var URLTestStatus = testURL(string);
			$("#URLInputError").text(URLTestStatus);	
		}
	});
	//Do a final check when the user tries to submit the form.  If it fails, display the error and don't submit it.
	$('#optionsList').submit(function() {
		var string = $( "#roomURLInput" ).val();
        var URLTestStatus = testURL(string);
		if (URLTestStatus === "") {
			return true; 
		} else if ($("#optionsList input[name='private']:checked").val() == 1) {
			return true;
		} else {
			$("#URLInputError").text(URLTestStatus);	
			return false;
		} 
        
    });
});


// Tests if a given URL String is a legitimate one. Returns "" if okay, otherwise it will return a description of the problem.
function testURL(urlString) {
	var status = "";
	var inactive = 0;
	if (!/^[a-zA-Z][\w]*$/.test(urlString)) {
		status = "Room URLs must begin with a letter.";
	}
	if (urlString.length == 32) {
		status = "Room URLs have a 32 character limit.";
	}
	if (urlString === "") {
		status = "Room URLs cannot be blank.";
	}
	return status;
	
};