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

package GCAT::Visualisation::R;

# make life easier
use warnings;
use strict;

# import some required modules
use Statistics::R;
use Cwd;

# use this routine to plot nucleotide frequencies
sub plot_NFs {
	return;	
}


# plot basic stats output
sub plot_Raw_Dist {

}

# plot frequency distribution
sub plot_Frequency_Dist {
	# get filename
	my ($filename, @organisms) = @_;

	# build path
	my $dir = getcwd();
	my $path = File::Spec->catfile($dir , "data");

	# setup in file
	my $infile = File::Spec->catfile($path, $filename);
	
	# setup out file
	my $output = substr($filename, 0, -4);
	my $outfile = File::Spec->catfile($path, $output);

	print $outfile . "\n";
	# setup R objects
	my $R = Statistics::R->new();
	
	# start R
	$R->startR();
	
	# main R script
	$R->send('library(zoo)');
	$R->send('library(gdata)');

	$R->send('freqs <- read.csv("' . $infile . '", header=TRUE)');
	$R->send('attach(freqs)');	
	$R->send('names(freqs)');	
	my $ret = $R->get();
	
	print Dumper($ret) . "\n";

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
	
	# tell user what we've done
	print "Outputted frequency distribution plot to $outfile.\n";
}

1;