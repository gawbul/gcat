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

package GCAT::Data::Output;

# make life easier
use warnings;
use strict;

# imports
use Text::CSV_XS;
use Cwd;
use File::Spec;
use Statistics::R;
use Data::Dumper;
use Scalar::Util qw(blessed);

# export subroutines
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(write_Raw_To_CSV write_Hash_To_CSV write_Array_To_CSV write_Unique_To_CSV concatenate_CSV write_to_File build_Char_Matrix write_To_SeqIO);

# write hash to CSV
sub write_Hash_To_CSV {
	# setup variables
	my ($feature, $organism, %type) = @_;

	# get root directory, setup path and filename
	my $dir = getcwd();
	my $path = File::Spec->catfile($dir , "data", $organism);
	my $filename = File::Spec->catfile($path, "$feature.csv");

	# setup CSV
	my $csv = Text::CSV_XS->new ({binary => 1, eol => $/});
  	
  	# open file
  	open my $fh, ">", "$filename" or die "$filename: $!";
 	
 	# add the header line
 	$csv->print ($fh, [$organism . '.desc', $organism . '.data']); 	

	# iterate through the output hash and print each line to CSV
	while (my ($key, $value) = each %type) {
		$csv->print ($fh, ["$key", "$type{$key}"]) or $csv->error_diag;
	}	

	# close the CSV
	close $fh or die "$filename: $!";
	print "Outputted data to $filename\n";
}

# write hash to CSV
sub write_Array_To_CSV {
	# setup variables
	my ($feature, $organism, @data) = @_;

	# get root directory, setup path and filename
	my $dir = getcwd();
	my $path = File::Spec->catfile($dir , "data", $organism);
	my $filename = File::Spec->catfile($path, "$feature.csv");

	# let user know what we're doing
	print "Writing data to $filename...\n";
	
	# setup CSV
	my $csv = Text::CSV_XS->new ({binary => 1, eol => $/});
  	
  	# open file
  	open my $fh, ">", "$filename" or die "$filename: $!";
 	
 	# add the header line
 	$csv->print ($fh, [$organism . '.desc', $organism . '.count', $organism . '.length']); 	

	# iterate through the output hash and print each line to CSV
	while (my $dat = shift @data) {
		my ($desc, $count, $length) = @$dat;
		$csv->print ($fh, [$desc, $count, $length]) or $csv->error_diag;
	}	

	# close the CSV
	close $fh or die "$filename: $!";
	print "Outputted data to $filename\n";
}

# write raw data to CSV
sub write_Raw_To_CSV {
	# setup variables
	my ($organism, $feature, @data) = @_;
	
	# sort the data ascending numerically
	@data = sort {$a <=> $b} @data;
	
	# get root directory and setup data path
	my $dir = getcwd();
	my $path = File::Spec->catfile($dir , "data", $organism);
	my $filename = File::Spec->catfile($path, $feature . "_raw.csv");
	
	# setup CSV
	my $csv = Text::CSV_XS->new ({binary => 1, quote_space => 0, eol => $/});
  	
  	# open file
  	open my $fh, ">", "$filename" or die "$filename: $!";
 	
 	# add the header line
 	$csv->print ($fh, [$organism . ".sizes"]);
	
	# iterate through the data array and print each line
	while (my $row = shift(@data)) {
		$csv->print ($fh, [$row]) or $csv->error_diag;
	}
	
	# close the CSV
	close $fh or die "$filename: $!";
	
	# let user know where we outputted
	print "Outputted raw data to $filename\n";
}

# write raw data to CSV
sub write_Unique_To_CSV {
	# setup variables
	my ($organism, $feature, @data) = @_;
	
	# sort the data ascending numerically
	@data = sort {$a <=> $b} @data;
	
	# get root directory and setup data path
	my $dir = getcwd();
	my $path = File::Spec->catfile($dir , "data", $organism);
	my $filename = File::Spec->catfile($path, $feature . "_unique_raw.csv");
	
	# setup CSV
	my $csv = Text::CSV_XS->new ({ binary => 1, quote_space => 0, eol => $/ });
  	
  	# open file
  	open my $fh, ">", "$filename" or die "$filename: $!";
 	
 	# add the header line
 	$csv->print ($fh, [$organism . ".sizes"]);
	
	# iterate through the data array and print each line
	while (my $row = shift(@data)) {
		$csv->print ($fh, [$row]) or $csv->error_diag;
	}
	
	# close the CSV
	close $fh or die "$filename: $!";

	# let user know where we outputted
	print "Outputted raw data to $filename\n";
}

# subroutine to write frequency distribution to CSV file
sub write_FDist_To_CSV {
	# setup variables
	my ($organism, $feature, @data) = @_;
	
	
}

# build a character matrix from input data
sub build_Char_Matrix {
	# import data
	my @species = @{shift(@_)};
	my @characters = @{shift(@_)}; 
	my @data = @{shift(@_)};

	# get rownames and colnames plus lengths
	my $nrows = scalar(@species);
	my $ncols = scalar(@characters);

	# convert to string literals
	$Data::Dumper::Terse = 1;
    $Data::Dumper::Indent = 0;	
	my $species = join(",", Dumper(@species));
	my $colnames = join(",", Dumper(@characters));
	my $data = join(",", Dumper(@data));

	# set the matrix filename
	my $dir = getcwd();
	my $path = File::Spec->catfile($dir , "data");
	my $matrix_filename = File::Spec->catfile($dir , "data", "character_matrix.csv");
	
	# setup R and start clean R session
	my $R = Statistics::R->new();
	$R->startR;
	
	# send R commands to build matrix
	$R->send("char_matrix <- matrix(c($data), nrow=$nrows, ncol=$ncols, byrow=T, dimnames=list(c($species), c($colnames)))");
	$R->send("write.csv(char_matrix, file=\"$matrix_filename\")");

	# end R session
	$R->stopR;	

	# tell user where data is
	print "Outputted character matrix to $matrix_filename\n";
	
	# return character matrix
	return;
}

# new concatenate subroutine module that uses R cbindX
sub concatenate_CSV {
	# import data
	my ($feature, $type, @organisms) = @_;
	
	# get root directory and setup data path
	my $dir = getcwd();
	my $path = File::Spec->catfile($dir , "data");
	srand (time ^ $$ ^ unpack "%L*", `ps axww | gzip -f`); # seed random number generator
	my $random = int(rand(9999999999)); # get random number
	my $out_file = File::Spec->catfile($dir , "data", $feature . "_$type\_all_$random.csv");
	
	# setup R and start clean R session
	my $R = Statistics::R->new();
	$R->startR;
	$R->send("library(gdata)");
	
	# traverse each organism
	for my $organism (@organisms) {
	  	# setup file path
		my $in_file = File::Spec->catfile($path, $organism, $feature . "_$type.csv");
		
		# open CSV in read
		$R->send("$organism <- read.csv(\"$in_file\", header=TRUE)");
		$R->send("attach($organism)");
	}

	# bind columns and write to csv
	$R->send("merged <- cbindX(" . join(",", @organisms) . ")");
	$R->send("row.names(merged) <- NULL");
	$R->send("write.csv(merged, \"$out_file\", quote=F, row.names=F)");

	# end R session
	$R->stopR;

	# tell user where data is
	print "Outputted all data to $out_file\n";		
	
	# return out file for R
	return $out_file;		
}

# write data to file
sub write_to_File {
	# setup variables
	my ($filename, $data) = @_;
	
	# open the file for read, truncate if exists
	open OUTFILE, ">", $filename or die "$filename: " . $!;
	# print data to file
	print OUTFILE $data;
	# close file
	close(OUTFILE);
}

# write array to output format
sub write_To_SeqIO {
	# setup variables
	my ($filename, $format, @features) = @_;
	my ($gene, $transcript, $gid, $tid, $feature_id, $feature_type, $feature_class, $feature_seq) = undef;

	# setup seqio output
	my $seqio_out = Bio::SeqIO->new(-file => ">$filename" , '-format' => $format);
	
	# traverse features
	my $count = 0;
	while (my $feature = shift @features) {
		# setup gid and tid
		my $slice = $feature->slice(); 
		my @genes = @{$slice->get_all_Genes};
		
		# check we have some genes
		if (scalar(@genes) > 0) {
			$gene = $genes[0];			
		}
		
		# check gene defined
		if (!defined $gene) {
			$gid = "NULL";
			$tid = "NULL";
		}
		else {
			$gid = $gene->stable_id();
			$transcript = $gene->canonical_transcript(); 
			$tid = $transcript->stable_id();
		}
		
		# set feature_id by blessed
		if (blessed($feature) eq 'Bio::EnsEMBL::Intron') {
			$feature_id = "INTRON" . ($count + 1);
			$feature_type = "INTRON";
			$feature_class = "INTRON";
			$feature_seq = $feature->seq();
		}
		elsif (blessed($feature) eq 'Bio::EnsEMBL::Exon') {
			$feature_id = $feature->stable_id();
			$feature_type = "EXON";
			$feature_class = "EXON";
			$feature_seq = $feature->seq()->seq();
		}	
		elsif (blessed($feature) eq 'Bio::EnsEMBL::RepeatFeature') {
			$feature_id = "REPEAT" . ($count + 1);
			my $rc = $feature->repeat_consensus();
			$feature_type = $rc->repeat_type();
			$feature_class = $rc->repeat_class();
			$feature_seq = $rc->repeat_consensus();
		}	
		else {
			print blessed($feature) . "\n";
			$feature_id = $feature->stable_id();
			$feature_type = "UNKNOWN";
			$feature_class = "UNKNOWN";
			$feature_seq = $feature->seq();
		}

		# build the bio seq object
		my $feature_obj = Bio::Seq->new(-primary_id => $feature_id,
										-display_id => $feature_id,
										-desc => $gid . "\t" . $tid . "\t" . $feature_type . "\t" . $feature_class . "\t" . $feature->start() . "\t" . $feature->end() . "\t" . $feature->length() . "\t" . $feature->strand(),
										-alphabet => 'dna',
										-seq => $feature_seq);
								
		# do we have a 0 length feature?
		if ($feature->length() == 0) {
			next;
		}
		
		# write the fasta sequence
		$seqio_out->write_seq($feature_obj);

		# let user know something is happening
		if (($count % 100) == 0) {
			print ".";
		}
		$count++;
	}	
	
	return $count;
}

# deprecated concatenate CSV subroutine
#sub _old_concatenate_CSV {
#	# import data
#	my $feature = shift(@_);
#	my @organisms = @_;
#	my %csv_hash;
#	my @order;
#	
#	# get root directory and setup data path
#	my $dir = getcwd();
#	my $path = File::Spec->catfile($dir , "data");
#	srand (time ^ $$ ^ unpack "%L*", `ps axww | gzip -f`); # seed random number generator
#	my $random = int(rand(9999999999)); # get random number
#	my $out_file = File::Spec->catfile($dir , "data", $feature ."_all_$random.csv");
#	
#	# traverse each organism
#	for my $organism (@organisms) {
#		# setup CSV
#		my $csv = Text::CSV_XS->new ({ binary => 1 });
#			  	
#	  	# open file
#		my $in_file = File::Spec->catfile($path, $organism, $feature . "_freqs.csv");
#	  	open my $fh, "<", "$in_file" or die "$in_file: $!";
#		
#		# traverse file and push array_ref to array 
#		my $rows = [];
#		while (my $row = $csv->getline($fh)) {
#			 push(@$rows, $row);
#		}
#		
#		## display to ensure not flattened the rows
#		#while (my $r = shift @{$rows}) {
#		#	print join(",", @$r) . "\n";
#		#}
#		
#		# push array to hash		
#		$csv_hash{$organism} = $rows;	
#		
#		# close the CSV
#		$csv->eof or $csv->error_diag;
#		close $fh or die "$in_file: $!";
#	}
#
#  	# open the out file
#  	open my $ofh, ">", "$out_file" or die "$out_file: $!";
#	
#	# get the size of the array in each hash array and sort in descending size
#	foreach my $k (sort {scalar(@{$csv_hash{$b}}) <=> scalar(@{$csv_hash{$a}})} keys %csv_hash) {
#		push(@order, $k);		
#	}
#	
#	# display data in order
#	for my $o (@order) {
#		while (my $array = shift @{$csv_hash{$o}}) {
#			print "@$array\n";
#		}
#	}
#	
#	# need to build rows from separate hashes
#	###########################
#	# *** MORE TO DO HERE *** #
#	###########################
#	
#	# close output CSV
#	close $ofh or die "$out_file: $!";
#
#	# tell user where data is
#	print "Outputted all data to $out_file\n";		
#	
#	# return out file for R
#	return $out_file;
#}

1;