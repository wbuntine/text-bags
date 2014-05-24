package links::File;

$links::URLs::VERSION = '0.52';

###################### CONFIGURATION #####################


############ END CONFIGURATION ######################

use Digest::MD5 qw(md5_hex);
use strict;
use POSIX;
use Encode;

# encoding pragmas follow any includes like "use"
use open ':utf8';

#  switches
$links::File::tagged = 0;
$links::File::breakdash = 0;
$links::File::nolcase = 0;
$links::File::stemming = 0;
$links::File::titletext = 0;
$links::File::linktext = 0;
$links::File::collsize = 1;
$links::File::collrepeatwords = 0;
$links::File::colllastnotstop = 0;
$links::File::collnotstop = 0;
$links::FILE::buildtext = 0;
$links::File::nostops = 0;   #  ignore stops when tokenising
$links::File::collsep = "XUQX";
$links::File::stemmer = undef;
$links::File::verbose = 0;
%links::File::stops = ();
$links::File::srcpar = "";
#    if defined, a regexp for tokens
$links::File::wordmatch = "";

$links::File::keeptabled = 0;  # set this to save text processed by tabletext()
$links::File::tabled = "";      # kept here

sub loadpar() {
    my $par = $_[0];
    open(PAR,"grep '^$par=' $links::File::srcpar |");
    $par = <PAR>;
    if ( defined($par) ) {
        chomp($par);
        $par =~ s/^[^=]+=//;
    }
    close(PAR);
    return $par;
}

sub loadstemmer() {
    $links::File::stemmer = Lingua::Stem->new(-locale => 'EN');
    $links::File::stemmer->stem_caching({ -level => 2 });
    if ( $links::File::verbose ) {
	print STDERR "Stemming  for 'EN' loaded\n";
    }
}

sub loadstops() {
    my $stopfile = $_[0];
    open(S,"<$stopfile") or 
	die "Cannot open '$stopfile': $?\n";
    while ( ($_=<S>) ) {
	chomp();
	$links::File::stops{lc($_)} = 1;
    }
    close(S);
    if ( $links::File::verbose ) {
	print STDERR "Stopwords from '$stopfile' loaded\n";
    }
}

#  grab pars transferred from linkTables
sub loadpars() {
    my $stem = $_[0];
    $links::File::srcpar = "$stem.srcpar";
    if ( ! -f $links::File::srcpar ) {
	die "Cannot open config file '$links::File::srcpar'\n";
    }
    my $cs = &loadpar("collsize");
    if ( defined($cs) ) {
	$links::File::collsize = int($cs);
    }
    my $doccount = &loadpar("documents");
    if ( defined($doccount) ) {
	$doccount = int($doccount);
    }
    if ( defined(&loadpar("breakdash")) ) {
	$links::File::breakdash = 1;
    }
    if ( defined(&loadpar("nolcase")) ) {
	$links::File::nolcase = 1;
    }
    if ( defined(&loadpar("stemming")) ) {
	$links::File::stemming = 1;
	&loadstemmer();
    }
    if ( defined(&loadpar("stopfile")) ) {
	&loadstops("$stem.stops");
    }
    if ( defined(&loadpar("titletext")) ) {
	$links::File::titletext = 1;
    }
    if ( defined(&loadpar("tagged")) ) {
	$links::File::tagged = 1;
    }
    if ( defined(&loadpar("linktext")) ) {
	$links::File::linktext = 1;
    }
    if ( defined(&loadpar("nocaseurl")) ) {
	$links::URLs::nocaseurl = 1;
    }
    if ( defined(&loadpar("nocleanurl")) ) {
	$links::URLs::nocleanurl = 1;
    }
    if ( defined(&loadpar("keepfragurl")) ) {
	$links::URLs::keepfragurl = 1;
    }
    my $wm = &loadpar("wordmatch");
    if ( defined($wm) ) {
	$links::File::wordmatch = $wm;
    }
    return $doccount;
}

sub openzip() {
    my ($FH,$file,$name) = @_;
    if ( $file =~ /.bz2$/ ) {
	open($FH,"bzcat $file |") or 
	    die "Cannot bzcat open input $name file '$file': $!";
    } elsif ( $file =~ /.gz$/ ) {
	open($FH,"zcat $file |") or 
	    die "Cannot bzcat open input $name file '$file': $!";
    } else {
	open($FH,"<$file") or die "Cannot open input $name file '$file': $!";
    }
    binmode $FH, ':utf8';
}

#    handle contrctions and possessives
#    removes quotes and other punctuation
#    
#
my $singlequotes = "\N{U+0027}\N{U+0060}\N{U+00B4}\N{U+2018}\N{U+2019}";
my $quotes = "\N{U+0022}\N{U+0027}\N{U+0060}\N{U+00B4}\N{U+2018}\N{U+2019}\N{U+201C}\N{U+201D}";
sub cleanpunct() {
    my $xml = " $_[0] ";
    # print STDERR "CLEAN-0: $xml\n";
    if ( $links::File::nolcase == 0 ) {
	$xml = lc($xml);
    }
    if ( $links::File::breakdash != 0 ) {
	$xml =~ s/\p{Dash_Punctuation}//g;
    }
    #  remove punctuation before space
    $xml =~ s/\p{IsPunct}+\s+/ /g;
    if ( $links::File::tagged ) {
	#  treat "XXX#c" as you would "XXX"
	$xml =~ s/\s\p{IsPunct}+\#\p{IsAlpha}\s+/ /g;
	$xml =~ s/\p{IsPunct}+(\#\p{IsAlpha})\s+/$1 /g;
    }
    #  split on ".." or "..."
    $xml =~ s/\.\.+/ /g;
    #  remove opening brackets or quotes
    $xml =~ s/\s\p{IsPunct}+(\p{IsAlnum})/ $1/g;
    #  deal with contractions
    $xml =~ s/([^\p{IsAlpha}]w)on[$singlequotes]t([^\p{IsAlpha}])/$1ill n"t$2/ig;
    $xml =~ s/([^\p{IsAlpha}]sha)n[$singlequotes]t([^\p{IsAlpha}])/$1ll n"t$2/ig;
    $xml =~ s/([^\p{IsAlpha}]can)[$singlequotes]t([^\p{IsAlpha}])/$1 n"t$2/ig;
    $xml =~ s/(\p{IsAlpha})n[$singlequotes]t([^\p{IsAlpha}])/$1 n"t$2/g;
    #  break before 's, 're, 'll, etc
    $xml =~ s/(\p{IsAlnum})[$singlequotes](\p{IsAlpha}{1,2})/$1 '$2/g;
    $xml =~ s/ n"t([^\p{IsAlpha}])/ n't$1/g;
    #  break at spaces
    $xml =~ s/\s+/ /g; 
    $xml =~ s/^\s//; 
    $xml =~ s/\s$//; 
    # print STDERR "CLEAN-1: $xml\n";
    return $xml;
}

#  remove stop words and optionally stem
#  stemmer can produce empty tokens, so watch it
sub tokenise() {
    my $text = $_[0];
    if ( $links::File::stemming ) {
	if ( $links::File::nostops ) {
	    return $links::File::stemmer->stem(split(/\s+/,$text));
	} 
	return $links::File::stemmer->stem(
	    grep(!defined($links::File::stops{lc($_)}), 
		 split(/\s+/,$text)));
    } else {
	my @sp;
	if ( $links::File::nostops ) {
	    @sp = split(/\s+/,$text);
	} else {
	    @sp = grep(!defined($links::File::stops{lc($_)}), split(/\s+/,$text));
	    # print STDERR "Tokenise: #" . join("#",@sp) . "#\n";
	}
	return \@sp;
    }
}

#  call the table(,) routine on the processed text, applying
#  cleanpunct(), tokenise() and optionally assembly of collections
sub tabletext() {
    my $text = "";
    my $table = $_[0];
    my $multicnt = 0;
    my $tw = &links::File::cleanpunct($_[1]);
    #  lower case by default, no stops
    if ( $links::File::collsize>1 ) {
	#  have to include stop words
	my $multi = 0;
	$links::File::nostops = 1;
	my $a = &links::File::tokenise($tw);
	#print STDERR "Checking $#$a words, $a->[0] $a->[1] ...\n";
	for (my $i=0; $i<=$#$a; $i++) {
	    if ( $a->[$i] eq "" ) {
		next;
	    }
	    if ( $links::FILE::buildtext==1 ) {
		$text .= " " . $a->[$i];
	    }
	    $multi = 0;
	    my $smax = $links::File::collsize;
	    if ( $i>$#$a - $links::File::collsize+1 ) {
		$smax = $#$a + 1 - $i;
	    }
	    #print STDERR "$a->[$i] by $smax\n";
	    if ( defined($links::File::stops{lc($a->[$i])}) ) {
		&$table("stop", $a->[$i]);
		#  this to prevent entering coll. with 100% stops
		#  or just 2 words, the first being a stop
		if ( $smax>2 ) {
		    my $allstops = defined($links::File::stops{lc($a->[$i+1])});
		    for (my $s=2; $s<$smax; $s++) {
			if ( $allstops && !defined($links::File::stops{lc($a->[$i+$s])}) ) {
			    $allstops = 0;
			}
			if ( $allstops==0 ) {
			    my $k = join($links::File::collsep,@$a[$i..$i+$s]);
			    if ( !$links::File::colllastnotstop ||
				 !defined($links::File::stops{lc($a->[$i+$s])}) )
			    {
				if ( &$table("coll", $k) == 1 ) {
				    $multi++;
				} 
			    }
			} 
		    }
		}
	    } else {
		if ( $links::File::wordmatch eq ""
		     ||  $a->[$i] =~ /$links::File::wordmatch/ ) {
		    print STDERR "$a->[$i] ## $links::File::wordmatch\n";
		    &$table("text", $a->[$i]);
		    for (my $s=1; $s<$smax; $s++) {
			my $k = join($links::File::collsep,@$a[$i..$i+$s]);
			if ( !$links::File::colllastnotstop ||
			     !defined($links::File::stops{lc($a->[$i+$s])}) )
			{
			    if ( &$table("coll", $k) == 1 ) {
				$multi++;
			    }
			}
		    }
		}
	    }
	    &$table("endword", "");
	    # print STDERR "Did $a->[$i] with $multi\n";
	    if ( ($links::FILE::buildtext==1) && ($multi==0) ) {
		$text .= "\n";
		$multicnt ++;
		# print STDERR "CR after $a->[$i]\n";
	    }
	}
	&$table("endword", "");
    } else {
	my $sp = &links::File::tokenise($tw);
	foreach my $k ( @$sp ) {
	    if ( $k ne ""  && ( $links::File::wordmatch eq ""
				||  $k =~ /$links::File::wordmatch/ )) {
		&$table("text", $k);
	    }	
	}
    }	    
    if ( $links::FILE::buildtext==1 ) {
	# print STDERR "tabletext dump m=$multicnt: $text\n";
	return $text;
    } 
    return "";
}

1;

__END__

=head1 NAME

links::File - Link file handling utilities

=head1 SYNOPSIS

 $links::File::tagged = 0;    # set when input tokens tagged with "#c"
 $links::File::breakdash = 0; #  usually hyphenated words separated, joins instead
 $links::File::nolcase = 0;   #  switch off default (all text made lower case) 
 $links::File::stemming = 0;  #  set when stemming in use
 $links::File::titletext = 0; #  add title text to general text
 $links::File::linktext = 0;  #  add link text to general text
 $links::File::collsize = 1;  #  set >1 when when n-grams or collocations
 $links::File::stemmer;       #  this is the loaded stemmer
 $links::File::verbose = 0;   #  verbosity level
 %links::File::stops = ();    #  stop words loaded here

 $textline = &links::File::cleanpunct($textline);
 @words =  &links::File::tokenise($textline);

 &links::File::openzip(\*IN,$file,"linkdata");

=head1 DESCRIPTION

Common link file handling utilities.

=head1 METHODS

=head2 cleanpunct()

 $textline = &links::File::cleanpunct($textline);

Clean text for tokenisation.  Handles contractions and possessives, removes quotes and other punctuation.  Considers flags
.I<breakdash>,
.I<nolcase>, and
.I<tagged>.

=head2 loadpars()

  &links::File::loadpars($stem);

The file name is constructed from "$stem.srcpar".
Load configuration parameters listed above previously stored by 
.I<linkTables>(1), and load the stemmer if 
.I<stemming> flag is set, and load the (copied) stopfile if one was used.  
Verbosity is not set.

=head2 loadstemmer()

  &links::File::loadstemmer();

Load EN stemmer.

=head2 loadstops()

  &links::File::loadstops($stopfile);

Load stops from file.

=head2 openzip()

 &links::File::openzip($filehandle,$file,$name);

Try opening with a I<bzcat> or I<zcat>. Rather inefficient since does a 
open with piping, whereas should use proper libraries.

=head2 tokensize()

  $arraypntr = &links::File::tokenise($textline);

Tokenise text by splitting on space, removing stopwords and optionally stemming.

=head1 AUTHOR

Wray Buntine, E<lt>wray.buntine@nicta.com.auE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Wray Buntine

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
