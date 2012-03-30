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
use GCAT::Statistics::R qw(check_R_Environ);
use Statistics::R;
use Cwd;

# export the subroutines
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(plot_NFs plot_Stacked_Barplot plot_Frequency_Dist);

# use this routine to plot nucleotide frequencies
sub plot_NFs {
	# check our R environment
	unless (!&check_R_Environ) {
		logger("Couldn't confirm R environment setup", "Error");
		exit;
	}
	
}

# plot stacked bar plot for repeats etc
sub plot_Stacked_Barplot {
	# check our R environment
	unless (!&check_R_Environ) {
		logger("Couldn't confirm R environment setup", "Error");
		exit;
	}
		
}

# plot frequency distribution
sub plot_Frequency_Dist {
	# check our R environment
	unless (!&check_R_Environ) {
		logger("Couldn't confirm R environment setup", "Error");
		exit;
	}
	
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
		$R->send('if (max(na.omit(' . $org . '.size' . ')) > x_max) x_max <- max(na.omit(' . $org . '.size))');
		$R->send('if (max(na.omit(' . $org . '.freqs' . ')) > y_max) y_max <- max(na.omit(' . $org . '.freqs))');
	}
	
	$R->send('x_max');	
	$R->send('y_max');	

	# setup PDF graphics device
	$R->send('pdf(file="' . $outfile . '", width=12, height=12)');

	# build colours
	$R->send('cols <- as.character(sample(rainbow(128),' . scalar(@organisms) . ', replace=F))');

	# plot frequency distribution 
	$R->send('plot(0, 0, type="l", xlim=c(0,x_max), xlab="' . substr(ucfirst($feature), 0, -1) . ' Size (bps)", ylim=c(1,y_max), log="y", ylab="Log Frequency", main="Frequency of ' . substr(ucfirst($feature), 0, -1) . ' Size in ' . scalar(@organisms) .' Organism(s)")');
	my $count = 1;
	foreach my $org (@organisms) {
		$R->send('lines(' . $org . '.size, ' . $org . '.freqs, type = "l", col=cols[' . $count . '])');
		$count++;
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