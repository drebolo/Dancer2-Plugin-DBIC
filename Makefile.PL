use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Plugin::DBIC',
    AUTHOR              => 'Al Newkirk <awncorp@cpan.org>',
    VERSION_FROM        => 'lib/Dancer/Plugin/DBIC.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Plugin/DBIC.pm',
    LICENSE             => 'perl',
    PREREQ_PM => {
        'DBIx::Class'                 => '0',
        'DBIx::Class::Schema::Loader' => '0',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-DBIC-*' },
);

