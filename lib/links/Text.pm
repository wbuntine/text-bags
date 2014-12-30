package links::Text;

$links::Text::VERSION = '0.71';

###################### CONFIGURATION #####################


############ END CONFIGURATION ######################

use Digest::MD5 qw(md5_hex);
use strict;
use POSIX;
use Encode;

# encoding pragmas follow any includes like "use"
use open ':utf8';

#  switches
$links::Text::tagged = 0;
$links::Text::breakdash = 0;
$links::Text::nolcase = 0;
$links::Text::titletext = 0;
$links::Text::linktext = 0;
$links::Text::collsize = 1;
$links::Text::collrepeatwords = 0;
$links::Text::colllastnotstop = 0;
$links::Text::collnotstop = 0;
$links::Text::buildtext = 0;
$links::Text::nostops = 0;   #  ignore stops when tokenising
$links::Text::collsep = "XUQX";
#    if defined, a regexp for tokens
$links::Text::wordmatch = "";

$links::Text::keeptabled = 0;  # set this to save text processed by tabletext()
$links::Text::tabled = "";      # kept here


#    handle contrctions and possessives
#    removes quotes and other punctuation
#    
#
my $singlequotes = "\N{U+0027}\N{U+0060}\N{U+00B4}\N{U+2018}\N{U+2019}";
my $quotes = "\N{U+0022}\N{U+0027}\N{U+0060}\N{U+00B4}\N{U+2018}\N{U+2019}\N{U+201C}\N{U+201D}";
sub cleanpunct() {
    my $xml = " $_[0] ";
    # print STDERR "CLEAN-0: $xml\n";
    if ( $links::Text::nolcase == 0 ) {
	$xml = lc($xml);
    }
    if ( $links::Text::breakdash != 0 ) {
	$xml =~ s/\p{Dash_Punctuation}//g;
    }
    #  remove punctuation before space
    $xml =~ s/\p{IsPunct}+\s+/ /g;
    if ( $links::Text::tagged ) {
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
	if ( $links::Text::nostops ) {
	    return $links::File::stemmer->stem(split(/\s+/,$text));
	} 
	return $links::File::stemmer->stem(
	    grep(!defined($links::Text::stops{lc($_)}), 
		 split(/\s+/,$text)));
    } else {  
	my @sp;
	if ( $links::Text::nostops ) {
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
    my $tw = &links::Text::cleanpunct($_[1]);
    #  lower case by default, no stops
    if ( $links::Text::collsize>1 ) {
	#  have to include stop words
	my $multi = 0;
	$links::Text::nostops = 1;
	my $a = &links::Text::tokenise($tw);
	# print STDERR "Checking $#$a words, $a->[0] $a->[1] ...\n";
	for (my $i=0; $i<=$#$a; $i++) {
	    if ( $a->[$i] eq "" ) {
		next;
	    }
	    if ( $links::Text::buildtext==1 ) {
		$text .= " " . $a->[$i];
	    }
	    $multi = 0;
	    my $smax = $links::Text::collsize;
	    if ( $i>$#$a - $links::Text::collsize+1 ) {
		$smax = $#$a + 1 - $i;
	    }
	    # print STDERR "   '$a->[$i]' by $smax\n";
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
			    my $k = join($links::Text::collsep,@$a[$i..$i+$s]);
			    if ( !$links::Text::colllastnotstop ||
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
		if ( $links::Text::wordmatch eq ""
		     ||  $a->[$i] =~ /$links::Text::wordmatch/ ) {
		    # print STDERR "Table '$a->[$i]' with smax=$smax ## $links::Text::wordmatch\n";
		    &$table("text", $a->[$i]);
		    for (my $s=1; $s<$smax; $s++) {
			my $k = join($links::Text::collsep,@$a[$i..$i+$s]);
			# print STDERR "  trying $k\n";
			if ( !$links::Text::colllastnotstop ||
			     !defined($links::File::stops{lc($a->[$i+$s])}) )
			{
			    # print STDERR "  tabling $k\n";
			    if ( &$table("coll", $k) == 1 ) {
				$multi++;
			    }
			}
		    }
		}
	    }
	    &$table("endword", "");
	    # print STDERR "Did '$a->[$i]' with multi=$multi\n";
	    if ( ($links::Text::buildtext==1) && ($multi==0) ) {
		$text .= "\n";
		$multicnt ++;
		# print STDERR "CR after $a->[$i]\n";
	    }
	}
	&$table("endword", "");
    } else {
	my $sp = &links::Text::tokenise($tw);
	foreach my $k ( @$sp ) {
	    if ( $k ne ""  && ( $links::Text::wordmatch eq ""
				||  $k =~ /$links::Text::wordmatch/ )) {
		&$table("text", $k);
	    }	
	}
    }	    
    if ( $links::Text::buildtext==1 ) {
	# print STDERR "tabletext dump m=$multicnt: $text\n";
	return $text;
    } 
    return "";
}

1;

__END__

=head1 NAME

links::Text - text handling utilities

=head1 SYNOPSIS

 $links::Text::tagged = 0;    # set when input tokens tagged with "#c"
 $links::Text::breakdash = 0; #  usually hyphenated words separated, joins instead
 $links::Text::nolcase = 0;   #  switch off default (all text made lower case) 
  $links::Text::titletext = 0; #  add title text to general text
 $links::Text::linktext = 0;  #  add link text to general text
 $links::Text::collsize = 1;  #  set >1 when when n-grams or collocations
 
 $textline = &links::Text::cleanpunct($textline);
 @words =  &links::Text::tokenise($textline);

 =head1 DESCRIPTION

Common link/text handling utilities.

=head1 METHODS

=head2 cleanpunct()

 $textline = &links::Text::cleanpunct($textline);

Clean text for tokenisation.  Handles contractions and possessives, removes quotes and other punctuation.  Considers flags
.I<breakdash>,
.I<nolcase>, and
.I<tagged>.

=head2 tokensize()

  $arraypntr = &links::Text::tokenise($textline);

Tokenise text by splitting on space, removing stopwords and optionally stemming.

=head1 AUTHOR

Wray Buntine, E<lt>wray.buntine@monash.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2014 by Wray Buntine

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
