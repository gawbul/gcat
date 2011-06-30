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

# first get the arguments
my $num_args = $#ARGV + 1;
my @inputs = @ARGV;
chomp(@inputs);

# check arguments list is sufficient
unless ($num_args >= 1) {
	print("This script requires at least one input argument, for the organism(s) you wish to download the information for.\n");
	exit;
}

# set start time
my $start_time = gettimeofday;

################################
# check our data is okay firstÊ#
################################
unshift(@inputs, "repeats");
&TEA::Data::Parsing::check_Data_OK(@inputs);

# split inputs
our $feature = shift(@inputs);
my @organisms = @inputs;

# traverse each organism and parse the fasta
foreach my $org (@organisms) {
	####################
	# get repeat stats #
	####################
	my @data = &TEA::Data::Parsing::get_Repeat_Stats($feature, $org);
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