
	use strict;
	use warnings;

	use ExtUtils::MakeMaker;

	my %config = (

	NAME => 'Infobot',
	VERSION_FROM => 'lib/Infobot.pm',

	);

	my %prerequisites = map { $_ => '' } qw(

		POE
		POE::Component::Client::HTTP
		POE::Component::IRC
		POE::Wheel::ReadLine
		File::Basename
		DBIx::Class
		DBIx::Class::Schema::Loader
		DBD::SQLite
		HTTP::Request
		HTML::TreeBuilder
		UNIVERSAL::require
		YAML::Syck	

	);

	WriteMakefile(

		%config,
		PREREQ_PM => \%prerequisites

	);

