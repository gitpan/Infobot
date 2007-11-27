
=head1 NAME

Infobot::Plugin::Conduit::Base - Base class for conduits

=head1 METHODS

=cut

package Infobot::Plugin::Conduit::Base;

	use strict;
	use warnings;

	use base (qw(Infobot::Base));
	use Infobot::Message;

=head2 set_name

As with C<Infobot::Base>, but explicitly sets category to C<conduit>.

=cut

	sub set_name {

		my $self = shift;
		my $name = shift;

		return $self->SUPER::set_name( 'conduit', $name );
		
	}

=head2 pipeline

Helper method around calling C<$self->stash('pipeline')->process( $message );>

=cut

	sub pipeline {

		my $self = shift;
		my $message = shift;

		return $self->stash('pipeline')->process( $message );

	}

=head1 SEE ALSO

The included tutorial on writing your own conduit

=cut

1;	
	
