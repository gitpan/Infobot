
package Infobot::Plugin::Query::RSS;

	use strict;
	use warnings;

	use base (qw(Infobot::Plugin::Query::Base::HTTP));

	our @required_modules = qw( XML::RSS HTTP::Request::Common );
	
	sub process {
		
		my $self = shift;
		my $message = shift;

		if ( $message->{message} =~ m/^headlines (https?:\/\/(\S+))\s*$/ ) {

			$self->get_rss( $message, $1 );
			return 1;

		} else {

			return undef;

		}

	}

	sub get_rss {

		my $self    = shift;
		my $message = shift;
		my $rss     = shift;

		$self->log( 5, "Requesting $rss" );
		$self->request( $message, HTTP::Request::Common::GET $rss ); 

	}

	sub response {

		my $self = shift;

		my ( $message, $response ) = @_;
	
		$self->log( 5, "Response received" );
		
		unless ( $response->is_success ) {

			$message->say("RSS fetch unsuccessful");
			$self->log( 5, "Request unsuccessful" );
			return;

		}

		$self->log( 7, "Successful response received" );

		my $data = $response->content;
		my $rss  = XML::RSS->new;

		eval { $rss->parse( $data ) };
		
		if ( $@ ) {

			$message->say("RSS unparseable");
			$self->log( 5, "RSS unparseable: $@" );
			return

		}	

		my $headlines;

		foreach my $item ( @{$rss->{"items"}} ) {
			
			$headlines .= $item->{"title"} . "; ";
			if ( 
				$self->{config}->{max_length} &&
				length( $headlines ) > $self->{config}->{max_length}
			) { 
				last 
			}
			
		}

		$headlines =~ s/; $//;
		$headlines =~ s/\s+/ /sg;

		$message->say( $headlines );

	}

1;
