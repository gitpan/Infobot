
package Infobot::Plugin::Query::Gender;

	use strict;
	use warnings;

	use base qw( Infobot::Plugin::Query::Base::DBIxClass );

	our @columns = qw( name male female );

	sub process {

		my $self    = shift;
		my $message = shift;

		my $text = $message->message;

		if ( $text =~ m/^gender (?:for )?(.+)/ ) {

			my $name = $1;

			my $stats = $self->dbi->find( $name ); 

			if ( $stats ) {

				$message->say( $stats->name . ' is ' . $stats->male .'/'. $stats->female );

			} else {

				$message->say( $name . 'not found' );

			}

			return 1;

		} else {

			return undef;

		}

	}

1;

