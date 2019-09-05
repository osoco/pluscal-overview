LATEX=$(which xelatex)
BIBTEX=$(which bibtex)

$LATEX PlusCal-Workshop.tex
$BIBTEX PlusCal-Workshop.aux
$LATEX PlusCal-Workshop.tex
$LATEX PlusCal-Workshop.tex
