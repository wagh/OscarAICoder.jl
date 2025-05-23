DOC_DIR = doc
MANUAL = $(DOC_DIR)/manual.tex
PDF = $(DOC_DIR)/manual.pdf

# Test directories
TEST_DIRS = $(DOC_DIR)/tst/commutative_algebra \
             $(DOC_DIR)/tst/algebraic_geometry \
             $(DOC_DIR)/tst/calculus \
             $(DOC_DIR)/tst/linear_algebra

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

test: $(TEST_FILES)
execute: $(TEST_FILES)
	@echo "Running execute tests..."
	@for test_file in $(TEST_DIRS)/*/*_tests.jl; do \
		echo "Running execute test: $$test_file"; \
		julia $$test_file > $$test_file.out 2>&1; \
		diff $$test_file.out $$test_file.expected 2>/dev/null || \
		(echo "Execute test failed: $$test_file" && cat $$test_file.out && exit 1); \
	done
	@echo "All execute tests passed successfully"
	@echo "Running tests..."
	@for test_file in $(TEST_FILES); do \
		echo "Running test: $$test_file"; \
		julia $$test_file > $$test_file.out 2>&1; \
		diff $$test_file.out $$test_file.expected 2>/dev/null || \
		(echo "Test failed: $$test_file" && cat $$test_file.out && exit 1); \
	done
	@echo "All tests passed successfully"

clean:
	@echo "Cleaning up..."
	@rm -f *.{aux,bbl,blg,brf,css,html,idx,ilg,ind,js,lab,log,out,pdf,pnr,six,toc,txt,xml,xml.bib}
	@rm -f $(DOC_DIR)/*.{aux,bbl,blg,brf,css,html,idx,ilg,ind,js,lab,log,out,pdf,pnr,six,tex,toc,txt,xml,xml.bib}
	@rm -f $(PDF)
	@rm -f $(DOC_DIR)/tst/*/*.out
	@rm -f $(DOC_DIR)/tst/*/*.log
	@echo "Cleanup complete"
