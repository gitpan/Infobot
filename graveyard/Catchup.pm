
package Infobot::Plugin::Core::Catchup;

	use strict;
	use warnings;

	use base (qw(Infobot::Plugin));
	use HTTP::Request::Common;
	use Infobot::Stash; my $stash = Infobot::Stash->new();
	use Infobot::Clients::HTTP;
	use POE;
	
	sub init {

		my $self = shift;

		POE::Session->create(
			object_states => [ $self => [qw(response _start make_request)] ],
		);

	}

	sub _start {

		my $kernel = $_[ KERNEL ];

		$kernel->alias_set('plugin_core_catchup_session');

	}
	
	sub make_request {

		my $kernel = $_[ KERNEL ];

		$kernel->post( @{ $_[ARG0] } );

	}
	
	sub process {
		
		my $self = shift;
		my $message = shift;

	# We don't care if this isn't public 

		return undef unless $message->{public};

		if ( $message->{message} =~ m/^catchup/ ) {

			if ( $stash->{irc_conduit}->{log}->{$message->context->{location}} ) {
			
			# Get the data
			
				my $catchup = join "\n", @{ $stash->{irc_conduit}->{log}->{$message->context->{location}} };
			
			# Create the HTTP request

				my $request = POST 'http://paste.husk.org/paste', [ channel => '', summary => $message->context->{location}, nick => $message->{who}, paste => $catchup ];

				$poe_kernel->post( 'plugin_core_catchup_session' => 'make_request',
					[
						'poe_component_client_http',
						'request',
						'response',
						$request,
						$message
					]
				);

				return 1;
			
			}

			return 1;
			
		}

		return undef;

	}

	sub response {

		my ( $request_object, $response_object ) = @_[ ARG0, ARG1 ];
		
		my $message  = $request_object->[1];
		my $response = $response_object->[0];
	
	# Private response

		$message->{public} = 0;
		
		my $content = $response->content;

		unless ( $response->is_success ) {

			$message->say("Interaction with paste.husk.org failed :-(" );
			return undef;

		}

		unless ($content =~ m!["'](http://paste.husk.org/\d+)["']!) {

			$message->say("Can't find a URL in paste.husk.org's response" );
			return undef;

		}

		$message->say("Catch up available at: $1?tx=on");
		return undef;

	}

1;
