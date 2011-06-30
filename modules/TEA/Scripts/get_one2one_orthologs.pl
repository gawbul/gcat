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

# make life easier
use warnings;
use strict;

# add includes
use Parallel::ForkManager;
use Time::HiRes qw(gettimeofday);
use TEA::Interface::Logging qw(logger);

# first get the arguments
my $num_args = $#ARGV + 1;
my @inputs = @ARGV;
chomp(@inputs);

# check arguments list is sufficient
unless ($num_args >= 2) {
	print("This script requires at least two input arguments, for the organism and organism(s) you wish to download the information for.\n");
	exit;
}

# set start time
my $start_time = gettimeofday;

####################

my $member_adaptor = Bio::EnsEMBL::Registry->get_adaptor('Multi', 'Compara', 'Member');
my $member = $member_adaptor->fetch_by_source_stable_id('ENSEMBLGENE','ENSG00000004059');

# then you get the homologies where the member is involved

my $homology_adaptor = Bio::EnsEMBL::Registry->get_adaptor('Multi', 'compara', 'Homology');
my $homologies = $homology_adaptor->fetch_all_by_Member($member);

# That will return a reference to an array with all homologies (orthologues in
# other species and paralogues in the same one)
# Then for each homology, you can get all the Members implicated

foreach my $homology (@{$homologies}) {
  # You will find different kind of description
  # UBRH, MBRH, RHS, YoungParalogues
  # see ensembl-compara/docs/docs/schema_doc.html for more details

  print $homology->description," ", $homology->subtype,"\n";

####################

# set end time and calculate time elapsed
my $end_time = gettimeofday;
my $elapsed = $end_time - $start_time;

# let user know we have finished
printf "Finished in %0.3f!\n", $elapsed;