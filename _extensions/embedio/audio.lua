local function audio(args, kwargs, meta)

    if not quarto.doc.is_format("html") then
        return
    end

    -- Start of HTML tag
    local htmlTable = {"<figure "} 

    -- Extracting caption and class from kwargs
    local caption = pandoc.utils.stringify(kwargs.caption)
    local class = pandoc.utils.stringify(kwargs.class)
    
    -- Add class attribute if provided
    if class then
        table.insert(htmlTable, 'class="' .. class .. '">')
    end

    -- Add caption if provided
    if caption then
        table.insert(htmlTable, '<figcaption>' .. caption .. '</figcaption>')
    end

    -- Start the audio tag
    table.insert(htmlTable, "<audio controls")

    -- Extracting input from args or kwargs
    local input = args[1] or kwargs.file
    input = pandoc.utils.stringify(input)

    -- Add source attribute with input file path
    if input then
        table.insert(htmlTable, ' src="' .. input .. '"')
    else
        quarto.log.error("Error: Audio file path is required for the audio shortcode.")
        assert(false)
    end

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

    -- Extract download option
    local download = pandoc.utils.stringify(kwargs.download) or "false"
    
    -- Add download link if provided
    if download == "true" then
        table.insert(htmlTable, '<br /><a href="' .. input ..'"> Download audio </a>')
    end    

    -- Add closing figure tag
    table.insert(htmlTable, "</figure>")

    return pandoc.RawBlock('html', table.concat(htmlTable))
end


return {
    ['audio'] = audio
}