use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'autobahn',
    AUTHOR              => q{YOUR NAME <youremail@example.com>},
    VERSION_FROM        => 'lib/autobahn.pm',
    ABSTRACT            => 'YOUR APPLICATION ABSTRACT',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'YAML'       => 0,
        'Dancer'     => 1.311,
	'DBIx::Class' => 0,
	'Dancer::Plugin::Auth::Github' => 0,
	'Dancer::Plugin::DBIC' => 0,
	'Data::UUID' => 0,
	'HTML::Entities' => 0,
	'HTML::FillInForm' => 0,
	'List::AllUtils' => 0,
	'Plack' => 0,
	'URI::Encode' => 0,
	'Template' => 0,
	'Dancer::Middleware::Rebase' => 0,
	'LWP::Protocol::https' => 0,
	'Unicode::CaseFold' => 0,
	'Moo' => 0,
	'POE::Component::FeedAggregator' => 0,
	'MooseX::POE' => 0,
	'Net::GitHub' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'autobahn-*' },
);
