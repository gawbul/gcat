#!/usr/bin/env perl

# Genome Comparison and Analysis Toolkit
#
# An adaptable and efficient toolkit for large-scale evolutionary comparative genomics analysis.
# Written in the Perl programming language, GCAT utilizes the BioPerl, Perl EnsEMBL and R Statistics
# APIs.
#
# Part of a PhD thesis entitled "Evolutionary Genomics of Organismal Diversity".
#
# Coded by Steve Moss
# gawbul@gmail.com
#
# C/o Dr David Lunt and Dr Domino Joyce,
# Evolutionary Biology Group,
# The University of Hull.

=head1 NAME

	advanced_stats

=head1 SYNOPSIS

    advanced_stats feature species1 species2 species3...
    
=head1 DESCRIPTION

	A script to retrieve all descriptive statistics and produce a frequency distribution plot for a particular feature (i.e. introns, exons, repeats, grepeats) for a list of species.

=cut

# make life easier
use warnings;
use strict;

# add includes
use GCAT::Analysis::Descriptive qw(get_Descriptive_Statistics);
use GCAT::Data::Output qw(write_Raw_To_CSV concatenate_CSV);
use GCAT::Data::Parsing qw(get_Sequence_Info get_Feature_Lengths);
use GCAT::Interface::Logging qw(logger);
use GCAT::Statistics::R;
use GCAT::Visualisation::R qw(plot_Frequency_Dist);
use Parallel::ForkManager;
use Time::HiRes qw(gettimeofday);
use Cwd;

# set variables
my ($raw_filename, $freqs_filename) = undef;

# first get the arguments
my $num_args = $#ARGV + 1;
my @inputs = @ARGV;
chomp(@inputs);

# check arguments list is sufficient
unless ($num_args >= 2) {
	logger("This script requires at least two input arguments, for the organisms you wish to download the information for.", "Error");
	exit;
}

# set start time
my $start_time = gettimeofday;

################################
# check our data is okay first #
################################
&GCAT::Data::Parsing::check_Data_OK(@inputs);

# split inputs
our $feature = shift(@inputs);
my $organisms = \@inputs;

# traverse each organism and parse the fasta
foreach my $org (@{$organisms}) {
	# let user know the crack
	print "Processing $feature advanced stats for $org...\n";
	
	#######################
	# do the basic counts #
	#######################
	my ($glen, $tlen, @data) = &GCAT::Data::Parsing::get_Feature_Lengths($feature, $org);

	#################################
	# Get GC content/NT frequencies #
	#################################
	
	my ($a, $c, $g, $t) = &GCAT::Data::Parsing::get_Sequence_Info($feature, $org);
	
	##########################
	# output RAW data to CSV #
	##########################

	&GCAT::Data::Output::write_Raw_To_CSV($org, $feature, @data);
	
	#####################################
	# return the descriptive statistics #
	#####################################

	&GCAT::Analysis::Descriptive::get_Descriptive_Statistics($glen, $tlen, $a, $c, $g, $t, $org, $feature, @data);
}

#########################
# display output charts #
#########################

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

# set end time and calculate time elapsed
my $end_time = gettimeofday;
my $elapsed = $end_time - $start_time;

# let user know we have finished
printf "Finished in %0.3f!\n", $elapsed;