
package Infobot::Plugin::Log::STDERR;

	use strict;
	use warnings;

	use base (qw(Infobot::Log));

	sub output {
	
		my $self = shift;
		
		my $level   = shift;
		my $package = shift;
		my $message = shift;	
		
		print STDERR "[$level] [$package] $message\n";
		
	}
1;	
