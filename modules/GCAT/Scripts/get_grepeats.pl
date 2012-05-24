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

	get_grepeats

=head1 SYNOPSIS

    get_grepeats species1 species2 species3
    
=head1 DESCRIPTION

	A program to retrieve genome wide repeat element sequences for a given number of species.

=cut

# make life easier
use strict;
use warnings;

# import some modules to use
use Time::HiRes qw(gettimeofday tv_interval);
use Parallel::ForkManager; # used for parallel processing
use GCAT::Interface::Logging qw(logger); # for logging
use GCAT::DB::EnsEMBL qw(connect_To_EnsEMBL check_Species_List get_DB_Name get_Genome_Repeats check_Genome_Repeats);
use GCAT::Visualisation::R;
use Cwd;
use File::Spec;

# get root directory and create data directory if doesn't exist
my $dir = getcwd();
mkdir "data" unless -d "data";

# get arguments
my $num_args = $#ARGV + 1;
my @organisms = @ARGV;

# check arguments list is sufficient
if ($num_args < 1) {
	logger("This script requires at least one input argument, for the organisms you wish to download the information for.", "Error");
	exit;
}

# set start time
my $start_time = gettimeofday;

# set autoflush for stdout
local $| = 1;

# setup fork manager
my $pm = new Parallel::ForkManager(8);

# connect to EnsEMBL and setup registry object
my $registry = &connect_To_EnsEMBL;

# check all species exist - no names have been mispelt?
unless (&check_Species_List($registry, @organisms)) {
	logger("You have incorrectly entered a species name or this species doesn't exist in the database.", "Error");
	exit;
}

# tell user what we're doing
print "Going to retrieve repeats for $num_args species: @organisms...\n";

# go through all organisms and retrieve repeat elements
foreach my $org_name (@organisms) {
	# start fork
	my $pid = $pm->start and next;

	# check repeats
	#&check_Genome_Repeats($registry, $org_name);
	
	# setup output filename
	mkdir "data/$org_name" unless -d "data/$org_name";
	my $path = File::Spec->catfile($dir, "data", "$org_name", "grepeats.fas");
	
	# get current database name
	my ($dbname, $release) = &get_DB_Name($registry, $org_name);
	
	# let user know we're starting
	print "Retrieving repeats for $dbname...\n";

	# retrieve repeats from gene IDs
	my $write_count = &get_Genome_Repeats($registry, $path, $org_name);
	
	# how many have we done?
	print "\nRetrieved $write_count repeat elements for $org_name.\n";
	
	# finish fork
	$pm->finish;
}

# build barplot
#&GCAT::Visualisation::R::plot_Stacked_Barplot("grepeats", @organisms);

# wait for all processes to finish
$pm->wait_all_children;

# set end time and calculate time elapsed
my $end_time = gettimeofday;
my $elapsed = $end_time - $start_time;

# let user know we have finished
printf "Finished in %0.3f!\n", $elapsed;