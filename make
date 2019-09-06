FILE=PlusCal-Overview
LATEX="$(which xelatex) -shell-escape"
BIBTEX=$(which bibtex)

$LATEX $FILE.tex
$BIBTEX $FILE.aux
$LATEX $FILE.tex
$LATEX $FILE.tex
rm $FILE.aux $FILE.bbl $FILE.blg $FILE.log $FILE.nav $FILE.out $FILE.snm $FILE.toc