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

	get_introns

=head1 SYNOPSIS

    get_intron_countss species1 species2 species3
    
=head1 DESCRIPTION

	A program to retrieve all intron counts from all genes, for a given number of species.

=cut

# import some modules to use
use strict;
use Time::HiRes qw(gettimeofday tv_interval);
use Parallel::ForkManager; # used for parallel processing
use GCAT::Interface::Logging qw(logger); # for logging
use GCAT::DB::EnsEMBL qw(connect_To_EnsEMBL);

# define variables
my %gene_type = ();

# get arguments
my $num_args = $#ARGV + 1;
my @organisms = @ARGV;

# check arguments list is sufficient
if ($num_args < 1) {
	logger("This script requires at least one input argument, for the organisms you wish to download the information for.", "Error");
	exit;
}

# tell user what we're doing
print "Going to retrieve intron counts for $num_args species: @organisms...\n";

# set start time
my $start_time = gettimeofday;

# connect to EnsEMBL and setup registry object
my $registry = &connect_To_EnsEMBL;

# setup fork manager
my $pm = new Parallel::ForkManager(8);

# go through all fish and retrieve exon ids and coordinates
my $count = 0;
foreach my $org_name (@organisms) {
	# start fork
	my $pid = $pm->start and next;
	
	# setup DB adapters
	my $gene_adaptor = $registry->get_adaptor($org_name, 'Core', 'Gene');
	my $tr_adaptor    = $registry->get_adaptor($org_name, 'Core', 'Transcript');
	
	# get current database name
	my $db_adaptor = $registry->get_DBAdaptor($org_name, "Core");
	my $dbname = $db_adaptor->dbc->dbname();
	
	# let user know we're starting
	my $printed = 0;
	print "Retrieving gene IDs for $dbname...\n";
	
	# retrieve all stable IDs
	my @geneids = &get_Gene_IDs($registry, $org_name);
	
	# go through each gene stable ID and retrieve canonical transcript and introns
	foreach my $geneid (@geneids)
	{
		if ($printed == 0) {
			print "Retrieving intron counts for $dbname...\n";
			$printed = 1;
		}
		
		# fetch the gene by stable id
		my $gene = $gene_adaptor->fetch_by_stable_id($geneid);
		
		# setup transcript adaptor to retrieve introns
		my $tr = $gene->canonical_transcript();
		
		# get all introns for the gene transcript
		my $introns = $tr->get_all_Introns();
		
		# increase count depending on bio_type defintion
		if (defined $gene_type{$gene->biotype}) {
			$gene_type{$gene->biotype} += @$introns;
		}
		else {
			$gene_type{$gene->biotype} = @$introns;
		}
	}
    
    # output to STDOUT - change this to CSV output ***
    print "Intron counts for $org_name...\n";
    while ( my ($key, $value) = each(%gene_type) ) {
        print "$key => $value\n";
    }
	
	# reset gene_type hash for next species
	%gene_type = ();
	
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
