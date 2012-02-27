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

	get_exons

=head1 SYNOPSIS

    get_exons species1 species2 species3...
    
=head1 DESCRIPTION

	A program to retrieve all exon sequences from all genes, for a given number of species.

=cut

# import some modules to use
use strict;
use Bio::Seq;
use Bio::SeqIO;
use Time::HiRes qw(gettimeofday tv_interval);
use Parallel::ForkManager; # used for parallel processing
use GCAT::Interface::Logging qw(logger); # for logging
use GCAT::DB::EnsEMBL;
use GCAT::Data::Output;
use Cwd;
use File::Spec;
use Log::Log4perl::DateFormat;
use Data::Dumper;

# define variables
our $index = 0;

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

# tell user what we're doing
print "Going to retrieve exons for $num_args species: @organisms...\n";

# set start time
my $start_time = gettimeofday;

# connect to EnsEMBL and setup registry object
my $registry = connect_to_EnsEMBL;

# set autoflush for stdout
local $| = 1;

# setup fork manager
my $pm = new Parallel::ForkManager(8);

# go through all fish and retrieve exon ids and coordinates
foreach my $org_name (@organisms) {
	# start fork
	my $pid = $pm->start and next;
	
	# setup output filename
	mkdir "data/$org_name" unless -d "data/$org_name";
	my $path = File::Spec->catfile($dir, "data", "$org_name", "exons.fas");
	
	# get current database name
	my $db_adaptor = $registry->get_DBAdaptor($org_name, "Core");
	my $dbname = $db_adaptor->dbc->dbname();
	my $release = $dbname;
	$release =~ m/[a-z]+_[a-z]+_core_([0-9]{2})_[0-9]{1}/;
	$release = int($1);

	# let user know we're starting
	print "Retrieving data for $dbname...\n";
	
	# retrieve all stable IDs
	my @geneids = &get_Gene_IDs($registry, $org_name);
	my $gene_count = $#geneids + 1;

	# retrieve exons from gene IDs
	my @exons = &get_Feature($registry, $org_name, "Exons");
	
	# write to fasta
	my $write_count = &write_to_SeqIO($path, "Fasta", @exons);
	
	# how many have we done?
	print "\nRetrieved $write_count exons for $org_name.\n";
	
	# finish fork
	$pm->finish;
}

# wait for all processes to finish
$pm->wait_all_children;

# set end time and calculate time elapsed
my $end_time = gettimeofday;
my $elapsed = $end_time - $start_time;

# let user know we have finished
printf "Finished in %0.3f!\n", $elapsed;
