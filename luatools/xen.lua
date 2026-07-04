--[[     


XenSrc.lua

Synapse X


]]

local unpack = unpack or table.unpack
math.randomseed(os.time())
math.random(); math.random(); math.random()

local _bit32_bxor
if bit32 and bit32.bxor then
    _bit32_bxor = bit32.bxor
elseif bit and bit.bxor then
    _bit32_bxor = function(a, b)
        local r = bit.bxor(a, b)
        if r < 0 then r = r + 4294967296 end
        return r
    end
else
    _bit32_bxor = function(a, b)
        local r, m = 0, 1
        a = a % 4294967296
        b = b % 4294967296
        while a > 0 or b > 0 do
            if (a % 2) ~= (b % 2) then r = r + m end
            a = math.floor(a / 2)
            b = math.floor(b / 2)
            m = m * 2
        end
        return r
    end
end

local function bxor(a, b)
    return _bit32_bxor(a % 256, b % 256)
end

local XEN_PREFIX = "SynapseXen_"
local _usedNames = {}

local function xenName(minLen, maxLen)
    minLen = minLen or 8
    maxLen = maxLen or 16
    local charset = "lIIl"
    local name
    repeat
        local len = math.random(minLen, maxLen)
        local t = { "l" }
        for j = 2, len do
            local r = math.random(1, #charset)
            t[j] = charset:sub(r, r)
        end
        name = XEN_PREFIX .. table.concat(t)
    until not _usedNames[name]
    _usedNames[name] = true
    return name
end

local JOKES = {
    "synapse xen best obfuscator no cap",
    "luraph better then xen bros :pensive:",
    "hi my 2.5mb script doesn't work with xen please help",
    "aspect network better obfuscator",
    "xen best rerubi paste",
    "skisploit is the superior obfuscator, clearly.",
    "inb4 posted on exploit reports section",
    "wally bad bird",
    "HELP ME PEOPLE ARE CRASHING MY GAME PLZ HELP",
    "SYNAPSE XEN [S+ SCRIPT PROTECTION] [BETTER THEN LURAPH] [AMAZING] OMG OMG OMG !!!!!!",
    "wait for someone on devforum to say they are gonna deobfuscate this",
    "epic gamer vision",
    "baby i just fell for uwu",
    "xen doesn't work on sk8r please help",
    "yed",
    "i put more time into this shitty list of dead memes then i did into the obfuscator itself",
}

local function randJoke() return JOKES[math.random(1, #JOKES)] end

local function cacheKey()
        return math.random(100000000, 999999999)
end

local function vmHash()
    local seed = tostring(os.time()) .. tostring(math.random())
    local h = 2166136261
    for i = 1, #seed do
        h = bxor(h, seed:byte(i))
        h = (h * 16777619) % 4294967296
    end
    local r = math.random(0, 2147483647)
    return string.format("%016x%016x", h, r)
end

local function makeParamNames()
    local PN = {
        Stk      = xenName(4, 8),
        K        = xenName(4, 8),
        I        = xenName(4, 8),
        P        = xenName(4, 8),
        A        = xenName(4, 8),
        B        = xenName(4, 8),
        C_       = xenName(4, 8),
        proto    = xenName(4, 8),
        PC       = xenName(4, 8),
        capSlots = xenName(4, 8),
        capC     = xenName(4, 8),
        Varg     = xenName(4, 8),
        env      = xenName(4, 8),
    }

    local sig = table.concat({
        PN.Stk, PN.K, PN.I, PN.P, PN.A, PN.B,
        PN.C_, PN.proto, PN.PC, PN.capSlots,
        PN.capC, PN.Varg, PN.env,
    }, ",")

        local subOrder = {
        { "capSlots", PN.capSlots },
        { "capC",     PN.capC     },
        { "proto",    PN.proto    },
        { "Varg",     PN.Varg     },
        { "Stk",      PN.Stk      },
        { "env",      PN.env      },
        { "C_",       PN.C_       },
        { "PC",       PN.PC       },
        { "K",        PN.K        },
        { "I",        PN.I        },
        { "P",        PN.P        },
        { "A",        PN.A        },
        { "B",        PN.B        },
    }

    local function applyPN(body)
        for _, pair in ipairs(subOrder) do
            body = body:gsub("%f[%w_]" .. pair[1] .. "%f[^%w_]", pair[2])
        end
        return body
    end

    return PN, sig, applyPN
end

local RESERVED = {
    ["if"]=true,["then"]=true,["else"]=true,["elseif"]=true,["end"]=true,
    ["for"]=true,["while"]=true,["do"]=true,["repeat"]=true,["until"]=true,
    ["function"]=true,["local"]=true,["return"]=true,["break"]=true,
    ["and"]=true,["or"]=true,["not"]=true,["in"]=true,["nil"]=true,
    ["true"]=true,["false"]=true,["continue"]=true,
}

local function tokenize(src)
    local tokens = {}
    local i, n = 1, #src
    while i <= n do
        local c = src:sub(i, i)
        if c == "[" then
            local j, eq = i + 1, 0
            while src:sub(j, j) == "=" do eq = eq + 1; j = j + 1 end
            if src:sub(j, j) == "[" then
                local close = "]" .. string.rep("=", eq) .. "]"
                local s = j + 1
                local e = src:find(close, s, true)
                if e then
                    tokens[#tokens+1] = { kind="longstring", text=src:sub(i, e+#close-1) }
                    i = e + #close
                else
                    tokens[#tokens+1] = { kind="other", text=c }; i = i + 1
                end
            else
                tokens[#tokens+1] = { kind="other", text=c }; i = i + 1
            end
        elseif c == "-" and src:sub(i, i+1) == "--" then
            local j, eq, isLong = i+2, 0, false
            if src:sub(j, j) == "[" then
                j = j + 1
                while src:sub(j, j) == "=" do eq=eq+1; j=j+1 end
                if src:sub(j, j) == "[" then isLong = true end
            end
            if isLong then
                local close = "]" .. string.rep("=", eq) .. "]"
                local e = src:find(close, j+1, true)
                local raw = e and src:sub(i, e+#close-1) or src:sub(i)
                tokens[#tokens+1] = { kind="longcomment", text=raw }
                i = e and (e+#close) or (n+1)
            else
                local e = src:find("\n", i, true)
                tokens[#tokens+1] = { kind="comment", text=(e and src:sub(i,e-1) or src:sub(i)) }
                i = e and e or (n+1)
            end
        elseif c == '"' or c == "'" then
            local delim, j, buf = c, i+1, {c}
            while j <= n do
                local ch = src:sub(j, j)
                if ch == "\\" then buf[#buf+1]=src:sub(j,j+1); j=j+2
                elseif ch == delim then buf[#buf+1]=ch; j=j+1; break
                else buf[#buf+1]=ch; j=j+1 end
            end
            tokens[#tokens+1] = { kind="string", text=table.concat(buf) }
            i = j
        elseif c:match("[%a_]") then
            local j = i
            while j <= n and src:sub(j,j):match("[%w_]") do j=j+1 end
            local word = src:sub(i, j-1)
            tokens[#tokens+1] = { kind=(RESERVED[word] and "other" or "name"), text=word }
            i = j
        elseif c:match("%d") or (c=="." and src:sub(i+1,i+1):match("%d")) then
            local j = i
            if src:sub(j, j+1):lower() == "0x" then
                j = j + 2
                while j<=n and src:sub(j,j):match("[%x]") do j=j+1 end
            else
                while j<=n and src:sub(j,j):match("[%d]") do j=j+1 end
                if j<=n and src:sub(j,j)=="." then
                    j=j+1
                    while j<=n and src:sub(j,j):match("[%d]") do j=j+1 end
                end
                if j<=n and src:sub(j,j):lower()=="e" then
                    j=j+1
                    if j<=n and src:sub(j,j):match("[%+%-]") then j=j+1 end
                    while j<=n and src:sub(j,j):match("[%d]") do j=j+1 end
                end
            end
            tokens[#tokens+1] = { kind="other", text=src:sub(i,j-1) }
            i = j
        elseif c == "\n" or c == "\r" or c == " " or c == "\t" then
                        local j = i
            while j<=n and src:sub(j,j):match("[ \t\r\n]") do j=j+1 end
            tokens[#tokens+1] = { kind="ws", text=" " }
            i = j
        else
            tokens[#tokens+1] = { kind="other", text=c }
            i = i + 1
        end
    end
    return tokens
end

local function renameVariables(code)
    local tokens  = tokenize(code)
    local nameMap = {}
    local used    = {}

    local function genUnique()
        local name
        repeat name = xenName(6, 14) until not used[name] and not RESERVED[name]
        used[name] = true
        return name
    end

    local function markLocal(text)
        if text and not RESERVED[text] and not nameMap[text] then
            nameMap[text] = genUnique()
        end
    end

    local function skipWS(toks, j)
        while j <= #toks and (toks[j].kind == "ws") do j = j + 1 end
        return j
    end

    local nt = #tokens
    local i = 1
    while i <= nt do
        local tok = tokens[i]
                if tok.kind == "other" and tok.text == "local" then
            local j = skipWS(tokens, i+1)
            if j <= nt and tokens[j].kind == "other" and tokens[j].text == "function" then
                j = skipWS(tokens, j+1)
                if j <= nt and tokens[j].kind == "name" then
                    markLocal(tokens[j].text)
                end
                i = j + 1
            else
                while j <= nt do
                    local t = tokens[j]
                    if t.kind == "name" then markLocal(t.text); j = j + 1
                    elseif t.kind == "other" and t.text == "," then j = j + 1
                    elseif t.kind == "ws" then j = j + 1
                    else break end
                end
                i = j
            end
                elseif tok.kind == "other" and tok.text == "for" then
            local j = skipWS(tokens, i+1)
            while j <= nt do
                local t = tokens[j]
                if t.kind == "name" then markLocal(t.text); j = j + 1
                elseif t.kind == "other" and t.text == "," then j = j + 1
                elseif t.kind == "ws" then j = j + 1
                else break end
            end
            i = j + 1
                elseif tok.kind == "other" and tok.text == "function" then
            local j = skipWS(tokens, i+1)
                        while j <= nt and tokens[j].kind ~= "other" do j = j + 1 end
                        if j <= nt and tokens[j].text == "(" then
                j = skipWS(tokens, j+1)
                while j <= nt and tokens[j].text ~= ")" do
                    local t = tokens[j]
                    if t.kind == "name" then markLocal(t.text); j = j + 1
                    elseif t.kind == "other" and (t.text == "," or t.text == "...") then j = j + 1
                    elseif t.kind == "ws" then j = j + 1
                    else j = j + 1 end
                end
            end
            i = j + 1
        else
            i = i + 1
        end
    end

        local out = {}
    for _, tok in ipairs(tokens) do
        if tok.kind == "comment" or tok.kind == "longcomment" then
                    elseif tok.kind == "name" and nameMap[tok.text] then
            out[#out+1] = nameMap[tok.text]
        else
            out[#out+1] = tok.text
        end
    end
    return table.concat(out)
end

local function b36(n)
    if n == 0 then return "0" end
    local C = "0123456789abcdefghijklmnopqrstuvwxyz"
    local s = ""
    while n > 0 do
        s = C:sub(n%36+1, n%36+1) .. s
        n = math.floor(n / 36)
    end
    return s
end

local function eCode(n)
    local s = b36(n)
    return b36(#s) .. s
end

local function lzw(inp)
    local d, ds = {}, 256
    for i = 0, 255 do d[string.char(i)] = i end
    local w, o = "", {}
    for i = 1, #inp do
        local c = inp:sub(i, i)
        local wc = w .. c
        if d[wc] then
            w = wc
        else
            o[#o+1] = eCode(d[w])
            d[wc] = ds; ds = ds + 1
            w = c
        end
    end
    if w ~= "" then o[#o+1] = eCode(d[w]) end
    return table.concat(o)
end

local function xorEncode(s, key)
    local t = {}
    for i = 1, #s do
        t[i] = string.format("%02x", bxor(s:byte(i), key))
    end
    return table.concat(t)
end

local function longStr(s)
    local lv = 0
    while s:find("]" .. string.rep("=", lv) .. "]", 1, true) do lv = lv + 1 end
    local eq = string.rep("=", lv)
    return "[" .. eq .. "[" .. s .. "]" .. eq .. "]"
end

local ISA = {}
ISA.OP = {
    LOADNIL=0,LOADBOOL=1,LOADINT=2,LOADFLOAT=3,LOADSTR=4,
    MOVE=5,GETGLOBAL=6,SETGLOBAL=7,GETTABLE=8,SETTABLE=9,
    NEWTABLE=10,ADD=11,SUB=12,MUL=13,DIV=14,MOD=15,POW=16,
    CONCAT=17,LT=18,LE=19,EQ=20,NE=21,GT=22,GE=23,NOT=24,
    UNM=25,LEN=26,CALL=27,CALLM=28,VCALL=29,JMP=30,
    JMPT=31,JMPF=32,RETURN=33,RETURNM=34,ALLOC_UPVAL=35,
    GET_UPVAL=36,SET_UPVAL=37,FREE_UPVAL=38,CLOSURE=39,VARARG=40,
        EXEC=41,
}
ISA.OP_COUNT = 42

function ISA.makeOpcodeMap()
    local pool = {}
    for i = 0, ISA.OP_COUNT - 1 do pool[i+1] = i end
    for i = ISA.OP_COUNT, 2, -1 do
        local j = math.random(1, i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    local enc, dec = {}, {}
    for canon = 0, ISA.OP_COUNT - 1 do
        local wire = pool[canon+1]
        enc[canon] = wire
        dec[wire]  = canon
    end
    return enc, dec
end

function ISA.makeXorStream(seed)
    local s = seed % 4294967296
    return function()
        s = (s * 1664525 + 1013904223) % 4294967296
        return s % 256
    end
end

local function buildVM(xorSeed, decodeMap)
    local PN, handlerSig, applyPN = makeParamNames()

    local N = {
        sb   = xenName(), ss   = xenName(), fl  = xenName(),
        up   = xenName(), xs   = xenName(), dm  = xenName(),
        bx   = xenName(), mkS  = xenName(), pSd = xenName(),
        ds   = xenName(), ex   = xenName(), dt  = xenName(),
        CC   = xenName(), lzw  = xenName(), hx  = xenName(),
    }

    local dmParts = {}
    for wire, canon in pairs(decodeMap) do
        dmParts[#dmParts+1] = "[" .. wire .. "]=" .. canon
    end
    local dmLit  = "{" .. table.concat(dmParts, ",") .. "}"
    local ckXS   = cacheKey()

    local parts = {}
    local function s(...)
        for _, v in ipairs({...}) do parts[#parts+1] = v .. ";" end
    end

        s(
        "local " .. N.sb  .. "=string.byte",
        "local " .. N.ss  .. "=string.sub",
        "local " .. N.fl  .. "=math.floor",
        "local " .. N.up  .. "=unpack or table.unpack",
        "local " .. N.CC  .. "={}"
    )

        local function cached(key, val)
        return N.CC.."["..key.."]="..N.CC.."["..key.."] or "
            .."(function() local "..xenName(4,8)..'="'..randJoke()..'"'..
            ";"..N.CC.."["..key.."]="..val..";return "..N.CC.."["..key.."] end)()"
    end
    s(
        cached(ckXS, tostring(xorSeed)),
        "local " .. N.xs .. "=" .. N.CC .. "[" .. ckXS .. "]",
        "local " .. N.dm .. "=" .. dmLit
    )

        s(
        "local " .. N.bx,
        "if bit and bit.bxor then "
            ..N.bx.."=function(a,b) local r=bit.bxor(a,b);if r<0 then r=r+4294967296 end;return r%256 end "
            .."elseif bit32 and bit32.bxor then "
            ..N.bx.."=function(a,b) return bit32.bxor(a,b)%256 end "
            .."else "
            ..N.bx.."=function(a,b) local r,m=0,1;while a>0 or b>0 do "
            .."local ra,rb=a%2,b%2;if ra~=rb then r=r+m end;"
            .."a="..N.fl.."(a/2);b="..N.fl.."(b/2);m=m*2 end;return r%256 end end"
    )

        s("local function "..N.mkS.."(seed) "
        .."local s=seed%4294967296;"
        .."return function() s=(s*1664525+1013904223)%4294967296;return s%256 end end")

        s("local function "..N.pSd.."(depth) "
        .."local lo="..N.bx.."("..N.xs.."%256,("..N.fl.."(depth*0x9E))%256);"
        .."return (lo+"..N.fl.."("..N.xs.."/256)*256)%4294967296 end")

        s("local function "..N.lzw.."(b) "
        .."local c,d,e,f,g='','',{},256,{};"
        .."for h=0,255 do g[h]=string.char(h) end;"
        .."local i=1;"
        .."local function k() "
        .."local l=tonumber("..N.ss.."(b,i,i),36);i=i+1;"
        .."local m=tonumber("..N.ss.."(b,i,i+l-1),36);i=i+l;return m end;"
        .."c=string.char(k());e[1]=c;"
        .."while i<=#b do local n=k();"
        .."if g[n] then d=g[n] else d=c.."..N.ss.."(c,1,1) end;"
        .."g[f]=c.."..N.ss.."(d,1,1);e[#e+1],c,f=d,d,f+1 end;"
        .."return table.concat(e) end")

        s("local function "..N.hx.."(h,key) "
        .."local t={};for i=1,#h,2 do "
        .."local v=tonumber("..N.ss.."(h,i,i+1),16);"
        .."t[#t+1]=string.char("..N.bx.."(v,key)) end;"
        .."return table.concat(t) end")

        s(
        "local " .. N.ds,
        N.ds .. "=function(blob) "
            .."local pos=1;"
            .."local function rb() local v="..N.sb.."(blob,pos);pos=pos+1;return v end;"
            .."local function r2() return rb()*256+rb() end;"
            .."local function rC(cidx) local t=rb();"
            .."if t==0 then return nil "
            .."elseif t==1 then return rb()~=0 "
            .."elseif t==2 then local a,b,c,d=rb(),rb(),rb(),rb();"
            .."local v=a*16777216+b*65536+c*256+d;"
            .."if v>=2147483648 then v=v-4294967296 end;return v "
            .."elseif t==3 then local bs={};for _=1,8 do bs[#bs+1]=rb() end;"
            .."local lo=bs[1]+bs[2]*256+bs[3]*65536+bs[4]*16777216;"
            .."local hi=bs[5]+bs[6]*256+bs[7]*65536+bs[8]*16777216;"
            .."if lo==0 and hi==0 then return 0 end;"
            .."local sg="..N.fl.."(hi/2147483648);"
            .."local ex="..N.fl.."(hi/1048576)%2048;"
            .."local mh=hi%1048576;"
            .."return((-1)^sg)*(2^(ex-1023))*((mh*4294967296+lo)/(2^52)+1) "
            .."elseif t==4 then local ckey=rb();local ln2=r2();local sc={};"
            .."for _i=1,ln2 do sc[_i]=string.char("..N.bx.."(rb(),ckey)) end;"
            .."return table.concat(sc) end end;"
            .."local function rP(depth) "
            .."local p={pa=rb(),va=rb()~=0,mr=rb(),K={},I={},P={}};"
            .."local nc=r2();for i=1,nc do p.K[i]=rC(i) end;"
            .."local ni=r2();"
            .."local st="..N.mkS.."("..N.pSd.."(depth));"
            .."for i=1,ni do "
            .."local s1,s2,s3,s4,s5,s6=st(),st(),st(),st(),st(),st();"
            .."local b1="..N.bx.."("..N.sb.."(blob,pos),s1);"
            .."local b2="..N.bx.."("..N.sb.."(blob,pos+1),s2);"
            .."local b3="..N.bx.."("..N.sb.."(blob,pos+2),s3);"
            .."local b4="..N.bx.."("..N.sb.."(blob,pos+3),s4);"
            .."local b5="..N.bx.."("..N.sb.."(blob,pos+4),s5);"
            .."local b6="..N.bx.."("..N.sb.."(blob,pos+5),s6);"
            .."pos=pos+6;"
            .."p.I[i]={"..N.dm.."[b1] or b1,b2,b3*256+b4,b5*256+b6} end;"
            .."local np=rb();for i=1,np do p.P[i]=rP(depth+1) end;"
            .."return p end;"
            .."return rP(0) end"
    )

    local exN = N.ex

    local handlers = {
        { ISA.OP.LOADNIL,    applyPN("Stk[A]=nil") },
        { ISA.OP.LOADBOOL,   applyPN("Stk[A]=(B~=0)") },
        { ISA.OP.LOADINT,    applyPN("local v=B*65536+C_;if v>=2147483648 then v=v-4294967296 end;Stk[A]=v") },
        { ISA.OP.LOADFLOAT,  applyPN("Stk[A]=K[B+1]") },
        { ISA.OP.LOADSTR,    applyPN("Stk[A]=K[B+1]") },
        { ISA.OP.MOVE,       applyPN("Stk[A]=Stk[B]") },
        { ISA.OP.GETGLOBAL,  applyPN("Stk[A]=env[K[B+1]]") },
        { ISA.OP.SETGLOBAL,  applyPN("env[K[B+1]]=Stk[A]") },
        { ISA.OP.GETTABLE,   applyPN("Stk[A]=Stk[B][Stk[C_]]") },
        { ISA.OP.SETTABLE,   applyPN("Stk[A][Stk[B]]=Stk[C_]") },
        { ISA.OP.NEWTABLE,   applyPN("Stk[A]={}") },
        { ISA.OP.ADD,        applyPN("Stk[A]=Stk[B]+Stk[C_]") },
        { ISA.OP.SUB,        applyPN("Stk[A]=Stk[B]-Stk[C_]") },
        { ISA.OP.MUL,        applyPN("Stk[A]=Stk[B]*Stk[C_]") },
        { ISA.OP.DIV,        applyPN("Stk[A]=Stk[B]/Stk[C_]") },
        { ISA.OP.MOD,        applyPN("Stk[A]=Stk[B]%Stk[C_]") },
        { ISA.OP.POW,        applyPN("Stk[A]=Stk[B]^Stk[C_]") },
        { ISA.OP.CONCAT,     applyPN("Stk[A]=Stk[B]..Stk[C_]") },
        { ISA.OP.LT,         applyPN("Stk[A]=Stk[B]<Stk[C_]") },
        { ISA.OP.LE,         applyPN("Stk[A]=Stk[B]<=Stk[C_]") },
        { ISA.OP.EQ,         applyPN("Stk[A]=Stk[B]==Stk[C_]") },
        { ISA.OP.NE,         applyPN("Stk[A]=(Stk[B]~=Stk[C_])") },
        { ISA.OP.GT,         applyPN("Stk[A]=Stk[B]>Stk[C_]") },
        { ISA.OP.GE,         applyPN("Stk[A]=Stk[B]>=Stk[C_]") },
        { ISA.OP.NOT,        applyPN("Stk[A]=not Stk[B]") },
        { ISA.OP.UNM,        applyPN("Stk[A]=-Stk[B]") },
        { ISA.OP.LEN,        applyPN("Stk[A]=#Stk[B]") },
        {
            ISA.OP.CALL,
            applyPN(
                "local fn=Stk[A];local ca={};"
                .."if B==0 then local _t=Stk[A+1];"
                .."if type(_t)=='table' then for _i=1,#_t do ca[_i]=_t[_i] end "
                .."elseif _t~=nil then ca[1]=_t end "
                .."else for i=1,B do ca[i]=Stk[A+i] end end;"
                .."local _cn=#ca;if _cn>200 then _cn=200 end;"
                .."local res={fn("..N.up.."(ca,1,_cn))};"
                .."if C_==0 then for i=1,#res do Stk[A+i-1]=res[i] end "
                .."else for i=1,C_ do Stk[A+i-1]=res[i] end end"
            ),
        },
        {
            ISA.OP.CALLM,
            applyPN(
                "local fn=Stk[A];local ca={};"
                .."for i=1,B do ca[i]=Stk[A+i] end;"
                .."local _cn=#ca;if _cn>200 then _cn=200 end;"
                .."local res={fn("..N.up.."(ca,1,_cn))};Stk[A]=res"
            ),
        },
        {
            ISA.OP.VCALL,
            applyPN(
                "local fn=Stk[A];local ca={};"
                .."if B==0 then local _t=Stk[A+1];"
                .."if type(_t)=='table' then for _i=1,#_t do ca[_i]=_t[_i] end "
                .."elseif _t~=nil then ca[1]=_t end "
                .."else for i=1,B do ca[i]=Stk[A+i] end end;"
                .."local _cn=#ca;if _cn>200 then _cn=200 end;"
                .."fn("..N.up.."(ca,1,_cn))"
            ),
        },
        { ISA.OP.JMP,    applyPN("return B,nil,nil,nil,nil") },
        { ISA.OP.JMPT,   applyPN("if Stk[A] then return B,nil,nil,nil,nil end") },
        { ISA.OP.JMPF,   applyPN("if not Stk[A] then return B,nil,nil,nil,nil end") },
        {
            ISA.OP.RETURN,
            applyPN(
                "local rv2,rm2;"
                .."if B==1 then rv2=nil;rm2=false "
                .."elseif B==0 then local rv={};local i=A;"
                .."while i<=proto.mr and Stk[i]~=nil do rv[#rv+1]=Stk[i];i=i+1 end;"
                .."rv2=rv;rm2=true "
                .."else local rv={};for i=A,A+B-2 do rv[#rv+1]=Stk[i] end;"
                .."rv2=rv;rm2=(#rv>1) end;"
                .."return nil,false,rv2,rm2,nil"
            ),
        },
        {
            ISA.OP.RETURNM,
            applyPN("local rv=type(Stk[A])=='table' and Stk[A] or {Stk[A]};return nil,false,rv,true,nil"),
        },
        {
            ISA.OP.ALLOC_UPVAL,
            applyPN("capC=capC+1;capSlots[capC]={v=Stk[A]};Stk[A]=capC;return nil,nil,nil,nil,capC"),
        },
        {
            ISA.OP.GET_UPVAL,
            applyPN("local _sid=Stk[B];local _sl=type(_sid)=='number' and capSlots[_sid];Stk[A]=_sl and _sl.v or nil"),
        },
        {
            ISA.OP.SET_UPVAL,
            applyPN("local _sid=Stk[A];local _sl=type(_sid)=='number' and capSlots[_sid];if _sl then _sl.v=Stk[B] end"),
        },
        { ISA.OP.FREE_UPVAL, "" },
        {
            ISA.OP.CLOSURE,
            applyPN(
                "local subP=P[B+1];local childCap={};local nPC=PC;"
                .."for _ci=1,C_ do local capInst=I[nPC];nPC=nPC+1;"
                .."local parentReg=capInst[3];local parentVal=Stk[parentReg];"
                .."if type(parentVal)=='number' and capSlots[parentVal] then "
                .."childCap[_ci]=capSlots[parentVal] "
                .."else childCap[_ci]={v=parentVal} end end;"
                .."Stk[A]="..exN.."(subP,childCap,env);return nPC,nil,nil,nil,nil"
            ),
        },
        {
            ISA.OP.VARARG,
            applyPN("if B==0 then Stk[A]={"..N.up.."(Varg,1,#Varg)} "
                .."else for i=1,B-1 do Stk[A+i-1]=Varg[i] end end"),
        },

        {
            ISA.OP.EXEC,
            applyPN(
                "local _src=K[B+1];"
                .."local _fn=loadstring and loadstring(_src) or load(_src);"
                .."if not _fn then Stk[A]=nil else Stk[A]=_fn end"
            ),
        },
    }

        for i = #handlers, 2, -1 do
        local j = math.random(1, i)
        handlers[i], handlers[j] = handlers[j], handlers[i]
    end

        local junkBodies = {
        applyPN("local " .. xenName(4,6) .. "=Stk[A]"),
        applyPN("local " .. xenName(4,6) .. "=B+C_"),
        applyPN("local " .. xenName(4,6) .. "=A*B"),
        "",
    }
    for _ = 1, math.random(10, 22) do
        local fakeId = math.random(ISA.OP_COUNT, 254)
        local body   = junkBodies[math.random(1, #junkBodies)]
        if math.random() < 0.4 then
            local ck2 = cacheKey()
            body = (body ~= "" and body..";" or "")
                ..N.CC.."["..ck2.."]="..N.CC.."["..ck2.."] or "
                .."(function() local "..xenName(4,6)..'="'..randJoke()..'";'
                .."return "..tostring(math.random(1,9999)).." end)()"
        end
        table.insert(handlers, math.random(1, #handlers+1), { fakeId, body })
    end

        s("local " .. N.ex)
    s("local " .. N.dt .. "={}")
    for _, h in ipairs(handlers) do
        local body = h[2] or ""
        local oid  = tostring(h[1])
        if body == "" then
            s(N.dt.."["..oid.."]=function("..handlerSig..") end")
        else
            s(N.dt.."["..oid.."]=function("..handlerSig..") "..body.." end")
        end
    end

        s(
        N.ex.."=function("..PN.proto..","..PN.capSlots..","..PN.env..") "
            .."if not "..PN.proto.." then return function() end end;"
            .."local "..PN.K.."="..PN.proto..".K;"
            .."local "..PN.I.."="..PN.proto..".I;"
            .."local "..PN.P.."="..PN.proto..".P;"
            .."if not "..PN.capSlots.." then "..PN.capSlots.."={} end;"
            .."local "..PN.capC.."=0;"
            .."for k,_ in pairs("..PN.capSlots..") do if k>"..PN.capC.." then "..PN.capC.."=k end end;"
            .."return function(...) "
            .."local "..PN.Stk.."={};local args={...};"
            .."for i=0,"..PN.proto..".pa-1 do "..PN.Stk.."[i]=args[i+1] end;"
            .."local "..PN.Varg.."={};"
            .."if "..PN.proto..".va then for i="..PN.proto..".pa+1,#args do "
            ..PN.Varg.."[#"..PN.Varg.."+1]=args[i] end end;"
            .."local "..PN.PC.."=1;local running=true;local retVal=nil;local retMulti=false;"
            .."while running do "
            .."local inst="..PN.I.."["..PN.PC.."];if not inst then break end;"
            .."local op_=inst[1];local "..PN.A.."=inst[2];"
            .."local "..PN.B.."=inst[3];local "..PN.C_.."=inst[4];"
            ..PN.PC.."="..PN.PC.."+1;"
            .."local _h="..N.dt.."[op_];"
            .."if _h then "
            .."local r1,r2,r3,r4,r5=_h("
            ..PN.Stk..","..PN.K..","..PN.I..","..PN.P..","
            ..PN.A..","..PN.B..","..PN.C_..","..PN.proto..","
            ..PN.PC..","..PN.capSlots..","..PN.capC..","..PN.Varg..","..PN.env..");"
            .."if r1~=nil then "..PN.PC.."=r1 end;"
            .."if r2~=nil then running=r2 end;"
            .."if r3~=nil or r2==false then retVal=r3 end;"
            .."if r4~=nil then retMulti=r4 end;"
            .."if r5~=nil then "..PN.capC.."=r5 end "
            .."end "
            .."end;"
            .."if retMulti then local _rn=#retVal;"
            .."if _rn>200 then _rn=200 end;"
            .."return "..N.up.."(retVal,1,_rn) "
            .."elseif retVal~=nil then return retVal end "
            .."end "
            .."end"
    )

    return table.concat(parts, ""), N
end

function ISA.serialiseProto(proto, xorSeed, encOp, depth)
    depth = depth or 0
    local function protoSeed(d)
        local lo = bxor(xorSeed % 256, (math.floor(d * 0x9E)) % 256)
        return (lo + math.floor(xorSeed / 256) * 256) % 4294967296
    end
    local bytes = {}
    local function wb(v) bytes[#bytes+1] = string.char(v % 256) end
    local function w2(v) wb(math.floor(v/256)); wb(v%256) end
    local function w4(v)
        wb(math.floor(v/16777216)%256)
        wb(math.floor(v/65536)%256)
        wb(math.floor(v/256)%256)
        wb(v%256)
    end
    wb(proto.params or 0)
    wb(proto.is_vararg and 1 or 0)
    wb(proto.max_reg or 0)
    local consts = proto.consts or {}
    w2(#consts)
    for ci, v in ipairs(consts) do
        local t = type(v)
        if v == nil then
            wb(0)
        elseif t == "boolean" then
            wb(1); wb(v and 1 or 0)
        elseif t == "number" then
            if math.floor(v)==v and v>=-2147483648 and v<=2147483647 then
                wb(2)
                local nn = v<0 and (v+4294967296) or v
                w4(nn)
            else
                wb(3)
                local sign = v<0 and 1 or 0
                if v<0 then v=-v end
                local exp, frac = 0, 0
                if v == 0 then
                elseif v == math.huge then exp = 2047
                else
                    exp  = math.floor(math.log(v)/math.log(2))
                    frac = v/(2^exp)-1
                    exp  = exp+1023
                end
                local hi    = sign*2147483648 + exp*1048576 + math.floor(frac*1048576)
                local lo_f  = (frac*1048576-math.floor(frac*1048576))*4294967296
                local lo    = math.floor(lo_f)
                wb(lo%256); wb(math.floor(lo/256)%256)
                wb(math.floor(lo/65536)%256); wb(math.floor(lo/16777216)%256)
                wb(hi%256); wb(math.floor(hi/256)%256)
                wb(math.floor(hi/65536)%256); wb(math.floor(hi/16777216)%256)
            end
        elseif t == "string" then
            wb(4)
            local ckey = bxor(xorSeed%256, (ci*0x6B)%256)
            wb(ckey)
            w2(#v)
            for i = 1, #v do wb(bxor(v:byte(i), ckey)) end
        end
    end
    local instrs = proto.instrs or {}
    w2(#instrs)
    local st = ISA.makeXorStream(protoSeed(depth))
    for _, ins in ipairs(instrs) do
        local op   = ins[1]
        local a    = ins[2] or 0
        local b    = ins[3] or 0
        local c    = ins[4] or 0
        local wire = encOp and encOp[op] or op
        local bh, bl = math.floor(b/256), b%256
        local ch, cl = math.floor(c/256), c%256
        local s1,s2,s3,s4,s5,s6 = st(),st(),st(),st(),st(),st()
        wb(bxor(wire,s1)); wb(bxor(a,s2))
        wb(bxor(bh,s3));   wb(bxor(bl,s4))
        wb(bxor(ch,s5));   wb(bxor(cl,s6))
    end
    local protos = proto.protos or {}
    wb(#protos)
    for _, sub in ipairs(protos) do
        local subBytes = ISA.serialiseProto(sub, xorSeed, encOp, depth+1)
        for i = 1, #subBytes do bytes[#bytes+1] = subBytes:sub(i,i) end
    end
    return table.concat(bytes)
end

local function vmifySourceClean(src)
    local xorSeed     = math.random(1, 0x7FFFFFFF)
    local encOp, decOp = ISA.makeOpcodeMap()
    local blobKey     = math.random(1, 254)

        local compressed  = lzw(src)
    local encodedHex  = xorEncode(compressed, blobKey)
    local blobLit     = longStr(encodedHex)

        local vmCode, N = buildVM(xorSeed, decOp)

    local execOp   = tostring(ISA.OP.EXEC)
    local vcallOp  = tostring(ISA.OP.VCALL)
    local returnOp = tostring(ISA.OP.RETURN)
    local varargOp = tostring(ISA.OP.VARARG)

        local gfenvShim = "local getfenv=getfenv;if not getfenv then getfenv=function() return _ENV end end;"

    local srcN   = xenName()
    local protoN = xenName()
    local envN   = xenName()
    local fnN    = xenName()
    local vaN    = xenName()

    local bootstrap = gfenvShim
        .. "local " .. srcN   .. "=" .. N.lzw .. "(" .. N.hx .. "(" .. blobLit .. "," .. tostring(blobKey) .. "));"
        .. "local " .. protoN .. "={pa=0,va=true,mr=2,"
        ..   "K={" .. srcN .. "},"
        ..   "I={"
        ..     "{" .. execOp   .. ",0,0,0},"
        ..     "{" .. varargOp .. ",1,0,0},"
        ..     "{" .. vcallOp  .. ",0,0,0},"
        ..     "{" .. returnOp .. ",0,0,0}"
        ..   "},"
        ..   "P={}};"
        .. "local " .. envN .. "=getfenv and getfenv(1) or (function() return _ENV end)();"
        .. "local " .. fnN  .. "=" .. N.ex .. "(" .. protoN .. ",nil," .. envN .. ");"
        .. fnN .. "(...)"

    local header = "--[[\n    SynapseXen v2.0.0 \n    VM Hash: " .. vmHash() .. "\n]]\n\n"

    return header .. vmCode .. bootstrap
end

local M = {}

function M.obfuscate(source, opts)
    opts = opts or {}
    local doVm     = opts.VmifyBC ~= false
    local doRename = opts.VariableRenamer ~= false
    local doBC     = opts.BytecodeEncoder

    local code = source

    if doRename then
        code = renameVariables(code)
    end

    if doVm then
        local ok, result = pcall(vmifySourceClean, code)
        if ok then
            code = result
        else
            io.stderr:write("[XenGen] VmifyBC failed: " .. tostring(result) .. "\n")
            io.stderr:write("[XenGen] Falling back to BytecodeEncoder\n")
            doBC = true
        end
    end

    if doBC and not doVm then
                local offset = math.random(1, 255)
        local hex = {}
        for i = 1, #code do
            hex[i] = string.format("%02X", bxor(code:byte(i), offset))
        end
        local encoded = table.concat(hex)
        code = string.format(
            'local _e,_o,_d="%s",%d,{};'
            ..'for _i=1,#_e,2 do '
            ..'local _b=tonumber(_e:sub(_i,_i+1),16);'
            ..'_b=(_b %% 256 ~= _o) and _b or (function(a,b) '
            ..'local r,m=0,1;while a>0 or b>0 do '
            ..'if a%%2~=b%%2 then r=r+m end;'
            ..'a=math.floor(a/2);b=math.floor(b/2);m=m*2 end;return r end)(_b,_o);'
            ..'_d[#_d+1]=string.char(_b) end;'
            ..'(assert(loadstring and loadstring(table.concat(_d)) or load(table.concat(_d))))(...)',
            encoded, offset
        )
    end

    return code
end

if arg and arg[1] then
    local f = assert(io.open(arg[1], "r"))
    local source = f:read("*a")
    f:close()
    io.stderr:write("[XenGen] Processing: " .. arg[1] .. "\n")
    local result = M.obfuscate(source, { VmifyBC=true, VariableRenamer=true })
    local outFile = arg[2] or arg[1]:gsub("%.lua$", "_xen.lua")
    local out = assert(io.open(outFile, "w"))
    out:write(result)
    out:close()
    io.stderr:write("[XenGen] Done → " .. outFile .. "\n")
    io.stderr:write("[XenGen] Output size: " .. #result .. " bytes\n")
end

return M



--[[ 








                                                            ——            ——                                                            
                                                          ———ÞG          ————                                                          
                                                        —————GG          ——————G                                                       
                                                      ———————GG          ———————gG                                                     
                                                  —   {——————GG          ———————Gg                                                     
                                               ————gG {——————GG          ———————Gg    ———                                                
                                             ——————GG ———————GG          ———————gG   {————                                            
                                          —————————gG ———————GG          ———————gG   {——————                                           
                                       ————————————gG ———————GG          ———————Gg   ————————                                          
                                     ——————————————GG ————————GG        {———————Gg   —————————                                       
                                  —————————————————gG {————————ÞG      —————————gG   —————————    ————ü                                  
                                ———————————————————gG  —————————6g    {————————GgG   ——————————    ——————Ç                               
                                ——————————Çg———————GG   —————————íG  —————————gGG    {——————————   ——————ÞG                              
                                ———————zgGGg———————gG    {—————————G—————————gGG     {——————————   ——————ÞG                              
                                ——————6GG    GggGgGgG     G————————————————ígGG       ——————————   ——————ÞG                              
                                ——————üG                    ——————————————üGgG        ———————————  ——————ÞG                              
                                ———————————————————          ————————————ÞgG          ———————————— ——————ÞG                              
                                ———————————————————Gg         ——————————GGG           ———————————————————ÞG                              
                                ———————————————————GG          ————————Ggg            ———————————————————ÞG                              
                                ———————————————————gG           ———————GG             ———————————————————ÞG                              
                                GgGGGGgggGGg———————gG           ———————gG             ———————g———————————ÞG                              
                                            ———————GG           ———————gG             ———————G———————————ÞG                              
                                ——————ÞG    ———————gG           ———————gg             ———————GG——————————ÞG                              
                                ————————G   ———————gG           ———————Gg             ———————gg——————————Þg                              
                                ———————————Ç———————GG           ———————GG             ———————Gg —————————ÞG                              
                                ———————————————————gG           ———————gG             ———————GG  ———————üGG                              
                                GÞí————————————————gG           ———————gG             ———————gG   ———ÏGGGg                               
                                   GÞz—————————————GG           ———————Gg             ———————gG   —GGGGG                                 
                                      gGÇ——————————gG           ———————Gg             ———————Gg    ——                                     
                                         GGÇ———————gG           ———————gG             ———————Gg                                          
                                            GGÞ————GG           ———————gG             —————GgGg                                          
                                               GgG—gG           ———————GG             ——ÇgGGg                                            
                                                  ggg           ———————gG             GgGg                                               
                                                                ———————gG                                                              
                                                                ———————GG                                                              
                                                                ———————gG                                                              
                                                                ——————zGG                                                              
                                                                 g6—gGGG                                                               
                                                                    Gg                                                                 





]]
