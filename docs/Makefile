.PHONY=asset-pdf asset-revealjs assets
.DEFAULT=assets

asset-pdf: 
	cd asset-generation
	quarto render my-pdf-file.qmd --output-dir ../assets

asset-revealjs: 
	cd asset-generation
	quarto render my-revealjs-slides.qmd --output-dir assets

assets:
	asset-revealjs asset-pdf
