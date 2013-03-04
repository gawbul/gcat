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

# make life that little bit easier
use warnings;
use strict;

# import our GCAT packages
use GCAT;
use GCAT::Interface::Logging;
use GCAT::Interface::Parse;
use GCAT::Statistics::R;

# check input options first
&GCAT::Interface::Parse::check_input_Options(@ARGV);

# check version information first
&GCAT::check_version_Numbers();

# let user know we're starting up
print "Starting up GCAT...\n";

# setup logging
&GCAT::Interface::Logging::setup_Logging();

# check R environment
&GCAT::Statistics::R::check_R_Environ();

# pass inputs to input_Parser
&GCAT::Interface::Parse::input_Parser(@ARGV);