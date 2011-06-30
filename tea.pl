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

# make life that little bit easier
use warnings;
use strict;

# import our TEA packages
use TEA::TEA;
use TEA::Interface::Logging;
use TEA::Interface::Parse;

# check version information first
&TEA::TEA::check_Version_Numbers;
&TEA::Interface::Logging::setup_Logging;

# pass inputs to input_Parser
&TEA::Interface::Parse::input_Parser(@ARGV);