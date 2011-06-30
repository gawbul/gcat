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