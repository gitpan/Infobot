
package Infobot::Plugin::Log::PrettyConsole;

	use strict;
	use warnings;

	use base (qw(Infobot::Plugin::Log::Base));

	our @required_modules = qw( Term::ANSIColor );

	sub color {

		&Term::ANSIColor::color;

	}

	sub output {
	
		my $self = shift;
		
		my $level   = shift;
		my $package = shift;
		my $message = shift;	

		$package =~ s/..+(......)$/<$1/g; # hee!

		my $color;

		if ( $level < 2 ) {
			$color = color 'bold red';
		} elsif ( $level < 3 ) {
			$color = color 'bold yellow';
		} elsif ( $level < 5 ) {
			$color = color 'bold white';
		} else {
			$color = color 'white';
		}

	
		print STDOUT (color 'bold white') . '[' . (color 'reset') .
					(color 'cyan ' )     . $package .
					(color 'bold white') . "] " . (color 'reset'); 
		
		print "$color$level. $message" . ( color 'reset' ) . "\n";

		return 1;

	}

1;	
