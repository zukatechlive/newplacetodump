-- this makes a script one line and wraps it in a function wrap, the "([[ This script was wrapped ]]):gsub(".+", function(a) wrap_=a end)" is merely a header for aesthetic

local function minify(code)
	local len = #code
	local i = 1

	local function findLongBracket(startIdx)
		if code:sub(startIdx, startIdx) ~= "[" then
			return nil
		end
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
			if m then
				return m
			end
		end
		return nil
	end

	local out = {}
	local prevType, prevText = nil, nil
	local prevPrevText, prevPrevPrevText = nil, nil
	local pendingNewline = false

	local function endsPrefixExpr()
		return prevType == "name"
			or prevType == "number"
			or prevType == "string"
			or prevText == ")"
			or prevText == "]"
			or prevText == "}"
	end

	local function isFunctionDeclParen()
		if prevType ~= "name" then
			return false
		end
		if prevPrevText == "." or prevPrevText == ":" then
			return prevPrevPrevText == "function"
		end
		return prevPrevText == "function"
	end

	local function emit(tokType, text)
		if prevType then
			local needSpace = false
			local insertSemicolon = false

			if (prevType == "name" or prevType == "number") and (tokType == "name" or tokType == "number") then
				needSpace = true
			elseif prevText == "-" and text:sub(1, 1) == "-" then
				needSpace = true
			elseif prevType == "number" and text:sub(1, 1) == "." then
				needSpace = true
			elseif
				pendingNewline
				and (text == "(" or text == "[")
				and endsPrefixExpr()
				and not (text == "(" and isFunctionDeclParen())
			then
				insertSemicolon = true
			end

			if insertSemicolon then
				table.insert(out, ";")
			elseif needSpace then
				table.insert(out, " ")
			end
		end

		table.insert(out, text)
		prevPrevPrevText = prevPrevText
		prevPrevText = prevText
		prevType = tokType
		prevText = text
		pendingNewline = false
	end

	while i <= len do
		local c = code:sub(i, i)

		if c:match("%s") then
			if c == "\n" then
				pendingNewline = true
			end
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

-- Cosmetic-only header templates. Each one is functionally a no-op:
-- it builds a string, runs a harmless gsub over it, and stuffs the result
-- into a throwaway global. %s is replaced with a randomized identifier name.
local HEADER_TEMPLATES = {
	'([[ Protected with Xenlite v2 ]]):gsub(".+", function(a) %s=a end)',
	'([[ Xenlite Protected ]]):gsub(".+", function(z) %s=z end)',
	'([[ Made with spite | Xenlite Protected ]]):gsub(".-", function(v) %s=v end)',
	'([[ Xenlite runtime ]]):gsub("..*", function(q) %s=q end)',
	'([[ Christ is King! ]]):gsub(".+", function(k) %s=k end)',
	'([[ Protected with Xenlite | Made by OverZuka. ]]):gsub("%%a+", function(w) %s=w end)',
	'([[ This script is protected with Xenlite v2 ]]):gsub(".+", function(h) %s=h end)',
}

local IDENT_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

local function randomIdent(minLen, maxLen)
	local len = math.random(minLen, maxLen)
	local chars = {}
	-- first char must not be a digit; IDENT_CHARS has none anyway
	for _ = 1, len do
		local idx = math.random(1, #IDENT_CHARS)
		table.insert(chars, IDENT_CHARS:sub(idx, idx))
	end
	return table.concat(chars)
end

local function randomHeader()
	math.randomseed(os.time() + os.clock() * 1000000)
	local template = HEADER_TEMPLATES[math.random(1, #HEADER_TEMPLATES)]
	local ident = randomIdent(4, 9)
	return template:format(ident)
end

-- Anti-Tamper Protection Functions
local function generateHash(code)
	local hash = 0
	for i = 1, #code do
		hash = (hash * 31 + string.byte(code, i)) % (2^32)
	end
	return string.format("%08x", hash)
end

local function wrapWithAntiTamper(header, minified)
	local codeBody = minified
	local hash = generateHash(codeBody)
	
	-- Create anti-tamper wrapper
	local antiTamperWrapper = string.format(
		[[local __HASH='%s' local function __verify() local __code=debug.getinfo(1).source local __h=0 for __i=1,#__code do __h=(__h*31+string.byte(__code,__i))%%(2^32) end return string.format("%%08x",__h) end if __verify()~=__HASH then error("[ANTI-TAMPER] Script integrity check failed!") end ]],
		hash
	)
	
	return header .. " return(function(...) " .. antiTamperWrapper .. codeBody .. " end)(...)"
end

local inputFile = arg[1]
if not inputFile then
	print("Usage: lua minify.lua <input.lua> [-o output.lua] [-nowrap] [-antitamper]")
	os.exit(1)
end

local outputFile = nil
local noWrap = false
local antiTamper = false

for idx = 2, #arg do
	if arg[idx] == "-o" and arg[idx + 1] then
		outputFile = arg[idx + 1]
	elseif arg[idx] == "-nowrap" then
		noWrap = true
	elseif arg[idx] == "-antitamper" then
		antiTamper = true
	end
end

local file = io.open(inputFile, "r")
if not file then
	io.stderr:write("Error: Could not open " .. inputFile .. "\n")
	os.exit(1)
end

local code = file:read("*a")
file:close()

local minified = minify(code)

local result
if noWrap then
	result = minified
else
	local header = randomHeader()
	if antiTamper then
		result = wrapWithAntiTamper(header, minified)
	else
		result = header .. " return(function(...) " .. minified .. " end)(...)"
	end
end

if outputFile then
	local out = io.open(outputFile, "w")
	out:write(result)
	out:close()
	print("Output written to: " .. outputFile)
	if antiTamper then
		print("[ANTI-TAMPER] Protection enabled")
	end
else
	print(result)
end
