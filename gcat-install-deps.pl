use strict;
use warnings;
use CPAN;

print "Starting GCAT dependencies install...\n\n";

CPAN::Shell->install (
	'',
	'DBI',
	'DBD::mysql',
	'Log::Log4perl',
	'Parallel::ForkManager',
	'Statistics::Descriptive',
	'Statistics::R',
	'Time::HiRes',
	'Set::IntSpan::Fast',
	'Set::IntSpan::Fast::XS',
	'Text::CSV',
	'Text::CSV_XS',
	'Text::FormatTable',
	'Tie::IxHash',
	'Cwd',
	'File::Spec',
	'File::Basename',
	'Pod::Select',
	'IO::String',
	'Config',
);

print "\n\nInstall complete!\n";
