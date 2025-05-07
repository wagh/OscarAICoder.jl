PDF = manual.pdf
TEX = manual.tex

all: $(PDF)
doc: $(PDF)

$(PDF): $(TEX)
	pdflatex $(TEX)
	pdflatex $(TEX)
	pdflatex $(TEX)
	pdflatex $(TEX)

cleanall:
	rm -f *.aux *.log *.out *.toc
	rm -f *.pdf

clean:
	rm -f *.aux *.log *.out *.toc
