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
our @EXPORT_OK = qw(connect_To_EnsEMBL get_Feature get_Gene_IDs get_Species_List check_Species_List get_Transcript_IDs get_Genome_Size get_Transcriptome_Size get_Exome_Size get_Intronome_Size 
					get_Gene_BioTypes get_Exon_IDs get_CTranscript_IDs get_CExon_IDs get_CIntron_Count get_UTR_Sizes get_Intron_Densities get_Exon_Densities get_Repeat_Genome_Stats get_DB_Name 
					get_Genome_Repeats);

# module imports
use Bio::EnsEMBL::Registry;
use feature "switch";
use GCAT::Interface::Config;
use GCAT::Interface::Logging qw(logger);
use Bio::SeqIO;
use Data::Dumper;

# connect to EnsEMBL
sub connect_To_EnsEMBL {
	# check the database to use in gcat.conf
	my $database = &GCAT::Interface::Config::get_conf_val("database");
	my ($host, $user, $pass, $port) = undef;
	
	# check if database is custom
	if ($database =~ /^custom/) {
		$database =~ s/^custom\(//; # remove custom( from beginning
		$database =~ s/\)$//; # remove ) from the end
		my @parts = split(/;/, $database);
		$host = $parts[0];
		$user = $parts[1];
		$pass = $parts[2];
		$port = $parts[3];
	}
	else {
		# what feature do we want?
		given ($database) {
			when ("ensembl") {
				($host, $user, $pass, $port) = ("ensembldb.ensembl.org", "anonymous", undef, 5306);
			}
			when ("genomes") {
				($host, $user, $pass, $port) = ("ensembldb.ensembl.org", "anonymous", undef, 5306);
			}
			when ("useast") {
				($host, $user, $pass, $port) = ("useastdb.ensembl.org", "anonymous", undef, 5306);
			}
			default {
				logger("Database not found or defined - using ensembldb.ensembl.org.", "Info");
				($host, $user, $pass, $port) = ("ensembldb.ensembl.org", "anonymous", undef, 5306);
			}
		}	
	}		
	# setup module access object
	my $registry = 'Bio::EnsEMBL::Registry';
	
	# connect with ensembl database
	$registry->load_registry_from_db(
	    -host => $host,
	    -user => $user,
	    -pass => $pass,
	    -port => $port
	);
	
	return $registry;
}

# check if all species are in the species list 
sub check_Species_List {
	# populate variables
	my ($registry, @organisms) = @_;
	my $all_okay = 1;
	
	my @species_list = &get_Species_List;
	
	# traverse species and check all is okay
	foreach my $species (@organisms) {
		# check species is in the list
		if (grep $_ eq $species, @species_list) {
			# remain true
		}
		else {
			# set false
			$all_okay = 0;		
		}
	}
	
	# check what the result was and return
	if ($all_okay == 0) {
		# as species was missing
		return 0;
	}
	else {
		# nothing missing
		return 1;
	}
}

# check if species is in the species list 
sub is_Species {
	# populate variables
	my ($registry, $species) = @_;
	my @species_list = &get_Species_List;
	
	# check species is in the list
	if (grep $_ eq $species, @species_list) {
		# return true
		return 1;
	}
	else {
		#return false
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
		if ($dba->group() eq 'core' && ${$dba->all_species()}[0] =~ /[a-z]+\_[a-z]+/) {
			push(@all_species, ${$dba->all_species()}[0]);
		}
	}
	
	# sort alphabetically
	@all_species = sort {$a cmp $b} @all_species;
	
	return @all_species;
}

# get name of a database
sub get_DB_Name {
	# define variables
	my ($registry, $organism) = @_;
	
	# get current database name
	my $db_adaptor = $registry->get_DBAdaptor($organism, "Core");
	my $dbname = $db_adaptor->dbc->dbname();
	my $release = $dbname;
	$release =~ m/[a-z]+_[a-z]+_core_([0-9]{2})_[0-9]{1}/;
	$release = int($1);
	
	# return the database name and the release number
	return ($dbname, $release);
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

# get UTR sizes
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
sub get_Repeat_Stats {
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

# call get feature retrieves a particular feature type
# currently just exons and introns
sub get_Feature {
	# define variables
	my ($registry, $organism, $feature) = @_;
	my @features = ();
	
	# what feature do we want?
	given (lc($feature)) {
		when ("exons") {
			@features = &get_Exons($registry, $organism);
		}
		when ("introns") {
			@features = &get_Introns($registry, $organism);
		}
		when ("repeats") {
			@features = &get_Repeats($registry, $organism);
		}
		default {
			logger("The feature $feature, is currently not defined for retrieval.", "Debug");
		}
	}
	
	return @features;
}

# subroutine to retrieve introns
sub get_Exons {
	# define variables
	my ($registry, $organism) = @_;
	my @exons = ();
		
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
		my $trexons = $tr->get_all_Exons();
		@exons = (@exons, @{$trexons});
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
		
		# get all introns
		my $trintrons = $tr->get_all_Introns();
		@introns = (@introns, @{$trintrons});
	}
	
	return @introns;
}

# subroutine to retrieve protein coding gene repeat elements
sub get_Repeats {
	# define variables
	my ($registry, $organism) = @_;
	my @repeats;
	
	# get gene IDs
	my @geneids = &get_Gene_IDs($registry, $organism);

	# setup gene adaptor
	my $gene_adaptor = $registry->get_adaptor($organism, 'Core', 'Gene');
	my $slice_adaptor = $registry->get_adaptor($organism, 'Core', 'Slice');
		
	foreach my $geneid (@geneids) {
		# fetch the gene by stable id
		my $gene = $gene_adaptor->fetch_by_stable_id($geneid);

		# only get protein coding genes
		unless ($gene->biotype eq "protein_coding") {
			next;
		}
			
		# setup slice adaptor to retrieve repeats for gene slice
		my $slice = $slice_adaptor->fetch_by_gene_stable_id($gene->stable_id());
		
		# get all repeats
		my $slrepeats = $slice->get_all_RepeatFeatures();
		@repeats = (@repeats, @{$slrepeats});
	}
	
	return @repeats;
}

# subroutine to retrieve genome wide repeat elements
sub get_Genome_Repeats {
	# define variables
	my ($registry, $filename, $organism) = @_;
	my $repeats_count = 0;
	my ($gene_id, $transcript_id, $seq) = undef;
	
	# setup seqio output
	my $seqio_out = Bio::SeqIO->new(-file => ">$filename" , '-format' => 'FASTA');
	
	# setup slice adaptor
	my $slice_adaptor = $registry->get_adaptor($organism, 'Core', 'Slice');
	
	# fetch all toplevel slices
	my @slices = @{$slice_adaptor->fetch_all('toplevel', undef, 0, 1)};
	
	# iterate through all slices
	while(my $slice = shift @slices){
		# get all repeats
		my $slrepeats = $slice->get_all_RepeatFeatures();
				
		# traverse repeats
		while (my $repeat = shift @{$slrepeats}) {
			# build repeat ID
			my $repeat_id = "REPEAT" . ($repeats_count + 1);

			# build the bio seq object
			my $rc = $repeat->repeat_consensus();
			my $repeat_obj = Bio::Seq->new( -primary_id => $repeat_id,
											-display_id => $repeat_id,
											-desc => "NULL\tNULL\t" . $rc->repeat_type() . "\t" . $rc->repeat_class() . "\t" . $repeat->start() . "\t" . $repeat->end() . "\t" . $rc->length() . "\t" . $repeat->strand(),
											-alphabet => 'dna',
											-seq => $rc->repeat_consensus);
																	
			# write the fasta sequence
			# unless we have a 0 length intron
			if ($repeat->length() == 0) {
				next;
			}
			
			# write sequence
			$seqio_out->write_seq($repeat_obj);
			
			# let user know something is happening
			if ($repeats_count % 1000 == 0) {
				print "."
			}
			
			# increment repeats count
			$repeats_count++;
		}	
	}

	# return counts
	return $repeats_count;
}

1;