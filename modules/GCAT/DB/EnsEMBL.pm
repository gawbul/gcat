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

package GCAT::DB::EnsEMBL;

# make life easier
use warnings;
use strict;

# export subroutines
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(connect_to_EnsEMBL get_Gene_IDs get_Species_List get_Transcript_IDs get_Genome_Size get_Transcriptome_Size get_Exome_Size get_Intronome_Size get_Gene_BioTypes get_Exon_IDs get_CTranscript_IDs get_CExon_IDs get_CIntron_Count get_UTR_Sizes get_Intron_Densities get_Exon_Densities get_Repeat_Genome_Stats);

# module imports
use Bio::EnsEMBL::Registry;
use feature "switch";

# connect to EnsEMBL
sub connect_to_EnsEMBL {
	# get values from @_
	my ($host, $user, $pass, $port) = @_;
	
	# check if values defined - default to local install
	unless (defined $host) {
		$host = 'ensembldb.ensembl.org';	
	}
	unless (defined $user) {
		$user = 'anonymous';
	}
	unless (defined $pass) {
		$pass = undef;
	}
	unless (defined $port) {
		$port = 5306;	
	}
	
	# setup module access object
	my $registry = 'Bio::EnsEMBL::Registry';
	
	# connect with ensembl database
	$registry->load_registry_from_db (
	    -host => $host,
	    -user => $user,
	    -pass => $pass,
	    -port => $port
	);
	
	return $registry;
}

# get genome size
# thanks to Bert from EnsEMBL for this code
# this returns the "Golden Path length""
sub get_Genome_Size {
	# retrieve input variables
	my ($registry, $organism) = @_;
	
	# setup slice adaptor
	my $slice_adaptor = $registry->get_adaptor($organism, 'Core', 'Slice');
	
	# fetch all toplevel slices
	my @slices = @{$slice_adaptor->fetch_all('toplevel', undef, 0, 1)};

	# intialize genome size variable
	my $genome_size = 0;

	# iterate through all slices
	foreach my $slice(@slices){
		# increase genome size by slice length
		$genome_size = $genome_size + $slice->length;
	}

	# return the genome size
	return $genome_size;	
}

# get transcriptome size
sub get_Transcriptome_Size {
	# retrieve input variables
	my ($registry, $organism) = @_;
	
	# setup gene adaptor
	my $gene_adaptor = $registry->get_adaptor($organism, 'Core', 'Gene');
	
	# intialize transcriptome size variable
	my $transcriptome_size = 0;

	# get gene IDs
	my @geneids = &get_Gene_IDs($registry, $organism);
	
	# iterate through all gene ids
	foreach my $geneid (@geneids){
		# fetch the gene by stable id
		my $gene = $gene_adaptor->fetch_by_stable_id($geneid);

		# only get protein coding genes
		unless ($gene->biotype eq "protein_coding") {
			next;
		}
		
		# get canonical transcript
		my $canonical_transcript = $gene->canonical_transcript();
				
		# increase transcriptome size by slice length
		$transcriptome_size = $transcriptome_size + $canonical_transcript->length();
	}

	# return the transcriptome size
	return $transcriptome_size;
}


# get exome size
sub get_Exome_Size {
	# retrieve input variables
	my ($registry, $organism) = @_;
	
	# setup gene adaptor
	my $gene_adaptor = $registry->get_adaptor($organism, 'Core', 'Gene');
	
	# intialize transcriptome size variable
	my $exome_size = 0;
	my $exon_count = 0;
	
	# get gene IDs
	my @geneids = &get_Gene_IDs($registry, $organism);
	
	# iterate through all gene ids
	foreach my $geneid (@geneids){
		# fetch the gene by stable id
		my $gene = $gene_adaptor->fetch_by_stable_id($geneid);

		# only get protein coding genes
		unless ($gene->biotype eq "protein_coding") {
			next;
		}
		
		# get canonical transcript
		my $canonical_transcript = $gene->canonical_transcript();
		
		# get exons
		my @exons = @{$canonical_transcript->get_all_Exons()};
		
		# iterate through exons
		foreach my $exon (@exons) {
			# increase exome size by slice length
			$exome_size = $exome_size + $exon->length();
			$exon_count++;
		}
	}

	# return the exome size
	return ($exome_size, $exon_count);	
}

# get the canonical intron size
sub get_Intronome_Size {
	# retrieve input variables
	my ($registry, $organism) = @_;
	
	# setup gene adaptor
	my $gene_adaptor = $registry->get_adaptor($organism, 'Core', 'Gene');
	
	# intialize intron size variable
	my $intronome_size = 0;
	my $intron_count = 0;
	
	# get gene IDs
	my @geneids = &get_Gene_IDs($registry, $organism);
	
	# iterate through all gene ids
	foreach my $geneid (@geneids){
		# fetch the gene by stable id
		my $gene = $gene_adaptor->fetch_by_stable_id($geneid);

		# only get protein coding genes
		unless ($gene->biotype eq "protein_coding") {
			next;
		}
		
		# get canonical transcript
		my $canonical_transcript = $gene->canonical_transcript();
		
		# get exons
		my @introns = @{$canonical_transcript->get_all_Introns()};
		
		# iterate through exons
		foreach my $intron (@introns) {
			# increase exome size by slice length
			$intronome_size = $intronome_size + $intron->length();
			$intron_count++;
		}
	}

	# return the intronome size
	return ($intronome_size, $intron_count);	
}

# get gene stable_ids
sub get_Gene_IDs {
	my ($registry, $organism) = @_;
	my $gene_adaptor = $registry->get_adaptor($organism, 'Core', 'Gene');
	
	# get all the stable IDs
	my @gene_ids = @{$gene_adaptor->list_stable_ids()};

	return @gene_ids;
}

# get number of gene biotypes
sub get_Gene_BioTypes {
	# retrieve the input variables
	my ($registry, $organism) = @_;
	
	# setup the biotypes hash
	my %biotypes = ();
	
	# get gene IDs
	my @gene_ids = &get_Gene_IDs($registry, $organism);
	 
	# go through genes and get biotype
	foreach my $geneid (@gene_ids) {
		# get gene adaptor
		my $gene_adaptor = $registry->get_adaptor($organism, 'Core', 'Gene');
		
		# fetch the gene by stable id
		my $gene = $gene_adaptor->fetch_by_stable_id($geneid);
		
		my $gene_biotypes = $gene->biotype();
		
		# increment the gene types
		if (exists $biotypes{$gene_biotypes}) {
			$biotypes{$gene_biotypes}++;
		}
		else {
			$biotypes{$gene_biotypes} = 1;
		}
	}
	
	# return the biotypes
	return %biotypes;
}

# get the transcript ids - includes alternately spliced transcripts
sub get_Transcript_IDs {
	# retrieve input variables
	my ($registry, $organism) = @_;
	
	# setup transcript adaptor
	my $transcript_adaptor = $registry->get_adaptor($organism, 'Core', 'Transcript' );
	
	# get all transcript IDs
	my @transcript_ids = @{$transcript_adaptor->list_stable_ids()};
	
	# return the transcript IDs
	return @transcript_ids;
}

# get the exon ids - includes alternately spliced transcripts
sub get_Exon_IDs {
	# retrieve input variables
	my ($registry, $organism) = @_;
	
	# setup exon adaptor
	my $exon_adaptor = $registry->get_adaptor($organism, 'Core', 'Exon' );
	
	# get all exon IDs
	my @exon_ids = @{$exon_adaptor->list_stable_ids()};
	
	# return the exon ids
	return @exon_ids;
}

# get the canonical transcript ids
sub get_CTranscript_IDs {
	# retrieve input variables
	my ($registry, $organism) = @_;
	
	# setup gene adaptor
	my $gene_adaptor = $registry->get_adaptor($organism, 'Core', 'Gene');
	
	# intialize transcript IDs array
	my @transcript_ids = ();

	# get gene IDs
	my @geneids = &get_Gene_IDs($registry, $organism);
	
	# iterate through all gene ids
	foreach my $geneid (@geneids){
		# fetch the gene by stable id
		my $gene = $gene_adaptor->fetch_by_stable_id($geneid);

		# only get protein coding genes
		unless ($gene->biotype eq "protein_coding") {
			next;
		}
		
		# get canonical transcript
		my $canonical_transcript = $gene->canonical_transcript();
		
		# push the transcript stable_id
		push(@transcript_ids, $canonical_transcript->stable_id());	
	}

	# return the canonical transcript IDs
	return @transcript_ids;	
}

# get the canonical exon ids
sub get_CExon_IDs {
	# retrieve input variables
	my ($registry, $organism) = @_;
	
	# setup gene adaptor
	my $gene_adaptor = $registry->get_adaptor( $organism, 'Core', 'Gene');
	
	# intialize exon IDs array
	my @exon_ids = ();

	# get gene IDs
	my @geneids = &get_Gene_IDs($registry, $organism);
	
	# iterate through all gene ids
	foreach my $geneid (@geneids){
		# fetch the gene by stable id
		my $gene = $gene_adaptor->fetch_by_stable_id($geneid);

		# only get protein coding genes
		unless ($gene->biotype eq "protein_coding") {
			next;
		}
		
		# get canonical transcript
		my $canonical_transcript = $gene->canonical_transcript();
		
		# get exons
		my @exons = @{$canonical_transcript->get_all_Exons()};
		
		# iterate through exons
		foreach my $exon (@exons) {
			# push exon stable_id 
			push(@exon_ids, $exon->stable_id());	
		}
	}

	# return the canonical transcript exon IDs
	return @exon_ids;	
}

# get the canonical intron numbers
sub get_CIntron_Count {
	# retrieve input variables
	my ($registry, $organism) = @_;
	
	# setup gene adaptor
	my $gene_adaptor = $registry->get_adaptor( $organism, 'Core', 'Gene');
	
	# intialize exon IDs array
	my $intron_count = 0;

	# get gene IDs
	my @geneids = &get_Gene_IDs($registry, $organism);
	
	# iterate through all gene ids
	foreach my $geneid (@geneids){
		# fetch the gene by stable id
		my $gene = $gene_adaptor->fetch_by_stable_id($geneid);

		# only get protein coding genes
		unless ($gene->biotype eq "protein_coding") {
			next;
		}
		
		# get canonical transcript
		my $canonical_transcript = $gene->canonical_transcript();
		
		# get introns
		my @introns = @{$canonical_transcript->get_all_Introns()};
		
		# iterate through introns
		foreach my $intron (@introns) {
			# increase intron count
			$intron_count++;
		}
	}

	# return the canonical transcript exon IDs
	return $intron_count;	
}

# get 5'-UTR size
sub get_UTR_Sizes {
	# retrieve variables
	my ($registry, $organism) = @_;
	
	# setup variables
	my ($fputr_size, $tputr_size) = 0;
		
	# get gene stable_ids
	my @gene_ids = &get_Gene_IDs($registry, $organism);

	# setup gene adaptor
	my $gene_adaptor = $registry->get_adaptor($organism, 'Core', 'Gene');
	
	# traverse gene IDs
	foreach my $gene_id (@gene_ids) {
		# fetch gene by stable id
		my $gene = $gene_adaptor->fetch_by_stable_id($gene_id);
		
		# only get protein coding genes
		unless ($gene->biotype eq "protein_coding") {
			next;
		}
		
		# get canonical transcript
		my $canonical_transcript = $gene->canonical_transcript();
		
		# retrieve coordinates for the canonical transcript
		my $ct_stt = $canonical_transcript->start();
		my $cds_stt = $canonical_transcript->coding_region_start();
		my $cds_end = $canonical_transcript->coding_region_end();	
		my $ct_end = $canonical_transcript->end();
		
		# check strand and retrieve sizes
		if ($canonical_transcript->strand == 1) {
			my $fputr_length = $cds_stt - $ct_stt;
			my $tputr_length = $ct_end - $cds_end;
			$fputr_size += $fputr_length;
			$tputr_size += $tputr_length; 
		}
		else {
			my $fputr_length = $ct_end - $cds_end;
			my $tputr_length = $cds_stt - $ct_stt;
			$fputr_size += $fputr_length;
			$tputr_size += $tputr_length;
		}
	}

	return ($fputr_size, $tputr_size);
}

# get intron densities
sub get_Intron_Densities {
	# retrieve variables
	my ($registry, $organism) = @_;
	
	# setup variables
	my (@intron_count, @intron_bonds) = ();
	my ($introns_total, $introns_per_gene, $bonds_total, $introns_per_bond) = 0;
	my $gene_count = 0;

	# get gene stable_ids
	my @gene_ids = &get_Gene_IDs($registry, $organism);

	# setup gene adaptor
	my $gene_adaptor = $registry->get_adaptor($organism, 'Core', 'Gene');
	
	# traverse gene IDs
	foreach my $gene_id (@gene_ids) {
		# fetch gene by stable id
		my $gene = $gene_adaptor->fetch_by_stable_id($gene_id);
		
		# only get protein coding genes
		unless ($gene->biotype eq "protein_coding") {
			next;
		}
		
		# get canonical transcript
		my $canonical_transcript = $gene->canonical_transcript();
		
		# retrieve coordinates for the canonical transcript
		my @introns = @{$canonical_transcript->get_all_Introns()};
		
		# push intron count to array
		push(@intron_count, scalar(@introns));
	
		# push gene intron density to array
		push(@intron_bonds, scalar(@introns) / ($canonical_transcript->length() - 1));

		# increment gene count
		$gene_count++;
	}

	# traverse intron counts
	foreach my $intron (@intron_count) {
		$introns_total += $intron;
	}
	
	# work out introns per gene as an average
	$introns_per_gene = $introns_total / $gene_count;
	
	# traverse bond counts
	foreach my $bond (@intron_bonds) {
		$bonds_total += $bond;
	}
	
	# work out introns per bond
	$introns_per_bond = $bonds_total / $gene_count;
	
	# return the values	
	return ($introns_per_gene, $introns_per_bond);	
}

# get exon densities
sub get_Exon_Densities {
	# retrieve variables
	my ($registry, $organism) = @_;
	
	# setup variables
	my (@exon_count, @exon_nts) = ();
	my ($exons_total, $exons_per_gene, $nt_total, $exons_per_nt) = 0;
	my $gene_count = 0;

	# get gene stable_ids
	my @gene_ids = &get_Gene_IDs($registry, $organism);

	# setup gene adaptor
	my $gene_adaptor = $registry->get_adaptor($organism, 'Core', 'Gene');
	
	# traverse gene IDs
	foreach my $gene_id (@gene_ids) {
		# fetch gene by stable id
		my $gene = $gene_adaptor->fetch_by_stable_id($gene_id);
		
		# only get protein coding genes
		unless ($gene->biotype eq "protein_coding") {
			next;
		}
		
		# get canonical transcript
		my $canonical_transcript = $gene->canonical_transcript();
		
		# retrieve coordinates for the canonical transcript
		my @exons = @{$canonical_transcript->get_all_Exons()};
		
		# push exon count to array
		push(@exon_count, scalar(@exons));
	
		# push gene exon density to array
		push(@exon_nts, (scalar(@exons) / $gene->length()));

		# increment gene count
		$gene_count++;
	}

	# traverse exon counts
	for (@exon_count) {
		$exons_total += $_;
	}
	
	# work out exons per gene as an average
	$exons_per_gene = $exons_total / $gene_count;
	
	# traverse exon densities
	for (@exon_nts) {
		$nt_total += $_;
	}
	
	# work out exons per nucleotide
	$exons_per_nt = $nt_total / $gene_count;
	print "$organism = $exons_per_nt\n";
	
	# return the values	
	return ($exons_per_gene, $exons_per_nt);	
}

# get repeat statistics
sub get_Repeat_Genome_Stats {
	# retrieve variables
	my ($registry, $organism) = @_;
	
	# setup variables
	my (@repeat_count, @repeat_densities) = ();
	my ($repeats_total, $repeat_size, $repeat_count, $repeat_density) = 0;
	my $gene_count = 0;

	# get gene stable_ids
	my @gene_ids = &get_Gene_IDs($registry, $organism);

	# setup gene adaptor
	my $gene_adaptor = $registry->get_adaptor($organism, 'Core', 'Gene');
	
	# setup slice adaptor
	my $slice_adaptor = $registry->get_adaptor($organism, 'Core', 'Slice');
		
	# traverse gene IDs
	foreach my $gene_id (@gene_ids) {
		# fetch gene by stable id
		my $gene = $gene_adaptor->fetch_by_stable_id($gene_id);
		
		# only get protein coding genes
		unless ($gene->biotype eq "protein_coding") {
			next;
		}
		
		# setup slice adaptor to retrieve repeats
		my $slice = $slice_adaptor->fetch_by_gene_stable_id($gene->stable_id());
		
		# get all repeats for the slice
		my @repeats = @{$slice->get_all_RepeatFeatures()};

		# check we have some repeats
		if (scalar(@repeats) <= 0) {
			next;
		}

		# increase repeat element count
		$repeat_count += scalar(@repeats);
		
		# get repeat lengths and add to repeat size variable
		foreach my $repeat (@repeats) {
			# get repeat consensus for length
			my $rc = $repeat->repeat_consensus();
			$repeat_size += $rc->length();
		}
		
		# push repeat density (per gene) to array
		push(@repeat_densities, (scalar(@repeats) / $gene->length()));

		# increment gene count
		$gene_count++;
	}

	# traverse exon densities
	for (@repeat_densities) {
		$repeats_total += $_;
	}
	
	# work out exons per bond
	$repeat_density = $repeats_total / $gene_count;
	
	# return the values	
	return ($repeat_size, $repeat_count, $repeat_density);	
}

# check if species is in the species list 
sub is_Species {
	# populate variables
	my ($species, $registry) = @_;
	my @species_list = &get_Species_List;
	
	# check species is in the list
	if (grep $_ eq $species, @species_list) {
		return 1;
	}
	else {
		print "Species \"$species\" not found in EnsEMBL database.\n";
		return 0;		
	}
}

use Data::Dumper;

# get species list
sub get_Species_List {
	# define variables
	my $registry = @_;
	my @all_species;
	
	# get all DB adaptors
	my @dbas = @{Bio::EnsEMBL::Registry->get_all_DBAdaptors()};
	
	# populate species list from first DB adaptor
	foreach my $dba (@dbas) {
		if ($dba->group() eq 'core' && ${$dba->all_species()}[0] =~ /[a-z]+\_[a-z]+/) {
			push(@all_species, ${$dba->all_species()}[0]);
		}
	}
	
	# sort alphabetically
	@all_species = sort {$a cmp $b} @all_species;
	
	return @all_species;
}

# call get feature retrieves a particular feature type
# currently just exons and introns
sub get_Feature {
	# define variables
	my ($registry, $feature, $organism) = @_;
	
	# what feature do we want?
	given ($feature) {
		when ("exons") {
			&get_Exons($registry, $organism);
		}
		when ("introns") {
			&get_Introns($registry, $organism);
		}
		default {
			print "This feature is currently not defined for retrieval.\n";
		}
	}
}

# subroutine to retrieve introns
sub get_Exons {
	# define variables
	my ($registry, $organism) = @_;
	my @exons;
	
	# get gene IDs
	my @geneids = &get_Gene_IDs($registry, $organism);

	# setup gene adaptor
	my $gene_adaptor = $registry->get_adaptor($organism, 'Core', 'Gene');
	
	foreach my $geneid (@geneids) {
		# fetch the gene by stable id
		my $gene = $gene_adaptor->fetch_by_stable_id($geneid);

		# only get protein coding genes
		unless ($gene->biotype eq "protein_coding") {
			next;
		}
			
		# setup transcript adaptor to retrieve introns
		my $tr = $gene->canonical_transcript();
		
		# get all exons
		my @tr_exons = $tr->get_all_Exons();
		@exons = (@exons, @tr_exons);
	}
	
	return @exons;
}

# subroutine to retrieve introns
sub get_Introns {
	# define variables
	my ($registry, $organism) = @_;
	my @introns;
	
	# get gene IDs
	my @geneids = &get_Gene_IDs($registry, $organism);

	# setup gene adaptor
	my $gene_adaptor = $registry->get_adaptor($organism, 'Core', 'Gene');
	
	foreach my $geneid (@geneids) {
		# fetch the gene by stable id
		my $gene = $gene_adaptor->fetch_by_stable_id($geneid);

		# only get protein coding genes
		unless ($gene->biotype eq "protein_coding") {
			next;
		}
			
		# setup transcript adaptor to retrieve introns
		my $tr = $gene->canonical_transcript();
		
		# get all exons
		my @tr_introns = $tr->get_all_Exons();
		@introns = (@introns, @tr_introns);
	}
	
	return @introns;
}

1;
