-- Avoid duplicate class definitions
local initializedSlideCSS = false

-- Load CSS into header once
local function ensureSlideCSSPresent()
  if initializedSlideCSS then 
    return
  end
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
  -- Requires Quarto v1.4.549

end

local function revealjs(args, kwargs, meta , raw_args)
  
  if not quarto.doc.is_format("html") then
    return
  end

  -- Enable CSS
  ensureSlideCSSPresent()

  -- Supported options for now
  local slide_file_name = pandoc.utils.stringify(kwargs["file"])
  local height = pandoc.utils.stringify(kwargs["height"]) or "475px"

  -- HTML block
  local template_revealjs = [[
<div>
<iframe class="slide-deck" src=%q height=%q></iframe>
</div>
  ]]

  -- Substitute values
  local combined_str = string.format(template_revealjs, slide_file_name, height)
  
  -- Return as HTML block
  return pandoc.RawBlock('html', combined_str)
end

return {
  ["revealjs"] = revealjs
}