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
use GCAT::Interface::Logging qw(logger);
use Statistics::R;
use File::Spec;
use Cwd;

# export the subroutines
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(check_R_Environ map_Chars_to_Tree);

# check the R environment is setup for GCAT
sub check_R_Environ {
	# setup variables
	my @pkg_list = ("ape", "geiger", "gdata");
	my $mirror = "http://star-www.st-andrews.ac.uk/cran/";
	
	# setup new R object
	my $R = Statistics::R->new();
	
	# start R session
	$R->startR;
	
	# define is.installed function
	$R->send("is.installed <- function(mypkg) is.element(mypkg, installed.packages()[,1])");
	
	# let user know what we're doing
	print "Checking R packages (@pkg_list) are installed...\n";

	# check if packages are installed
	foreach my $pkg (@pkg_list) {
		$R->send("is.installed(\"" . $pkg . "\")");
		my $ret = $R->read();
		if ($ret eq "[1] TRUE") {
			$R->send("library(" . $pkg . ")");
		}
		elsif ($ret eq "[1] FALSE") {
			#$R->send("Sys.setenv(http_proxy=\'http://slb-webcache.hull.ac.uk:3128\')"); # change this to your proxy server details and uncomment if using a proxy
			$R->send("options(repos=structure(c(CRAN=\"" . $mirror . "\")))"); # change this to your preferred mirror
			$R->send("install.packages(\"" . $pkg . "\", dependencies=T)");
			$R->send("library(" . $pkg . ")");
		}
		else {
			logger("An unknown error occurred while testing if R package \"$pkg\" exists!\n", "Error");
			exit;
		}
	}
	
	# stop R session
	$R->stopR;
	
	# let user know we're done
	print "Finished!\n";
}

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