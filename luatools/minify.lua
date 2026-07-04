local function minify(code)
    local len = #code
    local i = 1

    local function findLongBracket(startIdx)
        if code:sub(startIdx, startIdx) ~= "[" then return nil end
        local level = 0
        local j = startIdx + 1
        while j <= len and code:sub(j, j) == "=" do
            level = level + 1
            j = j + 1
        end
        if code:sub(j, j) == "[" then
            return level, j + 1
        end
        return nil
    end

    local NUMBER_PATTERNS = {
        "^0[xX]%x+",
        "^%d+%.%d*[eE][%+%-]?%d+",
        "^%.%d+[eE][%+%-]?%d+",
        "^%d+[eE][%+%-]?%d+",
        "^%d+%.%d*",
        "^%.%d+",
        "^%d+",
    }

    local function matchNumber(pos)
        for _, pat in ipairs(NUMBER_PATTERNS) do
            local m = code:match(pat, pos)
            if m then return m end
        end
        return nil
    end

    local out = {}
    local prevType, prevText = nil, nil
    local pendingNewline = false

            local function endsPrefixExpr()
        return prevType == "name" or prevType == "number" or prevType == "string"
            or prevText == ")" or prevText == "]" or prevText == "}"
    end

    local function emit(tokType, text)
        if prevType then
            local needSpace = false
            local insertSemicolon = false

            if (prevType == "name" or prevType == "number")
                and (tokType == "name" or tokType == "number") then
                needSpace = true
            elseif prevText == "-" and text:sub(1, 1) == "-" then
                needSpace = true
            elseif prevType == "number" and text:sub(1, 1) == "." then
                needSpace = true
            elseif pendingNewline and (text == "(" or text == "[") and endsPrefixExpr() then
                insertSemicolon = true
            end

            if insertSemicolon then
                table.insert(out, ";")
            elseif needSpace then
                table.insert(out, " ")
            end
        end

        table.insert(out, text)
        prevType = tokType
        prevText = text
        pendingNewline = false
    end

    while i <= len do
        local c = code:sub(i, i)

        if c:match("%s") then
            if c == "\n" then pendingNewline = true end
            i = i + 1

        elseif c == '"' or c == "'" then
            local quote = c
            local j = i + 1
            while j <= len do
                local cj = code:sub(j, j)
                if cj == "\\" then
                    j = j + 2
                elseif cj == quote then
                    j = j + 1
                    break
                elseif cj == "\n" then
                                        break
                else
                    j = j + 1
                end
            end
            emit("string", code:sub(i, j - 1))
            i = j

        elseif c == "[" then
            local level, contentStart = findLongBracket(i)
            if level then
                local closing = "]" .. string.rep("=", level) .. "]"
                local endPos = code:find(closing, contentStart, true)
                if endPos then
                    emit("string", code:sub(i, endPos + #closing - 1))
                    i = endPos + #closing
                else
                    emit("string", code:sub(i))
                    i = len + 1
                end
            else
                emit("symbol", "[")
                i = i + 1
            end

        elseif code:sub(i, i + 1) == "--" then
            local level = findLongBracket(i + 2)
            if level then
                local closing = "]" .. string.rep("=", level) .. "]"
                local endPos = code:find(closing, i + 4 + level, true)
                i = endPos and (endPos + #closing) or (len + 1)
            else
                local endPos = code:find("\n", i + 2)
                i = endPos and (endPos + 1) or (len + 1)
            end
            pendingNewline = true

        elseif c:match("[%a_]") then
            local m = code:match("^[%a_][%w_]*", i)
            emit("name", m)
            i = i + #m

        elseif c:match("%d") or (c == "." and code:sub(i + 1, i + 1):match("%d")) then
            local m = matchNumber(i)
            if m then
                emit("number", m)
                i = i + #m
            else
                emit("symbol", c)
                i = i + 1
            end

        else
            emit("symbol", c)
            i = i + 1
        end
    end

    return table.concat(out)
end

local inputFile = arg[1]
if not inputFile then
    print("Usage: lua minify.lua <input.lua> [-o output.lua]")
    os.exit(1)
end

local outputFile = nil
if arg[2] == "-o" and arg[3] then
    outputFile = arg[3]
end

local file = io.open(inputFile, "r")
if not file then
    io.stderr:write("Error: Could not open " .. inputFile .. "\n")
    os.exit(1)
end

local code = file:read("*a")
file:close()

local minified = minify(code)

if outputFile then
    local out = io.open(outputFile, "w")
    out:write(minified)
    out:close()
else
    print(minified)
end
