
package Infobot::Plugin::Conduit::Mail;

	use strict;
	use warnings;

# Import new() and a useful load()

	use base qw( Infobot::Plugin::Conduit::Base );

# Modules we'll be needing

 	our @required_modules = qw(Email::Folder Email::Delete Email::Send Email::Address);

# Load POE explicitly

	use POE;

# Setup

 sub init {

   my $self = shift;

   $self->set_name( shift() );

   POE::Session->create(

     object_states => [
       
       $self => [qw( poll _start )],

     ]

   );

   return 1;

 }

 sub _start {

 # We'll give everything 15 seconds to load... Remember $poe_kernel
 # has been provided by the POE module automatically...
   
   $poe_kernel->delay_set( poll => 5 );

 }

# Check for new mail

 sub poll {

   my ( $self ) = $_[ OBJECT ];

   my $folder = Email::Folder->new( $self->{config}->{mailbox} );

   for my $email ( $folder->messages ) {

      my ($address) = Email::Address->parse( $email->header('from') );

     $self->process( 
        name  => $address->phrase,
        email => $address->address, 
        text  => $email->header('subject')
      );

      my $message_id = $email->header('Message-ID');

      Email::Delete::delete_message(
        from => $self->{config}->{mailbox},
        matching => sub {
          my $message = shift;
          $message->header('Message-ID') =~ $message_id;
        }
      )

   }

   $poe_kernel->delay_set( poll => $self->{config}->{frequency} ); 

 }

 sub process {

   my $self = shift;
    my %options = @_;

  $self->log( 2, "$options{name} from $options{email} said $options{text}" );

 }

1;
