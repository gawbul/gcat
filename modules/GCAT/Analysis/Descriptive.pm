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

package GCAT::Analysis::Descriptive;

# make life easier
use warnings;
use strict;

# export subroutines
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(get_Descriptive_Statistics get_Character_Statistics);

# setup the includes
use Statistics::Descriptive;
use GCAT::DB::EnsEMBL;
use GCAT::Data::Output;
use Text::FormatTable;
use Cwd;
use File::Spec;
use Tie::IxHash;

# get the character matrix data
sub get_Character_Statistics {
	# retrieve variables
	my @rownames = @_;    # organisms are row names

	# setup variables
	my (
		$gene_count,     $genome_size,      $transcriptome_size,
		$exome_size,     $intronome_size,   $transcript_count,
		$exon_count,     $intron_count,     $fputr_size,
		$tputr_size,     $introns_per_gene, $introns_per_bond,
		$exons_per_gene, $exons_per_gl,     $repeat_size,
		$repeat_count,   $repeat_density
	  )
	  = 0;
	my @colnames = (
		"Total Gene Count",
		"Total Genome Size",
		"Transcriptome Size",
		"Exome Size",
		"Intronome Size",
		"Gene/Transcript Count",
		"Exon Count",
		"Intron Count",
		"5'-UTR Size",
		"3'-UTR Size",
		"Introns per Gene",
		"Introns per Bond",
		"Exons per Gene",
		"Exons % Gene Length",
		"Total Repeat Element Size",
		"Repeat Element Count",
		"Repeat Element Density"
	);
	my @data = ();

	# get number of genes and transcripts
	my $registry = &connect_to_EnsEMBL;

	# traverse through the given species and retrieve data
	foreach my $org (@rownames) {

		# let user know which species
		print "Processing $org...\n";

		# get gene IDs into array ref
		print "Getting gene count...\n";
		$gene_count = &get_Gene_IDs( $registry, $org );

		# get genome size
		print "Getting genome size...\n";
		$genome_size = &get_Genome_Size( $registry, $org );

		# get exome size - protein coding
		print "Getting exon size/count...\n";
		( $exome_size, $exon_count ) = &get_Exome_Size( $registry, $org );

		# get intronome size - protein coding
		print "Getting intron size/count...\n";
		( $intronome_size, $intron_count ) =
		  &get_Intronome_Size( $registry, $org );

		# get 5' and 3'-UTR size
		print "Getting 5'- and 3'-UTR sizes...\n";
		( $fputr_size, $tputr_size ) = &get_UTR_Sizes( $registry, $org );

		# get transcriptome size - protein coding - mRNA
		print "Getting transcript size/count...\n";
		$transcriptome_size = ( $exome_size + $fputr_size + $tputr_size );
		$transcript_count   = &get_CTranscript_IDs( $registry, $org );

		# get introns per gene and bond
		print "Getting intron densities (per gene/bond)...\n";
		$introns_per_gene = $intron_count / $transcript_count;
		$introns_per_bond =
		  $intron_count / ( $transcriptome_size - $transcript_count );

		# get exons per gene
		print "Getting exon densities (per gene/% gene length)...\n";
		$exons_per_gene = $exon_count / $transcript_count;
		$exons_per_gl   =
		  $exon_count / ( ( $transcriptome_size + $intronome_size ) / 100 );

		# get repeat element size
		print
"Getting repeat element statistics (size/count/per gene density)...\n";
		( $repeat_size, $repeat_count, $repeat_density ) =
		  &get_Repeat_Genome_Stats( $registry, $org );

		push(
			@data,
			(
				$gene_count,     $genome_size,      $transcriptome_size,
				$exome_size,     $intronome_size,   $transcript_count,
				$exon_count,     $intron_count,     $fputr_size,
				$tputr_size,     $introns_per_gene, $introns_per_bond,
				$exons_per_gene, $exons_per_gl,     $repeat_size,
				$repeat_count,   $repeat_density
			)
		);
	}

	# build the character matrix and return array reference
	print "Building character matrix...\n";
	&build_Char_Matrix( \@rownames, \@colnames, \@data );

	return 1;
}

# get the descriptive statistics
sub get_Descriptive_Statistics {

	# setup variables
	my $glens = shift(@_);
	my $tlens = shift(@_);

	my $as = shift(@_);
	my $cs = shift(@_);
	my $ts = shift(@_);
	my $gs = shift(@_);
	my $gc = $gs + $cs;

	my $organism = shift(@_);
	my $feature  = shift(@_);
	my @flens    = @_;
	my %output;

	# get number of genes and transcripts
	my $registry = &connect_to_EnsEMBL;
	my $genome_size    = &get_Genome_Size( $registry,    $organism );
	my $exome_size     = &get_Exome_Size( $registry,     $organism );
	my @gene_ids       = &get_Gene_IDs( $registry,       $organism );
	my @transcript_ids = &get_Transcript_IDs( $registry, $organism );
	my $g_num          = $#gene_ids + 1;
	my $tr_num         = $#transcript_ids + 1;

	# setup stats
	my $stats = Statistics::Descriptive::Full->new();
	$stats->add_data(@flens);

	# sort intron lengths numerically
	$stats->sort_data();
	my @sorted = $stats->get_data();

	#####################
	# calculate results #
	#####################

	# turn off strict subs and tie hash order
	no strict 'subs';
	tie( %output, Tie::IxHash );

	$output{'Genome size'}                       = $genome_size;
	$output{'Transcriptome size'}                = $exome_size + $stats->sum();
	$output{'Exome size'}                        = $exome_size;
	$output{'Genes'}                             = $g_num;
	$output{'Transcripts'}                       = $tr_num;
	$output{ 'Genes with ' . ucfirst($feature) } = $glens;
	$output{ 'Transcripts with ' . ucfirst($feature) } = $tlens;
	$output{ ucfirst($feature) . ' per Gene' } = $stats->count() / $glens;
	$output{ ucfirst($feature) }               = $stats->count();
	$output{'Minimum length'}                  = $stats->min();
	$output{'Maximum length'}                  = $stats->max();
	$output{'Total length'}                    = $stats->sum();
	$output{'Mean length'}                     = $stats->mean();
	$output{'Median length'}                   = $stats->median();
	$output{'Mode length'}                     = $stats->mode();
	$output{'Variance'}                        = $stats->variance();
	$output{'Standard Deviation'}              = $stats->standard_deviation();
	$output{'Geometric Mean Length'}           = $stats->geometric_mean();
	$output{'Harmonic Mean Length'}            = $stats->harmonic_mean();
	$output{'25th Percentile Length'}          = $stats->percentile(25);
	$output{'75th Percentile Length'}          = $stats->percentile(75);
	$output{'A NTs'}                           = $as;
	$output{'C NTs'}                           = $cs;
	$output{'G NTs'}                           = $gs;
	$output{'T NTs'}                           = $ts;
	$output{'GC %'}                            = ( $gc / $stats->sum() ) * 100;

	# adjust the decimal places
	for my $val ( values %output ) {
		$val =~ s/^(\d+\.\d+)\z/ sprintf '%.2f', $1/e;
	}

	# get root directory, setup path and filename
	my $dir      = getcwd();
	my $path     = File::Spec->catfile( $dir, "data", $organism );
	my $filename = File::Spec->catfile( $path, $feature . "_desc.csv" );

	# setup CSV
	my $csv = Text::CSV_XS->new( { binary => 1, eol => $/ } );

	# open file
	open my $fh, ">", "$filename" or die "$filename: $!";

	# add the header line
	$csv->print( $fh, [ $organism . '.desc', $organism . '.data' ] );

	# iterate through the output hash and print each line to CSV
	while ( my ( $key, $value ) = each %output ) {
		$key =~ s/\"//;
		$csv->print( $fh, [ "$key", "$output{$key}" ] ) or $csv->error_diag;
	}

	# close the CSV
	close $fh or die "$filename: $!";
	print "Outputted descriptive statistics to $filename\n";
	################################
	# build frequency distribution #
	################################

	# build fdist from unqiue lengths
	my %fseen = ();
	my @bin;
	foreach my $len (@sorted) {
		push( @bin, $len ) unless $fseen{$len}++;
	}
	my %fdist = $stats->frequency_distribution( \@bin );

	# get CSV filename
	$filename = File::Spec->catfile( $path, $feature . "_freqs.csv" );

	# setup CSV
	$csv = Text::CSV_XS->new( { binary => 1, eol => $/ } );

	# open file
	open $fh, ">", "$filename" or die "$filename: $!";

	# add the header line
	$csv->print( $fh, [ $organism . '.size', $organism . '.freqs' ] );

	# iterate through the fdist hash and print each line to CSV
	my @uflens = sort { $a <=> $b } keys %fdist;
	for my $uflen (@uflens) {
		$csv->print( $fh, [ $uflen, $fdist{$uflen} ] ) or $csv->error_diag;
	}

	# close the CSV
	close $fh or die "$filename: $!";
	print "Outputted frequency distribution to $filename\n";
}

1;
