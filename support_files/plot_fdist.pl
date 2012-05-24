# This is a helper script to build a frequency distribution plot for a number of species
# Coded by Steve Moss
# gawbul@gmail.com
# http://stevemoss.ath.cx

# make life simple
use warnings;
use strict;

# import modules
use GCAT::Visualisation::R;
use GCAT::Data::Output qw(concatenate_CSV);

# setup variables
my @orgs = ("homo_sapiens", "pan_troglodytes", "gorilla_gorilla", "pongo_abelii", "nomascus_leucogenys");
my $feature = "grepeats";
my $organisms = \@orgs;
my ($raw_filename, $freqs_filename) = undef;

# check if we have more than one organism
if (scalar(@{$organisms}) > 1) {
	# concatenate the raw CSVs
	$raw_filename = &concatenate_CSV($feature, "raw", @{$organisms});
	
	# concatenate the freqs CSVs
	$freqs_filename = &concatenate_CSV($feature, "freqs", @{$organisms});
}
else {
	# build path
	my $dir = getcwd();
	my $path = File::Spec->catfile($dir , "data", @{$organisms}[0]);
	
	# set filenames
	my $rawfile =  "$feature\_raw.csv";
	my $freqsfile = "$feature\_freqs.csv";
	$raw_filename = File::Spec->catfile($path , $rawfile);
	$freqs_filename = File::Spec->catfile($path , $freqsfile);
}

# build frequency distribution plot
&GCAT::Visualisation::R::plot_Frequency_Dist($freqs_filename, $feature, @{$organisms});
