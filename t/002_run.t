# -*- perl -*-

#  do query processing test

use Test::More tests => 3;

system("mkdir -p t/dat");

if ( system("blib/script/linkRedir t/dat.links t/dat/d > t/dat/d.relinks")  ) {
	ok(0, "linkRedir failed");
} else {
	ok(1 , " linkRedir ran");
}

if ( system("blib/script/linkTables --titletext --dictsize 500 t/dat/d.relinks t/dat/d") ) {
	ok(0, "linkTables failed");
	exit(1);
} else {
	ok(1 , " linkTables ran");
}

if ( system("blib/script/linkBags t/dat/d.relinks t/dat/d") ) {
	ok(0, "linkBags failed");
} else {
	ok( 1 , " linkBags ran");
}


system("rm -rf t/dat");
