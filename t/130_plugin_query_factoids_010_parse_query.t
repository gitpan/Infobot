
use Test::More tests => 1;

	use t::lib::FakeDBIxClass; # Just stop stuff complaining for now
	use t::lib::NullLog;

require_ok( 'Infobot::Plugin::Query::Factoids' );

__DATA__

	my @phrases = (
		[ is => ' hey, where is foo?'   ], # s/^\s*hey,*\s+where/where/i
		[ is => 'whois foo?'            ], # s/whois/who is/gi
		[ is => 'where can I find foo?' ], # s/where can i find/where is/i
		[ is => 'how about foo?'        ], # s/how about/where is/i
		[ is => 'gee, where is foo?'    ], # s/^(gee|boy|golly|gosh),? //i
    [ is => 'boy, what is foo?'     ], # s/^(gee|boy|golly|gosh),? //i
    [ is => 'golly, whois foo?'     ], # s/^(gee|boy|golly|gosh),? //i
    [ is => 'gosh, how about foo?'  ], # s/^(gee|boy|golly|gosh),? //i
		[ is => 'well whois foo?'       ], # s/^(well|and|but|or|yes),? //i
		[ is => 'aNd, how about foo?'   ], # s/^(well|and|but|or|yes),? //i
		[ is => 'golly, bUT, foo?'      ], # s/^(well|and|but|or|yes),? //i
		[ is => 'gee, OR whois foo?'    ], # s/^(well|and|but|or|yes),? //i
		[ is => 'yes foo?'              ], # s/^(well|and|but|or|yes),? //i
		[ is => 'does ne1 know foo?'    ],
		[ is => 'heya folks, foo?'      ],
		[ is => 'uhm, foo?'             ],
		[ is => 'okay, foo?'            ],
	);		

# Holy. Mother. Of. God. That is all.

	use strict;
	use warnings;	

	use Test::More tests => 15;

	use t::lib::FakeDBIxClass; # Just stop stuff complaining for now
	use t::lib::NullLog;

	use Infobot::Log;
	use Infobot::Message;
	use Infobot::Plugin::Query::Factoids;

	my $log = t::lib::NullLog->new();
	$log->stash( log => Infobot::Log->new() );
	$log->register();
	
	my $brain = Infobot::Plugin::Query::Factoids->new();
	$brain->init();

	my ( $get_verb, $get_key );
	{

		no strict 'refs';
		*{"Infobot::Plugin::Query::Factoids::get"} = sub { 

			my $self  = shift;
			$get_key  = shift;
			$get_verb = shift;

			unless ( $get_verb ) {

				( $get_verb, $get_key ) = split( /\s+/, $get_key );

			}

			return 1 if $get_key eq 'foo';
			return;

		}

	}

package FakeConduit;	

	my $result;

	use base 'Infobot::Base';
	sub say { $result = $_[1] }

package main;

# First attempt


	for ( @phrases ) {

		my ($verb, $phrase) = @$_;

		($get_verb, $get_key) = (undef,undef);

	# Set that in our fake database
	# Create an object

		my $message = Infobot::Message->new();
		$message->init(
			addressed => 1,
			conduit   => FakeConduit->new(), 
			context   => { channel => '#perl' },
			name      => 'sheriff',
			message   => $phrase, 
			public    => 1,
			nick      => 'purl',
			printable => $phrase,
		);

	# See if we get it back

		$brain->process( $message );

		is( $get_key,  'foo', "$phrase" );

	}

