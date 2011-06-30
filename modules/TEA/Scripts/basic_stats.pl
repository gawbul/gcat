#!/usr/bin/env perl
# Toolkit for Evolutionary Analysis.
#
# An expandable toolkit written in the Perl programming language.
# TEA utilizes the BioPerl and EnsEMBL Perl API libraries for
# evolutionary comparative genomics analysis.
#
# Part of a PhD thesis entitled "Evolutionary Genomics of Organismal Diversity".
# 
# Created by Steve Moss
# gawbul@gmail.com
# 
# C/o Dr David Lunt and Dr Domino Joyce,
# Evolutionary Biology Group,
# The University of Hull.

# make life easier
use warnings;
use strict;

# add includes
use Parallel::ForkManager;
use Time::HiRes qw(gettimeofday);
use TEA::Interface::Logging qw(logger);
use TEA::Data::Parsing;
use TEA::Data::Output;
use TEA::Analysis::Descriptive;
use TEA::Stats::RStats;

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
# check our data is okay firstÊ#
################################
&TEA::Data::Parsing::check_Data_OK(@inputs);

# split inputs
our $feature = shift(@inputs);
my @organisms = @inputs;

# setup fork manager
# my $pm = new Parallel::ForkManager(1);

# traverse each organism and parse the fasta
foreach my $org (@organisms) {
	# start fork manager
	# my $pid = $pm->start and next;

	#######################
	# do the basic counts #
	#######################
	my @data = &TEA::Data::Parsing::get_Feature_Lengths($feature, $org);

	# pull gene and transcript lengths from top
	my $glen = shift(@data);
	my $tlen = shift(@data);

	#################################
	# Get GC content/NT frequencies #
	#################################
	
	my @seq_info = &TEA::Data::Parsing::get_Sequence_Info($feature, $org);
	my ($a, $c, $g, $t) = @seq_info;

	##########################
	# output RAW data to CSV #
	##########################
	# add organism to top of data array
	unshift(@data, $feature);
	unshift(@data, $org);

	&TEA::Data::Output::write_Raw_To_CSV(@data);
	
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
	&TEA::Analysis::Descriptive::get_Descriptive_Statistics(@data);
	
	# finish fork
	# s$pm->finish;
}

# wait for all processes to finish
# $pm->wait_all_children;

########################
# display output chart #
########################

#unshift(@organisms, $feature);
#&TEA::Stats::RStats::plot_FDist(@organisms);

# set end time and calculate time elapsed
my $end_time = gettimeofday;
my $elapsed = $end_time - $start_time;

# let user know we have finished
printf "Finished in %0.3f!\n", $elapsed;