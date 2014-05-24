use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'text-bags',
    VERSION_FROM => 'lib/links/URLs.pm', # finds \$VERSION
    AUTHOR       => 'Wray Buntine',
    ABSTRACT     => 'Simple bag/list generation and for text and link preprocessing',
    PREREQ_PM    => {HTML::Entities => 0, Encode => 0, Getopt::Long => 0,
		     Pod::Usage => 0, IO::Handle => 0, POSIX => 0,
                     URI => 0, Digest::MD5 => 0, Lingua::Stem => 0,
		     Lingua::EN::Sentence => 0, XML::Parser => 0,
		     FileHandle => 0, File::Tail => 0, IO::Pipe => 0,
                    },
    EXE_FILES    => [ 
			'bin/linkRedir',
			'bin/linkSent',
			'bin/linkCoco',
			'bin/linkText',
			'bin/linkTables',
			'bin/linkTokens',
			'bin/linkBags',
			'bin/linkParse',
			'bin/wex2link',
			'bin/linkMatch',
		],
);
