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

	perl_test

=head1 SYNOPSIS

	perl_test.pl
    
=head1 DESCRIPTION

	This is a test script implemented in Perl.

=cut

# some imports
use warnings;
use strict;

print "We have Perl plug-in scripts :-)\n";

print "Arguments (" . scalar(@ARGV) . "): @ARGV\n";