# This is a helper script to ensure your R environment is setup for GCAT
# Coded by Steve Moss
# gawbul@gmail.com
# http://stevemoss.ath.cx/

# make life easier
use warnings;
use strict;

# import modules
use Statistics::R;

# setup new R object
my $R = Statistics::R->new();

# start R session
$R->startR;

# define is.installed function
$R->send("is.installed <- function(mypkg) is.element(mypkg, installed.packages()[,1])");

# check if gdata is installed
$R->send("is.installed(\'gdata\')");
my $ret = $R->read();
if ($ret eq "[1] TRUE") {
	$R->send("library(gdata)");
}
elsif ($ret eq "[1] FALSE") {
#	$R->send("Sys.setenv(http_proxy=\'http://slb-webcache.hull.ac.uk:3128\')"); # you should change this to your proxy server details if working behind a proxy
	$R->send("options(repos=structure(c(CRAN=\'http://star-www.st-andrews.ac.uk/cran/\')))"); # you should change this to your preferred mirror
	$R->send("install.packages(\'gdata\', dependencies=T)");
	$R->send("library(gdata)");
}
else {
	print "An unknown error occurred while testing if a package exists!\n";
}

# end R session
$R->stopR;
