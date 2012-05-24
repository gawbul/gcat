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

	get_gene_structure

=head1 SYNOPSIS

    get_gene_structure species1 species2 species3...
    
=head1 DESCRIPTION

	A program to retrieve all transcript UTRs and determine location of introns relative to 5', 3' and CDS

=cut

# make life easier
use strict;
use warnings;

# includes
use Time::HiRes qw(gettimeofday);
use GCAT::DB::EnsEMBL qw(connect_To_EnsEMBL get_Gene_Structure check_Species_List);
use GCAT::Data::Output qw(write_Array_To_File);
use GCAT::Interface::Logging qw(logger);
use GCAT::Visualisation::R qw(plot_Gene_Structure);
use Data::Dumper;
use File::Spec;
use Cwd;

# get arguments
my $num_args = $#ARGV + 1;
my @organisms = @ARGV;

# check arguments list is sufficient
if ($num_args < 1) {
	logger("This script requires at least one input argument, for the organism(s) you wish to download the information for.", "Error");
	exit;
}

# connect to EnsEMBL and setup registry object
my $registry = &connect_To_EnsEMBL;

# check all species exist - no names have been mispelt?
unless (&check_Species_List($registry, @organisms)) {
	logger("You have incorrectly entered a species name or this species doesn't exist in the database.", "Error");
	exit;
}

# get root directory and create data directory if doesn't exist
my $dir = getcwd();
mkdir "data" unless -d "data";

# tell user what we're doing
print "Going to retrieve gene structure for $num_args species: @organisms...\n";

# set start time
my $start_time = gettimeofday;

# traverse each organism and for UTR stuff - Dave
foreach my $org (@organisms) {
	# assign array reference 
	my $gene_structure = &GCAT::DB::EnsEMBL::get_Gene_Structure($registry, $org);

	Dumper($gene_structure);
		
	# setup output filename
	mkdir "data/$org" unless -d "data/$org";
	my $path = File::Spec->catfile($dir, "data", "$org", "gene_structure.csv");

	# write data to file
	&GCAT::Data::Output::write_Array_To_File($path, $gene_structure);
	
	# setup PDF filename
	$path = File::Spec->catfile($dir, "data", "$org", "gene_structure.pdf");
		
	# visualize gene structure
	&GCAT::Visualisation::R::plot_Gene_Structure($path, $gene_structure);
}

# set end time and calculate time elapsed
my $end_time = gettimeofday;
my $elapsed = $end_time - $start_time;

# let user know we have finished
printf "Finished in %0.3f!\n", $elapsed;