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

package TEA::DB::EnsEMBL;

# make life easier
use warnings;
use strict;

# export subroutines
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(connect_to_EnsEMBL get_Gene_IDs get_Species_List get_Transcript_IDs get_Genome_Size get_Transcriptome_Size get_Exome_Size);

# module imports
use Bio::EnsEMBL::Registry;
use feature "switch";

# connect to EnsEMBL
sub connect_to_EnsEMBL {
	# get values from @_
	my ($host, $user, $pass, $port) = @_;
	
	# check if values defined - default to ensembl
	unless (defined $host) {
		$host = 'ensembldb.ensembl.org';	
	}
	unless (defined $user) {
		$user = 'anonymous';
	}
	unless (defined $pass) {
		$pass = '';
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
# this returns golden path length
sub get_Genome_Size {
	# retrieve input variables
	my ($registry, $organism) = @_;
	
	# setup slice adaptor
	my $slice_adaptor = $registry->get_adaptor( $organism, 'Core', 'Slice');
	
	# fetch all toplevel slices
	my @slices = @{$slice_adaptor->fetch_all('toplevel', undef, 0, 1)};

	# intialize genome size variable
	my $genome_size = 0;

	# iterate through all slices
	foreach my $slice(@slices){
		# increase genome size by slice length
		$genome_size = $genome_size + $slice->length;
	}

	return $genome_size;	
}

# get transcriptome size
sub get_Transcriptome_Size {
	# retrieve input variables
	my ($registry, $organism) = @_;
	
	# setup gene adaptor
	my $gene_adaptor = $registry->get_adaptor( $organism, 'Core', 'Gene');
	
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

	return $transcriptome_size;
}


# get exome size
sub get_Exome_Size {
	# retrieve input variables
	my ($registry, $organism) = @_;
	
	# setup gene adaptor
	my $gene_adaptor = $registry->get_adaptor( $organism, 'Core', 'Gene');
	
	# intialize transcriptome size variable
	my $exome_size = 0;

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
		}
	}

	return $exome_size;	
}

# get gene stable_ids
sub get_Gene_IDs {
	my ($registry, $organism) = @_;
	my $gene_adaptor = $registry->get_adaptor($organism, 'Core', 'Gene');
	
	# get all the stable IDs
	my @gene_ids = @{$gene_adaptor->list_stable_ids()};

	return @gene_ids;
}

# get the transcript ids
sub get_Transcript_IDs {
	my ($registry, $organism) = @_;
	my $transcript_adaptor = $registry->get_adaptor($organism, 'Core', 'Transcript' );
	
	# get all transcript IDs
	my @trans_ids = @{$transcript_adaptor->list_stable_ids()};
	
	return @trans_ids;
}

# get the exon ids
sub get_Exon_IDs {
	my ($registry, $organism) = @_;
	my $exon_adaptor = $registry->get_adaptor($organism, 'Core', 'Exon' );
	
	# get all exon IDs
	my @exon_ids = @{$exon_adaptor->list_stable_ids()};
	
	return @exon_ids;
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

# get species list
sub get_Species_List {
	# define variables
	my $registry = @_;
	my @all_species;
	
	# get all DB adaptors
	my @dbas = @{Bio::EnsEMBL::Registry->get_all_DBAdaptors()};
	
	# populate species list from first DB adaptor
	foreach my $dba (@dbas) {
		if (${$dba->all_species()}[0] =~ /[a-z]+\_[a-z]+/) {
			push(@all_species, @{$dba->all_species()});
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
