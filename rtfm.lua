--- @module rtfm   Read the fucking manual.
local rtfm = {}

local ALL = '(.*)'
local ONE_WORD = '([^%s]*)%s*(.*)'
local TWO_WORD = '([^%s]+)%s*([^%s]*)%s*(.*)'

local CREATE_DEFAULT_TAGDEFS = function ()
    return {
        ['file'] = { level = 1, group = 11, title = 'Files',
            pattern = ONE_WORD, fields = 'typename,info', sort = 'typename' },
        ['module'] = { alias = 'file',
            title = 'Modules', group = 12 },
        ['script'] = { alias = 'file',
            title = 'Scripts', group = 13 },
        ['type'] = { level = 2, group = 29, title = 'Types',
            pattern = ONE_WORD, fields = 'typename,info', sort = 'typename' },
        ['class'] = { alias = 'type',
            title = 'Classes', group = 21 },
        ['object'] = { alias = 'type',
            title = 'Objects', group = 22 },
        ['table'] = { alias = 'type',
            title = 'Tables', group = 23 },
        ['interface'] = { alias = 'type',
            title = 'Interfaces', group = 24 },
        ['field'] = { level = 3, group = 31, title = 'Fields',
            pattern = TWO_WORD, fields = 'type,name,info', sort = 'name' },
        ['function'] = { level = 3, group = 33, title = 'Functions',
            pattern = ONE_WORD, fields = 'typename,info', sort = 'typename',
            parametric = true },
        ['constructor'] = { alias = 'function',
            title = 'Constructors', group = 32 },
        ['method'] = { alias = 'function',
            title = 'Methods', group = 34 },
        ['callback'] = { alias = 'function',
            title = 'Callbacks', group = 35 },
        ['continue'] = { alias = 'function',
            title = 'Continuations', group = 36 },
        ['param'] = { level = 4, title = 'Arguments',
            pattern = TWO_WORD, fields = 'type,name,info' },
        ['return'] = { level = 4, title = 'Returns',
            pattern = ONE_WORD, fields = 'type,info' },
        ['example'] = { level = 4, title = 'Examples',
            pattern = ALL, fields = 'note',
            code = true },
        ['synopsis'] = { alias = 'example',
            title = 'Synopsis', fields = 'info' },
        ['unknown'] = { level = 4, pattern = TWO_WORD,
            fields = 'type,name,info' },
    }
end

local DEFAULT_TEMPLATE = [[<!doctype html>
<html><head>
<title><@= self.title @></title>
<style>
html, body { background-color:#666; color:#333; font-size:12px;
    margin:0; padding:0; font-family:Lucida Grande, Lucida Sans Unicode,
    Lucida Sans, Geneva, Verdana, Bitstream Vera Sans, sans-serif; }
code { font-family:Lucida Console, Lucida Sans Typewriter, monaco,
    Bitstream Vera Sans Mono, monospace; }
body > div, body > section > article { max-width:600px; padding:40px;
    margin:auto; background:#f8f8f8; box-shadow:0px 0px 26px #000; }
body > section > article + article, body > div + section > article {
    margin:100px auto; }
h1, h2, h3, h4, h5, h6, p { font-weight:normal; font-size:12px;
    margin:0; padding:0; }
h1 { color:#666; font-size:150%; margin:0; padding:0; border:none; }
section > h2 { display:none; }
section > h3 { display:none; }
section > h4 { color:#aaa; font-style:italic; font-size:130%; margin:8px 0; }
section > h5 { font-weight:bold; color:#999; margin:8px 0}
a { color:#39c; text-decoration:none; }
p { line-height:150%; }
:target { text-decoration:underline; }
article > h2 { font-size:200%; }
article > h3 { font-size:140%; background:#ddd;
    margin:16px -48px;  padding:8px 48px;
    box-shadow:0 2px 4px rgba(0,0,0,0.2);  position:relative;
    border:1px solid white; text-shadow:0px 1px 1px #fff; }
article > h3:before { content:""; position:absolute; width:0px; height:0px; 
    bottom:-9px; left:-1px; border:4px solid #999; 
    border-bottom-color:transparent; border-left-color:transparent; }
article > h3:after { content:""; position:absolute; width:0px; height:0px;
    bottom:-9px; right:-1px; border:4px solid #999;
    border-bottom-color:transparent; border-right-color:transparent;  }
article > h3 > b { font-weight: normal; }
article > h4 { border:2px solid #eee; background:#eee;
    margin:0 -8px; padding:4px 8px; }
article > h4 + div { border:2px solid #eee;
    margin:0 -8px; padding:4px 8px; }
article > h4 .type { float:right; }
article > h5 { margin:8px 0 0; }
footer { text-align:center; margin:80px; color:#eee; font-style:italic; }
footer a { color:#fff; font-weight:bold; text-decoration:underline; }
.type { color: #666; }
.unknown { color: #c39; }
.primitive { color: #999; }
</style></head><body>
<@
local typenames = {}
for _, tag in ipairs(tags.flat) do
    if tag.typename then typenames[tag.typename] = tag end
end
local primitives = { ['nil'] = true, ['number'] = true, ['string'] = true,
    ['boolean'] = true, ['table'] = true, ['function'] = true,
    ['thread'] = true, ['userdata'] = true }
local idMap = {}
local function link (tag)
    if tag.type then
        write('<span class="type">')
        for m1, m2, m3 in tag.type:gmatch('([^%a]?)([%a]+)(.?)') do
            if typenames[m2] then
                write(m1 .. '<a href="#' .. m2 .. '">'
                    .. m2 .. '</a>' .. m3)
            elseif primitives[m2] then
                write(m1 .. '<span class="primitive">'
                    .. m2 .. '</span>' .. m3)
            else
                write(m1 .. '<span class="unknown">'
                    .. m2 .. '</span>' .. m3)
            end
        end
        write('</span> ')
    end
    if tag.name then
        write('<b>' .. tag.name .. '</b> ')
    end
    if tag.typename then
        local id = ''
        if not idMap[tag.typename] and tag.level < 4 then
            id = ' id="' .. tag.typename .. '"'
            idMap[tag.typename] = tag
        end
        write('<b' .. id .. '>' .. tag.typename .. '</b> ')
    end
    if not tag.parametric then
        return
    end
    local hasParam = false
    write('(')
    for index, child in ipairs(tag) do
        if child.id == 'param' then
            if hasParam then 
                write(', ')
            end
            write('<var>' .. child.name .. '</var>')
            hasParam = true
        end
    end
    write(')')
end
@>
<@ if self.index then @>
    <div>
        <h1><@= self.title @></h1>
        <nav><h3>Table of Contents</h3>
            <@ local lastTag = {} for _, tag in ipairs(tags) do @>
                <@ if tag.id ~= lastTag.id then @>
                    <@ if lastTag.id then @></dl></section><@ end @>
                    <section><h4><@= tag.title or tag.id @></h4>
                <@ end @>
                <a href="#<@= tag.typename @>"><@= tag.typename @></a>
                <p><@= tag.info @></p>
            <@ lastTag = tag end @>
            <@ if lastTag.id then @></section><@ end @>
        </nav>
    </div>
<@ end @>
<@
local function dump (tags)
    for index, tag in ipairs(tags) do 
        local lastTag = tags[index - 1] or {}
        local nextTag = tags[index + 1] or {} @>
        <@ if tag.id ~= lastTag.id then @>
            <section>
            <h<@= tag.level + 1 @>>
                <@= tag.title or tag.id @>
            </h<@= tag.level + 1 @>>
        <@ end @>
        <article>
            <@ if tag.type or tag.typename then @>
                <h<@= tag.level + 1 @>>
                    <@ link(tag) @>
                </h<@= tag.level + 1 @>>
            <@ end @>
            <div>
                <@ if tag.note then @><p><@= tag.note @></p><@ end @>
                <@ if tag.code then @>
                    <pre><code><@= tag.info @></code></pre>
                <@ else @>
                    <p><@= tag.info @></p>
                <@ end @>
                <@ if #tag > 0 then @>
                    <@ dump(tag) @>
                <@ end @>
            </div>
        </article>
        <@ if nextTag.id ~= tag.id then @>
            </section>
        <@ end @>
    <@ end 
end
dump(tags) @>
<footer>
    Documentation generated by
    <a href="about:blank">RTFM</a>.
</footer>
</body>
</html>
]]

--- @function rtfm.launch   Launch the generator from the command line.
--- @param string ...    Arguments passed in from command line.
function rtfm.launch (...)
    -- Try to load rtfmconf.lua
    local option = {}
    local env = setmetatable({}, { __index = function (self, index)
        return option.at[index] or _G[index]
    end })
    local configure = loadfile('rtfmconf.lua', 't', env)
    if not configure then
        configure = function () end
    end
    if setfenv then
        setfenv(configure, env)
    end
    -- Parse command line args
    local source = 'local o, c = ... return function (t) o.at = t; c()\n'
    local argIndex = 1
    for i = 1, select('#', ...) do
        local option = select(i, ...)
        local s, e, k, v = option:find('^%-%-(.*)=(.*)')
        if not s then
            break
        end
        v = (v == 'true' or v == 'false' or v == 'nil') and v
            or tonumber(v) or ('%q'):format(v)
        source = source .. 't.' .. k .. '=' .. tostring(v) .. '\n'
        argIndex = i + 1
    end
    source = source .. 'end'
    -- Create and run a generator
    local generator = rtfm.Generator(loadstring(source)(option, configure))
    generator:run({ select(argIndex, ...) })
end

--- @class Generator  Documentation generator.

--- @function Generator.sortTags  Function passed to table.sort.
local function sortTags (a, b)
    if a.level ~= b.level then
        return a.level > b.level
    end
    if a.group and b.group then
        if a.group ~= b.group then
            return a.group < b.group
        end
        if a.sort and a.sort == b.sort then
            for sort in a.sort:gmatch('(%a+)') do
                if a[sort] < b[sort] then
                    return true
                elseif a[sort] > b[sort] then
                    return false
                end
            end
        end
    end
    return a.index < b.index
end

--- @method Generator:nestTags   Nest and sort tags. 
local function nestTags (self, tags)
    local levels = {}
    local i = 0
    tags.flat = {}
    while i < #tags do
        i = i + 1
        local tag = tags[i]
        tags.flat[#tags.flat + 1] = tag
        if levels[tag.level] then
            table.sort(levels[tag.level], self.sortTags)
        end
        levels[tag.level] = tag
        for j = 1, tag.level - 1 do
            levels[j] = levels[j] or false
        end
        while #levels > tag.level do
            if levels[#levels] then
                table.sort(levels[#levels], self.sortTags)
            end
            levels[#levels] = nil
        end
        local parent
        local level = tag.level - 1
        while level > 0 and not parent do
            parent = levels[level]
            level = level - 1
        end
        if parent then
            tag.parent = parent
            parent[#parent + 1] = tag
            table.remove(tags, i)
            i = i - 1
        end
    end

    for _, level in ipairs(levels) do
        if level then
            table.sort(level, self.sortTags)
        end
    end

    table.sort(tags, self.sortTags)
end

--- @method Generator:run   Run the generator on a list of files.
--- @param {number:string} files   A table of source files to parse.
local function run (self, files)
    local tags = self.input:read(files)
    self:nestTags(tags)
    local text = self.template:apply(tags)
    self.output:write(text)
end

--- @constructor rtfm.Generator   Creates a Generator instance.
--- @param ConfigCallback configure  An optional configuration callback.
function rtfm.Generator (configure)
    local generator = {}
    
    --- @field Template template   The template for generated output.
    generator.template = rtfm.Template(generator)
    
    --- @field Reader input   The source file reader.
    generator.input = rtfm.Reader(generator)
    
    --- @field Writer output   The documentation writer.
    generator.output = rtfm.Writer(generator)
    
    --- @field {string:TagDef} tag  Tag definitions, keyed by ID.
    generator.tag = CREATE_DEFAULT_TAGDEFS()
    
    generator.sortTags = sortTags
    generator.nestTags = nestTags
    generator.run = run
    
    if configure then
        configure(generator)
    end
    for _, tag in pairs(generator.tag) do
        if tag.alias then
            setmetatable(tag, { __index = generator.tag[tag.alias] })
        end
    end
    
    return generator
end

--- @class Template   The default template.

--- @method Template:applyText   Apply the template.
--- @param string text   The full text of the template.
--- @param {number:TagDef} tags   List of tags to apply the template to.
local function applyText (self, text, tags)
    local open = '\nwrite[============[\n'
    local close = ']============]\n'
    if self.condense then
        local s, e, left, right = self.escapePattern:find('(.*)%(.*%)(.*)')
        text = text:gsub(right .. '[%s]+' .. left, right .. left) 
    end
    local source = 'local self, tags, write = ... ' .. open .. text
        :gsub(self.outputPattern, close .. 'write(%1\n)' .. open)
        :gsub(self.escapePattern, close .. '%1' .. open)
        .. close
    local func, reason = loadstring(source)
    if func then
        local buffer = {}
        func(self, tags, function (text) buffer[#buffer + 1] = text end)
        return table.concat(buffer)
    else
        return nil, reason
    end
end

--- @method Template:apply   Apply the template to a list of tags.
--- @param {number:TagDef} tags   List of tags to apply the template to.
--- @return string   Returns the generated output.
local function apply (self, tags)
    local text
    if self.path then
        local file = io.open(self.path)
        if file then
            text = file:read('*a')
        else
            io.stderr:write('\nTemplate file "' .. self.path
                .. '" not found.\nUsing built-in template.\n\n')
        end
        local result, reason = self:applyText(text, tags)
        if not result then
            io.stderr:write('\nError in template file.\n' .. reason .. '\n')
            text = nil
        end
    end
    if not text then
        return assert(self:applyText(self.text, tags))
    end
end

--- @constructor rtfm.Template   Creates a Template instance.
function rtfm.Template ()
    local template = {}
    --- @field string title   Main title to display in generated output.
    template.title = 'API Docs'
    --- @field string path   Path to a custom template.
    template.path = nil
    --- @field string text   Full text of the output template.
    template.text = DEFAULT_TEMPLATE
    --- @field boolean index   Whether to display an index (table of contents).
    template.index = true
    --- @field string escapePattern   Pattern to escape Lua code.
    template.escapePattern = '<@(.-)@>'
    --- @field string outputPattern   Pattern to output results of expressions.
    template.outputPattern = '<@=(.-)@>'
    --- @field boolean condense   Eliminate whitespace between escape sequences.
    template.condense = true
    
    template.apply = apply
    template.applyText = applyText
    
    return template
end

--- @class Reader   Parses the source files.

--- @method Reader:parseLine  Parse a line from a source file.
--- @param string line   Line of text to parse.
local function parseLine (self, line)
    local tags = self.tags
    local lastTag = tags[#tags]
    local column, _, id, data = line:find(self.sigil .. '([^%s]+)%s*(.*)')
    -- is this line a new tag?
    if id then
        if lastTag then
            lastTag.info = lastTag.info:gsub('\n*$', '')
        end
        local tag = setmetatable({}, {
            __index = self.generator.tag[id] or self.generator.tag.unknown
        })
        local m = { data:find(tag.pattern) }
        local i = 2
        for field in tag.fields:gmatch('[^,]+') do
            i = i + 1
            tag[field] = m[i]
        end
        tags[#tags + 1] = tag
        tag.index = #tags
        tag.column = column
        tag.data = data
        tag.id = id
        tag.info = tag.info or ''
    -- it's more info for the previous tag
    elseif lastTag then
        local left = line:sub(1, lastTag.column - 1)
        local right = line:sub(lastTag.column, -1)
        line = left:gsub('^[%s-]*', '') .. right
        if lastTag.info == '' then
            lastTag.info = line
        else
            lastTag.info = lastTag.info .. '\n' .. line
        end
    end
end

--- @method Reader:parseFile   Read a file and create tags from it.
--- @param string name   Name of file to parse.  
local function parseFile (self, name)
    local file = io.open(name)
    local inBlock = false
    for line in file:lines() do
        if line:find(self.blockEndPattern) then -- found end of block
            inBlock = false
        end
        if inBlock or line:find(self.linePattern) then -- in block or line
            self:parseLine(line)
        end
        if line:find(self.blockStartPattern) then -- found start of block
            inBlock = true
        end
    end
    file:close()
end

--- @method Reader:read   Read some files return a list of tags.
--- @param {number:string} files   List of files to parse.
--- @return {number:TagDef}   Returns a list of extracted tags.
local function read (self, files)
    for _, name in ipairs(files) do
        self:parseFile(name)
    end
    return self.tags
end

--- @constructor rtfm.Reader   Creates a Reader instance.
--- @param Generator generator   The generator instance.
function rtfm.Reader (generator)
    local reader = {}
    
    reader.generator = generator
    reader.tags = {}
    
    --- @field string sigil   The prefix character for tags; "@" by default.
    reader.sigil = '@'
    --- @field string blockStartPattern   Matches the start of a docblock.
    reader.blockStartPattern = '%-%-%-*%[%['
    --- @field string blockEndPattern   Matches the end of a docblock.
    reader.blockEndPattern = '%-*%]%]'
    --- @field string linePattern   Matches a line with a docblock.
    reader.linePattern = '%-%-%-'
    
    reader.parseFile = parseFile
    reader.parseLine = parseLine
    reader.read = read
    
    return reader
end

--- @class Writer   Outputs the generated text.

--- @method Writer:write   Outputs some text to a file or stdout.
--- @param {number:string} files   List of files to parse.
--- @return {number:TagDef}   Returns a list of extracted tags.
local function write (self, text)
    if self.path then
        local file = io.open(self.path, 'wb')
        file:write(text)
    else
        io.write(text)
    end
end

--- @constructor rtfm.Writer   Creates a Writer instance.
function rtfm.Writer ()
    local writer = {}
    --- @field string path   Path to output file. Uses stdout if omitted.
    writer.path = nil
    
    writer.write = write
    
    return writer
end

-- If running from the command line, launch the generator.
if arg and arg[0] and arg[0]:find('rtfm.lua$') then
    rtfm.launch(...)
end

return rtfm

--[[--
@type TagDef

@field number level     Tag level. Lower levels are parents of higher levels.
@field number group     Group priority level. Lower groups come first.
@field string sort      The name of a field to sort by after grouping.
@field string pattern   Matching pattern. Captures are inserted into fields.
@field string fields    Comma-delimited list of fields to populate from pattern.
@field string alias     The name of another `self.tag` to inherit from.
@field string title     A name to display in the template for this tag.
@field boolean parametric   Whether to display a parameter list overview.
--]]--
