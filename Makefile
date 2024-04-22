.PHONY=asset-pdf asset-revealjs assets
.DEFAULT=assets

asset-pdf: 
	quarto render asset-generation/my-pdf-file.qmd --output-dir ../docs/assets

asset-revealjs:
	quarto render asset-generation/my-revealjs-slides.qmd --output-dir ../docs/assets

assets:
	asset-revealjs asset-pdf
