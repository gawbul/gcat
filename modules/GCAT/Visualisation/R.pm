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
use GCAT::Interface::Logging qw(logger);
use Statistics::R;
use File::Spec;
use Cwd;

# export the subroutines
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(plot_NFs plot_Stacked_Barplot plot_Frequency_Dist plot_Gene_Structure);

# use this routine to plot nucleotide frequencies
sub plot_NFs {
	
}

# plot stacked bar plot for repeats etc
sub plot_Stacked_Barplot {
	# get arguments
	my ($feature, @organisms) = @_;

	# setup out file
	my $dir = getcwd();
	srand (time ^ $$ ^ unpack "%L*", `ps axww | gzip -f`); # seed random number generator
	my $random = int(rand(9999999999)); # get random number
	my $outfile = File::Spec->catfile($dir, "data", "$feature\_$random.pdf");

	# setup new R object
	my $R = Statistics::R->new();
	
	# start R
	$R->startR();

	# define return variable
	my $ret = undef;
	
	#################	
	# main R script #
	#################
	
	
	
	
	
	# stop R
	$R->stopR();
	
	# tell user what we've done
	print "Outputted stacked barplot to $outfile\n";					
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

	# create check for odd and even functions
	$R->send('is.even <- function(x) x %% 2 == 0');
	$R->send('is.odd <- function(x) x %% 2 != 0');

	# create odd and even lists
	$R->send('nums <- c(1:length(freqs))');
	$R->send('even_nums <- nums[is.even(nums)]');
	$R->send('odd_nums <- nums[is.odd(nums)]');

	# roundup function - round numbers up to the nearest 10 ^ (number length minus 2)
	$R->send('roundup <- function(x) (ceiling(x / 10^(nchar(x) - 2)) * 10^(nchar(x) - 2))');
	
	# work out max values
	$R->send('y_max <- roundup(max(na.omit(freqs[,even_nums])))');
	$R->send('x_max <-roundup(max(apply(na.omit(as.matrix(freqs[,odd_nums])), 2, function(x) quantile(x, .75))))');

	# setup PDF graphics device
	$R->send('pdf(file="' . $outfile . '", width=12, height=12)');

	# build colours
	$R->send('cols <- as.character(sample(colors()[grep("dark|sky|medium",colors())],' . scalar(@organisms) . ', replace=F))');

	# plot frequency distribution 
	$R->send('plot(0, 0, type="l", xlim=c(0,x_max), xlab="' . substr(ucfirst($feature), 0, -1) . ' Size (bps)", ylim=c(0,y_max), ylab="Frequency", main="Frequency of ' . substr(ucfirst($feature), 0, -1) . ' Size in ' . scalar(@organisms) .' Organism(s)")');
	my $count = 1;
	foreach my $org (@organisms) {
		$R->send('lines(' . $org . '.size, ' . $org . '.freqs, type = "l", col=cols[' . $count . '])');
		$count++;
	}				

	# add legend
	$R->send('legend("topright", inset=0.05, c("' . join("\",\"", @organisms) . '"), lty=1, lwd=2, col=cols)');

	# turn graphics device off, to allow writing to PDF file
	$R->send('dev.off()');
	
	# stop R
	$R->stopR();
	
	# tell user what we've done
	print "Outputted frequency distribution plot to $outfile\n";
}

# plot gene structure
sub plot_Gene_Structure {
	# get input arguments
	my ($filename, $data) = @_;
	
	
}

1;1