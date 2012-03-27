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
	# get arguments
	my ($infile, $feature, @organisms) = @_;
	
	# setup out file
	my $outfile = substr($infile, 0, -4) . ".pdf";

	# setup new R object
	my $R = Statistics::R->new();
	
	# start R
	$R->startR();

	# define return variable
	my $ret = undef;

	#################	
	# main R script #
	#################
	
	# load file
	$R->send('freqs <- read.csv("' . $infile . '", header=TRUE)');
	$R->send('attach(freqs)');
	$R->send('names(freqs)');	

	# work out maximum sizes
	$R->send('x_max <- 0');
	$R->send('y_max <- 0');
	# traverse organisms
	foreach my $org (@organisms) {
		$R->send('if (max(' . $org . '.size' . ') > x_max) x_max <- max(' . $org . '.size)');
		$R->send('if (max(' . $org . '.freqs' . ') > y_max) y_max <- max(' . $org . '.freqs)');
	}
	$R->send('x_max');	
	$R->send('y_max');	

	# setup PDF graphics device
	$R->send('pdf(file="' . $outfile . '", width=12, height=12)');

	# build colours
	$R->send('cols <- as.character(sample(colours(),' . scalar(@organisms) . ', replace=F))');

	# plot frequency distribution 
	$R->send('plot(0, 0, type="l", xlim=c(0,x_max), xlab="' . substr(ucfirst($feature), 0, -1) . ' Size (bps)", ylim=c(0,y_max), ylab="Frequency", main="Frequency of ' . substr(ucfirst($feature), 0, -1) . ' Size in ' . scalar(@organisms) .' Organism(s)")');
	foreach my $org (@organisms) {
		$R->send('lines(' . $org . '.size, ' . $org . '.freqs, type = "l", col=cols)');
	}				

	# add legend
	
	$R->send('legend("topright", inset=.05, c("' . join("\",\"", @organisms) . '"), lty=1, col=cols)');

	# turn graphics device off, to allow writing to PDF file
	$R->send('dev.off()');
	
	# stop R
	$R->stopR();
	
	# tell user what we've done
	print "Outputted frequency distribution plot to $outfile\n";
}

1;