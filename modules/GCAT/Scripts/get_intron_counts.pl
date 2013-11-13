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

	get_intron_counts

=head1 SYNOPSIS

    get_intron_counts species1 species2 species3
    
=head1 DESCRIPTION

	A program to retrieve all intron counts from all genes, for a given number of species.

=cut

# import some modules to use
use strict;
use Time::HiRes qw(gettimeofday tv_interval);
use Parallel::ForkManager; # used for parallel processing
use GCAT::Interface::Logging qw(logger); # for logging
use GCAT::DB::EnsEMBL qw(connect_To_EnsEMBL check_Species_List get_Gene_IDs);
use Sys::CPU;
use File::Spec;
use Cwd;
use Text::CSV_XS;

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

# setup CSV
my $csv = Text::CSV_XS->new ({binary => 1, eol => $/});

# set start time
my $start_time = gettimeofday;

# get number of processors
my $number_of_cpus = 1;#Sys::CPU::cpu_count();

print "\nFound ${number_of_cpus} CPUs, setting up for $number_of_cpus parallel threads\n\n";

# setup number of parallel processes ()
my $pm = new Parallel::ForkManager($number_of_cpus); # set number of processes to number of processors

# tell user what we're doing
print "Going to retrieve intron counts for $num_args species: @organisms...\n";

# open file for output
my $outfile = File::Spec->catfile($dir, "data", "intron_counts_data.csv");
open my $outfileh, ">$outfile" or die $!;
$csv->print ($outfileh, ["species_name", "gene_id", "gene_length", "transcript_length", "cdna_start", "cdna_end", "coding_region_start", "coding_region_end", "5p_utr_start", "5p_utr_end", "3p_utr_start", "3p_utr_end", "introns_count", "introns_per_nt", "introns_per_bond"]) or $csv->error_diag;

# go through all species and retrieve introns
my $count = 0;
foreach my $org_name (@organisms) {
	# start fork
	my $pid = $pm->start and next;
	
	# setup DB adapters
	my $gene_adaptor = $registry->get_adaptor($org_name, 'Core', 'Gene');
	my $tr_adaptor = $registry->get_adaptor($org_name, 'Core', 'Transcript');
	
	# get current database name
	my $db_adaptor = $registry->get_DBAdaptor($org_name, "Core");
	my $dbname = $db_adaptor->dbc->dbname();
	
	# retrieve all stable IDs
	my @geneids = &get_Gene_IDs($registry, $org_name);
	
	# go through each gene stable ID and retrieve canonical transcript and introns
	foreach my $geneid (@geneids)
	{
		# fetch the gene by stable id
		my $gene = $gene_adaptor->fetch_by_stable_id($geneid);
		
		# setup transcript adaptor to retrieve introns
		my $tr = $gene->canonical_transcript();
		
		# get all introns for the gene transcript
		my $introns = $tr->get_all_Introns();
		
		# work out values to output
		my $gene_length = $gene->length;
		my $transcript_length = $tr->length; # sum of exons
		my $cdna_start = $tr->cdna_coding_start ? $tr->cdna_coding_start : 0;
		my $cdna_end = $tr->cdna_coding_end ? $tr->cdna_coding_end : 0;
		my $coding_start = $tr->coding_region_start ? $tr->coding_region_start : 0;
		my $coding_end = $tr->coding_region_end ? $tr->coding_region_end : 0;
		my $_5putr = defined $tr->cdna_coding_start ? $tr->five_prime_utr_Feature : undef;
		my $_3putr = defined $tr->cdna_coding_end ? $tr->three_prime_utr_Feature : undef;
		my $_5putr_start = defined $_5putr ? $_5putr->start : 0;
		my $_5putr_end = defined $_5putr ? $_5putr->end : 0;
		my $_3putr_start = defined $_3putr ? $_3putr->start : 0;
		my $_3putr_end = defined $_3putr ? $_3putr->end : 0;
		my $introns_count = scalar(@$introns);
		my $introns_per_nt = undef;
		my $introns_per_bond = undef;	
		if ($introns_count > 0) {
			$introns_per_nt = $introns_count / $transcript_length;
			$introns_per_bond = $introns_count / ($transcript_length - 1);
		}
		else {
			$introns_per_nt = 0;
			$introns_per_bond = 0;
		}
		# output this to file
		# species_name	gene_id	cdna_length	intron_count	introns_per_nt	introns_per_bond
		$csv->print ($outfileh, [$org_name, $geneid, $gene_length, $transcript_length, $cdna_start, $cdna_end, $coding_start, $coding_end, $_5putr_start, $_5putr_end, $_3putr_start, $_3putr_end, $introns_count, $introns_per_nt, $introns_per_bond]) or $csv->error_diag;
	}

	# finish fork
	$pm->finish;
}
# wait for all processes to finish
$pm->wait_all_children;

# close file
close $outfileh;

# set end time and calculate time elapsed
my $end_time = gettimeofday;
my $elapsed = $end_time - $start_time;

# let user know we have finished
printf "Finished in %0.3f!\n", $elapsed;
