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

package TEA::Analysis::Descriptive;

# make life easier
use warnings;
use strict;

# export subroutines
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(get_Descriptive_Statistics);

#Êsetup the includes
use Statistics::Descriptive;
use TEA::DB::EnsEMBL;
use TEA::Data::Output;
use Text::FormatTable;
use Cwd;
use File::Spec;
use Tie::IxHash;

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
	my $feature = shift(@_);
	my @flens = @_;
	my %output;
	
	# get number of genes and transcripts
	my $registry = &connect_to_EnsEMBL(undef, undef, undef, undef);
	my $genome_size = &get_Genome_Size($registry, $organism);
	my $exome_size = &get_Exome_Size($registry, $organism);
	my @gene_ids = &get_Gene_IDs($registry, $organism);
	my @transcript_ids = &get_Transcript_IDs($registry, $organism);
	my $g_num = $#gene_ids + 1;
	my $tr_num = $#transcript_ids + 1;
	
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
	tie (%output, Tie::IxHash);
	
	$output{'Genome size'} = $genome_size;
	$output{'Transcriptome size'} = $exome_size + $stats->sum();
	$output{'Exome size'} = $exome_size;
	$output{'Genes'} = $g_num;
	$output{'Transcripts'} = $tr_num;
	$output{'Genes with ' . ucfirst($feature)} = $glens;
	$output{'Transcripts with ' . ucfirst($feature)} = $tlens;
	$output{ucfirst($feature) . ' per Gene'} = $stats->count() / $glens;
	$output{ucfirst($feature)} = $stats->count();
	$output{'Minimum length'} = $stats->min();
	$output{'Maximum length'} = $stats->max();
	$output{'Total length'} = $stats->sum();
	$output{'Mean length'} = $stats->mean();
	$output{'Median length'} = $stats->median();
	$output{'Mode length'} = $stats->mode();
	$output{'Variance'} = $stats->variance();
	$output{'Standard Deviation'} = $stats->standard_deviation();
	$output{'Geometric Mean Length'} = $stats->geometric_mean();
	$output{'Harmonic Mean Length'} = $stats->harmonic_mean();
	$output{'25th Percentile Length'} = $stats->percentile(25);
	$output{'75th Percentile Length'} = $stats->percentile(75);
	$output{'A NTs'} = $as;
	$output{'C NTs'} = $cs;
	$output{'G NTs'} = $gs;
	$output{'T NTs'} = $ts;
	$output{'GC %'} = ($gc / $stats->sum()) * 100;
	
	# adjust the decimal places
	for my $val ( values %output ) {
    	$val =~ s/^(\d+\.\d+)\z/ sprintf '%.2f', $1/e;
	}
	
	# get root directory, setup path and filename
	my $dir = getcwd();
	my $path = File::Spec->catfile($dir , "data", $organism);
	my $filename = File::Spec->catfile($path, $feature . "_desc.csv");
	
	# setup CSV
	my $csv = Text::CSV_XS->new ({ binary => 1, eol => $/ });
  	
  	# open file
  	open my $fh, ">", "$filename" or die "$filename: $!";
 	
 	# add the header line
 	$csv->print ($fh, [$organism . '.desc', $organism . '.data']); 	

	# iterate through the output hash and print each line to CSV
	while (my ($key, $value) = each %output) {
		$key =~ s/\"//;
		$csv->print ($fh, ["$key", "$output{$key}"]) or $csv->error_diag;
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
   		push(@bin, $len) unless $fseen{$len}++;
 	}
	my %fdist = $stats->frequency_distribution(\@bin);

	# get CSV filename
	$filename = File::Spec->catfile($path, $feature . "_freqs.csv");
	
	# setup CSV
	$csv = Text::CSV_XS->new ({ binary => 1, eol => $/ });
  	
  	# open file
  	open $fh, ">", "$filename" or die "$filename: $!";
 	
 	# add the header line
 	$csv->print ($fh, [$organism . '.size', $organism . '.freqs']); 	

	# iterate through the fdist hash and print each line to CSV
	my @uflens = sort {$a <=> $b} keys %fdist;
	for my $uflen (@uflens) {
    	$csv->print ($fh, [$uflen, $fdist{$uflen}]) or $csv->error_diag;
	}
	
	# close the CSV
	close $fh or die "$filename: $!";
	print "Outputted frequency distribution to $filename\n";
}

1;
