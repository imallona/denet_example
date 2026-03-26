SHELL      := bash
CONDA_RUN  := source ~/miniconda3/bin/activate && conda activate snakemake
SMK        := snakemake --use-conda --conda-frontend conda --cores 4
PAPER_DIR  := $(HOME)/src/2025_denet_profiler_appnote

.PHONY: all baseline denet setup-r-env figures clean

all: baseline denet figures

baseline:
	$(CONDA_RUN) && \
	$(SMK) --config use_denet=false outdir=results_baseline --forceall

denet:
	$(CONDA_RUN) && \
	PATH="$(HOME)/.cargo/bin:$$PATH" \
	$(SMK) --config use_denet=true outdir=results_denet --forceall

setup-r-env:
	source ~/miniconda3/bin/activate && \
	conda env create -f envs/rstats.yaml 2>/dev/null || \
	conda env update --name rstats -f envs/rstats.yaml

figures: setup-r-env
	mkdir -p figures
	source ~/miniconda3/bin/activate && \
	conda run -n rstats Rscript -e \
	  "rmarkdown::render('analysis.Rmd', output_dir='figures')"
	mkdir -p $(PAPER_DIR)/figures
	cp figures/analysis.pdf $(PAPER_DIR)/figures/denet_benchmark.pdf

clean:
	rm -rf results_baseline results_denet figures __pycache__ .snakemake
