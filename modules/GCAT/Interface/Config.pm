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

GCAT - GCAT Configuration File Parser

=cut

=head1 SYNOPSIS

    Config.pm

=cut

=head1 DESCRIPTION

	A module that parses the gcat.conf file for particular settings.

=cut

package GCAT::Interface::Config;

# make life easier
use warnings;
use strict;

# use other modules
use GCAT::Interface::Logging qw(logger);
use Cwd;
use File::Spec;

# set a config file value
sub set_conf_val {
	# get input from user
	my ($key, $value) = @_;
	
	# set path
	my $dir = getcwd();
	my $conffile = File::Spec->catfile($dir, "gcat.conf");
	
	# get conf hash
	my $hashref = &load_conf_file;
	my %hash = %$hashref;
	
	# set the hash value for the key - allows user to set their own values for their scripts
	$hash{$key} = $value;

	# open file and write out structure
	open CONFFILE, ">$conffile" or die $!;
    while(my ($k, $v) = each %hash) {
        print CONFFILE "$k=$v\n";
    }
	close(CONFFILE);

	logger("Set $key to $value","Info");
}


# load the config file
sub load_conf_file {
	# set path
	my $dir = getcwd();
	my $conffile = File::Spec->catfile($dir, "gcat.conf");
	
	# setup hash
	my %conf_hash = ();
		
	# check config file exists
	unless (-e $conffile) {
		# create config file
		open CONFFILE, ">$conffile" or die $!;
		print CONFFILE "database=ensembl\n";
		close(CONFFILE);
	}

	# open file and read in values
	open CONFFILE, "<$conffile" or warn $!;
	while (<CONFFILE>) {
		my $line = $_;
		chomp($line);
		
		# split on =
		my @parts = split(/=/, $line);
		
		# build hash
		if (scalar(@parts) == 2) {
			$conf_hash{$parts[0]} = $parts[1];
		}
		else {
			# perhaps empty line?
			# or malformed entry?
			# ignore for now
		}		
	}
	close(CONFFILE);

	# return reference to the hash
	return \%conf_hash;
}

# return a config file value
sub get_conf_val {
	# get input from user
	my $key = shift(@_);
	
	# get conf hash
	my $hashref = &load_conf_file;
	my %hash = %$hashref;
	
	# return reference to the value
	if (defined $hash{$key}) {
		return $hash{$key}
	}
	else {
		return undef;
	} 
}

# diplay all configuration options
sub display_conf_vals {
	# get all the values
	my $gethash = &load_conf_file;
	
    while(my ($k, $v) = each %$gethash) {
        print "$k\t\t\t$v\n";
    }
}

# diplay all configuration options
sub set_default_conf {
	# set file path
	my $dir = getcwd();
	my $conffile = File::Spec->catfile($dir, "gcat.conf");

	# open file and write out structure
	open CONFFILE, ">$conffile" or die $!;
	print CONFFILE "database=ensembl\n";
	close(CONFFILE);
}

# check config file exists
sub check_config_exists {
	# set file path
	my $dir = getcwd();
	my $conffile = File::Spec->catfile($dir, "gcat.conf");
	
	if (!-e $conffile) {
		logger("Configuration file missing, creating with default values.", "Debug")
		&set_default_conf;
	}
}

1;
