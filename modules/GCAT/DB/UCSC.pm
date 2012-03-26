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

package GCAT::DB::UCSC;

# make life easier
use warnings;
use strict;

# import modules
use feature "switch";
use GCAT::Interface::Logging qw(logger);
use DBI;
use DBD::mysql;

# export subroutines
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(connect_To_UCSC);

############################################################
# ***   NEED TO READ THESE TO IMPLEMENT UCSC ACCESS!   *** #
#														   #
# http://genome.ucsc.edu/FAQ/FAQdownloads.html#download23  #
# http://genome.ucsc.edu/FAQ/FAQdownloads#download29       #
# http://genome.ucsc.edu/cgi-bin/hgTables				   #
# http://genome.ucsc.edu/goldenPath/help/hgTablesHelp.html #
############################################################

# connect to UCSC MySQL server
sub connect_To_UCSC {
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
			when ("ucsc") {
				($host, $user, $pass, $port) = ("genome-mysql.cse.ucsc.edu", "genome", undef, 3306);
			}
			default {
				logger("Database not found or defined - using genome-mysql.cse.ucsc.edu.", "Info");
				($host, $user, $pass, $port) = ("genome-mysql.cse.ucsc.edu", "genome", undef, 3306);
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


1;