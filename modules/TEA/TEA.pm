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

package TEA::TEA;

use warnings;
use strict;

# lets try and load some of the require modules first
use Bio::EnsEMBL::Registry;
use Bio::SeqIO;

=head1 NAME

tea - The great new tea!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use tea;

    my $foo = tea->new();
    ...

=cut

=head1 AUTHOR

"Steve Moss", C<< <"gawbul at gmail.com"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tea at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=tea>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc tea

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=tea>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/tea>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/tea>

=item * Search CPAN

L<http://search.cpan.org/dist/tea/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 "Steve Moss".

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

sub check_Version_Numbers {
	# lets check the version numbers
	
	# first check EnsEMBL
	my $ensembl_version = Bio::EnsEMBL::Registry->software_version();
	if ($ensembl_version < 60) {
		die("Version >= 60 of the Perl EnsEMBL API is required. You have version $ensembl_version.\n");
	}
	
	# now check BioPerl
	my $bioperl_version = Bio::SeqIO->VERSION;
	if ($bioperl_version < 1.006001) {
		die("Version >= 1.006001 (1.6.1) of the BioPerl API is required. You have version $bioperl_version.\n");
	}
}

1; # End of tea
