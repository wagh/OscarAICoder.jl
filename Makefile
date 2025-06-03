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
	@rm -f $(DOC_DIR)/manual.aux
	@rm -f $(DOC_DIR)/manual.bbl
	@rm -f $(DOC_DIR)/manual.blg
	@rm -f $(DOC_DIR)/manual.idx
	@rm -f $(DOC_DIR)/manual.ilg
	@rm -f $(DOC_DIR)/manual.ind
	@rm -f $(DOC_DIR)/manual.log
	@rm -f $(DOC_DIR)/manual.out
	@rm -f $(DOC_DIR)/manual.toc
	@rm -f $(PDF)
	@echo "Cleanup complete"
