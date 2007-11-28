
	use strict;
	use warnings;
	
	use Test::More tests => 1;
	
	use_ok( 'Infobot::Plugin::Query::Client::HTTP' );

__DATA__

#!/usr/bin/perl

# 080_conduit_base_010_basic.t - Tests around the base class for query plugins

	use strict;
	use warnings;
	
	use Test::More tests => 1;

	use POE;
	use HTTP::Request::Common;
	use Infobot::Log;
	use Infobot::Plugin::Query::Client::HTTP;
	
	my @sites = (
	
#		[ Google   => 'http://www.google.com/'   => qr/^Google.*/  ],
		[ Yahoo    => 'http://www.yahoo.com/'    => qr/^Yahoo.*/   ],
#		[ Dilbert  => 'http://www.dilbert.com/'  => qr/^Dilbert.*/ ],
	
	);

	 my $object = Infobot::Plugin::Query::Client::HTTP->new();

# Add some fake logging in...

	$object->stash( log => Infobot::Log->new );

# First, let's set up some fake config data, and init the client...
	
	$object->stash( config => { 
		datasource => { foo => { extras => { FollowRedirects => 2 },  alias => 'http_client' } } ,
		query      => { bar => { extras => { http_client => 'http_client' } } }
	} );
	$object->init( 'foo' );

# Now let's fire off our requests...

	my $tester = TestModule->new();
	$tester->init('bar');

	POE::Session->create(
			package_states => [ main => [qw( _start )] ],
	);

	$poe_kernel->run();
	
	sub _start {
	
		for my $site ( @sites ) {
	
			my ( $name, $url, $regex ) = @$site;		
		
			my $request = GET $url;
		
			diag("Trying $name");
		
			$tester->request( $site, $request );
	
		}	
	
	}


package TestModule;

	use strict;
	use warnings;
	
	use Test::More;
	use base 'Infobot::Plugin::Query::Base::HTTP';

	sub response {
	
		my $self     = shift;
		my $message  = shift;
		my $response = shift;

		my $content = $response->content;
		my ($title) = $content =~ m!<title>(.+?)</title>!sgi;
	
		like( $title, $message->[2], $message->[0] . "'s title correct" );
	
	}

1;
