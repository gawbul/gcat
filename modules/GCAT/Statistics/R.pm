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

package GCAT::Statistics::R;

# make life easier
use warnings;
use strict;

# some imports
use File::Spec;
use Cwd;
use Text::CSV_XS;
use GCAT::Data::Output;
use Statistics::R;

# map character matrix to phylogenetic tree
sub map_Chars_to_Tree {
	# take input from the user
	my ($char_matrix_file, $phylogenetic_tree_file) = @_;
	
	# check the files exist
	if (! -e $char_matrix_file) {
		print("The character matrix file was not found at $char_matrix_file\n");
		exit;
	}
	if (! -e $phylogenetic_tree_file) {
		print("The phylogenetic tree file was not found at $phylogenetic_tree_file\n");
		exit;
	}
	
	# let user know what we're doing
	print "Mapping character matrix to the phylogenetic tree...";

	# setup R objects
	my $R = Statistics::R->new();
		
	# start R
	$R->startR();
	
	# main R script
	$R->send('library(ape)');
	
	my $ret;
	
	# stop R
	$R->stopR();
			
	##> new <- read.csv(file="/Users/stevemoss/Desktop/test.txt", row.names=1)
	##> new <- as.matrix(new)
	
}

1;