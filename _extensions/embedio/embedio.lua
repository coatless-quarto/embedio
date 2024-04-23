-- Check if variable missing or an empty string
local function isVariableEmpty(s)
  return s == nil or s == ''
end

-- Check if variable is present
local function isVariablePopulated(s)
  return not isVariableEmpty(s)
end

-- Check whether an argument is present in kwargs
-- If it is, return the value
local function tryOption(options, key)

  -- Protect against an empty options
  if not (options and options[key]) then
      return nil
  end

  -- Retrieve the option
  local option_value = pandoc.utils.stringify(options[key])
  -- Verify the option's value exists, return value otherwise nil.
  if isVariablePopulated(option_value) then
      return option_value
  else
      return nil
  end
end

-- Retrieve the option value or use the default value
local function getOption(options, key, default)
  return tryOption(options, key) or default
end

-- Validate input file path is not empty
local function checkFile(input)
  if input then
    return true
  else
    quarto.log.error("Error: file path is required for the embedio shortcode.")
    assert(false)
  end
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
      width: 100%;
  }
  </style>
  ]]

  -- Inject into the header
  quarto.doc.include_text("in-header", slideCSS)
end

local function revealjs(args, kwargs, meta , raw_args)
  
  if not quarto.doc.is_format("html") then return end

  -- Enable CSS
  ensureSlideCSSPresent()

  -- Supported options for now
  
  local slide_file_name = pandoc.utils.stringify(args[1] or kwargs["file"])
  checkFile(slide_file_name)

  local height = getOption(kwargs, "height", "475px")

  -- Check if "full-screen" parameter exists in kwargs
  local full_screen_link = getOption(kwargs, "full-screen-link", "true")

  -- HTML Template blocks
  local template_revealjs = [[
<div>
<iframe class="slide-deck" src=%q height=%q></iframe>
</div>
]]
  local template_revealjs_full_screen = [[
  <p><a href=%q target="_blank">View slides in full screen</a></p>
]]

  -- Obtain the combined template
  local combined_str = string.format(
    [[%s %s]], 
    (full_screen_link == "true" and string.format(template_revealjs_full_screen, slide_file_name) or ""), 
    string.format(template_revealjs, slide_file_name, height)
  )
  
  -- Return as HTML block
  return pandoc.RawBlock('html', combined_str)
end

local function audio(args, kwargs, meta)

  if not quarto.doc.is_format("html") then return end

  -- Start of HTML tag
  local htmlTable = {"<figure "} 

  -- Extracting caption, class, and download from kwargs
  local caption = pandoc.utils.stringify(kwargs.caption)
  local class = pandoc.utils.stringify(kwargs.class)
  local download_link = getOption(kwargs, "download-link", "false")

  -- Extracting input from args or kwargs
  local input = pandoc.utils.stringify(args[1] or kwargs.file)
  checkFile(input)

  -- Add class attribute if provided
  if class then
      table.insert(htmlTable, 'class="' .. class .. '">')
  end

  -- Add download link if provided
  if download_link == "true" then
    table.insert(htmlTable, '<p><a href="' .. input ..'"> Download audio file</a></p><br />')
  end

  -- Start the audio tag
  table.insert(htmlTable, "<audio controls")

  -- Add source attribute with input file path
  table.insert(htmlTable, ' src="' .. input .. '"')

  -- Automatically detect file type from the file extension
  local fileType = string.match(input, "%.([^%.]+)$")
  
  if fileType then
      table.insert(htmlTable, ' type="audio/' .. fileType .. '">')
  else
      quarto.log.error("Error: Unable to detect file type from the audio file path.")
      assert(false)
  end

  -- Add source element for browsers that do not support the audio tag
  table.insert(htmlTable, 'Your browser does not support the audio tag.')

  -- Add closing audio tag
  table.insert(htmlTable, "</audio>")

  -- Add caption if provided
  if caption then
    table.insert(htmlTable, '<figcaption>' .. caption .. '</figcaption>')
  end

  -- Add closing figure tag
  table.insert(htmlTable, "</figure>")

  return pandoc.RawBlock('html', table.concat(htmlTable))
end


local function pdf(args, kwargs, meta)

  if not quarto.doc.is_format("html") then return end

  -- Supported options for now
  local pdf_file_name = pandoc.utils.stringify(args[1] or kwargs["file"])
  checkFile(pdf_file_name)
  
  local height = getOption(kwargs, "height", "600px")
  local width = getOption(kwargs, "width", "100%")
  local download_link = getOption(kwargs, "download-link", "true")

  -- HTML block
  local template_pdf = [[
  <object data=%q type="application/pdf" width=%q height=%q>
    <p>Unable to display PDF file. <a href=%q>Download</a> instead.</p>
  </object>
  ]]

  local template_pdf_download_link = [[
  <p><a href=%q target="_blank">Download PDF File</a></p>
]]

  -- Obtain the combined template
  local combined_str = string.format(
    [[%s %s]], 
    (download_link == "true" and string.format(template_pdf_download_link, pdf_file_name) or ""), 
    string.format(template_pdf, pdf_file_name, width, height, pdf_file_name)
  )

  -- Return as HTML block
  return pandoc.RawBlock('html', combined_str)
end

return {
  ['audio'] = audio,
  ['pdf'] = pdf,
  ["revealjs"] = revealjs
}
