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

package GCAT;

# make life easier
use warnings;
use strict;

# lets try and load some of the require modules first
use Bio::EnsEMBL::Registry;
use Bio::Root::Version;
# Bio::Phylo 0.45+ - change this to BioPerl
#DBI
#DBD::mysql
#Log::Log4perl
#Parallel::ForkManager
#Statistics::Descriptive
#Statistics::R
#Time::HiRes
#Set::IntSpan::Fast
#Set::IntSpan::Fast::XS
#Text::CSV
#Text::CSV_XS
#Text::FormatTable
#Tie::IxHash

=head1 NAME

GCAT - Genome Comparison and Analysis Toolkit!

=head1 VERSION

Version 0.69

=cut

our $VERSION = '0.81';

=head1 SYNOPSIS

An adaptable and efficient toolkit for large-scale evolutionary comparative genomics analysis.
Written in the Perl programming language, GCAT utilizes the BioPerl, Perl EnsEMBL and R Statistics
APIs.

=cut

=head1 AUTHOR

"Steve Moss", C<< <"gawbul at gmail.com"> >>

=head1 BUGS

Please report any bugs or feature requests to C<gawbul at gmail.com>, or through
the web interface at L<https://bitbucket.org/gawbul/gcat/issues?status=new&status=open>.
I will be notified, and then you'll automatically be notified of progress on your bug as 
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GCAT

You can also look for information at:

L<https://bitbucket.org/gawbul/gcat/wiki>

=head1 ACKNOWLEDGEMENTS

Thanks to Dr Dave Lunt, Dr Domino Joyce, Dr Stuart Humphries and Dr Chris Venditti

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2012 "Steve Moss".

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

# get version number
sub version {
	return $VERSION;
}

# lets check the version numbers
sub check_Version_Numbers {
	# check BioPerl version
	my $bioperl_version = Bio::Root::Version->VERSION;
	if ($bioperl_version < 1.006901) {
		die("Version >= 1.006901 (1.6.9) of the BioPerl API is required. You have version $bioperl_version.\n");
	}
	
	# check EnsEMBL API version
	my $ensembl_version = Bio::EnsEMBL::Registry->software_version();
	if ($ensembl_version < 65) {
		# changed this so it doesn't die, but instead warns - this way users can use earlier versions of the api
		warn("Version >= 65 of the Perl EnsEMBL API was used to test this toolkit. You have version $ensembl_version.\n");
	}
	
	# check other package versions
	##
	## ** ToDo **
	##
}

1; # End of GCAT
