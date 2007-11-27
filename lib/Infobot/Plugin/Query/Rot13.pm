
package Infobot::Plugin::Query::Rot13;

	use strict;
	use warnings;

	use base (qw(Infobot::Plugin::Query::Base));
	
	sub process {
		
		my $self = shift;
		my $message = shift;

		if ( $message->{message} =~ m/^rot13 (.+)$/ ) {

			my $text = $1;
			
			$text =~ y/A-Za-z/N-ZA-Mn-za-m/;
			$message->say( $text );

			return 1;

		} else {

			return undef;

		}

	}

1;
