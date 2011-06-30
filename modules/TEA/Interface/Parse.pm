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

package TEA::Interface::Parse;

# make life easier
use warnings;
use strict;

=head1 NAME

tea - Parse interface!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This provides an interface for parsing input from the command line and processing the pipeline input file.

Perhaps a little code snippet.

    use TEA::Interface::Parse;

    my $foo = tea->new();
    ...

=cut

=head1 AUTHOR

"Steve Moss", C<< <"gawbul at gmail.com"> >>

=cut

# import necessary requires
use Getopt::Long;
use Cwd;
use File::Spec;
use TEA::Interface::Logging qw(logger);
use TEA::Interface::CLI;

# set variables for get opts
our $filename = "tea-pipeline.txt";
our $cmd = 0;

# this subroutine parses the input
sub input_Parser() {
	# setup getopts
	GetOptions("file=s" => \$filename,
			   "cmd"	=> \$cmd);
	
	# do the processing
	if (!$cmd) {
		# if command not set then process pipeline
		&process_Pipeline($filename);
	}
	elsif ($cmd) {
		# if command set then load command line interface
		&TEA::Interface::CLI::load_CLI();
	}
	else {
		die ("Caught some unexpected error whilst processing command line inputs.\n$filename\n$cmd");
	}
}

# this processes the input pipeline file
sub process_Pipeline() {
	# tell user what we are doing
	print "Processing commands from pipeline file $filename...\n\n";
	
	# open the file and read a line at a time
	open PIPELINE, "<$filename" or die $!;
	# loop through file
	while (my $line = <PIPELINE>) {
		# remove any newlines
		chomp $line;
		
		# check if this is a comment line or a blank line
		if ($line =~ /^#/ or $line eq "") {
			next; # do nothing - jump to next
		}
		# remove any end of line comments first
		my @parts = split(/#/, $line);
		$line = $parts[0];
		
		# lets split into command and arguments now
		@parts = split(/ /, $line);
		my $command = shift(@parts); # shift off the top entry
		
		# execute the script
		my $dir = getcwd();
		my $path = File::Spec->catfile($dir, 'modules', 'TEA', 'Scripts', $command . ".pl");

		# check exists and then execute if so
		if (!-e $path) {
			warn("Script $path not found.\n");
		}
		else {
			system("perl $path @parts");
			logger("Loaded $path with @parts", "Debug");
		}
		print "\n";
	}
	close(PIPELINE);
}

1;
