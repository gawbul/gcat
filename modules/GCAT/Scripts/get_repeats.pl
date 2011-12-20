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

	get_repeats

=head1 SYNOPSIS

    get_repeats species1 species2 species3
    
=head1 DESCRIPTION

	A program to retrieve all repeat element sequences for a given number of species.

=cut

# import some modules to use
use strict;
use Bio::Seq;
use Bio::SeqIO;
use Time::HiRes qw(gettimeofday tv_interval);
use Parallel::ForkManager; # used for parallel processing
use GCAT::Interface::Logging qw(logger); # for logging
use GCAT::DB::EnsEMBL;
use Cwd;
use File::Spec;

# define variables
my $repeat_num = 1;
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
print "Going to retrieve repeats for $num_args species: @organisms...\n";

# set start time
my $start_time = gettimeofday;

# connect to EnsEMBL and setup registry object
my $registry = connect_to_EnsEMBL;

# set autoflush for stdout
local $| = 1;

# setup fork manager
my $pm = new Parallel::ForkManager(8);

# go through all organisms and retrieve repeat elements
my $count = 0;
foreach my $org_name (@organisms) {
	# start fork
	my $pid = $pm->start and next;
	
	# setup output filename
	mkdir "data/$org_name" unless -d "data/$org_name";
	my $path = File::Spec->catfile($dir, "data", "$org_name", "repeats.fas");
	my $seqio_out = Bio::SeqIO->new(-file => ">$path" , '-format' => 'Fasta');
	
	# setup DB adapters
	my $gene_adaptor = $registry->get_adaptor($org_name, 'Core', 'Gene');
	my $slice_adaptor    = $registry->get_adaptor($org_name, 'Core', 'Slice');
	
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
			print "Retrieving repeat elements for $dbname...\n";
			$printed = 1;
		}
		
		# fetch the gene by stable id
		my $gene = $gene_adaptor->fetch_by_stable_id($geneid);

		# only get protein coding genes
		unless ($gene->biotype eq "protein_coding") {
			next;
		}
		
		# setup transcript adaptor to retrieve slice for repeats
		my $tr = $gene->canonical_transcript();
		
		# setup slice adaptor to retrieve repeats
		my $slice = $slice_adaptor->fetch_by_transcript_stable_id($tr->stable_id());
		
		# get all repeats for the slice
		my $repeats = $slice->get_all_RepeatFeatures();
		
		# traverse repeats
		while (my $repeat = shift @{$repeats}) {
			# create fake repeat stable ID
			my $repeat_stable_id = sprintf(substr($tr->stable_id(), 0, 6) . "R" . "%011d", $repeat_num);
			
			# build the bio seq object
			my $rc = $repeat->repeat_consensus();
			my $repeat_obj = Bio::Seq->new( -primary_id => $repeat_stable_id,
											-display_id => $repeat_stable_id,
											-desc => $gene->stable_id() . " " . $tr->stable_id() . " " . $rc->repeat_class() . " " . $repeat->start() . " " . $repeat->end() . " " . $rc->length() . " " . $repeat->strand(),
											-alphabet => 'dna',
											-seq => $rc->repeat_consensus());
																	
			# write the fasta sequence
			# unless we have a 0 length intron
			if ($repeat->length() == 0) {
				next;
			}
			
			$seqio_out->write_seq($repeat_obj);
			
			# let user know something is happening
			if ($count % 1000 == 0) {
				print "."
			}
			$repeat_num++;
			$count++;
		}
	}
	print "\nRetrieved $count repeats for $org_name.\n";
	
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
