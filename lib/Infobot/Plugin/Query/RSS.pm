
package Infobot::Plugin::Query::RSS;

	use strict;
	use warnings;

	use base (qw(Infobot::Plugin::Query::Base::HTTP));

	our @required_modules = qw( XML::RSS HTTP::Request::Common URI::Escape HTML::TreeBuilder );

# You can call this in three ways...
#   - First off, you can provide a straight-up RSS feed URL
#		- Secondly, you can provide a URL, and it'll look for RSS-y 'stuff'
#		- Thirdly, you can provide plain-text, which it'll google, and then look for RSS
	
	sub process {
		
		my $self = shift;
		my $message = shift;
	
	# Standard URL

		if ( $message->{message} =~ m/^headlines (https?:\/\/(\S+))\s*$/ ) {

			$self->get_rss( $message, $1 );
			return 1;

	# Key words...

		} elsif ( $message->{message} =~ /^headlines (.+)$/ ) {

			return undef unless $message->addressed;
		
			my $url = 'http://www.google.com/search?btnI=I%27m+Feeling+Lucky&q=' . URI::Escape::uri_escape( $1 );
		
			$self->get_rss( $message, $url );
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
			$self->log( 5, "Request unsuccessful: " . $response->code);
			
			if ( $response->code eq '500' ) {
			
				$self->log( 9, "HTTP error content: " . $response->content );
			
			}
			
			return;

		}

		$self->log( 7, "Successful response received" );

		my $data = $response->content;
		my $rss  = XML::RSS->new;

		eval { $rss->parse( $data ) };
		
		my $rss_fail = $@;
		my $html_fail;
		
		if ( $rss_fail ) {

		# If the content-type is HTML, this might be saveable still...
		
			$message->context->{query_stash}->{rss_find} = 0 unless $message->context->{query_stash}->{rss_find};
		
			$self->log( 9, "Content-type is " . $response->header( 'Content-type' ) );
			$self->log( 9, "RSS Find tries is " . $message->context->{query_stash}->{rss_find} );
		
			if (
				( $response->header( 'Content-type' ) =~ m!^text/html! ) &&
				(! $message->context->{query_stash}->{rss_find}++ )
			) {

				my $tree = HTML::TreeBuilder->new;
				eval { $tree->parse( $data ) };				
		
				if ( $@ ) {
				
					$self->log( 5, "HTML unparseable: [$@]" );
					$message->say("Unparseable HTML returned :-(");
					return undef;
				
				}
				
				my $good_link = $tree->look_down(
					'_tag', 'link',
					sub {
					
						my $element = shift;
						
						if (
							( $element->attr('type') =~ m/\brss/ ) &&
							( $element->attr('href') =~ m!^https?://! )
						) {
						
							return $element->attr('href');
						
						} else {
						
							return undef;
						
						}
					
					}
				);
				
				if ( $good_link ) {
				
					$self->get_rss( $message, $good_link->attr('href') );
				
				} else {
				
					$self->log(7, "No suitable links found");
				
				}
				
				return undef;
		
			} else {
			
				$self->log( 5, "RSS unparseable: [$rss_fail]" );
				$message->say("RSS unparseable");
				return undef;
			
			}
		
		}
		
		$self->log( 7, "RSS parse succeeded" );

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