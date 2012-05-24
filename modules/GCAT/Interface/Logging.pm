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

package GCAT::Interface::Logging;

# make life easier
use warnings;
use strict;

# import modules
use Cwd;

# export the logger subroutine
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(logger);

=head1 NAME

tea - Basic logging interface!

=cut

# some extra imports
use Log::Log4perl;

# lets setup this logging!!
sub setup_Logging {
	# log configuration
	my $logconf = q(
		log4perl.rootLogger = DEBUG, screen, file
		
		log4perl.appender.screen = Log::Log4perl::Appender::Screen
		log4perl.appender.screen.stderr = 0
		log4perl.appender.screen.layout = PatternLayout
		log4perl.appender.screen.layout.ConversionPattern = %p> %m%n
		
		log4perl.appender.file = Log::Log4perl::Appender::File
		log4perl.appender.file.filename = gcat.log
		log4perl.appender.file.mode = append
		log4perl.appender.file.layout = PatternLayout
		log4perl.appender.file.layout.ConversionPattern = %d %p> %F{1}:%L %M - %m%n
	);
		
	# initialise the logging
	Log::Log4perl->init(\$logconf);
}

# log routine
sub logger {
	# get input
	my $message = $_[0];
	my $type = lc($_[1]);
	
	# setup logger
	&setup_Logging;
	
	# setup logger
	my $logger = Log::Log4perl->get_logger();
	
	if ($type eq "error") {
		$logger->error($message);
	}
	elsif ($type eq "debug") {
		$logger->debug($message);
	}
	elsif ($type eq "info") {
		$logger->info($message);
	}
}

1;
