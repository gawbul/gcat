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

GCAT - The great new GCAT!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    CLI.pm
    
=head1 DESCRIPTION

	A module that provides a command line text based input for GCAT.

=cut

package GCAT::Interface::CLI;

# make life easier
use warnings;
use strict;

# other imports
use Cwd;
use File::Basename;
use File::Spec;
use Pod::Select;
use IO::String;
use Config;
use GCAT;
use GCAT::Interface::Logging qw(logger);
use GCAT::DB::EnsEMBL;

# define global variables
our @servers = ();
our @servers_information = ();
our @commands = ();
our @commands_information = ();
our @scripts = ();
our @scripts_information = ();

# setup the CLI environment
sub setup_CLI_ENV {
	# fill the command arrays
	@servers = ("ensembldb.ensembl.org", "mysql.ebi.ac.uk");
    @servers_information = ("Default Ensembl database", "Ensembl Genomes database");
    @commands = ("banner", "help", "clear", "scripts", "license", "databases", "species", "exit", "quit");
    @commands_information = ("display the program banner", "display this help message", "clear the screen",
                            "list available scripts", "display license information", "Display a list of database the user can connect to",
                            "display list of species names", "exit the command line interface", "quit the command line interface");
	
	# get scripts and fill scripts array
	my $dir = getcwd();
	my $path = File::Spec->catfile($dir, 'modules', 'GCAT', 'Scripts');
	my @script_paths = <$path/*.pl>;
	# setup the script details
	foreach my $script_path (@script_paths) {		
		# just push filename (minus extension) to the array 
		push (@scripts, substr((basename $script_path), 0, -3));
		# pull the DESCRIPTION information from the POD and push only the string to the information array
		my $output;
		tie *STDOUT, 'IO::String', \$output;
		podselect({-output => ">&STDOUT", -sections => ["DESCRIPTION"]}, $script_path);
		untie *STDOUT;
		foreach my $out ($output) {
			if ($out) {
				$out =~ s/^=head1 DESCRIPTION\s+//;
				$out =~ s/\s+$//;
			}
			else {
				$out = "No description found.";
			}
			push (@scripts_information, $out)
		}
	}
}

# display input prompt and get user input
sub get_User_Input {
	my $prompt = $_[0];
	print "$prompt ";
	my $input = <STDIN>;
	chomp($input);
	return $input;
}

# display the CLI usage
sub help {
	foreach my $i (0 .. scalar(@commands) - 1) {
		printf("%-15s%s\n", $commands[$i], $commands_information[$i]);
	}
}

# clear the CLI screen
sub clear {
	# check for OS first and either clear or cls
	if ($^O =~ /MSWin32/) {
		system("cls");
	}
	else {
		system("clear");
	}
}

# list databases
sub databases {
	foreach my $i (0 .. scalar(@servers) - 1) {
		printf("%-30s%s\n", $servers[$i], $servers_information[$i]);
	}	
}

# list species
sub species {
	# populate registry
	my $registry = connect_to_EnsEMBL;
	
	# get species list
	my @species = get_Species_List($registry);

	# display
	print "" . ($#species + 1) . " species found:\n";
	my $print_species = join(", ", @species);
	printf "$print_species.\n";
}

# list scripts
sub scripts {
	foreach my $i (0 .. scalar(@scripts) - 1) {
		printf("%-30s%s\n", $scripts[$i], $scripts_information[$i]);
	}		
}

# This displays the program banner
sub banner {
	my $ver = $VERSION;
	my $os_name = $Config{osname};
	my $os_arch = $Config{archname};
	my $os_ver = $Config{osvers};
    print "Genome Comparison and Analysis Toolkit\n";
	print "Command Line Interface version, $ver\n";
	print "Copyright (C) 2010-2011 Steve Moss\n";
	print "Platform: $os_name $os_arch ($os_ver)\n\n";
	print "GCAT is free software and comes with ABSOLUTELY NO WARRANTY.\n";
	print "You are welcome to redistribute it under certain conditions.\n";
	print "Type 'license' for distribution details.\n\n";
	print "Type 'help' for a list of commands. Type 'clear' to clear the console\n";
	print "Type 'exit' or 'quit' to quit GCAT.\n";
}

# This displays license information
sub license {
    print "This software is distributed under the terms of the GNU General\n";
	print "Public License Version 3, 29 June 2007. The terms of this license\n";
	print "are in a file called LICENSE which you should have received with\n";
	print "this software.\n\n";
	print "If you have not received a copy of this file, you can obtain one\n";
	print "at http://www.gnu.org/licenses/gpl-3.0.html.\n\n";
	print "Share, Copy, Learn, Adapt and Enjoy.\n";
}

# parse the command
sub cmd_parser {
	# fill the variables
	my $cmd = shift(@_);
	my @args = @_;
	my $args = join(" ", @args);
	
	# check if in commands
	if (grep $_ eq $cmd, @commands) {
		no strict 'refs';
		&$cmd;
	}
	# check if in scripts
	elsif (grep $_ eq $cmd, @scripts) {
		my $dir = getcwd();
		my $path = File::Spec->catfile($dir, 'modules', 'GCAT', 'Scripts', $cmd . ".pl");
		system("perl $path $args");
	}
	# report error
	else {
		&logger("You have entered an unknown command \"$cmd\".", "Debug")
	}
}

sub load_CLI {
	&setup_CLI_ENV;
	print "\n";
	&banner;
	print "\n";
    my $command = '';
    # start command loop
    while ($command ne "exit" || $command ne "quit") {
		# get user input
		$command = &get_User_Input("\>");
		chomp($command); # remove whitespace
		print "\n";
		if ($command ne "" || !defined $command) {
			if ($command =~ "^#.*?") {
				logger("You cannot enter a comment line from the command interface.", "Debug");
			}
            elsif ($command eq "exit" || $command eq "quit"){
            	last;
            }
            else {
				$command =~ s/#.*?$//; # remove any comments on same line
                my @inputs = split(/ /, $command);
                my $cmd = shift(@inputs);
                my @args = @inputs;
                my $args = join(" ", @args);
                # parse the commands
				&cmd_parser($cmd, $args);
            }
		}
		print "\n"; # always print an empty line after each input
    }
}

1;