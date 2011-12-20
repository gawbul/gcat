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

	basic_stats

=head1 SYNOPSIS

    basic_stats species1 species2 species3...
    
=head1 DESCRIPTION

	A program to retrieve all basic genomic descriptive statistics and produce plot.

=cut

# make life easier
use warnings;
use strict;

# add includes
use Parallel::ForkManager;
use Time::HiRes qw(gettimeofday);
use GCAT::Interface::Logging qw(logger);
use GCAT::Data::Parsing;
use GCAT::Data::Output;
use GCAT::Analysis::Descriptive;
use GCAT::Statistics::R;

# first get the arguments
my $num_args = $#ARGV + 1;
my @inputs = @ARGV;
chomp(@inputs);

# check arguments list is sufficient
unless ($num_args >= 2) {
	print("This script requires at least two input arguments, for the organisms you wish to download the information for.\n");
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
my @organisms = @inputs;

# traverse each organism and parse the fasta
foreach my $org (@organisms) {
	#######################
	# do the basic counts #
	#######################
	my @data = &GCAT::Data::Parsing::get_Feature_Lengths($feature, $org);

	# pull gene and transcript lengths from top
	my $glen = shift(@data);
	my $tlen = shift(@data);

	#################################
	# Get GC content/NT frequencies #
	#################################
	
	my @seq_info = &GCAT::Data::Parsing::get_Sequence_Info($feature, $org);
	my ($a, $c, $g, $t) = @seq_info;

	##########################
	# output RAW data to CSV #
	##########################
	# add organism to top of data array
	unshift(@data, $feature);
	unshift(@data, $org);

	&GCAT::Data::Output::write_Raw_To_CSV(@data);
	
	# add gene and transcript lengths back
	unshift(@data, $t);
	unshift(@data, $g);
	unshift(@data, $c);
	unshift(@data, $a);
	unshift(@data, $tlen);
	unshift(@data, $glen);
	
	#####################################
	# return the descriptive statistics #
	#####################################
	&GCAT::Analysis::Descriptive::get_Descriptive_Statistics(@data);
}

########################
# display output chart #
########################

#unshift(@organisms, $feature);
#&GCAT::Visualisation::R::plot_FDist(@organisms);

# set end time and calculate time elapsed
my $end_time = gettimeofday;
my $elapsed = $end_time - $start_time;

# let user know we have finished
printf "Finished in %0.3f!\n", $elapsed;