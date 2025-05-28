DOC_DIR = doc
MANUAL = $(DOC_DIR)/manual.tex
PDF = $(DOC_DIR)/manual.pdf

# Test directories
TEST_DIRS = test/unit test/integration

# Test files
TEST_FILES = $(shell find $(TEST_DIRS) -name "*.jl")

.PHONY: all doc test execute clean

all: doc test

doc: $(PDF)

$(PDF): $(MANUAL)
	@echo "Building documentation..."
	@cd $(DOC_DIR) && pdflatex -interaction=nonstopmode manual.tex
	@cd $(DOC_DIR) && pdflatex -interaction=nonstopmode manual.tex
	@cd $(DOC_DIR) && bibtex manual
	@cd $(DOC_DIR) && makeindex manual.idx
	@cd $(DOC_DIR) && pdflatex -interaction=nonstopmode manual.tex
	@cd $(DOC_DIR) && pdflatex -interaction=nonstopmode manual.tex
	@echo "Documentation built successfully: $(PDF)"

test:
	@echo "Running tests..."
	@julia test/runtests.jl
	@echo "All tests passed successfully"

.PHONY: test

clean:
	@echo "Cleaning up..."
	@rm -f *.{aux,bbl,blg,brf,css,html,idx,ilg,ind,js,lab,log,out,pdf,pnr,six,toc,txt,xml,xml.bib}
	@rm -f $(DOC_DIR)/*.{aux,bbl,blg,brf,css,html,idx,ilg,ind,js,lab,log,out,pdf,pnr,six,tex,toc,txt,xml,xml.bib}
	@rm -f $(PDF)
	@rm -f $(DOC_DIR)/tst/*/*.out
	@rm -f $(DOC_DIR)/tst/*/*.log
	@echo "Cleanup complete"
