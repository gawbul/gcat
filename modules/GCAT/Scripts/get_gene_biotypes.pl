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

	get_genes

=head1 SYNOPSIS

    get_genes species1 species2 species3...
    
=head1 DESCRIPTION

	A program to retrieve the gene numbers and types

=cut

# make life easier
use strict;
use warnings;

# includes
use Time::HiRes qw(gettimeofday);
use GCAT::DB::EnsEMBL;
use GCAT::Interface::Logging;
use Cwd;
use File::Spec;
use Text::CSV_XS;

# get arguments
my $num_args = $#ARGV + 1;
my @organisms = @ARGV;

# check arguments list is sufficient
if ($num_args < 1) {
	logger("This script requires at least one input argument, for the organisms you wish to download the information for.", "Error");
	exit;
}

# tell user what we're doing
print "Retrieving genes for $num_args species: @organisms...\n";

# set start time
my $start_time = gettimeofday;

# connect to EnsEMBL and setup registry object
my $registry = connect_to_EnsEMBL;

# traverse each organism and for UTR stuff - Dave
my %type = ();
foreach my $org (@organisms) {
	# setup gene adaptor
	my $gene_adaptor = $registry->get_adaptor($org, 'Core', 'Gene');
	
	# get the gene IDs for the organism
	my @gene_ids = &get_Gene_IDs($registry, $org);
	
	print "Processing " . ($#gene_ids + 1) . " gene IDs for $org...\n";
	
	# go through genes and get biotype
	foreach my $geneid (@gene_ids) {
		# fetch the gene by stable id
		my $gene = $gene_adaptor->fetch_by_stable_id($geneid);
		
		my $gene_biotypes = $gene->biotype();
		
		# increment the gene types
		if (exists $type{$gene_biotypes}) {
			$type{$gene_biotypes}++;
		}
		else {
			$type{$gene_biotypes} = 1;
		}
	}

	# get root directory, setup path and filename
	my $dir = getcwd();
	my $path = File::Spec->catfile($dir , "data", $org);
	my $filename = File::Spec->catfile($path, "gene_biotypes.csv");

	# check data directory exists
	unless (-d "$path") {
		mkdir $path;
	}
		
	# setup CSV
	my $csv = Text::CSV_XS->new ({ binary => 1, eol => $/ });
  	
  	# open file
  	open my $fh, ">", "$filename" or die "$filename: $!";
 	
 	# add the header line
 	$csv->print ($fh, [$org . '.biotype', $org . '.data']); 	

 	$csv->print ($fh, ["Total genes", $#gene_ids + 1]); 	

	# iterate through the output hash and print each line to CSV
	while (my ($key, $value) = each %type) {
		$csv->print ($fh, ["$key genes", "$type{$key}"]) or $csv->error_diag;
	}	

	# close the CSV
	close $fh or die "$filename: $!";
	print "Outputted gene biotypes to $filename\n";
}

# set end time and calculate time elapsed
my $end_time = gettimeofday;
my $elapsed = $end_time - $start_time;

# let user know we have finished
printf "Finished in %0.3f!\n", $elapsed;