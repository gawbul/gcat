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

=head1 NAME

	get_intron_splice_type

=head1 SYNOPSIS

    get_intron_splice_type species1 species2 species3...
    
=head1 DESCRIPTION

	A program to retrieve the intron splice types

=cut

# make life easier
use strict;
use warnings;

# includes
use Time::HiRes qw(gettimeofday);
use TEA::Data::Parsing;
use TEA::Interface::Logging;

# get arguments
my $num_args = $#ARGV + 1;
my @organisms = @ARGV;

# check arguments list is sufficient
if ($num_args < 1) {
	logger("This script requires at least one input argument, for the organisms you wish to download the information for.", "Error");
	exit;
}

# tell user what we're doing
print "Going to retrieve splice types for $num_args species: @organisms...\n";

# set start time
my $start_time = gettimeofday;

# traverse each organism and for UTR stuff - Dave
foreach my $org (@organisms) {
	&TEA::Data::Parsing::get_Intron_Splice_Type($org);
}

# set end time and calculate time elapsed
my $end_time = gettimeofday;
my $elapsed = $end_time - $start_time;

# let user know we have finished
printf "Finished in %0.3f!\n", $elapsed;