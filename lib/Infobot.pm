
package Infobot;

=head1 NAME

Infobot - Popular IRC bot

=head1 SYNOPSIS

 cd infobot;
 mkdir brains;
 perl scripts/create_database.pl brains/factoids.db

 ./infobot infobot.conf &

=head1 DESCRIPTION

B<PLEASE NOTE: This is a developer release. This code IS NOT READY TO USE,
LOOK AT, OR ANYTHING VAGUELY LIKE THAT.>

C<infobot> is an IRC bot which implements a sort of artificial
intelligence by learning information ("factoids") from channel
discussions and then responding intelligently to queries about this
accumulated information.  Through plug-ins, the C<infobot> can also
interactively query all sorts of other data sources.

The C<1.00> release of C<infobot> offers a new and improved back-end -
100% test and documentation coverage, a simple and stable plugin system,
while maintaining feature (and bug!) parity with C<0.43> were the
priorities in this release.

=head1 END USER INFORMATION

The rest of the documentation in this file is meant for C<infobot>
developers. Please view the docs/ directory for information for
end-users.

=cut

	use strict;
	use warnings;

	use base ( qw( Infobot::Base ) );
	use POE;

	require UNIVERSAL::require;

	my @services = (qw(

		Infobot::Log
		Infobot::Config
		Infobot::Pipeline

	));
	
	our $VERSION = '0.91_02';

# This makes the whole thing run... infobot.pl is a very thin
# wrapper on top of this.

=head1 DEVELOPER CONSIDERATIONS

The application is put together in such a way that almost everything should
use L<Infobot::Base> as its subclass. Methods should return 0 on failure, and
1 on success. An object's C<new> method should B<just> instantiate, nothing else
- leave any setup for C<init>.

=head1 METHODS

=head2 start

 Infobot->start( 'config_file_location' );

Loads all the specified components specified in the configuration file
and starts the L<POE> kernel. Returns on shutdown.

=cut

	sub start {

		my $package     = shift;
		my $config_file = shift;
	
		$package->stash( config_file => $config_file );

	# Set up our essential services

		for my $service ( @services ) {
	
		# Try and load up the service
	
			$service->require || die "Couldn't load $service: $@";		
		
		# Get its key - what we call it in the stash...

			my $key = $service->key;

		# Create an object, init, stash	

			my $class = $service->new || die $@;
			$package->stash( $key => $class );
			$package->stash( $key )->init || die $!;

		}
			
	# Load up the components we need... 
		
		#                           Config Section,  Required,  Pipeline 
		$package->_load_module_type('log',           1,         0         );
		$package->_load_module_type('datasource',    1,         0         );
		$package->_load_module_type('conduit',       0,         0         );
		$package->_load_module_type('query',         0,         1         );

		$poe_kernel->run();

		return 1;

	}

# Searches the config for modules to load of a specific
# type, and loads them if so

	sub _load_module_type {

		my $package  = shift;
		my $type     = shift;
		my $required = shift;
		my $pipeline = shift;

		return 1 unless $package->stash('config')->{$type};

	# Iterate through entries in the config file for 'type'

		for my $name ( keys %{ $package->stash('config')->{$type} } ) {

		# Get the name of the class the module lives in, then load it

			next unless $name; # Stop yaml being weird

			my $classname = $package->stash('config')->{$type}->{$name}->{class};
			$package->log( 4, "Loading $type [$name] [$classname]" );

			unless ( $classname->require ) {
				
				$package->log( 1, "Failed to require() $classname: $@" );
				die;

			}
			
		# Test if the module thinks it can be loaded. If it can,
		# then it should definitely init(), and we'll treat it as
		# fatal if it can't
				
			if ( $classname->load ) {
			
				my $class = $classname->new;	

				unless ( $class->init( $name ) ) {
						
					$package->log( 1, "$name: $classname didn't initialise! $@" );
					die;
					
				}
			
			# Add to the pipeline if required

				if ( $pipeline ) {

					my $priority = $class->priority;
					$package->stash('pipeline')->add( $priority, $class );
	
				}
	
		# If it can't be loaded, then check if it's required that
		# we can load it, and die if we can't, otherwise just 
		# shoot an error
	
			} else {

				if ( $required ) {

					$package->log( 1, "Failed to load() $type: $name $@" );
					die;

				} else {

					$package->log( 2, "Failed to load() $type: $name $@" );

				}

			}

		}
	}

1;	
