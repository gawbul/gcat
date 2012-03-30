# This is a helper script to ensure your R environment is setup for GCAT
# Coded by Steve Moss
# gawbul@gmail.com
# http://stevemoss.ath.cx/

# make life easier
use warnings;
use strict;

# import modules
use Statistics::R;

# setup variables
my @pkg_list = ("ape", "geiger", "gdata");
my $mirror = "http://star-www.st-andrews.ac.uk/cran/";

# setup new R object
my $R = Statistics::R->new();

# start R session
$R->startR;

# define is.installed function
$R->send("is.installed <- function(mypkg) is.element(mypkg, installed.packages()[,1])");

# let user know what we're doing
print "Checking packages (@pkg_list) are installed...\n";

# check if packages are installed
foreach my $pkg (@pkg_list) {
	$R->send("is.installed(\"" . $pkg . "\")");
	my $ret = $R->read();
	if ($ret eq "[1] TRUE") {
		$R->send("library(" . $pkg . ")");
	}
	elsif ($ret eq "[1] FALSE") {
	#	$R->send("Sys.setenv(http_proxy=\'http://slb-webcache.hull.ac.uk:3128\')"); # change this to your proxy server details and uncomment if using a proxy
		$R->send("options(repos=structure(c(CRAN=\"" . $mirror . "\")))"); # change this to your preferred mirror
		$R->send("install.packages(\"" . $pkg . "\", dependencies=T)");
		$R->send("library(" . $pkg . ")");
	}
	else {
		logger("An unknown error occurred while testing if \"$pkg\" exists!\n", "Error");
		exit;
	}
}

# end R session
$R->stopR;

# let user know we're done
print "Finished!\n";