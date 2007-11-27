
package Infobot::Plugin::Query::Greeting;

	use strict;
	
	use base (qw(Infobot::Plugin::Query::Base));

# ways to say hello
my @hello = ('hello', 
             'hi',
             'hey',
             'niihau',
             'bonjour',
             'hola',
             'salut',
             'que tal',
             'privet',
             "what's up");

	sub process {
		
		my $package = shift;
		my $message = shift;

    if ($message->{message} =~ /^\s*(h(ello|i(\s+there)?|owdy|ey|ola)|
                         salut|bonjour|niihau|que\s*tal)
                         (\s+$::param{nick})?\s*$/xi) {

        if ( $message->{public} && (! $message->{addressed} ) && rand() > 0.35) {
            # 65% chance of replying to a random greeting when not
            # addressed
            return 1;
        }

			$message->say( $hello[int(rand(@hello))] . ', ' . $message->name );

			return 1;

    }
    return undef;
}

1;
