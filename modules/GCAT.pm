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

use warnings;
use strict;

# lets try and load some of the require modules first
use Bio::EnsEMBL::Registry;
use Bio::SeqIO;

=head1 NAME

GCAT - Genome Comparison and Analysis Toolkit!

=head1 VERSION

Version 0.69

=cut

our $VERSION = '0.69';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use GCAT;

    my $foo = GCAT->new();
    ...

=cut

=head1 AUTHOR

"Steve Moss", C<< <"gawbul at gmail.com"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-GCAT at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=GCAT>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GCAT

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=GCAT>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/GCAT>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/GCAT>

=item * Search CPAN

L<http://search.cpan.org/dist/GCAT/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2011 "Steve Moss".

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
	my $bioperl_version = Bio::SeqIO->VERSION;
	if ($bioperl_version < 1.006001) {
		die("Version >= 1.006001 (1.6.1) of the BioPerl API is required. You have version $bioperl_version.\n");
	}
	
	# check EnsEMBL API version
	my $ensembl_version = Bio::EnsEMBL::Registry->software_version();
	if ($ensembl_version < 64) {
		die("Version >= 64 of the Perl EnsEMBL API is required. You have version $ensembl_version.\n");
	}
}

1; # End of GCAT