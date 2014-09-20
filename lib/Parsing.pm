use strict;
use warnings;

sub prepareText {
	my $text = shift;
	
	$text = htmlEscape( $text );
	$text = formattingCheck( $text );
	$text = autoLinker( $text );
		
	return $text;
};

sub htmlEscape {
	my $string = shift;
	
	unless( $string ) {
		return( "" );
	} else {
		$string =~ s/&/&amp;/g;
		$string =~ s/</&lt;/g;
		$string =~ s/>/&gt;/g;
		$string =~ s/'/&#39;/g;
		$string =~ s/"/&quot;/g;
	}
	return $string;
};

sub formattingCheck {
	my $string = shift;
	
	$string =~ s{\*\*(.+?)\*\*}{<i>$1</i>}g;
	$string =~ s{\*(.+?)\*}{<b>$1</b>}g;
	
	return $string;
};

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
		!<a\ target="_blank" href="$2"><img\ src="$2"\ /></a>!gix;
			
	return $string;
};

1;

__END__
