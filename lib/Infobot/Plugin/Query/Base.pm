
=head1 NAME

Infobot::Plugin::Query::Base - Base class for plugins

=cut

package Infobot::Plugin::Query::Base;

	use strict;
	use warnings;

	use base (qw(Infobot::Base));

=head1 METHODS

=head2 init

Calls C<set_name>

=cut

	sub init { 
	
		my $self = shift;
		my $name = shift;

		return $self->set_name( $name );
		
	} # Any other setup stuff in here...

=head2 set_name

Grabs the priority from the config, and puts it somewhere safe. Then calls
L<Infobot::Base>'s C<set_name> with C<query> as the category.

=cut

	sub set_name {

		my $self = shift;
		my $name = shift;

		$self->{_priority} = $self->stash('config')->{query}->{$name}->{priority};

		return $self->SUPER::set_name( 'query', $name );

	}

=head2 priority

Read-only accessor for the plugin's priority, set during C<set_name>

=cut

	sub priority {

		my $self = shift;

		return $self->{_priority};
		
	}

=head1 SEE ALSO

The tutorial on writing Query plugins

=cut

1;
