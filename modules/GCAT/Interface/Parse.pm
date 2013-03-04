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

package GCAT::Interface::Parse;

# make life easier
use warnings;
use strict;

=head1 NAME

GCAT - Parse interface!

=cut

=head1 SYNOPSIS

This provides an interface for parsing input from the command line and processing the pipeline input file.

=cut

=head1 AUTHOR

"Steve Moss", C<< <"gawbul at gmail.com"> >>

=cut

# import necessary requires
use Getopt::Long qw(HelpMessage GetOptions);
use Cwd;
use File::Spec;
use GCAT::Interface::Logging qw(logger);
use GCAT::Interface::CLI;
use POSIX;

# set variables for get opts
my $filename = "gcat-pipeline.txt";
my $cmd = 0;

# check input arguments
sub check_input_Options {
	# get arguments
	my $arguments = @_;
	
	# setup getopts
	GetOptions(	"file=s" => \$filename,
		   		"cmd"	 => \$cmd,
		   		"help|?" => \&help,
	) || usage();
}

# print usage
sub usage {
	# display usage to command line
	print STDERR @_ if @_;
	print STDERR "Usage:\t--file or -f\t= process input filename (requires filename as argument)\n\t--cmd or -c\t= start in interactive mode\n\n";
	exit(1);
}

sub help {
	# display help on command line
	print "Usage:\t--file or -f\t= process input filename (requires filename as argument)\n\t--cmd or -c\t= start in interactive mode\n\n";
	exit(0);
}

# this subroutine parses the input
sub input_Parser() {
	# setup getopts
	GetOptions(	"file=s" => \$filename,
		   		"cmd"	 => \$cmd,
	);
	
	# do the processing
	if (!$cmd) {
		# if command not set then process pipeline
		&process_Pipeline($filename);
	}
	elsif ($cmd) {
		# if command set then load command line interface
		&GCAT::Interface::CLI::load_CLI();
	}
	else {
		logger("Caught some unexpected error whilst processing command line inputs.\n$filename\n$cmd", "Error");
		die ();
	}
}

# this processes the input pipeline file
my ($startFromBool, $startline) = 0;
sub process_Pipeline() {
	# check to see if pipline temp file exists from previous failed run
	my $dir = getcwd();
	my @files = glob("$dir/gcat-pipeline-run-*.tmp");
	if (scalar(@files) != 0) {
		# reverse sort files so most recent run is at top - shouldn't be more than one, but do this just in case
		@files = sort {$b cmp $a} @files;
		my $lastrun = $files[0];
	
		# get last command
		open LASTRUN, "<$lastrun" or die $!;
		my @lines = <LASTRUN>;
		my $lastline = $lines[-1];
		my $linenums = scalar(@lines);
		$startline = int($linenums);
		close(LASTRUN);
	
		# inform the user and get how we will continue
		logger("Previous failed run detected - see $lastrun", "Error");
		print "Pipeline failed previous run at line $linenums: $lastline\n";
		
		# loop until correct option pressed
		$startFromBool = 1;
		my $userinput = "Y";
		while (1) {
			# get user input
			print "\nWould you like to continue from the previous command? (Y/n): ";
			$userinput = <>;
			chomp($userinput);
			# check what we have
			if ($userinput eq '') {
				$userinput = "Y";
				$startFromBool = 1;
				last;
			}
			elsif ($userinput eq "Y" or $userinput eq "y") {
				$startFromBool = 1;
				last;
			}
			elsif ($userinput eq "N" or $userinput eq "n") {
				# delete the tmp files and continue as normal
				print $dir . "\n";
				unlink(<$dir/*.tmp>) or die $!;
				$startFromBool = 0;
				last;
			}
			else {
				print "Unrecognised option ($userinput)";
			}
		}
	}
	
	# tell user what we are doing
	print "Processing commands from pipeline file $filename...\n\n";
	logger("Starting pipeline processing", "Info");
	
	# create temp file
	my ($sec, $min, $hr, $day, $mon, $year) = localtime;
	my $timestamp = POSIX::strftime("%d%m%Y%H%M%S", localtime);
	open TEMP, ">$dir/gcat-pipeline-run-$timestamp.tmp" or die $!;

	# open the file and read a line at a time
	my $path = File::Spec->catfile($dir, $filename);
	open PIPELINE, "<$path" or die $!;
	# loop through file
	my $count = 1;
	while (my $line = <PIPELINE>) {
		# remove any newlines
		chomp $line;
		
		# check if this is a comment line or a blank line
		if ($line =~ /^#/ or $line eq "") {
			next; # do nothing - jump to next
		}

		# go to correct line, if we are continuing from a previous failed run
		if ($startFromBool == 1 && $count < $startline) {
			$count++;
			next;
		}
	
		# remove any end of line comments first
		my @parts = split(/#/, $line);
		$line = $parts[0];
		
		# lets split into command and arguments now
		@parts = split(/ /, $line);
		my $command = shift(@parts); # shift off the top entry
		
		# execute the script
		my $dir = getcwd();
		my $path = File::Spec->catfile($dir, 'modules', 'GCAT', 'Scripts', $command . ".pl");

		# check exists and then execute if so
		if (!-e $path) {
			warn("Script $path not found.\n");
			logger("Pipeline entry $count: $path not found", "Error");
		}
		else {
			logger("Processing pipeline entry $count: $path with @parts", "Info");
			print TEMP "$line\n";
			system("perl $path @parts");
		}
		print "\n";
		$count++;
	}
	close(TEMP);
	close(PIPELINE);
	
	# remove temporary file
	logger("Finished pipeline processing", "Info");
	unlink(<$dir/*.tmp>) or die $!;
}

1;
