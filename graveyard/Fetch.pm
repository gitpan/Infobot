
package Infobot::Plugin::Query::Fetch;

	use strict;
	use warnings;

	use base (qw(Infobot::Plugin::Query::Base::HTTP));
	
	sub process {
		
		my $self = shift;
		my $message = shift;

		if ( $message->{message} =~ m/^fetch (\S+)\s*$/ ) {

			$self->request( HTTP::Request->new(GET => $1 ) );
			return 1;

		} else {

			return undef;

		}

	}

	sub response {

		my $self = shift;

		my ( $message, $response ) = @_;
		
		my $content = $response->content;
		my ($title) = $content =~ m!<title>(.+)</title>!igm;

		unless ( $response->is_success ) {

			warn("$content");

		}

		$message->say( 'Title: ' . $title );

	}

1;
