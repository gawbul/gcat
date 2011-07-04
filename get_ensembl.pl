#!/usr/bin/env perl

# A script to retrieve the current_mysql data for the latest ensembl release and push it to a local MySQL database
# Coded by Steve Moss
# gawbul@gmail.com
# 7th February 2011

# ToDo
#

###########################################################################
# * YOU NEED AT LEAST 2TB OF FREE SPACE FOR A SINGLE RELEASE OF ENSEMBL * #
###########################################################################

# make life easier
use warnings;
use strict;

# imports needed
use Net::FTP;
use Cwd;
use DBI;
use DBD::mysql;
use File::Spec;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use Time::HiRes qw(gettimeofday);

##############################################
# Variables here - change values as required #
##############################################

# variables for FTP connection
my $host = "ftp.ensembl.org";
my $username = "anonymous";
my $password = undef;
my $ftpdir = "/pub/current_mysql";

# variables for MySQL connection
my $sql_host = "localhost";
my $sql_port = 3306;
my $sql_username = "root";
# ask for MySQL server password instead of storing in plain text
print "What is your MySQL password (press enter for none)?: ";
my $sql_password = <STDIN>;
chop($sql_password);

# other variables
my $data_dir = "/Volumes/DATA/current_mysql"; ####### CHANGE THIS TO THE DIRECTORY YOU WANT TO STORE YOUR FILES IN #######

my $start_time = gettimeofday;

########################
# FTP stuff below here #
########################

# connect to ensembl ftp server
my $ftp = Net::FTP->new($host, KeepAlive=>1) or die "Error connecting to $host: $!";
 
# ftp login
$ftp->login($username, $password) or die "Login failed: $!";
 
# chdir to $ftpdir
$ftp->cwd($ftpdir) or die "Can't go to $ftpdir: $!";

# get list of ftp directories
my @dirs = $ftp->ls();
my %ftp_files = ();

# traverse the directories and just match core
foreach my $dir (@dirs) {
	# check if we have a core directory
	# this limits the downloaded data to the core databases
	# there is nothing stopping you removing this regex and downloading all the MySQL databases from EnsEMBL
	# obviously this depends on both the amount of time and space you have available
	#if ($dir =~ /[a-z]+_[a-z]+_core_[0-9]{2}_[0-9[a-z]{0,}/ || $dir =~ /ensembl_[a-z]+_[0-9]{2}/) { ####### CHANGE THIS REGEX IF YOU ONLY WANT SPECIFIC DATABASE #######
		# chdir to $dir
		my $newdir = $ftpdir . "/" . $dir;
		$ftp->cwd($newdir) or die "Can't go to $newdir: $!";

		print "Retrieving FTP directory structure for $dir...\n";

		# get file list
		my @files = $ftp->ls();
		
		# add array to hash
		$ftp_files{$dir} = \@files;
		
		# return to FTP root
		$ftp->cwd() or die "Can't go to FTP root: $!";
	#}	
}
print "Done!\n\n";

#-- close ftp connection
$ftp->quit or die "Error closing ftp connection: $!";

########################
# File retrieval stuff #
########################

# get directory list
@dirs = keys %ftp_files;
@dirs = sort {$a cmp $b} @dirs;

foreach my $dir (@dirs) {
	# build local directory structure
	unless (-d $data_dir) {
		mkdir $data_dir;
	}
	my $path = File::Spec->catfile($data_dir, $dir);
	unless (-d $path) {
		mkdir $path;
	}

	print "Retrieving files for $dir...\n";	

	my $files_ref = $ftp_files{$dir};
	my @files = @$files_ref;

	foreach my $file (@files) {
		unless (-e substr($file, 0, -3)) {
			# change to correct directory
			chdir $path;
			
			# retrieve the file
			system("wget -t 0 -c -N ftp://$host$ftpdir/$dir/$file");
		}
	}
}			
print "Done!\n\n";

##########################
# Extract the data files #
##########################

# change to data dir
chdir $data_dir;

# get directory listing
opendir(my $dh, $data_dir) or die "Can't opendir $data_dir: $!";
@dirs = grep {!/^\./ && -d "$data_dir/$_" } readdir($dh);
closedir $dh;

# sort directories
@dirs = sort {$a cmp $b} @dirs;

# traverse directories
foreach my $dir (@dirs) {
	# change into each directory in turn
	chdir "$data_dir/$dir";
	
	print "Extracting data for $dir (please be patient)...\n";

	# get list of files
	opendir($dh, "$data_dir/$dir") or die "Can't opendir $data_dir/$dir: $!";
	my @files = grep {!/^\./ && -f "$data_dir/$dir/$_" } readdir($dh);
	closedir $dh;
	@files = sort {$a cmp $b} @files;

	# populate tables in turn
	foreach my $file (@files) {
		if ($file =~ /\.gz$/) {
			my $input = $file;
			my $output = substr($file, 0, -3);
			my $status = 1;
			while (!(-e "$data_dir/$dir/$output")) {
				gunzip $input => $output or $status = 0;
				
				# if error in unzip then retrieve file again
				if ($status == 0) {
					# delete output file
					unlink $output;
					
					# get file again
					system("wget -t 2 -c -N ftp://$host/$ftpdir/$dir/$input");
					
					# update status
					$status = 1;
				}
			}
			unlink $input;
		}
	}
}
print "Done!\n\n";
chdir getcwd();

##########################
# MySQL stuff below here #
##########################

# change to data dir
chdir $data_dir;

# get directory listing
opendir($dh, $data_dir) or die "Can't opendir $data_dir: $!";
@dirs = grep {!/^\./ && -d "$data_dir/$_" } readdir($dh);
closedir $dh;

# sort directories
@dirs = sort {$a cmp $b} @dirs;

# traverse directories
foreach my $dir (@dirs) {
	# change into each directory in turn
	chdir "$data_dir/$dir";
	
	# create the database based on the dir name
	print "Creating database for $dir...\n";
	# setup database connection
	my $dsn = "DBI:mysql::$sql_host:$sql_port";
	my $dbh = DBI->connect($dsn, $sql_username, $sql_password) or die "Unable to connect: $DBI::errstr\n";
	$dbh->do("DROP DATABASE IF EXISTS $dir");
	$dbh->do("CREATE DATABASE IF NOT EXISTS $dir");
	$dbh->disconnect();
	
	# populate database with tables from .sql file
	print "Building database structure for $dir...\n";
	my $sql_file = File::Spec->catfile($data_dir, $dir, $dir . ".sql");
	system("mysql -h $sql_host -P $sql_port -u $sql_username --password=$sql_password $dir \< $sql_file");
			
	# get list of files
	opendir(my $dh, "$data_dir/$dir") or die "Can't opendir $data_dir/$dir: $!";
	my @files = grep {!/^\./ && -f "$data_dir/$dir/$_" } readdir($dh);
	closedir $dh;
	@files = sort {$a cmp $b} @files;
	
	# populate tables in turn
	foreach my $file (@files) {
		if ($file =~ /.*?\.txt$/) {
			# get variables
			my $sql_file = File::Spec->catfile($data_dir, $dir, $file);
			my $table = substr($file, 0, -4);
			
			# build query and execute
			print "Loading data in $sql_file into $dir...\n";
			system("mysqlimport -h $sql_host -P $sql_port -u $sql_username --password=$sql_password $dir $sql_file");
			#unlink $sql_file;
		}
	}
	
}
print "Done!\n\n";
chdir getcwd();

my $end_time = gettimeofday;
my $total_time = $end_time - $start_time;

print "Finished in $total_time seconds!\n";
