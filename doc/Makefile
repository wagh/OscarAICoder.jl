PDF = manual.pdf
TEX = manual.tex

all: $(PDF)
doc: $(PDF)

$(PDF): $(TEX)
	pdflatex -interaction=nonstopmode $(TEX)
	# makeindex -s $(TEX:.tex=.ist) -t $(TEX:.tex=.ilg) -o $(TEX:.tex=.ind) $(TEX:.tex=.idx)
	makeindex manual
	pdflatex -interaction=nonstopmode $(TEX)
	pdflatex -interaction=nonstopmode $(TEX)

cleanall:
	# rm -f *.aux *.log *.out *.toc *.ind *.ilg *.idx
	rm -f *.{aux,bbl,blg,brf,css,html,idx,ilg,ind,js,lab,log,out,pdf,pnr,six,toc,txt,xml,xml.bib}
	rm -f *.pdf

clean:
	# rm -f *.aux *.log *.out *.toc
	@rm -f *.{aux,bbl,blg,brf,css,html,idx,ilg,ind,js,lab,log,out,pdf,pnr,six,toc,txt,xml,xml.bib}
