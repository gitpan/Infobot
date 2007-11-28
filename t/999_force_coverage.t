
	use Test::More tests => 1;

	use Infobot;
	use Infobot::Base;
	use Infobot::Config;
	use Infobot::Log;
	use Infobot::Message;
	use Infobot::Pipeline;
	use Infobot::Plugin::Conduit::Base;
	use Infobot::Plugin::Log::Base;
	use Infobot::Plugin::Query::Base;
	use Infobot::Plugin::Query::Client::Base;
	use Infobot::Plugin::Query::Client::HTTP;
	use Infobot::Plugin::Query::Client::DBIxClass;
	use Infobot::Plugin::Query::RSS;
	use Infobot::Plugin::Query::GoogleDefine;
	use Infobot::Plugin::Query::Greeting;
	use Infobot::Plugin::Query::Rot13;
	use Infobot::Plugin::Query::Factoids;
	use Infobot::Service;

	ok(1, "Placeholder");

