# -*- perl -*-

#  do query processing test

use Test::More tests => 4;
use Config;

system("mkdir -p t/wex");

if ( system("gunzip -c t/wex.gz | blib/script/wex2link > t/wex/d.links") ) {
	ok(0, "wex2link failed");
	exit(1);
} else {
	ok(1 , "wex2link ran");
}

if ( system("blib/script/linkSent < t/wex/d.links > t/wex/ds.links") ) {
	ok(0, "linkSent failed");
	exit(1);
} else {
	ok(1 , "linkSent ran");
}


if ( system("blib/script/linkTables --titletext --linktext t/wex/ds.links t/wex/d") ) {
	ok(0, "linkTables failed");
	exit(1);
} else {
	ok(1 , "linkTables ran");
}

if ( system("blib/script/linkCoco t/wex/ds.links t/wex/d") ) {
        ok(0, "linkCoco failed");
        exit(1);
} else {
        ok(1 , " linkCoco ran");
}

system("rm -rf t/wex wikiline.bad");
