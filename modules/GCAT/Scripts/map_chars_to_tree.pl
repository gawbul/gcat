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

	map_chars_to_tree

=head1 SYNOPSIS

    map_chars_to_tree
    
=head1 DESCRIPTION

	A program to map the retrieved genome characteristics to a phylogenetic tree.

=cut

# make life easier
use strict;
use warnings;

# includes
use Time::HiRes qw(gettimeofday);
use GCAT::DB::EnsEMBL;
use GCAT::Analysis::Descriptive;
use GCAT::Interface::Logging;
use Cwd;
use File::Spec;
use Text::CSV_XS;
use Statistics::R;

# get arguments
my $num_args = $#ARGV + 1;
my $tree = $ARGV[0];

# check arguments list is sufficient
if ($num_args < 1) {
	print "This script requires at least one input argument, for the phylogenetic tree you wish to map the characters to.\n";
	exit;
}

# tell user what we're doing
print "Mapping genome characters to tree : $tree...\n";

# set start time
my $start_time = gettimeofday;

#######

# setup R and start clean R session
my $R = Statistics::R->new();
$R->startR;
	
# send R commands to build matrix
$R->send("library(ape)");
$R->send("genome_tree <- read.tree(file=\"$tree\")");

# end R session
$R->stopR;	

#######

# set end time and calculate time elapsed
my $end_time = gettimeofday;
my $elapsed = $end_time - $start_time;

# let user know we have finished
printf "Finished in %0.3f!\n", $elapsed;