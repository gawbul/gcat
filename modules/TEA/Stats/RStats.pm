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

package TEA::Stats::RStats;

# make life easier
use warnings;
use strict;

# some imports
use File::Spec;
use Cwd;
use Text::CSV_XS;
use TEA::Data::Output;
use Statistics::R;

# run R - deprecated
sub run_R {
	# get code
	my @lines = @_;
	
	# setup temporary R source file
	my $dir = getcwd();
	my $file = File::Spec->catfile($dir, "tea_tmp.R");
	
	# write lines to the R source file
	while (my $line = shift(@lines)) {
		open R_FILE, ">>" , $file;
		print R_FILE $line . "\n";
		close R_FILE;
	}
	
	# execute the file in R
	my $r_bin = ("/usr/bin/R");
	system("$r_bin --vanilla --silent --quiet --slave -f $file");
	
	# remove temporary file
	unlink $file;
}

# use this routine to plot nucleotide frequencies
sub plot_NFs {
	return;	
}

# plot basic stats output
sub plot_FDist {
	# declare variables
	my ($feature, $dir, $path, $input, $output, $raw_csv);
	my @organisms;
	
	# get data from arguments
	$feature = shift(@_);
	@organisms = @_;
	$dir = getcwd();
	$path = File::Spec->catfile($dir , "data");
	
	# setup out file
	$output = File::Spec->catfile($path, $feature . "_fdist.png");

	# setup R objects
	my $R = Statistics::R->new();
	my $ret;
	
	# start R
	$R->startR();
	
	# main R script
	$R->send('library(zoo)');
	$R->send('library(gdata)');

	foreach my $org (@organisms) {
		$R->send($org . '.raw <- read.csv("' . File::Spec->catfile($dir, "data", $org, $feature . "_raw.csv") . '", header=TRUE)');
		$R->send('attach(' . $org . '.raw)');	
		$R->send('names(' . $org . '.raw)');	
	}

	foreach my $org (@organisms) {
		$R->send($org . '_counts <- table(' . $org . '.raw)');
		$R->send($org . '_counts <- as.matrix(' . $org . '_counts)');
		$R->send($org . '_counts[is.na(' . $org . '_counts) <- 0');
		$R->send($org . '_counts[is.nan(' . $org . '_counts) <- 0');
	}
	$R->send('x_max = 5000');
	$R->send('y_max = 10000');

	$R->send('png(filename="' . $output . '", width=1024, height=768)');
	#$R->send('par(mar=c(5,5,5,3))');

	$R->send('plot(0, 0, type="l", xlab="Intron Size (bps)", ylab="Log Frequency", main="Frequency of Intron Size")');
	foreach my $org (@organisms) {
		$R->send('lines(' . $org . '_counts, type = "l", col=rainbow(65355))');

	}
	$R->send('legend("topright", inset=.05, c("' . join("\",\"", @organisms) . '"), lty=1)');

	$R->send('dev.off()');
	
	# stop R
	$R->stopR();
}


1;