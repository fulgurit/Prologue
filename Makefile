RUBY=ruby

LATEX=platex
DVIPDF=dvipdfmx
DVIPDFOPT=-p a5

TEXT= \
	doc/ch_01.dat \
	doc/ch_02.dat \
	doc/ch_03.dat \
	doc/ch_04.dat \
	doc/ch_05.dat \
	doc/ch_06.dat \
	doc/ch_07.dat \
	doc/ch_08.dat \
	doc/ch_09.dat \
	doc/ch_10.dat \
	doc/ch_11.dat \
	doc/ch_12.dat

.SUFFIXES: .tex .pdf

.tex.pdf:
	$(LATEX) $<
	$(DVIPDF) $(DVIPDFOPT) $*

Prologue.dat: Prologue.rb $(TEXT)
	$(RUBY) Prologue.rb

Prologue.tex: formatter.rb Prologue.dat
	$(RUBY) formatter.rb Prologue.dat > Prologue.tex

