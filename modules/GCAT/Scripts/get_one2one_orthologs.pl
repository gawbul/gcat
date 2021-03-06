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

	get_one2one_orthologs

=head1 SYNOPSIS

    get_one2one_orthologs gene_id1 gene_id2...
    
=head1 DESCRIPTION

	Get a list of orthologous gene IDs for a list of gene IDs.

=cut

# make life easier
use warnings;
use strict;

# add includes
use Parallel::ForkManager;
use Time::HiRes qw(gettimeofday);
use GCAT::DB::EnsEMBL qw(connect_To_EnsEMBL);
use GCAT::Interface::Logging qw(logger);
use Bio::EnsEMBL::Registry;

# setup variables
my @gene_ids = ();

# first get the arguments
my $num_args = $#ARGV + 1;
my @inputs = @ARGV;
chomp(@inputs);

# check arguments list is sufficient
unless ($num_args >= 1) {
	logger("This script requires at least one input argument, for the gene ID(s) you wish to download the orthologous information for.\n", "Error");
	exit;
}

# set start time
my $start_time = gettimeofday;

####################

# connect to EnsEMBL and setup registry object
my $registry = &connect_To_EnsEMBL;

# traverse through gene ID list
foreach my $gene_id (@inputs) {
	# setup member adaptor and retrieve by gene stable_id
	my $member_adaptor = $registry->get_adaptor('Multi', 'Compara', 'Member');
	my $member = $member_adaptor->fetch_by_source_stable_id('ENSEMBLGENE', $gene_id); # e.g. ENSDARG00000076177 ()Zebrafish POLR2A)
	
	# setup homology adaptor and get the homologies where the member is involved
	my $homology_adaptor = $registry->get_adaptor('Multi', 'Compara', 'Homology');
	my $homologies = $homology_adaptor->fetch_all_by_Member($member);
	
	# traverse homologies
	foreach my $homology (@{$homologies}) {
		# will return different kinds of description - UBRH, MBRH, RHS, YoungParalogues
		# see ensembl-compara/docs/docs/schema_doc.html for more details
		
		if ($homology->description eq "ortholog_one2one") {
			my ($first, $second) = @{$homology->gene_list()};
			push(@gene_ids, $second->stable_id());
		}
	}
}

# display gene ids
print "@gene_ids\n";

####################

# set end time and calculate time elapsed
my $end_time = gettimeofday;
my $elapsed = $end_time - $start_time;

# let user know we have finished
printf "Finished in %0.3f!\n", $elapsed;