
=head1 NAME

How to write a conduit

=head1 CONSIDERATIONS

A conduit is a method for getting queries in to the C<infobot>,
and spitting out replies. The most obvious is an IRC server,
but there's no reason that any two way data source can't be
turned in to a conduit.

C<infobot> uses L<POE> to avoid blocking between various IO
requests. While the code is written in such a way as to hide
L<POE> as far as possible from developers building simple plugins,
building a conduit will definitely require it, so some familiarity
with L<POE> is required for this tutorial.

=head1 A BAD IDEA

Wouldn't it be great to be able to interact with infobot via email?

=head1 SCAFFOLDING

C<infobot> makes some assumptions about your components. The first
of these is that you have a C<load()> method which returns true or
false depending on if the system is capable of running your
component. In almost every case, this involves checking for the 
availability of modules.

We're going to be using L<Email::Folder>, L<Email::Delete>, L<Email::Address> and
L<Email::Send>. Luckily, L<Infobot::Base> has a method to make
it very easy to check for required modules, and what's more, it'll
autmoatically check your package for an array containing these
modules. Even better, it's called C<load()>, so you don't even
need to define C<load()> in most modules.

FINALLY, L<POE> is definitely available to you, and will
export some useful stuff in to our namepace, so we C<use>
it explicitly.

Hence:

 package Infobot::Conduit::Mail;

   use strict;
	 use warnings;

 # Import new() and a useful load()

   use base qw( Infobot::Conduit ); # Specialised subclass of Infobot::Base

 # Modules we'll be needing

   our @required_modules = qw(Email::Folder Email::Delete Email::Send Email::Address);

 # Load POE explicitly

   use POE;

=head1 CONFIGURATION 

Our conduit is going to need some external data to set up properly -
an email address and name to send from, a subject line to use, an
incoming mailbox to monitor, AND a frequency for monitoring. And
we're going to want this from the configuration file that runs
C<infobot>. 

The convention for adding modules in to the configuration file is
nice and simple. This is a C<conduit>, so it sits under the conduit
section. We need to define a C<class> for it, and any C<extras> we
like. An example will make this clear:

 conduit:
    'Bad Idea Email':
      class : Infobot::Conduit::Mail
      extras:
          server    : localhost
          from      : 'infobot <infobot@clueball.com>'
          subject   : Infobot Reply
          mailbox   : /home/sheriff/Maildir/infobot/
          frequency : 10 

This is L<YAML>. It's a bitch with whitespace being non-perfect, so
be careful. C<Bad Idea Email> is how we talk about the component,
C<class> is the package which provides it, and you freestyle the
C<extras> to whatever you want.

At this point, we almost have a working component. All that's left
is ...

=head1 INIT

Components are given a chance to do any set up once they're loaded
in their C<init> method. The C<init> method is passed the name of
the component (so: C<Bad Idea Email> in this case), and is expected
to return 1 on success.

You can use this name, to access the configuration values you set.
There's a long way and an easy way. We're interested in the easy
way: 

 $self->set_name( shift() );

This sets C<<$self->{name}>> appropriately, and makes everything
from C<extras> available in C<<$self->{config}>>.

So to make this a workable module, let's add a very simple C<init()>
method which doesn't do anything... So that we get some output, we're
going to write to the log. The log is available through any subclass
of C<Infobot::Base> as C<log>. Pass it a priority and a message -
you can find a list of priorities in L<Infobot::Log>. We're going to 
set our priority to 2 - a serious error - just so it shows up: 

 # Setup

 sub init {

   my $self = shift;

   $self->set_name( shift() );

   $self->log( 2, "We will be reply to mail as $self->{config}->{from}" );

   return 1;

 }

Add it in, fire up C<infobot>! Amongst other lines, I get:

 [Infobot] 4. Loading conduit [Bad Idea Email] [Infobot::Conduit::Mail]
 [<::Base] 2. We will be reply to mail as Infobot <infobot@clueball.com>

=head1 INPUTS

How to get email in to the C<infobot>? We're going to go with polling
a mailbox every so often, and using the subject lines of any mail we
find as queries, and then delete the email.

To do this nicely, every x seconds, without blocking, we're going to
use L<POE>. As this tutorial requires a good knowledge B<of> L<POE>,
we'll be skipping over how it works... What we do need, is to set up
a session in our C<init> block, and post our first event to it...

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

So far so good. We're now going to need to define a C<_start> method,
and a C<poll> method - the method that we're going to set up to run
periodically. C<_start> just needs to call poll for the first time:

 sub _start {

 # We'll give everything 15 seconds to load... Remember $poe_kernel
 # has been provided by the POE module automatically...
   
   $poe_kernel->delay_set( poll => 15 );

 }

The C<poll> method is a little more complicated, so let's just make
it print a message for the time being...

 sub poll {

   my ( $self ) = $_[ OBJECT ];

   $self->log( 2, "Polling" );

   $poe_kernel->delay_set( poll => $self->{config}->{frequency} ); 

 }

And let's set it to run! I get the output:

 [<::Base] 2. Polling
 [<::Base] 2. Polling
 [<::Base] 2. Polling

Great news!

=head1 CREATING A MESSAGE

This document isn't about using the Email modules, so you'll just
have to trust the following routine rewrite of C<poll()>that you 
need to add, blindly. B<This will delete all mail it finds in the
target mailbox>.

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

Let's write a light-weight C<process> method at this point so we
can see this code in action.

 sub process {

   my $self = shift;
		my %options = @_;

		$self->log( 2, "$options->{name} from $options->{email} said $options->{text}" );

 }

And run it! You'll need to arrange for some mail to find its way in to your infobot mail store for this to happen tho...

=head1 CREATING A MESSAGE

=head1 SAY

