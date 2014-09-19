=encoding utf8

=head2 Users

=over 1

This is the Perl Module containing all of the attributes and methods of the User object.

=back

=cut

package Users;

use Mojolicious::Lite;
use DateTime;
use MongoDB;

=head2 new

=item $user->new();

=over 1

C<new()> makes a new User object. Possible attributes are randString (defined as part of the C<new()> function),
controller and database (to be moved to Rooms.pm).

=back

=cut

sub new {
	my ( $class, %options ) = @_;
	
	my @upperConsonants = ( "B", "C", "D", "F", "G", "H", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "V", "W", "X", "Y", "Z" );
	my @lowerVowels = ( "a", "e", "i", "o", "u" );
	my @lowerConsonants = ( "b", "c", "d", "f", "g", "h", "j", "k", "l", "m", "n", "p", "q", "r", "s", "t", "v", "w", "x", "y", "z" );
	
	my $randString = sprintf(
		$upperConsonants[ int( rand( @upperConsonants ) ) ] . 
		$lowerVowels[ int( rand( @lowerVowels ) ) ] . 
		$lowerConsonants[ int( rand( @lowerConsonants ) ) ] . 
		int( rand( 10 ) ) . 
		int( rand( 10 ) ) . 
		int( rand( 10 ) )
	);
	
	my $self = {
		randString	=> $randString,
		%options,
	};
	
	bless( $self, $class );
	return( $self );
}


sub signMessage {
	my $self = shift;
	my $hashIn = shift;
	
	my $timeString = localtime();
	
	my $hashOut = {
		rand => $self->{randString},
		name => $self->{name},
		text => $hashIn->{text},
		time => $timeString,
		type => "user",
	};
	return $hashOut;
};

1;

__END__
