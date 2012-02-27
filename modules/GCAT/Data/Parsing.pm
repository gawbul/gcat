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

package GCAT::Data::Parsing;

# make life easier
use warnings;
use strict;

# export subroutines
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(check_Data_OK get_Feature_Lengths get_Gene_IDs_from_Feature);

# imports
use Cwd;
use Bio::SeqIO;
use Bio::DB::GFF;
use Bio::DB::Fasta;
use File::Spec;
use GCAT::DB::EnsEMBL;
use Time::HiRes qw(gettimeofday tv_interval);
use Set::IntSpan::Fast;
use Text::CSV_XS;
use Statistics::Descriptive;

# do data checks for a given feature for give organisms
sub check_Data_OK {
	# setup variables
	my $feature = shift(@_);
	my @organisms = @_;
	
	# get root directory and setup data path
	my $dir = getcwd();
	my $path = File::Spec->catfile($dir , "data");
	my $filename = $feature . ".fas";
	
	# check data directory exists
	if (! -d "$path") {
		print("The data directory does not exist. You must first retrieve some data.\n");
		exit;
	}
	
	# check organism data directories exist and filenames exist
	foreach my $org (@organisms) {
		# check organism data directory exists
		unless (-d "$path/$org") {
			print("One or more of the organisms doesn't have a data directory.\nPlease retrieve data for at least \"$org\" first.\n");
			exit; 
		}
		# check feature filename exists
		unless (-e "$path/$org/$filename") {
			print("One or more of the organisms doesn't this $feature data available. Please retrieve this data for at least \"$org\" first.\n");
			exit; 		
		}
	}
}

# build unique intron sizes
sub get_Repeat_Stats {
	# setup arguments
	my ($feature, $organism) = @_;
	
	# define variables
	my %class = ();
	my @classes;
	my ($rcount, $rtotal) = 0;
	
	###############################
	# retrieve repeat coordinates #
	###############################
	
	# get root directory and setup data path
	my $dir = getcwd();
	my $filename = "$feature.fas";
				
	# setup file path
	my $path = File::Spec->catfile($dir, "data", $organism, $filename);
	
	# create new Bio::DB object
	my $db = Bio::DB::Fasta->new("$path");
	
	# get all feature ids
	my @feature_ids = $db->get_all_ids();

	print "Processing " . ($#feature_ids + 1) . " repeat sequences for $organism...\n";
	# loop through features
	while (my $ft = shift(@feature_ids)) {
		my ($rid, $gid, $tid, $rclass, $rstt, $rend, $rlen, $rstrand) = split(/ /, $db->header($ft));
		# remove 0 length introns
		if ($rlen > 0) {
			push(@{$class{$rclass}}, $rlen);
			$rtotal += $rlen;
			$rcount++;
		}
	}

	##################################
	# work out the numbers and sizes #
	##################################
	
	print "Calculating repeat class sizes...\n";
	
	# iterate through the hash
	while (my ($key, $value) = each %class) {
		# declare variables
		my $count = 0;
		my $total = 0;
		# get hash array
		my @rlens = @{$class{$key}};
		# iterate through array for class
		foreach my $rlen (@rlens) {
			$count++;
			$total += $rlen;
		}
		push(@classes, [$key, $count, $total]);
		print "Class $key: $count $feature ($total bps)\n";
	}
	
	print "Returned $rcount $feature ($rtotal bps)\n\n";

	return @classes;
}

# build unique intron sizes
sub get_Unique_Features {
	# setup arguments
	my ($feature, $organism) = @_;
	
	# define some variables
	my %coords = ();
	my @introns;
	
	###############################
	# retrieve intron coordinates #
	###############################

	# get root directory and setup data path
	my $dir = getcwd();
	my $filename = $feature . ".fas";
				
	# setup file path
	my $path = File::Spec->catfile($dir, "data", $organism, $filename);
	
	# create new Bio::DB object
	my $db = Bio::DB::Fasta->new("$path");
	
	# get all feature ids
	my @feature_ids = $db->get_all_ids();
	
	print "\nProcessing $organism...\n";
	
	print "Adding " . ($#feature_ids + 1) . " $feature coordinates...\n";
	
	# loop through features
	while (my $ft = shift(@feature_ids)) {
		my ($fid, $gid, $tid, $fstt, $fend, $flen, $fstrand) = split(/ /, $db->header($ft));
		unless (defined $coords{$gid}) {
		 	$coords{$gid} = Set::IntSpan::Fast->new();
		}
		# remove 0 length introns
		if ($flen > 0) {
			if ($fstt == $fend) {
				$coords{$gid}->add($fstt);					
			}
			else {
				$coords{$gid}->add_range($fstt, $fend);
			}
		}
	}
	
	###############################
	# retrieve repeat coordinates #
	###############################
	
	# get root directory and setup data path
	$dir = getcwd();
	$filename = "repeats.fas";
				
	# setup file path
	$path = File::Spec->catfile($dir, "data", $organism, $filename);
	
	# create new Bio::DB object
	$db = Bio::DB::Fasta->new("$path");
	
	# get all feature ids
	@feature_ids = $db->get_all_ids();

	print "Processing " . ($#feature_ids + 1) . " repeat coordinates...\n";
	# loop through features
	while (my $ft = shift(@feature_ids)) {
		my ($rid, $gid, $tid, $rclass, $rstt, $rend, $rlen, $rstrand) = split(/ /, $db->header($ft));
		# remove 0 length introns
		if ($rlen > 0) {
			if (defined $coords{$gid}) {
				$coords{$gid}->remove_range($rstt, $rend);
			}
		}
	}

	############################
	# work out the coordinates #
	############################
	
	print "Calculating unique $feature...\n";
	
	# build individual intron sizes again
	while (my ($key, $value) = each %coords) {
		my $range = $coords{$key}->as_string;
		my @intron_pairs = split(/,/, $range);
		foreach my $pair (@intron_pairs) {
			my ($start, $end) = split(/-/, $pair);
			unless (defined $end) {
				push(@introns, 1);				
			}
			else {
				my $intron_size = ($end - $start) + 1;
				push(@introns, $intron_size);
			}
		}
	}
	
	print "Returned " . ($#introns + 1) . " unique $feature\n";

	return @introns;
}

# get information from sequence
sub get_Sequence_Info {
	# setup arguments
	my ($feature, $organism) = @_;
	
	# declare some variables
	my $a_nts = 0;
	my $c_nts = 0;
	my $g_nts = 0;
	my $t_nts = 0;
	
	# define some variables
	my (@seq_info);
	
	# get root directory and setup data path
	my $dir = getcwd();
	my $filename = $feature . ".fas";
				
	# setup file path
	my $path = File::Spec->catfile($dir, "data", $organism, $filename);
	
	# create new Bio::DB object
	my $db = Bio::DB::Fasta->new("$path");
	
	# get all feature ids
	my @feature_ids = $db->get_all_ids();

	# loop through features
	while (my $ft = shift(@feature_ids)) {
		my $seq = $db->seq($ft);
		my $as = ($seq =~ tr/A//);
		my $cs = ($seq =~ tr/C//);
		my $gs = ($seq =~ tr/G//);
		my $ts = ($seq =~ tr/T//);
		$a_nts = $a_nts + $as;
		$c_nts = $c_nts + $cs;
		$g_nts = $g_nts + $gs;
		$t_nts = $t_nts + $ts;
	}
	push(@seq_info, $a_nts);
	push(@seq_info, $c_nts);
	push(@seq_info, $g_nts);
	push(@seq_info, $t_nts);

	return @seq_info;
}

# get a count of the features for CSV
sub get_Feature_Lengths {
	# setup arguments
	my ($feature, $organism) = @_;
	
	# define some variables
	my (@flens, @gids, @tids);
	
	# get root directory and setup data path
	my $dir = getcwd();
	my $filename = $feature . ".fas";
				
	# setup file path
	my $path = File::Spec->catfile($dir, "data", $organism, $filename);
	
	# create new Bio::DB object
	my $db = Bio::DB::Fasta->new("$path");
	
	# get all feature ids
	my @feature_ids = $db->get_all_ids();

	# loop through features
	while (my $ft = shift(@feature_ids)) {
		my ($fid, $gid, $tid, $fstt, $fend, $flen, $fstrand) = split(/ /, $db->header($ft));
		# remove 0 length introns
		if ($flen > 0) {
			push (@flens, $flen);
			push (@gids, $gid);
			push (@tids, $tid);
		}
	}
	
	# sort the gene IDs
	my @sorted = sort { $a cmp $b } @gids;
	
	# get list of unique gene IDs
	my %fseen = ();
	my @ugids;
	foreach my $gid (@sorted) {
   		push(@ugids, $gid) unless $fseen{$gid}++;
 	}

	# sort the transcript IDs
	@sorted = sort { $a cmp $b } @tids;
	
	# get list of unique transcript IDs
	%fseen = ();
	my @utids;
	foreach my $tid (@sorted) {
   		push(@utids, $tid) unless $fseen{$tid}++;
 	}
 		
	# setup return data add gene lens, transcript lens and feature in that order
	unshift(@flens, $#utids + 1);
	unshift(@flens, $#ugids + 1);
	
	return @flens;
}

# get the gene IDs for a certain organism
sub get_Gene_IDs_from_Feature {
	# setup arguments
	my ($feature, $organism, $start, $end) = @_;
	
	# define some variables
	my @gids;
	
	# get root directory and setup data path
	my $dir = getcwd();
	my $filename = $feature . ".fas";
				
	# setup file path
	my $path = File::Spec->catfile($dir, "data", $organism, $filename);
	
	# create new Bio::DB object
	my $db = Bio::DB::Fasta->new("$path");
	
	# get all feature ids
	my @feature_ids = $db->get_all_ids();
	
	print "Processing " . ($#feature_ids + 1). " feature IDs...\n";
	# loop through features
	while (my $ft = shift(@feature_ids)) {
		my ($fid, $gid, $tid, $fstt, $fend, $flen, $fstrand) = split(/ /, $db->header($ft));
		# remove 0 length introns
		if ($flen > 0) {
			if ($flen >= $start && $flen <= $end) {
				my $obj = $db->get_Seq_by_id($ft);
				push (@gids, [$gid, $flen, $obj->seq()]);
			}
		}
	}
	
	# setup return data
	return @gids;	
}

# get the number of introns at UTR boundries or within CDS
sub get_Intron_Position_in_Transcript {
	# set start time
	my $start_time = gettimeofday;
	
	# setup arguments
	my $organism = $_[0];
	
	# define some variables
	our (%coords, %fputr, %tputr) = ();
	our ($cds_length, $fputr_length, $tputr_length) = 0;
	my $count;
	
	# set autoflush for stdout
	local $| = 1;
	
	print "\nFetching CDS and UTR coordinates for $organism...\n";
	
	# setup EnsEMBL connection for next step
	my $registry = &connect_to_EnsEMBL;
	
	# setup gene adaptor
	my $gene_adaptor = $registry->get_adaptor( $organism, 'Core', 'Gene');
	
	# get gene IDs
	my @geneids = &get_Gene_IDs($registry, $organism);
		
	# iterate through all gene ids
	$count = 0;
	foreach my $geneid (@geneids){
		# fetch the gene by stable id
		my $gene = $gene_adaptor->fetch_by_stable_id($geneid);
	
		# only get protein coding genes
		unless ($gene->biotype eq "protein_coding") {
			next;
		}
		
		# get canonical transcript
		my $transcript = $gene->canonical_transcript();
			
		# retrieve coordinates for the canonical transcript
		my $cds_stt = $transcript->coding_region_start;
		my $cds_end = $transcript->coding_region_end;	
		
		# lets push the coordinates to our transcript list
		if (defined $cds_stt && defined $cds_end) {
			# check our IntSpan hashes are defined
			unless (defined $coords{$transcript->stable_id}) {
				$coords{$transcript->stable_id} = Set::IntSpan::Fast->new;	
			}
			unless (defined $fputr{$transcript->stable_id}) {
				$fputr{$transcript->stable_id} = Set::IntSpan::Fast->new;	
			}
			unless (defined $tputr{$transcript->stable_id}) {
				$tputr{$transcript->stable_id} = Set::IntSpan::Fast->new;	
			}
			
			# add the numbers - adjusting fputr and tputr for strand direction		
			$coords{$transcript->stable_id}->add_range($cds_stt, $cds_end);
			$cds_length += ($cds_end - $cds_stt);

#			print $transcript->strand . "\n";
#			print $transcript->start . "\n\n";
#			print $cds_stt . "\n";
#			print $cds_end . "\n\n";
#			print $transcript->end . "\n";
						
			# if we are missing UTRs then ignore next section
			if ($cds_stt == $transcript->start() && $cds_end == $transcript->end()) {	
				next;
			}
			elsif ($cds_stt == $transcript->start()) {
				# work out UTR position based on strand
				if ($transcript->strand == 1) {
					$tputr{$transcript->stable_id}->add_range($cds_end + 1, $transcript->end);
					$tputr_length += ($transcript->end - $cds_end);
				}
				else {
					$fputr{$transcript->stable_id}->add_range($cds_end + 1, $transcript->end);				
					$fputr_length += ($transcript->end - $cds_end);
				}							
			}
			elsif($cds_end == $transcript->end()) {
				# work out UTR position based on strand
				if ($transcript->strand == 1) {
					$fputr{$transcript->stable_id}->add_range($transcript->start, $cds_stt - 1);
					$fputr_length += ($cds_stt - $transcript->start);
				}
				else {
					$tputr{$transcript->stable_id}->add_range($transcript->start, $cds_stt - 1);	
					$tputr_length += ($cds_stt - $transcript->start);
				}					
			}
			else {
				# work out UTR position based on strand
				if ($transcript->strand == 1) {
					$fputr{$transcript->stable_id}->add_range($transcript->start, $cds_stt - 1);
					$tputr{$transcript->stable_id}->add_range($cds_end + 1, $transcript->end);
					$fputr_length += ($cds_stt - $transcript->start);
					$tputr_length += ($transcript->end - $cds_end);
				}
				else {
					$tputr{$transcript->stable_id}->add_range($transcript->start, $cds_stt - 1);
					$fputr{$transcript->stable_id}->add_range($cds_end + 1, $transcript->end);				
					$fputr_length += ($transcript->end - $cds_end);
					$tputr_length += ($cds_stt - $transcript->start);
				}	
			}
		}

		# let user know something is happening
		if ($count % 1000 == 0) {
			print ".";
		}
		$count++;
	}
	
	print "\nCalculating intron locations...\n\n";

	# get root directory and setup data path
	my $dir = getcwd();
	my $filename = "introns.fas";
				
	# setup file path
	my $path = File::Spec->catfile($dir, "data", $organism, $filename);
	
	# create new Bio::DB object
	my $db = Bio::DB::Fasta->new("$path");
	
	# get all feature ids
	my @feature_ids = $db->get_all_ids();

	# setup some variables,
	my $fp_utr_count = 0;
	my $tp_utr_count = 0;
	my $cds_count = 0;
	my $intron_count = 0;
	
	# added this to get individual lengths for different intron locations
	our %loc_count = ("fputr" => 0, "cds" => 0, "tputr" => 0);
	our %fdist = ("fputr" => [],"cds" => [], "tputr" => []);	

	# loop through features
	while (my $ft = shift @feature_ids) {
		my ($fid, $gid, $tid, $fstt, $fend, $flen, $strand) = split(/ /, $db->header($ft));
		# remove 0 length introns
		if ($flen > 0 && defined $coords{$tid}) {
			if ($fstt == $fend) {
				if ($coords{$tid}->contains($fstt)) {
					$cds_count++;
					$loc_count{"cds"} += 1;
					push(@{$fdist{"cds"}}, 1);
				}
				elsif ($fputr{$tid}->contains($fstt)) {
					$fp_utr_count++;
					$loc_count{"fputr"} += 1;	
					push(@{$fdist{"fputr"}}, 1);
				}
				elsif ($tputr{$tid}->contains($fstt)) {
					$tp_utr_count++;
					$loc_count{"tputr"} += 1;
					push(@{$fdist{"tputr"}}, 1);
				}
				else {
					# shouldn't happen - no other possible locations
					print "Shouldn't happen!\n";
				}		
			}
			else {
				if ($coords{$tid}->contains_any($fstt, $fend)) {
					$cds_count++;
					$loc_count{"cds"} += $flen;
					push(@{$fdist{"cds"}}, $flen);						
				}
				elsif ($fputr{$tid}->contains_any($fstt, $fend)) {
					$fp_utr_count++;	
					$loc_count{"fputr"} += $flen;	
					push(@{$fdist{"fputr"}}, $flen);						
				}
				elsif ($tputr{$tid}->contains_any($fstt, $fend)) {
					$tp_utr_count++;	
					$loc_count{"tputr"} += $flen;	
					push(@{$fdist{"tputr"}}, $flen);						
				}
				else {
					# shouldn't happen - no other possible locations
					print "Shouldn't happen!\n";
				}				
			}
			$intron_count++;
		}
	}
	
	# calculate total transcript length
	my $tr_length = $fputr_length + $cds_length + $tputr_length;
		
	# get CSV filename
	$filename = File::Spec->catfile($dir, "data", $organism, "introns_utr_pos_desc.csv");
	
	# setup CSV
	my $csv = Text::CSV_XS->new ({ binary => 1, eol => $/ });
  	
  	# open file
  	open my $fh, ">", "$filename" or die "$filename: $!";
 	
 	# add the header line
 	$csv->print ($fh, [$organism . '.desc', $organism . '.data']); 	
 	$csv->print ($fh, ["5\' UTR introns", $fp_utr_count]); 	
 	$csv->print ($fh, ["5\' UTR introns length", $loc_count{"fputr"}]);
 	$csv->print ($fh, ["5\' UTR introns \% of total 5\' UTR length", ($loc_count{"fputr"} / $fputr_length) * 100]);	
 	$csv->print ($fh, ["3\' UTR introns", $tp_utr_count]); 	
 	$csv->print ($fh, ["3\' UTR introns length", $loc_count{"tputr"}]); 		
 	$csv->print ($fh, ["3\' UTR introns \% of total 3\' UTR length", ($loc_count{"tputr"} / $tputr_length) * 100]);
 	$csv->print ($fh, ["CDS introns", $cds_count]); 	
 	$csv->print ($fh, ["CDS introns length", $loc_count{"cds"}]); 		
 	$csv->print ($fh, ["CDS introns \% of total CDS length", ($loc_count{"cds"} / $cds_length) * 100]);
 	$csv->print ($fh, ["Total introns", $intron_count]); 	
 	$csv->print ($fh, ["Total 5\' UTR length", $fputr_length]);
 	$csv->print ($fh, ["5\' UTR introns length \% of total transcript length", ($loc_count{"fputr"} / $tr_length) * 100]);		 	
 	$csv->print ($fh, ["Total 3\' UTR length", $tputr_length]); 	
 	$csv->print ($fh, ["3\' UTR introns length \% of total transcript length", ($loc_count{"tputr"} / $tr_length) * 100]);	
 	$csv->print ($fh, ["Total CDS length", $cds_length]);
 	$csv->print ($fh, ["CDS introns length \% of total transcript length", ($loc_count{"cds"} / $tr_length) * 100]);	
 	$csv->print ($fh, ["Total transcript length", $tr_length]);
	
	# close the CSV
	close $fh or die "$filename: $!";
	print "Outputted intron position and length counts to $filename\n";
		
	# iterate through each key (fputr, cds and tputr)
	print "Building frequency distributions...\n";
	foreach my $key (keys %fdist) {		
		# setup stats
		my $stats = Statistics::Descriptive::Full->new();
		$stats->add_data(@{$fdist{$key}});

 		# sort intron lengths numerically
		$stats->sort_data();
		my @sorted = $stats->get_data();
		
		# build fdist from unqiue lengths
		my %fseen = ();
		my @bin;
		foreach my $len (@sorted) {
	   		push(@bin, $len) unless $fseen{$len}++;
	 	}
		my %freqdist = $stats->frequency_distribution(\@bin);

		# get CSV filename
		$filename = File::Spec->catfile($dir, "data", $organism, "introns_" . $key . "_freqs.csv");
		
		# setup CSV
		my $csv = Text::CSV_XS->new ({ binary => 1, eol => $/ });
	  	
	  	# open file
	  	open my $fh, ">", "$filename" or die "$filename: $!";
	 	
	 	# add the header line
	 	$csv->print ($fh, [$organism . '.sizes', $organism . '.freqs']);

		my @uflens = sort {$a <=> $b} keys %freqdist;
		for my $uflen (@uflens) {
	    	$csv->print ($fh, [$uflen, $freqdist{$uflen}]) or $csv->error_diag;
		}
	
		# close the CSV
		close $fh or die "$filename: $!";
		print "Outputted intron position frequencies to $filename\n";	
	}
	
	# set end time
	my $end_time = gettimeofday;
	my $elapsed = $end_time - $start_time;

	# let user know we have finished
	printf "Finished in %0.3f!\n", $elapsed;
}

# get intron splice type
sub get_Intron_Splice_Type {
	# set start time
	my $start_time = gettimeofday;
	
	# setup arguments
	my $organism = $_[0];
	
	# define some variables
	my @seqs;
	my ($u2_introns, $u12_introns, $other_introns, $count) = 0;
	
	# get root directory and setup data path
	my $dir = getcwd();
	my $filename = "introns.fas";
				
	# setup file path
	my $path = File::Spec->catfile($dir, "data", $organism, $filename);
	
	# create new Bio::DB object
	my $stream = Bio::DB::Fasta->new("$path")->get_PrimarySeq_stream();
	
	# variable for frequency distribution
	our %fdist = ("u2" => [],"u12" => [], "other" => []);
		
	# loop through features
	while (my $seq = $stream->next_seq) {
		if ($seq->seq =~ /^GT.*?AG$/) {
			$u2_introns++;
			push(@{$fdist{"u2"}}, $seq->length());
		}
		elsif ($seq->seq =~ /^AT.*?AC$/) {
			$u12_introns++;
			push(@{$fdist{"u12"}}, $seq->length());
		}
		else {
			$other_introns++;
			push(@{$fdist{"other"}}, $seq->length());
		}
		$count++;
	}
	
	# get CSV filename
	$filename = File::Spec->catfile($dir, "data", $organism, "intron_splice_type_desc.csv");
	
	# setup CSV
	my $csv = Text::CSV_XS->new ({ binary => 1, eol => $/ });
  	
  	# open file
  	open my $fh, ">", "$filename" or die "$filename: $!";
 	
 	# add the header line
 	$csv->print ($fh, [$organism . '.desc', $organism . '.data']); 	

 	$csv->print ($fh, ["U2 (major) number", $u2_introns]); 	
 	$csv->print ($fh, ["U2 (major) percentage", ($u2_introns / $count) * 100]); 
 	$csv->print ($fh, ["U12 (minor) number", $u12_introns]); 	
 	$csv->print ($fh, ["U12 (minor) percentage", ($u12_introns / $count) * 100]); 
 	$csv->print ($fh, ["Other number", $other_introns]); 	
 	$csv->print ($fh, ["Other percentage", ($other_introns / $count) * 100]); 	
 	$csv->print ($fh, ["Introns analysed", $count]); 	
 	
	# close the CSV
	close $fh or die "$filename: $!";
	print "Outputted spliceosome type information to $filename\n";
	
	# iterate through each key (fputr, cds and tputr)
	print "Building frequency distributions...\n";
	foreach my $key (keys %fdist) {		
		# setup stats
		my $stats = Statistics::Descriptive::Full->new();
		$stats->add_data(@{$fdist{$key}});

 		# sort intron lengths numerically
		$stats->sort_data();
		my @sorted = $stats->get_data();
		
		# build fdist from unqiue lengths
		my %fseen = ();
		my @bin;
		foreach my $len (@sorted) {
	   		push(@bin, $len) unless $fseen{$len}++;
	 	}
		my %freqdist = $stats->frequency_distribution(\@bin);

		# get CSV filename
		$filename = File::Spec->catfile($dir, "data", $organism, "introns_" . $key . "_freqs.csv");
		
		# setup CSV
		my $csv = Text::CSV_XS->new ({ binary => 1, eol => $/ });
	  	
	  	# open file
	  	open my $fh, ">", "$filename" or die "$filename: $!";
	 	
	 	# add the header line
	 	$csv->print ($fh, [$organism . '.sizes', $organism . '.freqs']);

		my @uflens = sort {$a <=> $b} keys %freqdist;
		for my $uflen (@uflens) {
	    	$csv->print ($fh, [$uflen, $freqdist{$uflen}]) or $csv->error_diag;
		}
	
		# close the CSV
		close $fh or die "$filename: $!";
		print "Outputted splicesome type frequencies to $filename\n";	
	} 	
	
	# set end time
	my $end_time = gettimeofday;
	my $elapsed = $end_time - $start_time;

	# let user know we have finished
	printf "Finished in %0.3f!\n", $elapsed;
}

1;