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

=head1 NAME

	get_unique_introns

=head1 SYNOPSIS

    get_unique_introns species1 species2 species3
    
=head1 DESCRIPTION

	A program to retrieve all intron sequences from all genes, for a given number of species.

=cut

# import some modules to use
use strict;
use Time::HiRes qw(gettimeofday tv_interval);
use Parallel::ForkManager; # used for parallel processing
use TEA::Interface::Logging qw(logger); # for logging
use TEA::Data::Parsing;
use TEA::Data::Output;
use Cwd;
use File::Spec;

# get arguments
my $num_args = $#ARGV + 1;
my @organisms = @ARGV;

# check arguments list is sufficient
if ($num_args < 1) {
	logger("This script requires at least one input argument, for the organisms you wish to download the information for.", "Error");
	exit;
}

# tell user what we're doing
print "Going to retrieve unique introns for $num_args species: @organisms...\n";

# set start time
my $start_time = gettimeofday;

# traverse organisms and retrieve data
foreach my $organism (@organisms) { 
	my @data = &TEA::Data::Parsing::get_Unique_Features('introns', $organism);

	# output to CSV
	unshift(@data, 'introns');
	unshift(@data, $organism);
	&TEA::Data::Output::write_Unique_To_CSV(@data);
}

# set end time and calculate time elapsed
my $end_time = gettimeofday;
my $elapsed = $end_time - $start_time;

# let user know we have finished
printf "Finished in %0.3f!\n", $elapsed;