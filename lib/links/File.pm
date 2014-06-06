package links::File;

###################### CONFIGURATION #####################


############ END CONFIGURATION ######################

use Digest::MD5 qw(md5_hex);
use strict;
use POSIX;
use Encode;

# encoding pragmas follow any includes like "use"
use open ':utf8';

$links::File::srcpar = "";
#  switches
$links::File::stemming = 0;
$links::File::stemmer = undef;
$links::File::verbose = 0;
%links::File::stops = ();


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
	$links::Text::collsize = int($cs);
    }
    my $doccount = &loadpar("documents");
    if ( defined($doccount) ) {
	$doccount = int($doccount);
    }
    if ( defined(&loadpar("breakdash")) ) {
	$links::Text::breakdash = 1;
    }
    if ( defined(&loadpar("nolcase")) ) {
	$links::Text::nolcase = 1;
    }
    if ( defined(&loadpar("stemming")) ) {
	$links::File::stemming = 1;
	&loadstemmer();
    }
    if ( defined(&loadpar("stopfile")) ) {
	&loadstops("$stem.stops");
    }
    if ( defined(&loadpar("titletext")) ) {
	$links::Text::titletext = 1;
    }
    if ( defined(&loadpar("tagged")) ) {
	$links::Text::tagged = 1;
    }
    if ( defined(&loadpar("linktext")) ) {
	$links::Text::linktext = 1;
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
	$links::Text::wordmatch = $wm;
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

1;

__END__

=head1 NAME

links::File - Link file handling utilities

=head1 SYNOPSIS

 $links::File::verbose = 0;   #  verbosity level
 %links::File::stops = ();    #  stop words loaded here

 &links::File::openzip(\*IN,$file,"linkdata");

=head1 DESCRIPTION

Common link file handling utilities.

=head1 METHODS

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

=head1 AUTHOR

Wray Buntine, E<lt>wray.buntine@monash.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2014 by Wray Buntine

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
