all:  textbagsguide.pdf


MAN1FILES=linkBags.pdf  linkMatch.pdf  linkRedir.pdf  linkTables.pdf  linkTokens.pdf \
 linkCoco.pdf  linkParse.pdf  linkSent.pdf   linkText.pdf    wex2link.pdf

MAN3FILES=links\:\:File.pdf  links\:\:URLs.pdf
	
#  run twice for TOC
textbagsguide.pdf: textbagsguide.tex $(MAN1FILES)  $(MAN3FILES)
	pdflatex textbagsguide
	pdflatex textbagsguide

%.pdf:  ../blib/man1/%.1p
	man -l -Tpdf $< > $@

%.pdf:  ../blib/man3/%.3pm
	man -l -Tpdf $< > $@

clean:
	rm -f link*.pdf wex2link.pdf textbagsguide.log textbagsguide.aux textbagsguide.out textbagsguide.toc

distclean:  clean
	rm -f textbagsguide.pdf *~
