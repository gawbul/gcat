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

    basic_stats feature species1 species2 species3...
    
=head1 DESCRIPTION

	Get a break down of the classes and total number and length of a particular feature (i.e. introns, exons, repeats, grepeats) for a list of species.

=cut

# make life easier
use warnings;
use strict;

# add includes
use GCAT::Interface::Logging qw(logger);
use GCAT::Data::Parsing qw(check_Data_OK get_Basic_Stats);
use GCAT::Data::Output qw(write_Array_To_CSV);
use Parallel::ForkManager; # use for parallel code
use Time::HiRes qw(gettimeofday);

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

# check our data is okay first
&GCAT::Data::Parsing::check_Data_OK(@inputs);

# split inputs
our $feature = shift(@inputs);
my $organisms = \@inputs;

# setup fork manager
my $pm = new Parallel::ForkManager(8);

# traverse each organism and parse the fasta
foreach my $org (@{$organisms}) {
	# get basic stats
	my @data = &GCAT::Data::Parsing::get_Basic_Stats($feature, $org);

	# write output
	&write_Array_To_CSV($feature, $org, @data);

	# finish fork
	$pm->finish;
}
# wait for all processes to finish
$pm->wait_all_children;

# set end time and calculate time elapsed
my $end_time = gettimeofday;
my $elapsed = $end_time - $start_time;

# let user know we have finished
printf "Finished in %0.3f!\n", $elapsed;