#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'tea' ) || print "Bail out!
";
}

diag( "Testing tea $tea::VERSION, Perl $], $^X" );
