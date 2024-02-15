local function pdf(args, kwargs, meta)

  if not quarto.doc.is_format("html") then
    return
  end

  -- Supported options for now
  local pdf_file_name = args[1] or kwargs["file"]
  pdf_file_name = pandoc.utils.stringify(pdf_file_name)
  
  local height = pandoc.utils.stringify(kwargs["height"]) or "600px"
  local width = pandoc.utils.stringify(kwargs["height"]) or "100%"

  -- HTML block
  local template_pdf = [[
  <object data=%q type="application/pdf" width=%q height=%q>
    <p>Unable to display PDF file. <a href=%q>Download</a> instead.</p>
  </object>
  ]]

  -- Substitute values
  local combined_str = string.format(template_pdf, pdf_file_name, width, height, pdf_file_name)

  -- Return as HTML block
  return pandoc.RawBlock('html', combined_str)
end

return {
    ['pdf'] = pdf
  }
