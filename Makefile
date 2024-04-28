.PHONY: asset-revealjs asset-pdf asset-html assets
.DEFAULT_GOAL := help

asset-html: ## Render HTML Webpage
	quarto render asset-generation/my-html-page.qmd --output-dir ../docs/assets

asset-pdf: ## Render PDF Document
	quarto render asset-generation/my-pdf-file.qmd --output-dir ../docs/assets

asset-revealjs: ## Render RevealJS Slides
	quarto render asset-generation/my-revealjs-slides.qmd --output-dir ../docs/assets

assets:	asset-revealjs asset-pdf asset-html  ## Render all assets

help:  ## Show help messages for make targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(firstword $(MAKEFILE_LIST)) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-18s\033[0m %s\n", $$1, $$2}'

