#!/usr/bin/perl

# 050_config_010_basic.t - Tests for our log multiplexer

	use strict;
	use warnings;

	use Test::More tests => 8;

	use_ok( 'Infobot::Log' );

	my $object = Infobot::Log->new();

# write() without an init() should cause our backup STDERR logging to fire, and
# also return undef...

	ok(! $object->write("#", 1, "Ignore this message!"), "write returns undef if uninitialised" );

# Init with no object should do the same...

	$object->init();
	ok(! $object->write("#", 1, "Ignore this message!"), "write returns undef if defaulting to STDERR" );

# Let's add a couple of fake log objects, and see if they both get hit...

	my $log1;
	my $log2;

	ok( $object->register( FakeLog1->new ), "First log registration returns true"  );
	ok( $object->register( FakeLog2->new ), "Second log registration returns true" );

	my $value = rand(100);

	ok( $object->write( "#", 1, $value ), "write() returns true if there are log objects" );
	is( $log1, $value, "Log 1 hit properly" );
	is( $log2, $value, "Log 2 hit properly" );
	

package FakeLog1;

	use base 'Infobot::Base';

	sub write { $log1 = $_[3]; return 1 }

package FakeLog2;

	use base 'Infobot::Base';

	sub write { $log2 = $_[3]; return 1 }