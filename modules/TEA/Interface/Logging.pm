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

package TEA::Interface::Logging;

# make life easier
use warnings;
use strict;
use Cwd;

# export the logger subroutine
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(logger);

=head1 NAME

tea - Basic logging interface!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

# some extra imports
use Log::Log4perl qw(:easy);

# lets setup this logging!!
sub setup_Logging {
	# setup log file path
	my $dir = getcwd();
	my $path = File::Spec->catfile($dir, "tea.log");
	
	# initialise the logging
	Log::Log4perl->easy_init(
	    {
	    	file  => ">>$path",
	    	level => $ERROR,
	    },
	
	    {
	    	level => $DEBUG,
	    }
	    );
}

# log routine
sub logger {
	my $message = $_[0];
	my $type = $_[1];
	if ($type eq "Error") {
		ERROR($message);
	}
	elsif ($type eq "Debug") {
		DEBUG($message);
	}
}

1;
