-- embedio tests. Run from the repo root: quarto pandoc lua path/to/qtest.lua
local t = require("qtest")

t.test("html: an iframe with a full-screen link, 475px by 100% by default", function()
  local r = t.render("embeds.qmd", "html")
  r:succeeded()
  t.in_order(r.text, {
    '<a href="assets/page.html" target="_blank">View webpage in full screen</a>',
    '<iframe src="assets/page.html" height="475px" width="100%"></iframe>',
  })
end)

t.test("html: height, width and class set the iframe; full-screen-link=false drops the link", function()
  local r = t.render("embeds.qmd", "html")
  t.contains(r.text, '<div class="framed">')
  t.contains(r.text, '<iframe src="assets/page.html" height="300px" width="50%"></iframe>')
  t.count(r.text, "View webpage in full screen", 1)
end)

t.test("revealjs: slides get the slide-deck frame, and its CSS is added once per page", function()
  local r = t.render("embeds.qmd", "html")
  t.count(r.text, '<iframe class="slide-deck" src="assets/slides.html"', 2)
  t.count(r.text, "View slides in full screen", 2)
  t.count(r.text, ".slide-deck {", 1)
end)

t.test("pdf: an object with a download link, 600px by 100% by default; options change both", function()
  local r = t.render("embeds.qmd", "html")
  t.contains(r.text, '<object data="assets/doc.pdf" type="application/pdf" width="100%" height="600px">')
  t.contains(r.text, '<object data="assets/doc.pdf" type="application/pdf" width="80%" height="400px">')
  t.count(r.text, "Download PDF File", 1)
end)

-- Regression: audio put an empty class and caption on every figure, and
-- worked out a type attribute from the file extension, which failed the
-- render with "assertion failed!" for a file without one.
t.test("audio: caption, class and download-link only when given; a file without an extension works", function()
  local r = t.render("embeds.qmd", "html")
  t.contains(r.text, '<figure class="figure"><audio controls="" src="assets/clip.mp3">')
  t.in_order(r.text, {
    '<figure class="podcast figure">',
    '<a href="assets/recording"> Download audio file</a>',
    '<audio controls="" src="assets/recording">',
    "<figcaption>A recording</figcaption>",
  })
  t.count(r.text, "<figcaption>", 1)
  t.count(r.text, "Download audio file", 1)
  t.not_contains(r.text, "<audio controls type=")
end)

-- Regression: attributes were quoted with Lua's %q, so a non-ASCII name got
-- Lua escapes like \226\128\148 in its URL, and a quote in `class` could add
-- attributes of its own.
t.test("file names and classes are escaped for HTML attributes", function()
  local r = t.render("escaping.qmd", "html")
  r:succeeded()
  t.contains(r.text, "data=\"assets/notes—draft &amp; 'v2'.pdf\"")
  t.contains(r.text, 'class="wide&quot; onload=&quot;alert(1)"')
  t.not_contains(r.text, "\\226")
end)

t.test("a missing file or path warns and shows a placeholder; the rest of the page renders", function()
  local r = t.render("missing.qmd", "html")
  r:succeeded()
  t.contains(r.log, 'the pdf shortcode can\'t find the file "assets/nowhere.pdf"')
  t.contains(r.log, "the html shortcode needs a file path")
  t.in_order(r.text, {
    "<p>Before.</p>",
    "<strong>File not found:</strong> <code>assets/nowhere.pdf</code>",
    "<strong>File not found:</strong> the <code>html</code> shortcode has no file path.",
    "<p>After.</p>",
  })
end)

-- Regression (#16): embedded files had to be listed under `resources` by
-- hand, or they were missing from the rendered site. Quarto finds files in
-- iframe src and object data itself, but not in audio src.
t.test("website: an embedded audio file is copied into the output folder", function()
  local r = t.render("site", "html", { output = "site/_site/index.html" })
  r:succeeded()
  t.ok(r.files["site/_site/assets/theme.mp3"], "site/_site/assets/theme.mp3 exists")
end)

-- Regression: outside HTML the shortcodes returned nil, which Quarto treats as
-- an unknown shortcode ("Shortcode 'pdf' not found"), and then the render
-- failed. Other formats now get nothing in place of an embed.
t.test("typst and docx: the document renders, without the embeds", function()
  for _, format in ipairs({ "typst", "docx" }) do
    local r = t.render("embeds.qmd", format)
    r:succeeded()
    r:no_warnings()
    t.not_contains(r.text, "assets/page.html")
    t.not_contains(r.text, "assets/doc.pdf")
  end
end)
