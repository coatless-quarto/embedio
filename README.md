# Quarto Extension Development with Lua in a Devcontainer

This repository houses a devcontainer that setups a [Quarto extension development environment](https://quarto.org/docs/extensions/lua.html). The container is setup to work with [GitHub Codespaces](https://github.com/features/codespaces) to instantly have a cloud-based developer workflow.

You can try out the Codespace by clicking on the following button:

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/coatless-devcontainer/quarto-extension-dev?quickstart=1)

**Note:** Codespaces are available to Students and Teachers for free [up to 180 core hours per month](https://docs.github.com/en/education/manage-coursework-with-github-classroom/integrate-github-classroom-with-an-ide/using-github-codespaces-with-github-classroom#about-github-codespaces) through [GitHub Education](https://education.github.com/). Otherwise, you will have [up to 60 core hours and 15 GB free per month](https://github.com/features/codespaces#pricing).

The devcontainer contains:

- The latest [pre-release](https://quarto.org/docs/download/prerelease) version of Quarto.
- [Quarto VS Code Extension](https://marketplace.visualstudio.com/items?itemName=quarto.quarto).
- [Lua LSP VS Code Extension](https://marketplace.visualstudio.com/items?itemName=sumneko.lua) for Lua code intelligence.
- [GitHub copilot VS Code Extension](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot).
- `R` and `Python`
- `knitr` and `jupyter`

## References

- [Quarto: Lua API Reference](https://quarto.org/docs/extensions/lua-api.html)
- [Quarto: Lua Development](https://quarto.org/docs/extensions/lua.html)
- [Pandoc: Lua Filters](https://pandoc.org/lua-filters.html)
- [Lua: Manual](https://www.lua.org/manual/5.4/)
