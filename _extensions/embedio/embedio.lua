---@alias ShortcodeArgs string[] Positional shortcode arguments
---@alias ShortcodeKwargs table<string, string|pandoc.Inlines> Named shortcode arguments (a missing key reads as empty Inlines)

---@class IframeOptions
---@field label string What the full-screen link calls the embedded file
---@field iframe_class? string Class for the `<iframe>` element
---@field setup? fun() Runs before the embed is built

-- Retrieve an option as a string, or the default when it is missing or empty
---@overload fun(kwargs: ShortcodeKwargs, key: string): string?
---@param kwargs ShortcodeKwargs
---@param key string
---@param default string
---@return string
local function getOption(kwargs, key, default)
  local value = kwargs[key] ~= nil and pandoc.utils.stringify(kwargs[key]) or ""
  if value == "" then
    return default
  end
  return value
end

-- Escape a value for use inside a double-quoted HTML attribute
---@param s string
---@return string
local function escapeAttr(s)
  return (s:gsub('[&<>"\']', {
    ['&'] = '&amp;', ['<'] = '&lt;', ['>'] = '&gt;', ['"'] = '&quot;', ["'"] = '&#39;'
  }))
end

-- Check if a path is a remote reference (URL, data URI, or anchor)
---@param path string
---@return boolean
local function isRemoteRef(path)
  return path:find("^%a+://") ~= nil or
         path:find("^//") ~= nil or
         path:find("^data:") ~= nil or
         path:find("^#") ~= nil
end

-- Register a local file as a Quarto resource so it is copied to the output
---@param file_path string
local function ensureResource(file_path)
  if file_path == "" or isRemoteRef(file_path) then
    return
  end

  -- Strip query strings and fragments (e.g. audio.mp3#t=10)
  local resource_path = file_path:match("^[^%?#]+") or file_path

  -- Resolve to an absolute path based on the input document's directory
  local abs_path
  if pandoc.path.is_absolute(resource_path) then
    abs_path = resource_path
  else
    local doc_dir = pandoc.path.directory(quarto.doc.input_file)
    abs_path = pandoc.path.normalize(pandoc.path.join({doc_dir, resource_path}))
  end

  quarto.doc.add_resource(abs_path)
end

-- Quarto renders these into a file of the same name, so `slides.html` next to
-- `slides.qmd` counts as present before it is rendered
local source_extensions = { ".qmd", ".ipynb", ".Rmd", ".rmd", ".md" }

---@param path string
---@return boolean
local function fileExists(path)
  local file = io.open(path, "r")
  if file == nil then return false end
  file:close()
  return true
end

-- Check that a local file is there to embed; remote references are not
-- checked. A root-relative path in a project (`/assets/page.html`) is also
-- looked up from the project directory, as Quarto resolves it in websites.
---@param file_path string
---@return boolean
local function fileFound(file_path)
  if isRemoteRef(file_path) then return true end

  -- Strip query strings and fragments (e.g. audio.mp3#t=10)
  local path = file_path:match("^[^%?#]+") or file_path

  local candidates = {}
  if pandoc.path.is_absolute(path) then
    table.insert(candidates, path)
    local project_dir = quarto.project.directory
    if project_dir then
      table.insert(candidates, pandoc.path.join({project_dir, (path:gsub("^[/\\]+", ""))}))
    end
  else
    table.insert(candidates, pandoc.path.join({pandoc.path.directory(quarto.doc.input_file), path}))
  end

  for _, candidate in ipairs(candidates) do
    if fileExists(candidate) then return true end
    local stem = pandoc.path.split_extension(candidate)
    for _, ext in ipairs(source_extensions) do
      if fileExists(stem .. ext) then return true end
    end
  end
  return false
end

-- Template for the box shown in HTML in place of an embed whose file is missing
local template_missing = [[
<div class="embedio-missing" style="border: 2px dashed #dc3545; border-radius: 0.375rem; background: rgba(220, 53, 69, 0.08); padding: 0.75rem 1rem; margin: 1rem 0;"><strong>File not found:</strong> %s</div>
]]

-- Read the file path from the first argument or `file`, and register it as a
-- resource. When there is no path or the file is not there, warn and return a
-- placeholder to show instead of the embed, so the rest of the page renders.
---@param args ShortcodeArgs
---@param kwargs ShortcodeKwargs
---@param shortcode string Shortcode name for the warning and the placeholder
---@return string file_path
---@return pandoc.RawBlock? placeholder Set when the file is missing
local function getFilePath(args, kwargs, shortcode)
  local file_path = pandoc.utils.stringify(args[1] or kwargs["file"])
  if file_path == "" then
    quarto.log.warning("embedio: the " .. shortcode .. " shortcode needs a file path. " ..
      "Pass it as the first argument or as file=\"...\". Showing a placeholder instead.")
    return file_path, pandoc.RawBlock("html", string.format(template_missing,
      "the <code>" .. shortcode .. "</code> shortcode has no file path."))
  end
  if not fileFound(file_path) then
    quarto.log.warning("embedio: the " .. shortcode .. " shortcode can't find the file \"" ..
      file_path .. "\". Showing a placeholder instead.")
    return file_path, pandoc.RawBlock("html", string.format(template_missing,
      "<code>" .. escapeAttr(file_path) .. "</code>"))
  end

  -- Ensure file is copied to the output directory
  ensureResource(file_path)
  return file_path
end

-- Avoid duplicate class definitions
local initializedSlideCSS = false

-- Load CSS into header once
local function ensureSlideCSSPresent()
  if initializedSlideCSS then return end
  initializedSlideCSS = true

  -- Default CSS class
  local slideCSS = [[ 
  <style>
  .slide-deck {
      border: 3px solid #dee2e6;
  }
  </style>
  ]]

  -- Inject into the header
  quarto.doc.include_text("in-header", slideCSS)
end

-- Template for displaying a full-screen link
local template_full_screen = [[
    <p><a href="%s" target="_blank">View %s in full screen</a></p>
  ]]

-- Template for the iframe and the div that wraps it
local template_iframe = [[
    <div%s>
      <iframe%s src="%s" height="%s" width="%s"></iframe>
    </div>
  ]]

-- Build a shortcode that embeds a file in an iframe (`html` and `revealjs`)
---@param shortcode string
---@param options IframeOptions
---@return fun(args: ShortcodeArgs, kwargs: ShortcodeKwargs): pandoc.RawBlock|pandoc.Blocks
local function iframeShortcode(shortcode, options)
  local iframe_class = options.iframe_class and (' class="' .. options.iframe_class .. '"') or ""

  return function(args, kwargs)
    -- Other formats get nothing. Returning nil instead makes Quarto print
    -- "Shortcode not found" and then fail the render.
    if not quarto.doc.is_format("html") then return pandoc.Blocks({}) end

    if options.setup then options.setup() end

    -- Get the file name, size, full-screen link option, and wrapper class
    local file_path, placeholder = getFilePath(args, kwargs, shortcode)
    if placeholder then return placeholder end
    local file_name = escapeAttr(file_path)
    local height = getOption(kwargs, "height", "475px")
    local width = getOption(kwargs, "width", "100%")
    local full_screen_link = getOption(kwargs, "full-screen-link", "true")
    local class = getOption(kwargs, "class")
    local div_class = class and (' class="' .. escapeAttr(class) .. '"') or ""

    -- Combine the full-screen link (if requested) with the iframe
    local combined_str = string.format(
      [[%s %s]],
      (full_screen_link == "true" and string.format(template_full_screen, file_name, options.label) or ""),
      string.format(template_iframe, div_class, iframe_class, file_name, escapeAttr(height), escapeAttr(width))
    )

    -- Return the combined HTML as a pandoc RawBlock
    return pandoc.RawBlock('html', combined_str)
  end
end

-- Embed an HTML file
local html = iframeShortcode("html", { label = "webpage" })

-- Embed Reveal.js slides
local revealjs = iframeShortcode("revealjs", {
  label = "slides",
  iframe_class = "slide-deck",
  setup = ensureSlideCSSPresent
})

-- Embed an audio player
---@param args ShortcodeArgs
---@param kwargs ShortcodeKwargs
---@return pandoc.RawBlock|pandoc.Blocks
local function audio(args, kwargs)

  if not quarto.doc.is_format("html") then return pandoc.Blocks({}) end

  -- Start of HTML tag
  local htmlTable = {"<figure"}

  -- Extracting caption, class, and download from kwargs
  local caption = getOption(kwargs, "caption")
  local class = getOption(kwargs, "class")
  local download_link = getOption(kwargs, "download-link", "false")

  -- Extracting input from args or kwargs
  local file_path, placeholder = getFilePath(args, kwargs, "audio")
  if placeholder then return placeholder end
  local input = escapeAttr(file_path)

  -- Add class attribute if provided
  if class then
      table.insert(htmlTable, ' class="' .. escapeAttr(class) .. '"')
  end
  table.insert(htmlTable, ">")

  -- Add download link if provided
  if download_link == "true" then
    table.insert(htmlTable, '<p><a href="' .. input ..'"> Download audio file</a></p><br />')
  end

  -- Add the audio tag with the input file path, and a fallback message for
  -- browsers that do not support it
  table.insert(htmlTable, '<audio controls src="' .. input .. '">')
  table.insert(htmlTable, 'Your browser does not support the audio tag.')
  table.insert(htmlTable, "</audio>")

  -- Add caption if provided
  if caption then
    table.insert(htmlTable, '<figcaption>' .. caption .. '</figcaption>')
  end

  -- Add closing figure tag
  table.insert(htmlTable, "</figure>")

  return pandoc.RawBlock('html', table.concat(htmlTable))
end

-- Embed a PDF file
---@param args ShortcodeArgs
---@param kwargs ShortcodeKwargs
---@return pandoc.RawBlock|pandoc.Blocks
local function pdf(args, kwargs)

  if not quarto.doc.is_format("html") then return pandoc.Blocks({}) end

  -- Supported options for now
  local file_path, placeholder = getFilePath(args, kwargs, "pdf")
  if placeholder then return placeholder end
  local pdf_src = escapeAttr(file_path)
  local height = getOption(kwargs, "height", "600px")
  local width = getOption(kwargs, "width", "100%")
  local download_link = getOption(kwargs, "download-link", "true")

  -- HTML block
  local template_pdf = [[
  <object data="%s" type="application/pdf" width="%s" height="%s">
    <p>Unable to display PDF file. <a href="%s">Download</a> instead.</p>
  </object>
  ]]

  local template_pdf_download_link = [[
  <p><a href="%s" target="_blank">Download PDF File</a></p>
]]

  -- Obtain the combined template
  local combined_str = string.format(
    [[%s %s]],
    (download_link == "true" and string.format(template_pdf_download_link, pdf_src) or ""),
    string.format(template_pdf, pdf_src, escapeAttr(width), escapeAttr(height), pdf_src)
  )

  -- Return as HTML block
  return pandoc.RawBlock('html', combined_str)
end

return {
  ['audio'] = audio,
  ['pdf'] = pdf,
  ['revealjs'] = revealjs,
  ['html'] = html
}
