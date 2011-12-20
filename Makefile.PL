use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'GCAT',
    AUTHOR              => q{"Steve Moss" <"gawbul@gmail.com">},
    VERSION_FROM        => 'modules/GCAT.pm',
    ABSTRACT_FROM       => 'modules/GCAT.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'GCAT-*' },
);
