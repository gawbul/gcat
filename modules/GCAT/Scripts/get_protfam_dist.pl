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

	get_protfam_dist

=head1 SYNOPSIS

    get_protfam_dist species1 species2 species3
    
=head1 DESCRIPTION

	A program to retrieve the distribution of protein family members across the entire genome for a group of organims.

=cut

# import some modules to use
use strict;
use Time::HiRes qw(gettimeofday tv_interval);
use Parallel::ForkManager; # used for parallel processing
use GCAT::Interface::Logging qw(logger); # for logging
use GCAT::DB::EnsEMBL qw(connect_To_EnsEMBL check_Species_List get_Gene_IDs);
use GCAT::Data::Output qw(write_to_File);
use Cwd;
use File::Spec;
use Sys::CPU;

# get arguments
my $num_args = $#ARGV + 1;
my @organisms = @ARGV;

# connect to EnsEMBL and setup registry object
my $registry = &connect_To_EnsEMBL;

# check all species exist - no names have been mispelt?
unless (&check_Species_List($registry, @organisms)) {
	logger("You have incorrectly entered a species name or this species doesn't exist in the database.", "Error");
	exit;
}

# check arguments list is sufficient
if ($num_args < 1) {
	logger("This script requires at least one input argument, for the organism(s) you wish to download the information for.", "Error");
	exit;
}

# get root directory and create data directory if doesn't exist
my $dir = getcwd();
mkdir "data" unless -d "data";

# set start time
my $start_time = gettimeofday;

# setup member and family adaptors
my $member_adaptor = $registry->get_adaptor('Multi', 'Compara', 'Member');
my $family_adaptor = $registry->get_adaptor('Multi','Compara','Family');

# get number of processors
my $number_of_cpus = Sys::CPU::cpu_count();

print "\nFound ${number_of_cpus} CPUs, setting up for $number_of_cpus parallel threads\n\n";

# setup number of parallel processes ()
my $pm = new Parallel::ForkManager($number_of_cpus); # set number of processes to number of processors

# setup array for data
my @data = ();

# open file for output
my $outfile = File::Spec->catfile($dir, "data", "protein_family_distribution_data.txt");
open OUTFILE, ">$outfile" or die $!;

# data structure retrieval and handling
my $done = 0;
$pm->run_on_finish (
	sub {
		my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data_structure_reference) = @_;
		
		# check we have a data structure returned
		if (defined($data_structure_reference)) {  # test rather than assume child sent anything
			# split data array ref into separate arrays
			foreach my $data (@$data_structure_reference) {
				print OUTFILE join("\t", @$data) . "\n";
			}
		}
		else {
			# do nothing
		}
		$done++;
	}
);

# tell user what we're doing
print "Going to retrieve gene family distribution for $num_args species: @organisms...\n";

# set autoflush for stdout
local $| = 1;

# iterate over organism list
foreach my $organism (@organisms) {
	# start threads
	$pm->start and next;
	
	# start of by getting all gene ids
	my @geneids = &get_Gene_IDs($registry, $organism);
	
	# iterate over gene ids
	foreach my $geneid (@geneids) {
		# retrieve member
		my $member = $member_adaptor->fetch_by_source_stable_id('ENSEMBLGENE', $geneid);
		
		# check we have member attributes for this species
		unless(defined $member) {
			next;
		}

		# get taxon id
		my $taxonid = $member->taxon_id();

		# retrieve families
		my $families = $family_adaptor->fetch_all_by_Member($member);
		
		foreach (my $family = shift@{$families}) {
			# check we have a family
			unless (defined $family) {
				next;
			}
			
			# get member count by taxon id
			my $pf_count = $family->Member_count_by_source_taxon('ENSEMBLGENE', $taxonid);
			
			# output family counts
			# species_name	gene_id	family_id	family_count
			push(@data, [$organism, $geneid, $family->stable_id(), $pf_count]);
		}
	}
	# end this loop and return data
	$pm->finish(0, \@data); # Terminates the child process
	
	# display dot for every gene complete
	print "."
}
# wait for processes to quit
$pm->wait_all_children;

# close file
close OUTFILE;

# let user know we're done
print "Processed $done organisms.\nRaw data in $outfile.\n";

# now to do frequency distributions

####################

# set end time and calculate time elapsed
my $end_time = gettimeofday;
my $elapsed = $end_time - $start_time;

# let user know we have finished
printf "Finished in %0.3f!\n", $elapsed;