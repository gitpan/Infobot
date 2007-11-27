
package Infobot::Plugin::Conduit::Console;

	use strict;
	use warnings;

	use base (qw(Infobot::Plugin::Conduit::Base));
	use POE;

	our @required_modules = (qw(POE::Wheel::ReadLine));

	sub init {

		my $self = shift;

		my $session = POE::Session->create(

			args => [ $self ],
			object_states => [
				$self => [qw( _start got_input _stop )],
			]
		
		);	
			
	}

sub _start {
		
    my ($heap) = $_[ HEAP ];
    $heap->{readline_wheel} =
      POE::Wheel::ReadLine->new( InputEvent => 'got_input' );
    $heap->{readline_wheel}->get("Say Something: ");

}

sub _stop {
    delete $_[HEAP]->{readline_wheel};
}

sub say {

	my $self = shift;
	my $message = shift;

	my $reply = shift;

	my $heap = $message->context->{heap};

	$heap->{readline_wheel}->put( $reply );
	return 1;

}

sub got_input {

    my ( $self, $heap, $kernel, $session ) = @_[ OBJECT, HEAP, KERNEL, SESSION ];
		my $input = $_[ ARG0 ];
		my $exception = $_[ ARG1 ];

    if ( defined $input ) {
			
			my $message = Infobot::Message->new();

			unless ( $message->init(
				conduit   => $self,
				context   => { heap => $heap },
				name      => 'console user', 
				message   => $input,
				public    => 0,
				addressed => 1,
				nick      => $self->stash('config')->{alias},
				printable => $input,
			) ) { 
			
				$self->log( 2, "Failed to initialise the message" );
				die;
			
			}
			
		# Give to the pipeline
			$self->pipeline($message);
			$heap->{readline_wheel}->get("Say Something Else: ");

    } elsif ( $exception eq 'interrupt' ) {
    
    	$heap->{readline_wheel}->put("Goodbye.");
        delete $heap->{readline_wheel};
        return;
    
    } else {
        $heap->{readline_wheel}->put("Goodbye.");
        delete $heap->{readline_wheel};
        return;
    }


}

1;	
