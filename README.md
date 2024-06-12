# embedio: Shortcodes for Embedding in Quarto <img src="logo-embedio.png" align ="right" alt="" width ="150"/>

The `embedio` shortcode extension allows you to incorporate different file types into Quarto HTML documents by using Quarto's shortcode mechanism. The shortcodes expand out to be valid HTML.

## Installation

To install the `embedio` shortcode extension, follow these steps:

1. Open your terminal.

2. Execute the following command:

```bash
quarto add coatless-quarto/embedio
```

This command will download and install the shortcode extension under the `_extensions` subdirectory of your Quarto project. If you are using version control, ensure that you include this directory in your repository.

## Usage

We presently support the following shortcodes:

| Shortcode  | Description                                                     |
|------------|-----------------------------------------------------------------|
| `audio`    | Embeds an audio player with optional caption and download link. |
| `pdf`      | Embeds a PDF file with customizable width and height.           |
| `revealjs` | Embeds a Reveal.js slide deck with optional height.             |
| `html`     | Embeds an HTML webpage with customizable width and height.      |

You can use the shortcode immediately in a Quarto project that has the extension installed by typing into the document:

```md
{{< shortcode-name filename >}}
```

For example, we can embed RevealJS slides using:

```md
{{< revealjs "assets/my-slides.html" >}}
```

## Help

To report a bug, please [add an issue](https://github.com/coatless-quarto/embedio/issues/new) to the repository's [bug tracker](https://github.com/coatless-quarto/embedio/issues).

Want to contribute a feature? Please open an issue ticket to discuss the feature before sending a pull request. 

