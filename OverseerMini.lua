do
	local _zukSource = [=[
local function main()
	local ZukDecompile
	local prettyPrint
	local cleanOutput
	task.defer(function()
	local FLOAT_PRECISION = 7
	local Reader = {}
	function Reader.new(bytecode)
		local stream = buffer.fromstring(bytecode)
		local cursor = 0
		local blen   = buffer.len(stream)
		local self   = {}
		local function guard(n)
			if cursor + n > blen then
				error(string.format("Reader OOB: need %d byte(s) at offset %d (buf len %d)", n, cursor, blen), 2)
			end
		end
		function self:len()       return blen end
		function self:nextByte()
			guard(1); local r = buffer.readu8(stream, cursor); cursor += 1; return r
		end
		function self:nextSignedByte()
			guard(1); local r = buffer.readi8(stream, cursor); cursor += 1; return r
		end
		function self:nextBytes(count)
			local t = {}
			for i = 1, count do t[i] = self:nextByte() end
			return t
		end
		function self:nextChar()     return string.char(self:nextByte()) end
		function self:nextUInt32()
			guard(4); local r = buffer.readu32(stream, cursor); cursor += 4; return r
		end
		function self:nextInt32()
			guard(4); local r = buffer.readi32(stream, cursor); cursor += 4; return r
		end
		function self:nextFloat()
			guard(4); local r = buffer.readf32(stream, cursor); cursor += 4
			return tonumber(string.format("%0."..FLOAT_PRECISION.."f", r))
		end
		function self:nextVarInt()
			local result = 0
			for i = 0, 4 do
				local b = self:nextByte()
				result = bit32.bor(result, bit32.lshift(bit32.band(b, 0x7F), i * 7))
				if not bit32.btest(b, 0x80) then break end
			end
			return result
		end
		function self:nextString(slen)
			slen = slen or self:nextVarInt()
			if slen == 0 then return "" end
			guard(slen)
			local r = buffer.readstring(stream, cursor, slen); cursor += slen; return r
		end
		function self:nextDouble()
			guard(8); local r = buffer.readf64(stream, cursor); cursor += 8; return r
		end
		return self
	end
	function Reader:Set(fp) FLOAT_PRECISION = fp end
	local Strings = {
		SUCCESS              = "%s",
		TIMEOUT              = "-- DECOMPILER TIMEOUT",
		COMPILATION_FAILURE  = "-- SCRIPT FAILED TO COMPILE, ERROR:\n%s",
		UNSUPPORTED_LBC_VERSION = "-- BYTECODE VERSION %d IS NOT SUPPORTED (EXPECTED %d-%d)",
		USED_GLOBALS         = "-- USED GLOBALS: %s.\n",
		DECOMPILER_REMARK    = "-- DECOMPILER REMARK: %s\n",
	}
	local CASE_MULTIPLIER = 227
	local Luau = {
		OpCode = {
			{name="NOP",type="none"},{name="BREAK",type="none"},
			{name="LOADNIL",type="A"},{name="LOADB",type="ABC"},
			{name="LOADN",type="AsD"},{name="LOADK",type="AD"},
			{name="MOVE",type="AB"},
			{name="GETGLOBAL",type="AC",aux=true},{name="SETGLOBAL",type="AC",aux=true},
			{name="GETUPVAL",type="AB"},{name="SETUPVAL",type="AB"},
			{name="CLOSEUPVALS",type="A"},
			{name="GETIMPORT",type="AD",aux=true},
			{name="GETTABLE",type="ABC"},{name="SETTABLE",type="ABC"},
			{name="GETTABLEKS",type="ABC",aux=true},{name="SETTABLEKS",type="ABC",aux=true},
			{name="GETTABLEN",type="ABC"},{name="SETTABLEN",type="ABC"},
			{name="NEWCLOSURE",type="AD"},{name="NAMECALL",type="ABC",aux=true},
			{name="CALL",type="ABC"},{name="RETURN",type="AB"},
			{name="JUMP",type="sD"},{name="JUMPBACK",type="sD"},
			{name="JUMPIF",type="AsD"},{name="JUMPIFNOT",type="AsD"},
			{name="JUMPIFEQ",type="AsD",aux=true},{name="JUMPIFLE",type="AsD",aux=true},
			{name="JUMPIFLT",type="AsD",aux=true},{name="JUMPIFNOTEQ",type="AsD",aux=true},
			{name="JUMPIFNOTLE",type="AsD",aux=true},{name="JUMPIFNOTLT",type="AsD",aux=true},
			{name="ADD",type="ABC"},{name="SUB",type="ABC"},{name="MUL",type="ABC"},
			{name="DIV",type="ABC"},{name="MOD",type="ABC"},{name="POW",type="ABC"},
			{name="ADDK",type="ABC"},{name="SUBK",type="ABC"},{name="MULK",type="ABC"},
			{name="DIVK",type="ABC"},{name="MODK",type="ABC"},{name="POWK",type="ABC"},
			{name="AND",type="ABC"},{name="OR",type="ABC"},
			{name="ANDK",type="ABC"},{name="ORK",type="ABC"},
			{name="CONCAT",type="ABC"},
			{name="NOT",type="AB"},{name="MINUS",type="AB"},{name="LENGTH",type="AB"},
			{name="NEWTABLE",type="AB",aux=true},{name="DUPTABLE",type="AD"},
			{name="SETLIST",type="ABC",aux=true},
			{name="FORNPREP",type="AsD"},{name="FORNLOOP",type="AsD"},
			{name="FORGLOOP",type="AsD",aux=true},
			{name="FORGPREP_INEXT",type="A"},
			{name="FASTCALL3",type="ABC",aux=true},
			{name="FORGPREP_NEXT",type="A"},{name="NATIVECALL",type="none"},
			{name="GETVARARGS",type="AB"},{name="DUPCLOSURE",type="AD"},
			{name="PREPVARARGS",type="A"},{name="LOADKX",type="A",aux=true},
			{name="JUMPX",type="E"},{name="FASTCALL",type="AC"},
			{name="COVERAGE",type="E"},{name="CAPTURE",type="AB"},
			{name="SUBRK",type="ABC"},{name="DIVRK",type="ABC"},
			{name="FASTCALL1",type="ABC"},
			{name="FASTCALL2",type="ABC",aux=true},{name="FASTCALL2K",type="ABC",aux=true},
			{name="FORGPREP",type="AsD"},
			{name="JUMPXEQKNIL",type="AsD",aux=true},{name="JUMPXEQKB",type="AsD",aux=true},
			{name="JUMPXEQKN",type="AsD",aux=true},{name="JUMPXEQKS",type="AsD",aux=true},
			{name="IDIV",type="ABC"},{name="IDIVK",type="ABC"},
			{name="_COUNT",type="none"},
		},
		BytecodeTag = {
			LBC_VERSION_MIN=1, LBC_VERSION_MAX=6,
			LBC_TYPE_VERSION_MIN=1, LBC_TYPE_VERSION_MAX=3,
			LBC_CONSTANT_NIL=0, LBC_CONSTANT_BOOLEAN=1, LBC_CONSTANT_NUMBER=2,
			LBC_CONSTANT_STRING=3, LBC_CONSTANT_IMPORT=4, LBC_CONSTANT_TABLE=5,
			LBC_CONSTANT_CLOSURE=6, LBC_CONSTANT_VECTOR=7,
		},
		BytecodeType = {
			LBC_TYPE_NIL=0,LBC_TYPE_BOOLEAN=1,LBC_TYPE_NUMBER=2,LBC_TYPE_STRING=3,
			LBC_TYPE_TABLE=4,LBC_TYPE_FUNCTION=5,LBC_TYPE_THREAD=6,LBC_TYPE_USERDATA=7,
			LBC_TYPE_VECTOR=8,LBC_TYPE_BUFFER=9,LBC_TYPE_ANY=15,
			LBC_TYPE_TAGGED_USERDATA_BASE=64,LBC_TYPE_TAGGED_USERDATA_END=64+32,
			LBC_TYPE_OPTIONAL_BIT=bit32.lshift(1,7),LBC_TYPE_INVALID=256,
		},
		CaptureType  = {LCT_VAL=0,LCT_REF=1,LCT_UPVAL=2},
		BuiltinFunction = {
			LBF_NONE=0,LBF_ASSERT=1,LBF_MATH_ABS=2,LBF_MATH_ACOS=3,LBF_MATH_ASIN=4,
			LBF_MATH_ATAN2=5,LBF_MATH_ATAN=6,LBF_MATH_CEIL=7,LBF_MATH_COSH=8,
			LBF_MATH_COS=9,LBF_MATH_DEG=10,LBF_MATH_EXP=11,LBF_MATH_FLOOR=12,
			LBF_MATH_FMOD=13,LBF_MATH_FREXP=14,LBF_MATH_LDEXP=15,LBF_MATH_LOG10=16,
			LBF_MATH_LOG=17,LBF_MATH_MAX=18,LBF_MATH_MIN=19,LBF_MATH_MODF=20,
			LBF_MATH_POW=21,LBF_MATH_RAD=22,LBF_MATH_SINH=23,LBF_MATH_SIN=24,
			LBF_MATH_SQRT=25,LBF_MATH_TANH=26,LBF_MATH_TAN=27,
			LBF_BIT32_ARSHIFT=28,LBF_BIT32_BAND=29,LBF_BIT32_BNOT=30,LBF_BIT32_BOR=31,
			LBF_BIT32_BXOR=32,LBF_BIT32_BTEST=33,LBF_BIT32_EXTRACT=34,
			LBF_BIT32_LROTATE=35,LBF_BIT32_LSHIFT=36,LBF_BIT32_REPLACE=37,
			LBF_BIT32_RROTATE=38,LBF_BIT32_RSHIFT=39,LBF_TYPE=40,
			LBF_STRING_BYTE=41,LBF_STRING_CHAR=42,LBF_STRING_LEN=43,LBF_TYPEOF=44,
			LBF_STRING_SUB=45,LBF_MATH_CLAMP=46,LBF_MATH_SIGN=47,LBF_MATH_ROUND=48,
			LBF_RAWSET=49,LBF_RAWGET=50,LBF_RAWEQUAL=51,LBF_TABLE_INSERT=52,
			LBF_TABLE_UNPACK=53,LBF_VECTOR=54,LBF_BIT32_COUNTLZ=55,LBF_BIT32_COUNTRZ=56,
			LBF_SELECT_VARARG=57,LBF_RAWLEN=58,LBF_BIT32_EXTRACTK=59,
			LBF_GETMETATABLE=60,LBF_SETMETATABLE=61,LBF_TONUMBER=62,LBF_TOSTRING=63,
			LBF_BIT32_BYTESWAP=64,
			LBF_BUFFER_READI8=65,LBF_BUFFER_READU8=66,LBF_BUFFER_WRITEU8=67,
			LBF_BUFFER_READI16=68,LBF_BUFFER_READU16=69,LBF_BUFFER_WRITEU16=70,
			LBF_BUFFER_READI32=71,LBF_BUFFER_READU32=72,LBF_BUFFER_WRITEU32=73,
			LBF_BUFFER_READF32=74,LBF_BUFFER_WRITEF32=75,LBF_BUFFER_READF64=76,
			LBF_BUFFER_WRITEF64=77,
			LBF_VECTOR_MAGNITUDE=78,LBF_VECTOR_NORMALIZE=79,LBF_VECTOR_CROSS=80,
			LBF_VECTOR_DOT=81,LBF_VECTOR_FLOOR=82,LBF_VECTOR_CEIL=83,
			LBF_VECTOR_ABS=84,LBF_VECTOR_SIGN=85,LBF_VECTOR_CLAMP=86,
			LBF_VECTOR_MIN=87,LBF_VECTOR_MAX=88,
		},
		ProtoFlag = {
			LPF_NATIVE_MODULE  = bit32.lshift(1,0),
			LPF_NATIVE_COLD    = bit32.lshift(1,1),
			LPF_NATIVE_FUNCTION= bit32.lshift(1,2),
		},
	}
	function Luau:INSN_OP(i)  return bit32.band(i,0xFF) end
	function Luau:INSN_A(i)   return bit32.band(bit32.rshift(i,8),0xFF) end
	function Luau:INSN_B(i)   return bit32.band(bit32.rshift(i,16),0xFF) end
	function Luau:INSN_C(i)   return bit32.band(bit32.rshift(i,24),0xFF) end
	function Luau:INSN_D(i)   return bit32.rshift(i,16) end
	function Luau:INSN_sD(i)
		local D=self:INSN_D(i); return (D>0x7FFF and D<=0xFFFF) and (-(0xFFFF-D)-1) or D
	end
	function Luau:INSN_E(i)   return bit32.rshift(i,8) end
	function Luau:GetBaseTypeString(t, checkOpt)
		local BT=self.BytecodeType
		local tag=bit32.band(t,bit32.bnot(BT.LBC_TYPE_OPTIONAL_BIT))
		local names={[BT.LBC_TYPE_NIL]="nil",[BT.LBC_TYPE_BOOLEAN]="boolean",
			[BT.LBC_TYPE_NUMBER]="number",[BT.LBC_TYPE_STRING]="string",
			[BT.LBC_TYPE_TABLE]="table",[BT.LBC_TYPE_FUNCTION]="function",
			[BT.LBC_TYPE_THREAD]="thread",[BT.LBC_TYPE_USERDATA]="userdata",
			[BT.LBC_TYPE_VECTOR]="Vector3",[BT.LBC_TYPE_BUFFER]="buffer",
			[BT.LBC_TYPE_ANY]="any"}
		local r=names[tag] or "unknown"
		if checkOpt then
			r ..= (bit32.band(t,BT.LBC_TYPE_OPTIONAL_BIT)==0) and "" or "?"
		end
		return r
	end
	function Luau:GetBuiltinInfo(bfid)
		local BF=self.BuiltinFunction
		local map={
			[BF.LBF_NONE]="none",[BF.LBF_ASSERT]="assert",
			[BF.LBF_TYPE]="type",[BF.LBF_TYPEOF]="typeof",
			[BF.LBF_RAWSET]="rawset",[BF.LBF_RAWGET]="rawget",
			[BF.LBF_RAWEQUAL]="rawequal",[BF.LBF_RAWLEN]="rawlen",
			[BF.LBF_TABLE_UNPACK]="unpack",[BF.LBF_SELECT_VARARG]="select",
			[BF.LBF_GETMETATABLE]="getmetatable",[BF.LBF_SETMETATABLE]="setmetatable",
			[BF.LBF_TONUMBER]="tonumber",[BF.LBF_TOSTRING]="tostring",
			[BF.LBF_MATH_ABS]="math.abs",[BF.LBF_MATH_ACOS]="math.acos",
			[BF.LBF_MATH_ASIN]="math.asin",[BF.LBF_MATH_ATAN2]="math.atan2",
			[BF.LBF_MATH_ATAN]="math.atan",[BF.LBF_MATH_CEIL]="math.ceil",
			[BF.LBF_MATH_COSH]="math.cosh",[BF.LBF_MATH_COS]="math.cos",
			[BF.LBF_MATH_DEG]="math.deg",[BF.LBF_MATH_EXP]="math.exp",
			[BF.LBF_MATH_FLOOR]="math.floor",[BF.LBF_MATH_FMOD]="math.fmod",
			[BF.LBF_MATH_FREXP]="math.frexp",[BF.LBF_MATH_LDEXP]="math.ldexp",
			[BF.LBF_MATH_LOG10]="math.log10",[BF.LBF_MATH_LOG]="math.log",
			[BF.LBF_MATH_MAX]="math.max",[BF.LBF_MATH_MIN]="math.min",
			[BF.LBF_MATH_MODF]="math.modf",[BF.LBF_MATH_POW]="math.pow",
			[BF.LBF_MATH_RAD]="math.rad",[BF.LBF_MATH_SINH]="math.sinh",
			[BF.LBF_MATH_SIN]="math.sin",[BF.LBF_MATH_SQRT]="math.sqrt",
			[BF.LBF_MATH_TANH]="math.tanh",[BF.LBF_MATH_TAN]="math.tan",
			[BF.LBF_MATH_CLAMP]="math.clamp",[BF.LBF_MATH_SIGN]="math.sign",
			[BF.LBF_MATH_ROUND]="math.round",
			[BF.LBF_BIT32_ARSHIFT]="bit32.arshift",[BF.LBF_BIT32_BAND]="bit32.band",
			[BF.LBF_BIT32_BNOT]="bit32.bnot",[BF.LBF_BIT32_BOR]="bit32.bor",
			[BF.LBF_BIT32_BXOR]="bit32.bxor",[BF.LBF_BIT32_BTEST]="bit32.btest",
			[BF.LBF_BIT32_EXTRACT]="bit32.extract",[BF.LBF_BIT32_EXTRACTK]="bit32.extract",
			[BF.LBF_BIT32_LROTATE]="bit32.lrotate",[BF.LBF_BIT32_LSHIFT]="bit32.lshift",
			[BF.LBF_BIT32_REPLACE]="bit32.replace",[BF.LBF_BIT32_RROTATE]="bit32.rrotate",
			[BF.LBF_BIT32_RSHIFT]="bit32.rshift",[BF.LBF_BIT32_COUNTLZ]="bit32.countlz",
			[BF.LBF_BIT32_COUNTRZ]="bit32.countrz",[BF.LBF_BIT32_BYTESWAP]="bit32.byteswap",
			[BF.LBF_STRING_BYTE]="string.byte",[BF.LBF_STRING_CHAR]="string.char",
			[BF.LBF_STRING_LEN]="string.len",[BF.LBF_STRING_SUB]="string.sub",
			[BF.LBF_TABLE_INSERT]="table.insert",[BF.LBF_VECTOR]="Vector3.new",
			[BF.LBF_BUFFER_READI8]="buffer.readi8",[BF.LBF_BUFFER_READU8]="buffer.readu8",
			[BF.LBF_BUFFER_WRITEU8]="buffer.writeu8",[BF.LBF_BUFFER_READI16]="buffer.readi16",
			[BF.LBF_BUFFER_READU16]="buffer.readu16",[BF.LBF_BUFFER_WRITEU16]="buffer.writeu16",
			[BF.LBF_BUFFER_READI32]="buffer.readi32",[BF.LBF_BUFFER_READU32]="buffer.readu32",
			[BF.LBF_BUFFER_WRITEU32]="buffer.writeu32",[BF.LBF_BUFFER_READF32]="buffer.readf32",
			[BF.LBF_BUFFER_WRITEF32]="buffer.writef32",[BF.LBF_BUFFER_READF64]="buffer.readf64",
			[BF.LBF_BUFFER_WRITEF64]="buffer.writef64",
			[BF.LBF_VECTOR_MAGNITUDE]="vector.magnitude",[BF.LBF_VECTOR_NORMALIZE]="vector.normalize",
			[BF.LBF_VECTOR_CROSS]="vector.cross",[BF.LBF_VECTOR_DOT]="vector.dot",
			[BF.LBF_VECTOR_FLOOR]="vector.floor",[BF.LBF_VECTOR_CEIL]="vector.ceil",
			[BF.LBF_VECTOR_ABS]="vector.abs",[BF.LBF_VECTOR_SIGN]="vector.sign",
			[BF.LBF_VECTOR_CLAMP]="vector.clamp",[BF.LBF_VECTOR_MIN]="vector.min",
			[BF.LBF_VECTOR_MAX]="vector.max",
		}
		return map[bfid] or ("builtin#"..tostring(bfid))
	end
	do
		local raw = Luau.OpCode
		local encoded = {}
		for i, v in raw do
			local case = bit32.band((i-1)*CASE_MULTIPLIER, 0xFF)
			encoded[case] = v
		end
		Luau.OpCode = encoded
	end
	local DEFAULT_OPTIONS = {
		EnabledRemarks       = {ColdRemark=false, InlineRemark=true},
		DecompilerTimeout    = 10,
		DecompilerMode       = "disasm",
		ReaderFloatPrecision = 7,
		ShowDebugInformation = false,
		ShowInstructionLines = false,
		ShowOperationIndex   = false,
		ShowOperationNames   = false,
		ShowTrivialOperations= false,
		UseTypeInfo          = true,
		ListUsedGlobals      = true,
		ReturnElapsedTime    = false,
		CleanMode            = true,
	}
	local LuauCompileUserdataInfo = true
	pcall(function()
		local ok, r = pcall(function() return game:GetFastFlag("LuauCompileUserdataInfo") end)
		if ok then LuauCompileUserdataInfo = r end
	end)
	local LuauOpCode        = Luau.OpCode
	local LuauBytecodeTag   = Luau.BytecodeTag
	local LuauBytecodeType  = Luau.BytecodeType
	local LuauCaptureType   = Luau.CaptureType
	local LuauProtoFlag     = Luau.ProtoFlag
	local function toBoolean(v)      return v ~= 0 end
	local function toEscapedString(v)
		if type(v) == "string" then
			return string.format("%q", v)
		end
		return tostring(v)
	end
	local function formatIndexString(key)
		if type(key) == "string" and key:match("^[%a_][%w_]*$") then
			return "." .. key
		end
		return "[" .. toEscapedString(key) .. "]"
	end
	local function padLeft(v, ch, n)
		local s = tostring(v); return string.rep(ch, math.max(0, n-#s)) .. s
	end
	local function padRight(v, ch, n)
		local s = tostring(v); return s .. string.rep(ch, math.max(0, n-#s))
	end
	local ROBLOX_GLOBALS = {
		"game","workspace","script","plugin","settings","shared","UserSettings",
		"print","warn","error","assert","pcall","xpcall","require","select",
		"pairs","ipairs","next","unpack","type","typeof","tostring","tonumber",
		"setmetatable","getmetatable","rawset","rawget","rawequal","rawlen",
		"math","table","string","bit32","coroutine","os","utf8","task","buffer",
		"Instance","Enum","Vector3","Vector2","CFrame","Color3","BrickColor",
		"UDim","UDim2","Ray","Axes","Faces","NumberRange","NumberSequence",
		"ColorSequence","TweenInfo","RaycastParams","OverlapParams",
		"tick","time","wait","delay","spawn","_G","_VERSION",
	}
	local function isGlobal(key)
		for _, v in ipairs(ROBLOX_GLOBALS) do if v == key then return true end end
		return false
	end
	local function Decompile(bytecode, options)
		local bytecodeVersion, typeEncodingVersion
		Reader:Set(options.ReaderFloatPrecision)
		local reader = Reader.new(bytecode)
		local function disassemble()
			if bytecodeVersion >= 4 then
				typeEncodingVersion = reader:nextByte()
			end
			local stringTable = {}
			local function readStringTable()
				local n = reader:nextVarInt()
				for i = 1, n do stringTable[i] = reader:nextString() end
			end
			local userdataTypes = {}
			local function readUserdataTypes()
				if LuauCompileUserdataInfo then
					while true do
						local idx = reader:nextByte()
						if idx == 0 then break end
						userdataTypes[idx] = reader:nextVarInt()
					end
				end
			end
			local protoTable = {}
			local function readProtoTable()
				local n = reader:nextVarInt()
				for i = 1, n do
					local protoId = i - 1
					local proto = {
						id=protoId, instructions={}, constants={},
						captures={}, innerProtos={}, instructionLineInfo={},
					}
					protoTable[protoId] = proto
					proto.maxStackSize  = reader:nextByte()
					proto.numParams     = reader:nextByte()
					proto.numUpvalues   = reader:nextByte()
					proto.isVarArg      = toBoolean(reader:nextByte())
					if bytecodeVersion >= 4 then
						proto.flags = reader:nextByte()
						local resultTypedParams, resultTypedUpvalues, resultTypedLocals = {}, {}, {}
						local allTypeInfoSize = reader:nextVarInt()
						local hasTypeInfo = allTypeInfoSize > 0
						proto.hasTypeInfo = hasTypeInfo
						if hasTypeInfo then
							local totalTypedParams   = allTypeInfoSize
							local totalTypedUpvalues = 0
							local totalTypedLocals   = 0
							if typeEncodingVersion and typeEncodingVersion > 1 then
								totalTypedParams   = reader:nextVarInt()
								totalTypedUpvalues = reader:nextVarInt()
								totalTypedLocals   = reader:nextVarInt()
							end
							if totalTypedParams > 0 then
								resultTypedParams = reader:nextBytes(totalTypedParams)
								table.remove(resultTypedParams, 1)
								table.remove(resultTypedParams, 1)
							end
							for j = 1, totalTypedUpvalues do
								resultTypedUpvalues[j] = {type=reader:nextByte()}
							end
							for j = 1, totalTypedLocals do
								local lt  = reader:nextByte()
								local lr  = reader:nextByte()
								local lsp = reader:nextVarInt() + 1
								local lep = reader:nextVarInt() + lsp - 1
								resultTypedLocals[j] = {type=lt, register=lr, startPC=lsp}
							end
						end
						proto.typedParams   = resultTypedParams
						proto.typedUpvalues = resultTypedUpvalues
						proto.typedLocals   = resultTypedLocals
					end
					proto.sizeInstructions = reader:nextVarInt()
					for j = 1, proto.sizeInstructions do
						proto.instructions[j] = reader:nextUInt32()
					end
					proto.sizeConstants = reader:nextVarInt()
					for j = 1, proto.sizeConstants do
						local constType  = reader:nextByte()
						local constValue
						local BT = LuauBytecodeTag
						if constType == BT.LBC_CONSTANT_BOOLEAN then
							constValue = toBoolean(reader:nextByte())
						elseif constType == BT.LBC_CONSTANT_NUMBER then
							constValue = reader:nextDouble()
						elseif constType == BT.LBC_CONSTANT_STRING then
							constValue = stringTable[reader:nextVarInt()]
						elseif constType == BT.LBC_CONSTANT_IMPORT then
							local id = reader:nextUInt32()
							local idxCount = bit32.rshift(id, 30)
							local ci1 = bit32.band(bit32.rshift(id,20), 0x3FF)
							local ci2 = bit32.band(bit32.rshift(id,10), 0x3FF)
							local ci3 = bit32.band(id, 0x3FF)
							local tag = ""
							local function kv(idx) return proto.constants[idx+1] end
							if     idxCount == 1 then tag = tostring(kv(ci1) and kv(ci1).value or "")
							elseif idxCount == 2 then tag = tostring(kv(ci1) and kv(ci1).value or "")
								.."."..tostring(kv(ci2) and kv(ci2).value or "")
							elseif idxCount == 3 then tag = tostring(kv(ci1) and kv(ci1).value or "")
								.."."..tostring(kv(ci2) and kv(ci2).value or "")
								.."."..tostring(kv(ci3) and kv(ci3).value or "")
							end
							constValue = tag
						elseif constType == BT.LBC_CONSTANT_TABLE then
							local sz = reader:nextVarInt()
							local keys = {}
							for k = 1, sz do keys[k] = reader:nextVarInt()+1 end
							constValue = {size=sz, keys=keys}
						elseif constType == BT.LBC_CONSTANT_CLOSURE then
							constValue = reader:nextVarInt() + 1
						elseif constType == BT.LBC_CONSTANT_VECTOR then
							local x,y,z,w = reader:nextFloat(),reader:nextFloat(),reader:nextFloat(),reader:nextFloat()
							constValue = w == 0 and ("Vector3.new("..x..","..y..","..z..")")
								or ("vector.create("..x..","..y..","..z..","..w..")")
						end
						proto.constants[j] = {type=constType, value=constValue}
					end
					proto.sizeInnerProtos = reader:nextVarInt()
					for j = 1, proto.sizeInnerProtos do
						proto.innerProtos[j] = protoTable[reader:nextVarInt()]
					end
					proto.lineDefined = reader:nextVarInt()
					local nameId = reader:nextVarInt()
					proto.name = stringTable[nameId]
					local hasLineInfo = toBoolean(reader:nextByte())
					proto.hasLineInfo = hasLineInfo
					if hasLineInfo then
						local lgap = reader:nextByte()
						local baselineSize = bit32.rshift(proto.sizeInstructions-1, lgap)+1
						local smallLineInfo, absLineInfo = {}, {}
						local lastOffset, lastLine = 0, 0
						for j = 1, proto.sizeInstructions do
							local b = reader:nextSignedByte()
							lastOffset += b
							smallLineInfo[j] = lastOffset
						end
						for j = 1, baselineSize do
							local lc = lastLine + reader:nextInt32()
							absLineInfo[j-1] = lc
							lastLine = lc
						end
						local resultLineInfo = {}
						for j, line in ipairs(smallLineInfo) do
							local absIdx = bit32.rshift(j-1, lgap)
							local absLine = absLineInfo[absIdx]
							local rl = line + absLine
							if lgap <= 1 and (-line == absLine) then
								rl += absLineInfo[absIdx+1] or 0
							end
							if rl <= 0 then rl += 0x100 end
							resultLineInfo[j] = rl
						end
						proto.lineInfoSize = lgap
						proto.instructionLineInfo = resultLineInfo
					end
					local hasDebugInfo = toBoolean(reader:nextByte())
					proto.hasDebugInfo = hasDebugInfo
					if hasDebugInfo then
						local totalLocals = reader:nextVarInt()
						local debugLocals = {}
						for j = 1, totalLocals do
							debugLocals[j] = {
								name     = stringTable[reader:nextVarInt()],
								startPC  = reader:nextVarInt(),
								endPC    = reader:nextVarInt(),
								register = reader:nextByte(),
							}
						end
						proto.debugLocals = debugLocals
						local totalUpvals = reader:nextVarInt()
						local debugUpvalues = {}
						for j = 1, totalUpvals do
							debugUpvalues[j] = {name=stringTable[reader:nextVarInt()]}
						end
						proto.debugUpvalues = debugUpvalues
					end
				end
			end
			readStringTable()
			if bytecodeVersion and bytecodeVersion > 5 then readUserdataTypes() end
			readProtoTable()
			local mainProtoId = reader:nextVarInt()
			return mainProtoId, protoTable
		end
		local function organize()
			local mainProtoId, protoTable = disassemble()
			local mainProto = protoTable[mainProtoId]
			mainProto.main = true
			local registerActions = {}
			local function baseProto(proto)
				local protoRegisterActions = {}
				registerActions[proto.id] = {proto=proto, actions=protoRegisterActions}
				local instructions = proto.instructions
				local innerProtos  = proto.innerProtos
				local constants    = proto.constants
				local captures     = proto.captures
				local flags        = proto.flags
				local function collectCaptures(baseIdx, p)
					local nup = p.numUpvalues
					if nup > 0 then
						local _c = p.captures
						for j = 1, nup do
							local cap = instructions[baseIdx + j]
							local ctype = Luau:INSN_A(cap)
							local sreg  = Luau:INSN_B(cap)
							if ctype == LuauCaptureType.LCT_VAL or ctype == LuauCaptureType.LCT_REF then
								_c[j-1] = sreg
							elseif ctype == LuauCaptureType.LCT_UPVAL then
								_c[j-1] = captures[sreg]
							end
						end
					end
				end
				local function writeFlags()
					if type(flags) == "table" then return end
					local rawFlags = type(flags) == "number" and flags or 0
					local df = {}
					if proto.main then
						df.native = toBoolean(bit32.band(rawFlags, LuauProtoFlag.LPF_NATIVE_MODULE))
					else
						df.native = toBoolean(bit32.band(rawFlags, LuauProtoFlag.LPF_NATIVE_FUNCTION))
						df.cold   = toBoolean(bit32.band(rawFlags, LuauProtoFlag.LPF_NATIVE_COLD))
					end
					flags = df; proto.flags = df
				end
				local function writeInstructions()
					local auxSkip = false
					local function reg(act, regs, extra, hide)
						table.insert(protoRegisterActions, {
							usedRegisters=regs or {}, extraData=extra,
							opCode=act, hide=hide
						})
					end
					for idx, instruction in ipairs(instructions) do
						if auxSkip then auxSkip=false; continue end
						local oci = LuauOpCode[Luau:INSN_OP(instruction)]
						if not oci then continue end
						local opn  = oci.name
						local opt  = oci.type
						local isAux= oci.aux == true
						local A,B,C,sD,D,E,aux
						if     opt=="A"   then A=Luau:INSN_A(instruction)
						elseif opt=="E"   then E=Luau:INSN_E(instruction)
						elseif opt=="AB"  then A=Luau:INSN_A(instruction); B=Luau:INSN_B(instruction)
						elseif opt=="AC"  then A=Luau:INSN_A(instruction); C=Luau:INSN_C(instruction)
						elseif opt=="ABC" then A=Luau:INSN_A(instruction); B=Luau:INSN_B(instruction); C=Luau:INSN_C(instruction)
						elseif opt=="AD"  then A=Luau:INSN_A(instruction); D=Luau:INSN_D(instruction)
						elseif opt=="AsD" then A=Luau:INSN_A(instruction); sD=Luau:INSN_sD(instruction)
						elseif opt=="sD"  then sD=Luau:INSN_sD(instruction)
						end
						if isAux then
							auxSkip=true; reg(oci,nil,nil,true)
							aux=instructions[idx+1]
						end
						local st = not options.ShowTrivialOperations
						if opn=="NOP" or opn=="BREAK" or opn=="NATIVECALL" then reg(oci,nil,nil,st)
						elseif opn=="LOADNIL" then reg(oci,{A})
						elseif opn=="LOADB"   then reg(oci,{A},{B,C})
						elseif opn=="LOADN"   then reg(oci,{A},{sD})
						elseif opn=="LOADK"   then reg(oci,{A},{D})
						elseif opn=="MOVE"    then reg(oci,{A,B})
						elseif opn=="GETGLOBAL" or opn=="SETGLOBAL" then reg(oci,{A},{aux})
						elseif opn=="GETUPVAL" or opn=="SETUPVAL"  then reg(oci,{A},{B})
						elseif opn=="CLOSEUPVALS" then reg(oci,{A},nil,st)
						elseif opn=="GETIMPORT" then reg(oci,{A},{D,aux})
						elseif opn=="GETTABLE" or opn=="SETTABLE" then reg(oci,{A,B,C})
						elseif opn=="GETTABLEKS" or opn=="SETTABLEKS" then reg(oci,{A,B},{C,aux})
						elseif opn=="GETTABLEN" or opn=="SETTABLEN" then reg(oci,{A,B},{C})
						elseif opn=="NEWCLOSURE" then
							reg(oci,{A},{D})
							local p2=innerProtos[D+1]
							if p2 then collectCaptures(idx,p2); baseProto(p2) end
						elseif opn=="DUPCLOSURE" then
							reg(oci,{A},{D})
							local c=constants[D+1]
							if c then local p2=protoTable[c.value-1]; if p2 then collectCaptures(idx,p2); baseProto(p2) end end
						elseif opn=="NAMECALL"  then reg(oci,{A,B},{C,aux},st)
						elseif opn=="CALL"      then reg(oci,{A},{B,C})
						elseif opn=="RETURN"    then reg(oci,{A},{B})
						elseif opn=="JUMP" or opn=="JUMPBACK" then reg(oci,{},{sD})
						elseif opn=="JUMPIF" or opn=="JUMPIFNOT" then reg(oci,{A},{sD})
						elseif opn=="JUMPIFEQ" or opn=="JUMPIFLE" or opn=="JUMPIFLT"
						    or opn=="JUMPIFNOTEQ" or opn=="JUMPIFNOTLE" or opn=="JUMPIFNOTLT" then
							reg(oci,{A,aux},{sD})
						elseif opn=="ADD" or opn=="SUB" or opn=="MUL" or opn=="DIV"
						    or opn=="MOD" or opn=="POW" then reg(oci,{A,B,C})
						elseif opn=="ADDK" or opn=="SUBK" or opn=="MULK" or opn=="DIVK"
						    or opn=="MODK" or opn=="POWK" then reg(oci,{A,B},{C})
						elseif opn=="AND" or opn=="OR" then reg(oci,{A,B,C})
						elseif opn=="ANDK" or opn=="ORK" then reg(oci,{A,B},{C})
						elseif opn=="CONCAT" then
							local regs={A}
							for r=B,C do table.insert(regs,r) end
							reg(oci,regs)
						elseif opn=="NOT" or opn=="MINUS" or opn=="LENGTH" then reg(oci,{A,B})
						elseif opn=="NEWTABLE" then reg(oci,{A},{B,aux})
						elseif opn=="DUPTABLE" then reg(oci,{A},{D})
						elseif opn=="SETLIST"  then
							if C~=0 then
								local regs={A,B}
								for k=1,C-1 do table.insert(regs,B+k) end
								reg(oci,regs,{aux,C})
							else reg(oci,{A,B},{aux,C}) end
						elseif opn=="FORNPREP" then reg(oci,{A,A+1,A+2},{sD})
						elseif opn=="FORNLOOP" then reg(oci,{A},{sD})
						elseif opn=="FORGLOOP" then
							local nv=bit32.band(aux or 0,0xFF)
							local regs={}
							for k=1,nv do table.insert(regs,A+k) end
							reg(oci,regs,{sD,aux})
						elseif opn=="FORGPREP_INEXT" or opn=="FORGPREP_NEXT" then reg(oci,{A,A+1})
						elseif opn=="FORGPREP"  then reg(oci,{A},{sD})
						elseif opn=="GETVARARGS" then
							if B~=0 then
								local regs={A}
								for k=1,B-1 do table.insert(regs,A+k) end
								reg(oci,regs,{B})
							else reg(oci,{A},{B}) end
						elseif opn=="PREPVARARGS" then reg(oci,{},{A},st)
						elseif opn=="LOADKX"  then reg(oci,{A},{aux})
						elseif opn=="JUMPX"   then reg(oci,{},{E})
						elseif opn=="COVERAGE" then reg(oci,{},{E},st)
						elseif opn=="JUMPXEQKNIL" or opn=="JUMPXEQKB"
						    or opn=="JUMPXEQKN"   or opn=="JUMPXEQKS" then
							reg(oci,{A},{sD,aux})
						elseif opn=="CAPTURE" then reg(oci,nil,nil,st)
						elseif opn=="SUBRK" or opn=="DIVRK" then reg(oci,{A,C},{B})
						elseif opn=="IDIV"  then reg(oci,{A,B,C})
						elseif opn=="IDIVK" then reg(oci,{A,B},{C})
						elseif opn=="FASTCALL"  then reg(oci,{},{A,C},st)
						elseif opn=="FASTCALL1" then reg(oci,{B},{A,C},st)
						elseif opn=="FASTCALL2" then
							local r2=bit32.band(aux or 0,0xFF)
							reg(oci,{B,r2},{A,C},st)
						elseif opn=="FASTCALL2K" then reg(oci,{B},{A,C,aux},st)
						elseif opn=="FASTCALL3" then
							local r2=bit32.band(aux or 0,0xFF)
							local r3=bit32.band(bit32.rshift(aux or 0,8),0xFF)
							reg(oci,{B,r2,r3},{A,C},st)
						end
					end
				end
				writeFlags()
				writeInstructions()
			end
			baseProto(mainProto)
			return mainProtoId, registerActions, protoTable
		end
		local function finalize(mainProtoId, registerActions, protoTable)
			local finalResult = ""
			local totalParameters = 0
			local usedGlobals    = {}
			local usedGlobalsSet = {}
			local function isValidGlobal(key)
				if usedGlobalsSet[key] then return false end
				return not isGlobal(key)
			end
			local function processResult(res)
				local embed = ""
				if options.ListUsedGlobals and #usedGlobals > 0 then
					embed = string.format(Strings.USED_GLOBALS, table.concat(usedGlobals, ", "))
				end
				return embed .. res
			end
			if options.DecompilerMode == "disasm" then
				local resultParts = {}
				local function emit(s) resultParts[#resultParts + 1] = s end
				local function writeActions(protoActions)
					local actions  = protoActions.actions
					local proto    = protoActions.proto
					local lineInfo = proto.instructionLineInfo
					local inner    = proto.innerProtos
					local consts   = proto.constants
					local caps     = proto.captures
					local pflags   = proto.flags
					local numParams= proto.numParams
					local jumpMarkers = {}
					local function makeJump(idx) jumpMarkers[idx]=(jumpMarkers[idx] or 0)+1 end
					totalParameters += numParams
					if proto.main and pflags and pflags.native then emit("--!native\n") end
					local function buildRegNames(instrIdx)
						local names = {}
						if proto.debugLocals then
							for _, dl in ipairs(proto.debugLocals) do
								if instrIdx >= dl.startPC and instrIdx <= dl.endPC then
									names[dl.register] = dl.name
								end
							end
						end
						return names
					end
					local function fmtUpv(r)
						local du = proto.debugUpvalues
						if du and du[r+1] and du[r+1].name ~= "" then
							return du[r+1].name
						end
						return "upv_"..r
					end
					local regNameCache = {}
					local function fmtReg(r, instrIdx)
						if instrIdx and proto.debugLocals then
							local cached = regNameCache[instrIdx]
							if not cached then
								cached = buildRegNames(instrIdx)
								regNameCache[instrIdx] = cached
							end
							if cached[r] and cached[r] ~= "" then
								return cached[r]
							end
						end
						local pr = r+1
						if pr < numParams+1 then
							return "p"..((totalParameters-numParams)+pr)
						end
						return "v"..(r-numParams)
					end
					local function paramName(j)
						if proto.debugLocals then
							for _, dl in ipairs(proto.debugLocals) do
								if dl.startPC == 0 and dl.register == j-1 then
									return dl.name
								end
							end
						end
						return "p"..(totalParameters+j)
					end
					local function fmtConst(k)
						if not k then return "nil" end
						if k.type == LuauBytecodeTag.LBC_CONSTANT_VECTOR then
							return tostring(k.value)
						end
						if type(tonumber(k.value))=="number" then
							return tostring(tonumber(string.format("%0."..options.ReaderFloatPrecision.."f", k.value)))
						end
						return toEscapedString(k.value)
					end
					local function fmtProto(p)
						local body=""
						local nativePrefix=""
						if p.flags and p.flags.native then
							if p.flags.cold and options.EnabledRemarks.ColdRemark then
								nativePrefix ..= string.format(Strings.DECOMPILER_REMARK,
									"This function is marked cold and is not compiled natively")
							end
							nativePrefix ..= "@native "
						end
						if p.name then body=nativePrefix.."local function "..p.name
						else body=nativePrefix.."function" end
						body ..= "("
						for j=1,p.numParams do
							local pb=paramName(j)
							if p.hasTypeInfo and options.UseTypeInfo and p.typedParams and p.typedParams[j] then
								pb ..= ": "..Luau:GetBaseTypeString(p.typedParams[j],true)
							end
							if j~=p.numParams then pb ..= ", " end
							body ..= pb
						end
						if p.isVarArg then
							body ..= (p.numParams>0) and ", ..." or "..."
						end
						body ..= ")\n"
						if options.ShowDebugInformation then
							body ..= "-- proto pool id: "..p.id.."\n"
							body ..= "-- num upvalues: "..p.numUpvalues.."\n"
							body ..= "-- num inner protos: "..(p.sizeInnerProtos or 0).."\n"
							body ..= "-- size instructions: "..(p.sizeInstructions or 0).."\n"
							body ..= "-- size constants: "..(p.sizeConstants or 0).."\n"
							body ..= "-- lineinfo gap: "..(p.lineInfoSize or "n/a").."\n"
							body ..= "-- max stack size: "..p.maxStackSize.."\n"
							body ..= "-- is typed: "..tostring(p.hasTypeInfo).."\n"
						end
						return body
					end
					local function writeProto(reg, p)
						local body=fmtProto(p)
						if p.name then
							emit("\n"..body)
							writeActions(registerActions[p.id])
							emit("end\n"..fmtReg(reg).." = "..p.name)
						else
							emit(fmtReg(reg).." = "..body)
							writeActions(registerActions[p.id])
							emit("end")
						end
					end
					local CLEAN_SUPPRESS = {
						CLOSEUPVALS=true, PREPVARARGS=true, COVERAGE=true,
						CAPTURE=true, FASTCALL=true, FASTCALL1=true,
						FASTCALL2=true, FASTCALL2K=true, FASTCALL3=true,
						JUMPX=true, NOP=true, JUMPBACK=true,
					}
					for i, action in ipairs(actions) do
						if action.hide then continue end
						local ur  = action.usedRegisters
						local ed  = action.extraData
						local oci = action.opCode
						if not oci then continue end
						local opn = oci.name
						if options.CleanMode and CLEAN_SUPPRESS[opn] then continue end
						if options.CleanMode and opn == "RETURN" then
							local b = ed and ed[1] or 0
							if b == 1 then continue end
						end
						if options.CleanMode and opn == "MOVE" and
						   i > 1 and actions[i-1] and
						   (actions[i-1].opCode.name == "NEWCLOSURE" or
						    actions[i-1].opCode.name == "DUPCLOSURE") then
							continue
						end
						local function R(r) return fmtReg(r, i) end
						local function handleJumps()
							local n = jumpMarkers[i]
							if n then
								jumpMarkers[i]=nil
							for _=1,n do emit("end\n") end
							end
						end
						handleJumps()
						if not options.CleanMode then
							if options.ShowOperationIndex then
								emit("["..padLeft(i,"0",3).."] ")
							end
							if options.ShowInstructionLines and lineInfo and lineInfo[i] then
								emit(":"..padLeft(lineInfo[i],"0",3)..":")
							end
							if options.ShowOperationNames then
								emit(padRight(opn," ",15))
							end
						end
						if opn=="LOADNIL" then emit(R(ur[1]).." = nil")
						elseif opn=="LOADB" then
							emit(R(ur[1]).." = "..toEscapedString(toBoolean(ed[1])))
							if ed[2]~=0 then emit(" +"..ed[2]) end
						elseif opn=="LOADN" then emit(R(ur[1]).." = "..ed[1])
						elseif opn=="LOADK" then emit(R(ur[1]).." = "..fmtConst(consts[ed[1]+1]))
						elseif opn=="MOVE"  then emit(R(ur[1]).." = "..R(ur[2]))
						elseif opn=="GETGLOBAL" then
							local gk=tostring(consts[ed[1]+1] and consts[ed[1]+1].value or "")
							if options.ListUsedGlobals and isValidGlobal(gk) then
								table.insert(usedGlobals,gk); usedGlobalsSet[gk]=true
							end
							emit(R(ur[1]).." = "..gk)
						elseif opn=="SETGLOBAL" then
							local gk=tostring(consts[ed[1]+1] and consts[ed[1]+1].value or "")
							if options.ListUsedGlobals and isValidGlobal(gk) then
								table.insert(usedGlobals,gk); usedGlobalsSet[gk]=true
							end
							emit(gk.." = "..R(ur[1]))
						elseif opn=="GETUPVAL" then emit(R(ur[1]).." = "..fmtUpv(caps[ed[1]]))
						elseif opn=="SETUPVAL" then emit(fmtUpv(caps[ed[1]]).." = "..R(ur[1]))
						elseif opn=="CLOSEUPVALS" then emit("-- clear captures from back until: "..ur[1])
						elseif opn=="GETIMPORT" then
							local imp=tostring(consts[ed[1]+1] and consts[ed[1]+1].value or "")
							local totalIdx = bit32.rshift(ed[2] or 0, 30)
							if totalIdx==1 and options.ListUsedGlobals and isValidGlobal(imp) then
								table.insert(usedGlobals,imp); usedGlobalsSet[imp]=true
							end
							emit(R(ur[1]).." = "..imp)
						elseif opn=="GETTABLE" then
							emit(R(ur[1]).." = "..R(ur[2]).."["..R(ur[3]).."]")
						elseif opn=="SETTABLE" then
							emit(R(ur[2]).."["..R(ur[3]).."] = "..R(ur[1]))
						elseif opn=="GETTABLEKS" then
							local key = consts[ed[2]+1] and consts[ed[2]+1].value
							emit(R(ur[1]).." = "..R(ur[2])..formatIndexString(key))
						elseif opn=="SETTABLEKS" then
							local key = consts[ed[2]+1] and consts[ed[2]+1].value
							emit(R(ur[2])..formatIndexString(key).." = "..R(ur[1]))
						elseif opn=="GETTABLEN" then
							emit(R(ur[1]).." = "..R(ur[2]).."["..(ed[1]+1).."]")
						elseif opn=="SETTABLEN" then
							emit(R(ur[2]).."["..(ed[1]+1).."] = "..R(ur[1]))
						elseif opn=="NEWCLOSURE" then
							local p2=inner[ed[1]+1]; if p2 then writeProto(ur[1],p2) end
						elseif opn=="DUPCLOSURE" then
							local c=consts[ed[1]+1]
							if c then
								local p2=protoTable[c.value-1]; if p2 then writeProto(ur[1],p2) end
							end
						elseif opn=="NAMECALL" then
							local method=tostring(consts[ed[2]+1] and consts[ed[2]+1].value or "")
							emit("-- :"..method)
						elseif opn=="CALL" then
							local baseR=ur[1]
							local nArgs=ed[1]-1; local nRes=ed[2]-1
							local nmMethod=""; local argOff=0
							local prev=actions[i-1]
							if prev and prev.opCode and prev.opCode.name=="NAMECALL" then
								nmMethod=":"..tostring(consts[prev.extraData[2]+1] and consts[prev.extraData[2]+1].value or "")
								nArgs-=1; argOff+=1
							end
							local callBody=""
							if nRes==-1 then callBody="... = "
							elseif nRes>0 then
								local rb=""
								for k=1,nRes do
									rb..=R(baseR+k-1)
									if k~=nRes then rb..=", " end
								end
								callBody=rb.." = "
							end
							callBody ..= R(baseR)..nmMethod.."("
							if nArgs==-1 then callBody..="..."
							elseif nArgs>0 then
								local ab=""
								for k=1,nArgs do
									ab..=R(baseR+k+argOff)
									if k~=nArgs then ab..=", " end
								end
								callBody..=ab
							end
							callBody..=")"
							emit(callBody)
						elseif opn=="RETURN" then
							local baseR=ur[1]; local tot=ed[1]-2
							local rb=""
							if tot==-2 then rb=" "..R(baseR)..", ..."
							elseif tot>-1 then
								rb=" "
								for k=0,tot do
									rb..=R(baseR+k)
									if k~=tot then rb..=", " end
								end
							end
							emit("return"..rb)
						elseif opn=="JUMP" then emit("-- jump to #"..(i+ed[1]))
						elseif opn=="JUMPBACK" then emit("-- jump back to #"..(i+ed[1]+1))
						elseif opn=="JUMPIF" then
							local ei=i+ed[1]; makeJump(ei)
							emit("if not "..R(ur[1]).." then -- goto #"..ei)
						elseif opn=="JUMPIFNOT" then
							local ei=i+ed[1]; makeJump(ei)
							emit("if "..R(ur[1]).." then -- goto #"..ei)
						elseif opn=="JUMPIFEQ" then
							local ei=i+ed[1]; makeJump(ei)
							emit("if "..R(ur[1]).." ~= "..R(ur[2]).." then -- goto #"..ei)
						elseif opn=="JUMPIFLE" then
							local ei=i+ed[1]; makeJump(ei)
							emit("if "..R(ur[1]).." > "..R(ur[2]).." then -- goto #"..ei)
						elseif opn=="JUMPIFLT" then
							local ei=i+ed[1]; makeJump(ei)
							emit("if "..R(ur[1]).." >= "..R(ur[2]).." then -- goto #"..ei)
						elseif opn=="JUMPIFNOTEQ" then
							local ei=i+ed[1]; makeJump(ei)
							emit("if "..R(ur[1]).." == "..R(ur[2]).." then -- goto #"..ei)
						elseif opn=="JUMPIFNOTLE" then
							local ei=i+ed[1]; makeJump(ei)
							emit("if "..R(ur[1]).." <= "..R(ur[2]).." then -- goto #"..ei)
						elseif opn=="JUMPIFNOTLT" then
							local ei=i+ed[1]; makeJump(ei)
							emit("if "..R(ur[1]).." < "..R(ur[2]).." then -- goto #"..ei)
						elseif opn=="ADD"  then emit(R(ur[1]).." = "..R(ur[2]).." + "..R(ur[3]))
						elseif opn=="SUB"  then emit(R(ur[1]).." = "..R(ur[2]).." - "..R(ur[3]))
						elseif opn=="MUL"  then emit(R(ur[1]).." = "..R(ur[2]).." * "..R(ur[3]))
						elseif opn=="DIV"  then emit(R(ur[1]).." = "..R(ur[2]).." / "..R(ur[3]))
						elseif opn=="MOD"  then emit(R(ur[1]).." = "..R(ur[2]).." % "..R(ur[3]))
						elseif opn=="POW"  then emit(R(ur[1]).." = "..R(ur[2]).." ^ "..R(ur[3]))
						elseif opn=="ADDK" then emit(R(ur[1]).." = "..R(ur[2]).." + "..fmtConst(consts[ed[1]+1]))
						elseif opn=="SUBK" then emit(R(ur[1]).." = "..R(ur[2]).." - "..fmtConst(consts[ed[1]+1]))
						elseif opn=="MULK" then emit(R(ur[1]).." = "..R(ur[2]).." * "..fmtConst(consts[ed[1]+1]))
						elseif opn=="DIVK" then emit(R(ur[1]).." = "..R(ur[2]).." / "..fmtConst(consts[ed[1]+1]))
						elseif opn=="MODK" then emit(R(ur[1]).." = "..R(ur[2]).." % "..fmtConst(consts[ed[1]+1]))
						elseif opn=="POWK" then emit(R(ur[1]).." = "..R(ur[2]).." ^ "..fmtConst(consts[ed[1]+1]))
						elseif opn=="AND"  then emit(R(ur[1]).." = "..R(ur[2]).." and "..R(ur[3]))
						elseif opn=="OR"   then emit(R(ur[1]).." = "..R(ur[2]).." or "..R(ur[3]))
						elseif opn=="ANDK" then emit(R(ur[1]).." = "..R(ur[2]).." and "..fmtConst(consts[ed[1]+1]))
						elseif opn=="ORK"  then emit(R(ur[1]).." = "..R(ur[2]).." or "..fmtConst(consts[ed[1]+1]))
						elseif opn=="CONCAT" then
							local tgt=table.remove(ur,1)
							local cb=""
							for k,r in ipairs(ur) do
								cb..=fmtReg(r, i); if k~=#ur then cb..=" .. " end
							end
							emit(R(tgt).." = "..cb)
						elseif opn=="NOT"    then emit(R(ur[1]).." = not "..R(ur[2]))
						elseif opn=="MINUS"  then emit(R(ur[1]).." = -"..R(ur[2]))
						elseif opn=="LENGTH" then emit(R(ur[1]).." = #"..R(ur[2]))
						elseif opn=="NEWTABLE" then
							emit(R(ur[1]).." = {}")
							if options.ShowDebugInformation and ed[2] and ed[2]>0 then
								emit(" ")
							end
						elseif opn=="DUPTABLE" then
							local cv=consts[ed[1]+1]
							if cv and type(cv.value)=="table" then
								local tb="{"
								for k=1,cv.value.size do
									tb..=fmtConst(consts[cv.value.keys[k]])
									if k~=cv.value.size then tb..=", " end
								end
								emit(R(ur[1]).." = {} -- "..tb.."}")
							else emit(R(ur[1]).." = {}") end
						elseif opn=="SETLIST" then
							local tgt=ur[1]; local src=ur[2]
							local si=ed[1]; local vc=ed[2]
							if vc==0 then
								emit(R(tgt).."["..si.."] = [...]")
							else
								local tot2=#ur-1; local cb=""
								for k=1,tot2 do
									cb..=R(tgt).."["..(si+k-1).."] = "..R(src+k-1)
									if k~=tot2 then cb..="\n" end
								end
								emit(cb)
							end
						elseif opn=="FORNPREP" then
							emit("for "..R(ur[1]).." = "..R(ur[1])..", "..R(ur[2])..", "..R(ur[3]).." do -- end at #"..(i+ed[1]))
						elseif opn=="FORNLOOP" then
							emit("end -- iterate + jump to #"..(i+ed[1]))
						elseif opn=="FORGLOOP" then
							emit("end -- iterate + jump to #"..(i+ed[1]))
						elseif opn=="FORGPREP_INEXT" then
							local tr=ur[1]+1
							emit("for "..R(tr+2)..", "..R(tr+3).." in ipairs("..R(tr)..") do")
						elseif opn=="FORGPREP_NEXT" then
							local tr=ur[1]+1
							emit("for "..R(tr+2)..", "..R(tr+3).." in pairs("..R(tr)..") do")
						elseif opn=="FORGPREP" then
							local ei=i+ed[1]+2
							local ea=actions[ei]
							local vb=""
							if ea then
								for k,r in ipairs(ea.usedRegisters) do
									vb..=fmtReg(r, i); if k~=#ea.usedRegisters then vb..=", " end
								end
							end
							emit("for "..vb.." in "..R(ur[1]).." do -- end at #"..ei)
						elseif opn=="GETVARARGS" then
							local vc2=ed[1]-1
							local rb=""
							if vc2==-1 then rb=R(ur[1])
							else
								for k=1,vc2 do
									rb..=R(ur[k]); if k~=vc2 then rb..=", " end
								end
							end
							emit(rb.." = ...")
						elseif opn=="PREPVARARGS" then emit("-- ... ; number of fixed args: "..ed[1])
						elseif opn=="LOADKX" then emit(R(ur[1]).." = "..fmtConst(consts[ed[1]+1]))
						elseif opn=="JUMPX"    then emit("-- jump to #"..(i+ed[1]))
						elseif opn=="COVERAGE" then emit("-- coverage ("..ed[1]..")")
						elseif opn=="JUMPXEQKNIL" then
							local rev=bit32.rshift(ed[2] or 0,0x1F)~=1
							local sign=rev and "~=" or "=="
							local ei=i+ed[1]; makeJump(ei)
							emit("if "..R(ur[1]).." "..sign.." nil then -- goto #"..ei)
						elseif opn=="JUMPXEQKB" then
							local val=tostring(toBoolean(bit32.band(ed[2] or 0,1)))
							local rev=bit32.rshift(ed[2] or 0,0x1F)~=1
							local sign=rev and "~=" or "=="
							local ei=i+ed[1]; makeJump(ei)
							emit("if "..R(ur[1]).." "..sign.." "..val.." then -- goto #"..ei)
						elseif opn=="JUMPXEQKN" or opn=="JUMPXEQKS" then
							local cidx=bit32.band(ed[2] or 0,0xFFFFFF)
							local val=fmtConst(consts[cidx+1])
							local rev=bit32.rshift(ed[2] or 0,0x1F)~=1
							local sign=rev and "~=" or "=="
							local ei=i+ed[1]; makeJump(ei)
							emit("if "..R(ur[1]).." "..sign.." "..val.." then -- goto #"..ei)
						elseif opn=="CAPTURE"  then emit("-- upvalue capture")
						elseif opn=="SUBRK"    then emit(R(ur[1]).." = "..fmtConst(consts[ed[1]+1]).." - "..R(ur[2]))
						elseif opn=="DIVRK"    then emit(R(ur[1]).." = "..fmtConst(consts[ed[1]+1]).." / "..R(ur[2]))
						elseif opn=="IDIV"     then emit(R(ur[1]).." = "..R(ur[2]).." // "..R(ur[3]))
						elseif opn=="IDIVK"    then emit(R(ur[1]).." = "..R(ur[2]).." // "..fmtConst(consts[ed[1]+1]))
						elseif opn=="FASTCALL" then emit("-- FASTCALL; "..Luau:GetBuiltinInfo(ed[1]).."()")
						elseif opn=="FASTCALL1" then emit("-- FASTCALL1; "..Luau:GetBuiltinInfo(ed[1]).."("..R(ur[1])..")")
						elseif opn=="FASTCALL2" then emit("-- FASTCALL2; "..Luau:GetBuiltinInfo(ed[1]).."("..R(ur[1])..", "..R(ur[2])..")")
						elseif opn=="FASTCALL2K" then
							emit("-- FASTCALL2K; "..Luau:GetBuiltinInfo(ed[1]).."("..R(ur[1])..", "..fmtConst(consts[(ed[3] or 0)+1])..")")
						elseif opn=="FASTCALL3" then
							emit("-- FASTCALL3; "..Luau:GetBuiltinInfo(ed[1]).."("..R(ur[1])..", "..R(ur[2])..", "..R(ur[3])..")")
						end
						emit("\n")
					end
				end
				writeActions(registerActions[mainProtoId])
				finalResult = processResult(table.concat(resultParts))
			else
				finalResult = processResult("-- one day..")
			end
			return finalResult
		end
		local function manager(proceed, issue)
			if proceed then
				local startTime = os.clock()
				local result
				local ok, res = pcall(function() return finalize(organize()) end)
				result = ok and res or ("-- RUNTIME ERROR:\n-- " .. tostring(res))
				if (os.clock() - startTime) >= options.DecompilerTimeout then
					return Strings.TIMEOUT
				end
				return string.format(Strings.SUCCESS, result)
			else
				if issue == "COMPILATION_FAILURE" then
					local remaining = reader:len() - 1
					return string.format(Strings.COMPILATION_FAILURE, reader:nextString(remaining))
				elseif issue == "UNSUPPORTED_LBC_VERSION" then
					return string.format(Strings.UNSUPPORTED_LBC_VERSION,
						bytecodeVersion,
						LuauBytecodeTag.LBC_VERSION_MIN,
						LuauBytecodeTag.LBC_VERSION_MAX)
				end
			end
		end
		bytecodeVersion = reader:nextByte()
		if bytecodeVersion == 0 then
			return manager(false, "COMPILATION_FAILURE")
		elseif bytecodeVersion >= LuauBytecodeTag.LBC_VERSION_MIN
		   and bytecodeVersion <= LuauBytecodeTag.LBC_VERSION_MAX then
			return manager(true)
		else
			return manager(false, "UNSUPPORTED_LBC_VERSION")
		end
	end
	local CONST_TYPE = {
		[0]="nil",[1]="boolean",[2]="number(f64)",[3]="string",
		[4]="import",[5]="table",[6]="closure",[7]="number(f32)",[8]="number(i16)"
	}
	local function parseProto(p, stringTable, depth, bytecodeVer)
		local result = {
			depth=depth or 0, maxStack=p:nextByte(), numParams=p:nextByte(),
			numUpvals=p:nextByte(), isVararg=p:nextByte()~=0,
			constants={}, protos={}, upvalues={}, debugName="", strings={}, imports={},
		}
		if (bytecodeVer or 4) >= 4 then
			result.flags = p:nextByte()
			local typeSize = p:nextVarInt()
			if typeSize>0 then for _=1,typeSize do p:nextByte() end end
		end
		local instrCount = p:nextVarInt()
		for _=1,instrCount do p:nextUInt32() end
		local constCount = p:nextVarInt()
		for i=1,constCount do
			local kind=p:nextByte()
			local name=CONST_TYPE[kind] or ("unknown("..kind..")")
			local value
			if     kind==0 then value="nil"
			elseif kind==1 then value=p:nextByte()~=0 and "true" or "false"
			elseif kind==2 then value=tostring(p:nextDouble())
			elseif kind==7 then value=tostring(p:nextFloat())
			elseif kind==8 then
				local lo,hi=p:nextByte(),p:nextByte()
				local n=lo+hi*256; if n>=32768 then n=n-65536 end; value=tostring(n)
			elseif kind==3 then
				local idx=p:nextVarInt()
				value=stringTable[idx] or ("<string #"..idx..">")
				table.insert(result.strings,value)
			elseif kind==4 then
				local id=p:nextUInt32()
				local k0=bit32.band(bit32.rshift(id,20),0x3FF)
				local k1=bit32.band(bit32.rshift(id,10),0x3FF)
				local k2=bit32.band(id,0x3FF)
				local parts={}
				for _,k in ipairs({k0,k1,k2}) do
					if stringTable[k] then table.insert(parts,stringTable[k]) end
				end
				value=table.concat(parts,"."); table.insert(result.imports,value)
			elseif kind==5 then
				local keys,ks=p:nextVarInt(),{}
				for _=1,keys do
					local kidx=p:nextVarInt(); table.insert(ks,stringTable[kidx] or "?")
				end
				value="{"..table.concat(ks,", ").."}"
			elseif kind==6 then value="<proto #"..p:nextVarInt()..">"
			else value="?" end
			table.insert(result.constants,{kind=name,value=value,index=i-1})
		end
		local innerProtoCount=p:nextVarInt()
		for _=1,innerProtoCount do
			table.insert(result.protos, p:nextVarInt())
		end
		result.lineDefined = p:nextVarInt()
		local nameId = p:nextVarInt()
		result.debugName = stringTable[nameId] or ""
		local hasLines=p:nextByte()
		if hasLines~=0 then
			local lgap=p:nextByte()
			local baselineSize=bit32.rshift(instrCount-1,lgap)+1
			for _=1,instrCount do p:nextSignedByte() end
			for _=1,baselineSize do p:nextInt32() end
		end
		local hasDebug=p:nextByte()
		if hasDebug~=0 then
			local lc=p:nextVarInt()
			for _=1,lc do p:nextVarInt();p:nextVarInt();p:nextVarInt();p:nextByte() end
			local uc=p:nextVarInt()
			for j=1,uc do
				local ui=p:nextVarInt()
				table.insert(result.upvalues,stringTable[ui] or ("upval_"..j))
			end
		end
		return result
	end
	local function parseBytecode(bytes)
		local reader2=Reader.new(bytes)
		local ver=reader2:nextByte()
		if ver==0 then return nil,"Compile error: "..reader2:nextString(reader2:len()-1) end
		local typesVer=0
		if ver >= 4 then typesVer=reader2:nextByte() end
		local stringCount=reader2:nextVarInt()
		local stringTable={}
		for i=1,stringCount do
			local len=reader2:nextVarInt(); stringTable[i]=reader2:nextString(len)
		end
		local protoCount=reader2:nextVarInt()
		local protos={}
		for i=1,protoCount do
			local ok,proto=pcall(parseProto,reader2,stringTable,0,ver)
			table.insert(protos,ok and proto or {error=tostring(proto),depth=0})
		end
		local entryProto=reader2:nextVarInt()
		return {version=ver,typesVersion=typesVer,
			stringTable=stringTable,protos=protos,entryProto=entryProto}
	end
	local function buildReport(parsed, scriptName)
		local lines={}
		local function w(s) table.insert(lines,s or "") end
		w("_zukatechzukatech_zukatechzukatechhzukatech_")
		w("  code reconstructor — "..(scriptName or "unknown"))
		w("_zukatechzukatech_zukatechzukatechhzukatech_")
		w("  Luau version : "..parsed.version)
		w("  Types version: "..parsed.typesVersion)
		w("  Proto count  : "..#parsed.protos)
		w("  Entry proto  : #"..parsed.entryProto)
		w("  Strings total: "..#parsed.stringTable)
		w("")
		w("── STRING TABLE ─────────────────────────────────────")
		for i,s in ipairs(parsed.stringTable) do w(string.format("  [%3d] %q",i,s)) end
		w("")
		local function walkProto(proto,idx)
			if proto.error then w("  [Proto #"..idx.."] PARSE ERROR: "..proto.error); return end
			local ind=string.rep("  ",proto.depth+1)
			local dn=proto.debugName~="" and (" '"..proto.debugName.."'") or ""
			w(string.format("%s── Proto #%d%s",ind,idx,dn))
			w(string.format("%s   params=%d  upvals=%d  maxStack=%d  vararg=%s",
				ind,proto.numParams,proto.numUpvals,proto.maxStack,tostring(proto.isVararg)))
			if #proto.upvalues>0 then w(ind.."   Upvalues: "..table.concat(proto.upvalues,", ")) end
			if #proto.imports>0  then
				w(ind.."   Imports:")
				for _,imp in ipairs(proto.imports) do w(ind.."     "..imp) end
			end
			if #proto.strings>0  then
				w(ind.."   String literals:")
				for _,s in ipairs(proto.strings) do w(ind..'     "'..s..'"') end
			end
			if #proto.constants>0 then
				w(ind.."   All constants:")
				for _,c in ipairs(proto.constants) do
					w(string.format("%s     [%2d] %-14s %s",ind,c.index,c.kind,tostring(c.value)))
				end
			end
			w("")
			for i2,inner in ipairs(proto.protos) do walkProto(inner,i2) end
		end
		w("── PROTO TREE ───────────────────────────────────────")
		for i,proto in ipairs(parsed.protos) do walkProto(proto,i) end
		return table.concat(lines,"\n")
	end
	local function _ppImpl(text)
		local result = {}
		local depth  = 0
		local DEDENT_BEFORE      = { ["end"]=true, ["until"]=true }
		local INDENT_AFTER       = { ["then"]=true, ["do"]=true, ["repeat"]=true }
		local DEDENT_THEN_INDENT = { ["else"]=true, ["elseif"]=true }
		local function stripStrings(s)
			s = s:gsub('"[^"]*"', '""')
			s = s:gsub("'[^']*'", "''")
			s = s:gsub("%-%-.*$", "")
			return s
		end
		local function firstWord(s)
			return (stripStrings(s):match("^%s*([%a_][%w_]*)")) or ""
		end
		local function containsOpener(s)
			local clean = stripStrings(s)
			local fw = clean:match("^%s*([%a_][%w_]*)")
			if fw == "elseif" or fw == "else" then return false end
			for w in clean:gmatch("[%a_][%w_]*") do
				if INDENT_AFTER[w] then return true end
				if w == "function" then return true end
			end
			return false
		end
		for line in (text .. "\n"):gmatch("[^\n]*\n") do
			local bare = line:gsub("\n$", "")
			if bare == "" then
				result[#result + 1] = "\n"; continue
			end
			local expr = bare:match("^%[%d+%]%s*:?%d*:?%s*%u[%u_]*%s+(.*)") or bare
			local kw = firstWord(expr)
			if DEDENT_THEN_INDENT[kw] then
				depth = math.max(0, depth - 1)
				result[#result + 1] = string.rep("    ", depth) .. bare .. "\n"
				depth += 1
			elseif DEDENT_BEFORE[kw] then
				depth = math.max(0, depth - 1)
				result[#result + 1] = string.rep("    ", depth) .. bare .. "\n"
			else
				result[#result + 1] = string.rep("    ", depth) .. bare .. "\n"
				if containsOpener(expr) then depth += 1 end
			end
		end
		return table.concat(result)
	end
	local function _coImpl(text)
		local rawLines = {}
		for line in (text .. "\n"):gmatch("[^\n]*\n") do
			rawLines[#rawLines + 1] = line:gsub("\n$", "")
		end
		local function escpat(s)
			return s:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
		end
		local function nextNonBlank(start)
			local j = start
			while j <= #rawLines and (rawLines[j] == nil or rawLines[j]:match("^%s*$")) do
				j += 1
			end
			return j
		end
		local function tryCollapse(i)
			local line = rawLines[i]
			if line == nil then return false end
			local reg, lit = line:match('^%s*(v%d+) = (".-")%s*$')
			if not reg then reg, lit = line:match('^%s*(v%d+) = (%-?%d+%.?%d*)%s*$') end
			if not reg then reg, lit = line:match('^%s*(v%d+) = (true)%s*$') end
			if not reg then reg, lit = line:match('^%s*(v%d+) = (false)%s*$') end
			if not reg then reg, lit = line:match('^%s*(v%d+) = (nil)%s*$') end
			if not reg then reg, lit = line:match('^%s*(v%d+) = ([%a_][%w_%.]*)%s*$') end
			if not reg then return false end
			local j = nextNonBlank(i + 1)
			if j > #rawLines or rawLines[j] == nil then return false end
			local nextLine = rawLines[j]
			local ep = escpat(reg)
			local count = 0
			for _ in nextLine:gmatch(ep) do count += 1 end
			if count ~= 1 then return false end
			if nextLine:match("^%s*" .. ep .. "%s*=") then return false end
			rawLines[j] = nextLine:gsub(ep, lit, 1)
			rawLines[i] = nil
			return true
		end
		for _ = 1, 8 do
			for i = 1, #rawLines do tryCollapse(i) end
		end
		local function tryFoldField(i)
			local line = rawLines[i]
			if not line then return false end
			local lreg, src, field = line:match('^%s*(v%d+) = (v%d+)%.([%a_][%w_]*)%s*$')
			if not lreg then
				lreg, src, field = line:match('^%s*(v%d+) = (v%d+)%[(.-)%]%s*$')
				if lreg then field = "[" .. field .. "]" else return false end
			else
				field = "." .. field
			end
			local j = nextNonBlank(i + 1)
			if j > #rawLines then return false end
			local nextLine = rawLines[j]
			local epSrc = escpat(src)
			local epReg = escpat(lreg)
			local count = 0
			for _ in nextLine:gmatch(epReg) do count += 1 end
			if count ~= 1 then return false end
			if nextLine:match("^%s*" .. epReg .. "%s*=") then return false end
			rawLines[j] = nextLine:gsub(epReg, src .. field, 1)
			rawLines[i] = nil
			return true
		end
		for _ = 1, 6 do
			for i = 1, #rawLines do tryFoldField(i) end
		end
		local pass2 = {}
		for idx = 1, #rawLines do
			local line = rawLines[idx]
			if line == nil then continue end
			local stripped = line:match("^%s*(.-)%s*$")
			if stripped:match("^%-%- goto #%d+$") then continue end
			if stripped:match("^%-%- jump") then continue end
			line = line:gsub("%s*%-%- goto #%d+", "")
			line = line:gsub("%s*%-%- end at #%d+", "")
			line = line:gsub("%s*%-%- iterate %+ jump to #%d+", "")
			pass2[#pass2 + 1] = line
		end
		local pass3 = {}
		local i = 1
		while i <= #pass2 do
			local line = pass2[i]
			local nxt  = pass2[i + 1]
			local s    = line and line:match("^%s*(.-)%s*$") or ""
			local isNilInit = s:match("^v%d+ = nil") ~= nil
			local nextIsFor = nxt and nxt:match("^%s*for%s+v%d+") ~= nil
			if isNilInit and nextIsFor then
				i += 1
			else
				pass3[#pass3 + 1] = line
				i += 1
			end
		end
		local seen = {}
		local pass4 = {}
		for _, line in ipairs(pass3) do
			local reg = line:match("^%s*(v%d+)%s*=")
			if reg and not seen[reg] then
				seen[reg] = true
				line = line:gsub("^(%s*)(v%d+%s*=)", "%1local %2", 1)
			end
			pass4[#pass4 + 1] = line
		end
		local final = {}
		local lastBlank = false
		for _, line in ipairs(pass4) do
			local isBlank = line:match("^%s*$") ~= nil
			if isBlank and lastBlank then continue end
			lastBlank = isBlank
			final[#final + 1] = line
		end
		return table.concat(final, "\n")
	end
		ZukDecompile = Decompile
		prettyPrint  = _ppImpl
		cleanOutput  = _coImpl
		getgenv()._ZUK_DECOMPILE    = Decompile
		getgenv()._ZUK_PRETTYPRINT  = _ppImpl
		getgenv()._ZUK_CLEANOUTPUT  = _coImpl
	end)
]=]
	local ok, err = pcall(loadstring(_zukSource))
	if not ok then
		warn("[OverseerMini] zukv2 failed to load: " .. tostring(err))
	end
end
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
if not _G.Modules then
	_G.Modules = {}
end
local Modules = _G.Modules
Modules.TI = {
	State = {
		CurrentTable = nil,
		PathStack = {},
		VisitedTables = {},
		ModuleList = {},
		ActivePatches = {},
		FreezeList = {},
		UI = nil,
		MetatableChain = {},
		SelectedModule = nil,
	},
	Config = {
		BG_LIGHT = Color3.fromRGB(240, 240, 240),
		BG_PANEL = Color3.fromRGB(236, 233, 216),
		BG_DARK = Color3.fromRGB(212, 208, 200),
		BG_WHITE = Color3.fromRGB(255, 255, 255),
		BORDER_DARK = Color3.fromRGB(128, 128, 128),
		BORDER_LIGHT = Color3.fromRGB(128, 128, 128),
		TEXT_BLACK = Color3.fromRGB(0, 0, 0),
		TEXT_GRAY = Color3.fromRGB(128, 128, 128),
		ACCENT = Color3.fromRGB(111, 0, 0),
		HIGHLIGHT = Color3.fromRGB(51, 153, 255),
		FROZEN_RED = Color3.fromRGB(255, 0, 0),
		SUCCESS_GREEN = Color3.fromRGB(0, 180, 0),
		WARNING_ORANGE = Color3.fromRGB(255, 165, 0),
		ROW_HEIGHT = 22,
	},
}
local TI = Modules.TI
function TI:_generateUID()
	local cs = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	local r = ""
	for _ = 1, 12 do
		r = r .. cs:sub(math.random(1, #cs), math.random(1, #cs))
	end
	return r
end
function TI:_createBorder(parent, inset)
	local top = inset and self.Config.BORDER_DARK or self.Config.BORDER_LIGHT
	local bottom = inset and self.Config.BORDER_LIGHT or self.Config.BORDER_DARK
	local function edge(sz, pos, col)
		local f = Instance.new("Frame", parent)
		f.Size = sz
		f.Position = pos
		f.BackgroundColor3 = col
		f.BorderSizePixel = 0
		f.ZIndex = parent.ZIndex + 1
	end
	edge(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 0), top)
	edge(UDim2.new(0, 1, 1, 0), UDim2.new(0, 0, 0, 0), top)
	edge(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 1, -1), bottom)
	edge(UDim2.new(0, 1, 1, 0), UDim2.new(1, -1, 0, 0), bottom)
end
function TI:_createButton(parent, text, size, position, callback)
	local btn = Instance.new("TextButton", parent)
	btn.Size = size
	btn.Position = position
	btn.BackgroundColor3 = self.Config.BG_PANEL
	btn.Text = text
	btn.TextColor3 = self.Config.TEXT_BLACK
	btn.Font = Enum.Font.SourceSans
	btn.TextSize = 11
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.ClipsDescendants = true
	self:_createBorder(btn, false)
	if callback then
		btn.MouseButton1Click:Connect(callback)
	end
	btn.MouseButton1Down:Connect(function()
		btn.BackgroundColor3 = self.Config.BG_DARK
		for _, c in ipairs(btn:GetChildren()) do
			if c.Name == "BorderTop" or c.Name == "BorderLeft" then
				c.BackgroundColor3 = self.Config.BORDER_DARK
			elseif c.Name == "BorderBottom" or c.Name == "BorderRight" then
				c.BackgroundColor3 = self.Config.BORDER_LIGHT
			end
		end
	end)
	btn.MouseButton1Up:Connect(function()
		btn.BackgroundColor3 = self.Config.BG_PANEL
		for _, c in ipairs(btn:GetChildren()) do
			if c.Name == "BorderTop" or c.Name == "BorderLeft" then
				c.BackgroundColor3 = self.Config.BORDER_LIGHT
			elseif c.Name == "BorderBottom" or c.Name == "BorderRight" then
				c.BackgroundColor3 = self.Config.BORDER_DARK
			end
		end
	end)
	btn.MouseEnter:Connect(function()
		if btn.BackgroundColor3 ~= self.Config.BG_DARK then
			TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = self.Config.BG_LIGHT }):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		if btn.BackgroundColor3 ~= self.Config.BG_DARK then
			TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = self.Config.BG_PANEL }):Play()
		end
	end)
	return btn
end
function TI:_showNotification(message, msgType)
	if not self.State.UI then
		return
	end
	local notif = Instance.new("Frame", self.State.UI.Main)
	notif.Size = UDim2.fromOffset(280, 50)
	notif.Position = UDim2.new(1, -290, 1, 10)
	notif.BackgroundColor3 = msgType == "success" and Color3.fromRGB(220, 255, 220)
		or msgType == "error" and Color3.fromRGB(255, 220, 220)
		or msgType == "warning" and Color3.fromRGB(255, 245, 220)
		or self.Config.BG_LIGHT
	notif.BorderSizePixel = 0
	notif.ZIndex = 1000
	self:_createBorder(notif, true)
	local icon = Instance.new("TextLabel", notif)
	icon.Size = UDim2.fromOffset(34, 34)
	icon.Position = UDim2.fromOffset(8, 8)
	icon.BackgroundTransparency = 1
	icon.ZIndex = 1001
	icon.Text = msgType == "success" and "✓"
		or msgType == "error" and "✗"
		or msgType == "warning" and "⚠"
		or "ℹ"
	icon.TextColor3 = msgType == "success" and self.Config.SUCCESS_GREEN
		or msgType == "error" and self.Config.FROZEN_RED
		or msgType == "warning" and self.Config.WARNING_ORANGE
		or self.Config.ACCENT
	icon.Font = Enum.Font.SourceSansBold
	icon.TextSize = 22
	local msg = Instance.new("TextLabel", notif)
	msg.Size = UDim2.new(1, -48, 1, -4)
	msg.Position = UDim2.fromOffset(44, 2)
	msg.BackgroundTransparency = 1
	msg.ZIndex = 1001
	msg.Text = message
	msg.TextColor3 = self.Config.TEXT_BLACK
	msg.Font = Enum.Font.SourceSans
	msg.TextSize = 10
	msg.TextXAlignment = Enum.TextXAlignment.Left
	msg.TextYAlignment = Enum.TextYAlignment.Center
	msg.TextWrapped = true
	TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Position = UDim2.new(1, -290, 1, -60) })
		:Play()
	task.delay(3, function()
		local out = TweenService:Create(notif, TweenInfo.new(0.3), { Position = UDim2.new(1, -290, 1, 10) })
		out:Play()
		out.Completed:Connect(function()
			notif:Destroy()
		end)
	end)
end
function TI:GetRawMetatable(tbl)
	local ok, res = pcall(getmetatable, tbl)
	if ok and type(res) == "table" then
		return res, "getmetatable"
	end
	if getrawmetatable then
		ok, res = pcall(getrawmetatable, tbl)
		if ok and type(res) == "table" then
			return res, "getrawmetatable"
		end
	end
	if debug and debug.getmetatable then
		ok, res = pcall(debug.getmetatable, tbl)
		if ok and type(res) == "table" then
			return res, "debug.getmetatable"
		end
	end
	return nil, nil
end
function TI:UnlockMetatable(tbl)
	if type(tbl) ~= "table" then
		return false, "Not a table"
	end
	local mt = self:GetRawMetatable(tbl)
	if not mt then
		return false, "No metatable"
	end
	local locked = pcall(getmetatable, tbl) == false
	if setrawmetatable and locked then
		local ok = pcall(setrawmetatable, tbl, mt)
		return ok, ok and "Unlocked via setrawmetatable" or "setrawmetatable failed"
	end
	return not locked, locked and "Locked (no bypass available)" or "Already accessible"
end
function TI:AnalyzeMetatableChain(tbl)
	local chain, current, depth, visited = {}, tbl, 0, {}
	while current and depth < 20 do
		if visited[current] then
			break
		end
		visited[current] = true
		local mt, method = self:GetRawMetatable(current)
		if not mt then
			break
		end
		local unlocked, unlockMsg = self:UnlockMetatable(current)
		local entry = {
			Depth = depth,
			Metatable = mt,
			Fields = {},
			HasIndex = false,
			IndexType = nil,
			IndexValue = nil,
			Locked = not unlocked,
			AccessMethod = method,
			UnlockMessage = unlockMsg,
		}
		pcall(function()
			for k, v in pairs(mt) do
				table.insert(entry.Fields, { Key = k, Value = v, Type = type(v) })
				if k == "__index" then
					entry.HasIndex = true
					entry.IndexType = type(v)
					entry.IndexValue = v
				end
			end
		end)
		table.insert(chain, entry)
		if entry.HasIndex and entry.IndexType == "table" then
			current = entry.IndexValue
		else
			break
		end
		depth += 1
	end
	return chain
end
function TI:GetDisplayValue(value)
	local t = type(value)
	if t == "string" then
		return '"' .. value .. '"'
	elseif t == "number" then
		if value == math.floor(value) and value >= 0 and value < 2 ^ 32 then
			return string.format("%d (0x%X)", value, value)
		end
		return tostring(value)
	elseif t == "boolean" then
		return tostring(value)
	elseif t == "table" then
		local n = 0
		for _ in pairs(value) do
			n += 1
			if n > 100 then
				break
			end
		end
		return "{table: " .. n .. (n > 100 and "+" or "") .. " entries}"
	elseif t == "function" then
		if debug and debug.getinfo then
			local info = debug.getinfo(value)
			if info then
				return string.format("function (%s:%s)", (info.source or "?"):sub(1, 20), info.linedefined or "?")
			end
		end
		return "function"
	elseif t == "userdata" then
		local ok, s = pcall(tostring, value)
		return ok and (s .. " [userdata]") or "[userdata]"
	else
		return tostring(value)
	end
end
function TI:ParseValue(text, expectedType)
	if expectedType == "string" or text:match('^".*"$') or text:match("^'.*'$") then
		return text:gsub("^[\"']", ""):gsub("[\"']$", "")
	elseif text == "true" then
		return true
	elseif text == "false" then
		return false
	elseif text == "nil" then
		return nil
	elseif text == "{}" then
		return {}
	elseif tonumber(text) then
		return tonumber(text)
	else
		return expectedType == "any" and text or nil
	end
end
function TI:CreatePatch(tbl, key, newValue, freeze)
	if not tbl or key == nil then
		return false
	end
	local patchId = self:_generateUID()
	pcall(function()
		if setreadonly then
			setreadonly(tbl, false)
		elseif make_writeable then
			make_writeable(tbl)
		end
	end)
	local original = rawget(tbl, key)
	local patch = {
		ID = patchId,
		Table = tbl,
		Key = key,
		Original = original,
		NewValue = newValue,
		Frozen = freeze or false,
		Type = type(newValue),
		Timestamp = tick(),
		Active = true,
		Connection = nil,
	}
	rawset(tbl, key, newValue)
	self.State.ActivePatches[patchId] = patch
	if freeze then
		patch.Connection = RunService.Heartbeat:Connect(function()
			pcall(function()
				if setreadonly then
					setreadonly(tbl, false)
				end
				rawset(tbl, key, newValue)
				if setreadonly then
					setreadonly(tbl, true)
				end
			end)
		end)
		self.State.FreezeList[patchId] = patch
	end
	pcall(function()
		if setreadonly then
			setreadonly(tbl, true)
		end
	end)
	self:RefreshPatchList()
	self:_showNotification("Patched: " .. tostring(key), "success")
	return patchId
end
function TI:RemovePatch(patchId)
	local patch = self.State.ActivePatches[patchId]
	if not patch then
		return false
	end
	if patch.Connection then
		patch.Connection:Disconnect()
	end
	pcall(function()
		if setreadonly then
			setreadonly(patch.Table, false)
		elseif make_writeable then
			make_writeable(patch.Table)
		end
		rawset(patch.Table, patch.Key, patch.Original)
		if setreadonly then
			setreadonly(patch.Table, true)
		end
	end)
	self.State.ActivePatches[patchId] = nil
	self.State.FreezeList[patchId] = nil
	self:RefreshPatchList()
	self:_showNotification("Patch removed", "success")
	return true
end
function TI:ToggleFreeze(patchId)
	local patch = self.State.ActivePatches[patchId]
	if not patch then
		return
	end
	patch.Frozen = not patch.Frozen
	if patch.Frozen then
		if not patch.Connection then
			local tbl, key, val = patch.Table, patch.Key, patch.NewValue
			patch.Connection = RunService.Heartbeat:Connect(function()
				pcall(function()
					if setreadonly then
						setreadonly(tbl, false)
					end
					rawset(tbl, key, val)
					if setreadonly then
						setreadonly(tbl, true)
					end
				end)
			end)
		end
		self.State.FreezeList[patchId] = patch
	else
		if patch.Connection then
			patch.Connection:Disconnect()
			patch.Connection = nil
		end
		self.State.FreezeList[patchId] = nil
	end
	self:RefreshPatchList()
end
function TI:DrillDown(name, tbl)
	if type(tbl) ~= "table" then
		self:_showNotification("Cannot dive: " .. tostring(name) .. " is " .. type(tbl), "warning")
		return
	end
	local ok, err = pcall(function()
		return next(tbl)
	end)
	if not ok then
		self:_showNotification("Table is protected: " .. tostring(name), "error")
		return
	end
	table.insert(self.State.PathStack, tostring(name))
	self.State.CurrentTable = tbl
	self.State.VisitedTables = {}
	self:RefreshInspector()
	self:_showNotification("Diving into: " .. tostring(name), "info")
end
function TI:GoBack()
	if #self.State.PathStack == 0 then
		return
	end
	table.remove(self.State.PathStack)
	local root = self.State._RootTable
	if not root then
		return
	end
	local tbl = root
	for _, part in ipairs(self.State.PathStack) do
		tbl = type(tbl) == "table" and tbl[part] or nil
		if not tbl then
			return
		end
	end
	self.State.CurrentTable = tbl
	self.State.VisitedTables = {}
	self:RefreshInspector()
end
function TI:RefreshInspector()
	if not self.State.UI or not self.State.CurrentTable then
		return
	end
	for _, c in ipairs(self.State.UI.InspectorScroll:GetChildren()) do
		if not c:IsA("UIListLayout") then
			c:Destroy()
		end
	end
	local pathText = #self.State.PathStack > 0 and table.concat(self.State.PathStack, " > ") or "Root"
	self.State.UI.PathLabel.Text = pathText
	self:PopulateTable(self.State.CurrentTable)
	local chain = self:AnalyzeMetatableChain(self.State.CurrentTable)
	self.State.MetatableChain = chain
	if #chain > 0 then
		self:DisplayMetatableChain(chain)
	end
end
function TI:PopulateTable(tbl, isMetatable)
	if not tbl or type(tbl) ~= "table" then
		return
	end
	if self.State.VisitedTables[tbl] then
		return
	end
	local entries = {}
	local ok, err = pcall(function()
		for k, v in pairs(tbl) do
			table.insert(entries, { Key = k, Value = v })
		end
	end)
	if not ok then
		self:CreateInspectorRow("[ERROR]", "Cannot read table: " .. tostring(err), tbl, isMetatable)
		return
	end
	if #entries == 0 then
		self:CreateInspectorRow("[EMPTY]", "No entries", tbl, isMetatable)
		self.State.VisitedTables[tbl] = true
		return
	end
	self.State.VisitedTables[tbl] = true
	table.sort(entries, function(a, b)
		local as, bs = tostring(a.Key), tostring(b.Key)
		local aS = as:match("^%[")
		local bS = bs:match("^%[")
		if aS and not bS then
			return false
		end
		if bS and not aS then
			return true
		end
		local an, bn = tonumber(a.Key), tonumber(b.Key)
		if an and bn then
			return an < bn
		end
		if an then
			return true
		end
		if bn then
			return false
		end
		return as < bs
	end)
	for _, e in ipairs(entries) do
		self:CreateInspectorRow(e.Key, e.Value, tbl, isMetatable)
	end
end
function TI:CreateInspectorRow(key, value, parentTable, isMetatable)
	if not self.State.UI then
		return
	end
	local valueType = type(value)
	local displayValue = self:GetDisplayValue(value)
	if valueType == "table" then
		local n, ok = 0, true
		ok = pcall(function()
			for _ in pairs(value) do
				n += 1
				if n > 100 then
					break
				end
			end
		end)
		displayValue = ok and ("{table: " .. n .. (n > 100 and "+" or "") .. " entries}") or "{table: protected}"
	end
	local row = Instance.new("Frame", self.State.UI.InspectorScroll)
	row.Size = UDim2.new(1, -2, 0, self.Config.ROW_HEIGHT)
	row.BorderSizePixel = 0
	local isPatched, isFrozen = false, false
	for _, p in pairs(self.State.ActivePatches) do
		if p.Table == parentTable and p.Key == key then
			isPatched = true
			isFrozen = p.Frozen
			break
		end
	end
	row.BackgroundColor3 = isFrozen and Color3.fromRGB(255, 220, 220)
		or isMetatable and self.Config.BG_LIGHT
		or self.Config.BG_WHITE
	local activeBox = Instance.new("TextButton", row)
	activeBox.Size = UDim2.fromOffset(12, 12)
	activeBox.Position = UDim2.new(0.03, -6, 0.5, -6)
	activeBox.BackgroundColor3 = self.Config.BG_WHITE
	activeBox.Text = isPatched and "X" or ""
	activeBox.TextColor3 = self.Config.TEXT_BLACK
	activeBox.Font = Enum.Font.SourceSansBold
	activeBox.TextSize = 10
	activeBox.BorderSizePixel = 0
	activeBox.AutoButtonColor = false
	self:_createBorder(activeBox, true)
	local keyLabel = Instance.new("TextLabel", row)
	keyLabel.Size = UDim2.new(0.26, -4, 1, 0)
	keyLabel.Position = UDim2.new(0.07, 2, 0, 0)
	keyLabel.BackgroundTransparency = 1
	keyLabel.Text = tostring(key)
	keyLabel.TextColor3 = isMetatable and Color3.fromRGB(0, 0, 128) or self.Config.TEXT_BLACK
	keyLabel.Font = isMetatable and Enum.Font.Code or Enum.Font.SourceSans
	keyLabel.TextSize = 10
	keyLabel.TextXAlignment = Enum.TextXAlignment.Left
	keyLabel.TextTruncate = Enum.TextTruncate.AtEnd
	local typeLabel = Instance.new("TextLabel", row)
	typeLabel.Size = UDim2.new(0.12, -4, 1, 0)
	typeLabel.Position = UDim2.new(0.33, 2, 0, 0)
	typeLabel.BackgroundTransparency = 1
	typeLabel.Text = valueType
	typeLabel.TextColor3 = self.Config.TEXT_GRAY
	typeLabel.Font = Enum.Font.SourceSans
	typeLabel.TextSize = 9
	typeLabel.TextXAlignment = Enum.TextXAlignment.Left
	local valueBox = Instance.new("TextBox", row)
	valueBox.Size = UDim2.new(0.35, -4, 1, 0)
	valueBox.Position = UDim2.new(0.45, 2, 0, 0)
	valueBox.BackgroundTransparency = 1
	valueBox.Text = displayValue
	valueBox.TextColor3 = self.Config.TEXT_BLACK
	valueBox.Font = Enum.Font.Code
	valueBox.TextSize = 9
	valueBox.TextXAlignment = Enum.TextXAlignment.Left
	valueBox.TextTruncate = Enum.TextTruncate.AtEnd
	valueBox.TextEditable = (valueType ~= "table" and valueType ~= "function")
	valueBox.ClearTextOnFocus = false
	valueBox.FocusLost:Connect(function(enterPressed)
		if enterPressed and valueBox.TextEditable then
			local nv = self:ParseValue(valueBox.Text, valueType)
			if nv ~= nil then
				self:CreatePatch(parentTable, key, nv, false)
			else
				self:_showNotification("Invalid value for type: " .. valueType, "error")
			end
		end
	end)
	local actionBtn = self:_createButton(row, "Patch", UDim2.fromOffset(45, 16), UDim2.new(0.80, 2, 0.5, -8), function()
		if valueType == "table" then
			self:DrillDown(key, value)
		elseif valueType == "function" then
			self:_showNotification("Function at: " .. tostring(key) .. " — hook from full tool", "info")
		else
			local nv = self:ParseValue(valueBox.Text, valueType)
			if nv ~= nil then
				self:CreatePatch(parentTable, key, nv, false)
			else
				self:_showNotification("Invalid value for type: " .. valueType, "error")
			end
		end
	end)
	actionBtn.TextSize = 9
	if valueType == "table" then
		actionBtn.Text = "Dive"
		actionBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
	elseif valueType == "function" then
		actionBtn.Text = "Info"
		actionBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
	end
	local freezeBtn = self:_createButton(
		row,
		"Freeze",
		UDim2.fromOffset(45, 16),
		UDim2.new(0.88, 2, 0.5, -8),
		function()
			if valueBox.TextEditable then
				local nv = self:ParseValue(valueBox.Text, valueType)
				if nv ~= nil then
					self:CreatePatch(parentTable, key, nv, true)
				else
					self:_showNotification("Invalid value for type: " .. valueType, "error")
				end
			else
				self:_showNotification("Cannot freeze " .. valueType, "warning")
			end
		end
	)
	freezeBtn.TextSize = 9
	if valueType == "table" then
		local lastClick = 0
		row.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local now = tick()
				if now - lastClick < 0.5 then
					pcall(function()
						self:DrillDown(key, value)
					end)
				end
				lastClick = now
			end
		end)
	end
	row.MouseEnter:Connect(function()
		if not isFrozen then
			row.BackgroundColor3 = Color3.fromRGB(230, 240, 255)
		end
	end)
	row.MouseLeave:Connect(function()
		local pFrozen = false
		for _, p in pairs(self.State.ActivePatches) do
			if p.Table == parentTable and p.Key == key then
				pFrozen = p.Frozen
				break
			end
		end
		row.BackgroundColor3 = pFrozen and Color3.fromRGB(255, 220, 220)
			or isMetatable and self.Config.BG_LIGHT
			or self.Config.BG_WHITE
	end)
end
function TI:DisplayMetatableChain(chain)
	if not self.State.UI or not chain or #chain == 0 then
		return
	end
	for i, entry in ipairs(chain) do
		local sep = Instance.new("Frame", self.State.UI.InspectorScroll)
		sep.Size = UDim2.new(1, -2, 0, self.Config.ROW_HEIGHT)
		sep.BorderSizePixel = 0
		sep.BackgroundColor3 = entry.Locked and Color3.fromRGB(200, 100, 100) or self.Config.ACCENT
		local lbl = Instance.new("TextLabel", sep)
		lbl.Size = UDim2.new(1, -8, 1, 0)
		lbl.Position = UDim2.fromOffset(4, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = (entry.Locked and "🔒 " or "🔓 ")
			.. "METATABLE #"
			.. i
			.. " (depth "
			.. entry.Depth
			.. ")"
			.. (entry.Locked and " [LOCKED]" or " [Unlocked]")
		lbl.TextColor3 = self.Config.BG_WHITE
		lbl.Font = Enum.Font.SourceSansBold
		lbl.TextSize = 10
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		if entry.AccessMethod or entry.UnlockMessage then
			local info = Instance.new("Frame", self.State.UI.InspectorScroll)
			info.Size = UDim2.new(1, -2, 0, self.Config.ROW_HEIGHT)
			info.BackgroundColor3 = Color3.fromRGB(240, 240, 200)
			info.BorderSizePixel = 0
			local il = Instance.new("TextLabel", info)
			il.Size = UDim2.new(1, -8, 1, 0)
			il.Position = UDim2.fromOffset(4, 0)
			il.BackgroundTransparency = 1
			il.Text = "  ℹ️ " .. (entry.UnlockMessage or ("Access: " .. entry.AccessMethod))
			il.TextColor3 = Color3.fromRGB(100, 100, 0)
			il.Font = Enum.Font.SourceSansItalic
			il.TextSize = 9
			il.TextXAlignment = Enum.TextXAlignment.Left
		end
		for _, field in ipairs(entry.Fields) do
			self:CreateInspectorRow(field.Key, field.Value, entry.Metatable, true)
		end
	end
end
function TI:RefreshPatchList()
	if not self.State.UI then
		return
	end
	for _, c in ipairs(self.State.UI.PatchScroll:GetChildren()) do
		if not c:IsA("UIListLayout") then
			c:Destroy()
		end
	end
	local count = 0
	for id, patch in pairs(self.State.ActivePatches) do
		count += 1
		self:CreatePatchRow(id, patch)
	end
	self.State.UI.PatchCount.Text = "Patches: " .. count
end
function TI:CreatePatchRow(patchId, patch)
	local row = Instance.new("Frame", self.State.UI.PatchScroll)
	row.Size = UDim2.new(1, -2, 0, self.Config.ROW_HEIGHT)
	row.BackgroundColor3 = patch.Frozen and Color3.fromRGB(255, 220, 220) or self.Config.BG_WHITE
	row.BorderSizePixel = 0
	local freezeBox = Instance.new("TextButton", row)
	freezeBox.Size = UDim2.fromOffset(12, 12)
	freezeBox.Position = UDim2.new(0.05, -6, 0.5, -6)
	freezeBox.BackgroundColor3 = self.Config.BG_WHITE
	freezeBox.Text = patch.Frozen and "X" or ""
	freezeBox.TextColor3 = self.Config.FROZEN_RED
	freezeBox.Font = Enum.Font.SourceSansBold
	freezeBox.TextSize = 10
	freezeBox.BorderSizePixel = 0
	freezeBox.AutoButtonColor = false
	self:_createBorder(freezeBox, true)
	freezeBox.MouseButton1Click:Connect(function()
		self:ToggleFreeze(patchId)
	end)
	local keyLbl = Instance.new("TextLabel", row)
	keyLbl.Size = UDim2.new(0.38, -4, 1, 0)
	keyLbl.Position = UDim2.new(0.13, 2, 0, 0)
	keyLbl.BackgroundTransparency = 1
	keyLbl.Text = tostring(patch.Key)
	keyLbl.TextColor3 = self.Config.TEXT_BLACK
	keyLbl.Font = Enum.Font.SourceSans
	keyLbl.TextSize = 9
	keyLbl.TextXAlignment = Enum.TextXAlignment.Left
	keyLbl.TextTruncate = Enum.TextTruncate.AtEnd
	local valLbl = Instance.new("TextLabel", row)
	valLbl.Size = UDim2.new(0.35, -4, 1, 0)
	valLbl.Position = UDim2.new(0.51, 2, 0, 0)
	valLbl.BackgroundTransparency = 1
	valLbl.Text = tostring(patch.NewValue):sub(1, 20)
	valLbl.TextColor3 = self.Config.TEXT_BLACK
	valLbl.Font = Enum.Font.Code
	valLbl.TextSize = 9
	valLbl.TextXAlignment = Enum.TextXAlignment.Left
	valLbl.TextTruncate = Enum.TextTruncate.AtEnd
	local del = self:_createButton(row, "X", UDim2.fromOffset(16, 16), UDim2.new(0.88, 0, 0.5, -8), function()
		self:RemovePatch(patchId)
	end)
	del.TextSize = 10
	del.Font = Enum.Font.SourceSansBold
	del.BackgroundColor3 = Color3.fromRGB(255, 200, 200)
end
local ROBLOX_MODULE_BLACKLIST = {
	["BaseCamera"] = true,
	["MouseLockController"] = true,
	["OrbitalCamera"] = true,
	["ControlModule"] = true,
	["CameraModule"] = true,
	["PlayerModule"] = true,
	["ClassicCamera"] = true,
	["Poppercam"] = true,
	["TransparencyController"] = true,
}
function TI:ScanModules()
	if not self.State.UI then
		return
	end
	for _, c in ipairs(self.State.UI.ModuleScroll:GetChildren()) do
		if not c:IsA("UIListLayout") then
			c:Destroy()
		end
	end
	self.State.ModuleList = {}
	task.spawn(function()
		for _, root in ipairs({ ReplicatedStorage, Players.LocalPlayer, Workspace }) do
			if root then
				for _, obj in ipairs(root:GetDescendants()) do
					if obj:IsA("ModuleScript") and not ROBLOX_MODULE_BLACKLIST[obj.Name] then
						self:AddModuleToList(obj)
					end
				end
				task.wait()
			end
		end
		self:_showNotification("Found " .. #self.State.ModuleList .. " modules", "success")
	end)
end
function TI:AddModuleToList(ms)
	if not self.State.UI then
		return
	end
	local row = Instance.new("TextButton", self.State.UI.ModuleScroll)
	row.Size = UDim2.new(1, -2, 0, self.Config.ROW_HEIGHT)
	row.BackgroundColor3 = self.Config.BG_WHITE
	row.Text = ""
	row.BorderSizePixel = 0
	row.AutoButtonColor = false
	local lbl = Instance.new("TextLabel", row)
	lbl.Size = UDim2.new(1, -8, 1, 0)
	lbl.Position = UDim2.fromOffset(4, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = ms.Name
	lbl.TextColor3 = self.Config.TEXT_BLACK
	lbl.Font = Enum.Font.SourceSans
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextTruncate = Enum.TextTruncate.AtEnd
	row.MouseButton1Click:Connect(function()
		for _, child in ipairs(self.State.UI.ModuleScroll:GetChildren()) do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = self.Config.BG_WHITE
				for _, l in ipairs(child:GetChildren()) do
					if l:IsA("TextLabel") then
						l.TextColor3 = self.Config.TEXT_BLACK
					end
				end
			end
		end
		row.BackgroundColor3 = self.Config.HIGHLIGHT
		lbl.TextColor3 = self.Config.BG_WHITE
		self.State.SelectedModule = ms
		if self.State.UI and self.State.UI.ScriptViewerName then
			self.State.UI.ScriptViewerName.Text = ms.Name .. "  (" .. ms:GetFullName() .. ")"
			self.State.UI.ScriptViewerOutput.Text = "← Click Decompile to view '" .. ms.Name .. "' as disassembly"
			self.State.UI.ScriptViewerStatus.Text = ""
		end
		self:LoadModule(ms)
	end)
	row.MouseEnter:Connect(function()
		if row.BackgroundColor3 ~= self.Config.HIGHLIGHT then
			row.BackgroundColor3 = self.Config.BG_LIGHT
		end
	end)
	row.MouseLeave:Connect(function()
		if row.BackgroundColor3 ~= self.Config.HIGHLIGHT then
			row.BackgroundColor3 = self.Config.BG_WHITE
		end
	end)
	table.insert(self.State.ModuleList, { Script = ms, Row = row, Name = ms.Name })
end
function TI:LoadModule(ms)
	local success, result, done = false, nil, false
	task.spawn(function()
		success, result = pcall(require, ms)
		done = true
	end)
	local t = 0
	while not done and t < 2 do
		task.wait(0.1)
		t += 0.1
	end
	if not done then
		self:_showNotification("Timeout loading: " .. ms.Name, "warning")
		return
	end
	if not success then
		self:_showNotification("Error: " .. tostring(result), "error")
		return
	end
	if result == nil then
		result = { ["[Module]"] = ms.Name, ["[Returns]"] = "nil" }
	end
	if type(result) ~= "table" then
		result = { ["[Value]"] = result, ["[Type]"] = type(result) }
	end
	self.State._RootTable = result
	self.State.CurrentTable = result
	self.State.PathStack = {}
	self.State.VisitedTables = {}
	self:RefreshInspector()
	self:_showNotification("Loaded: " .. ms.Name, "success")
end
function TI:FilterModules(query)
	query = query:lower()
	for _, md in ipairs(self.State.ModuleList) do
		md.Row.Visible = query == "" or md.Name:lower():find(query, 1, true) ~= nil
	end
end
local ICON_B64 =
	"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"
local _ICON_ASSET = nil
local function _getIconAsset()
	if _ICON_ASSET then
		return _ICON_ASSET
	end
	if type(writefile) == "function" and type(getcustomasset) == "function" then
		local path = "zukamisc_icons/TI_logo.jpg"
		pcall(makefolder, "zukamisc_icons")
		pcall(function()
			local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
			local data = ICON_B64:gsub("[^" .. b .. "=]", "")
			local result = {}
			local i = 1
			while i <= #data do
				local c1 = (b:find(data:sub(i, i), 1, true) or 1) - 1
				local c2 = (b:find(data:sub(i + 1, i + 1), 1, true) or 1) - 1
				local c3 = data:sub(i + 2, i + 2) == "=" and 0 or ((b:find(data:sub(i + 2, i + 2), 1, true) or 1) - 1)
				local c4 = data:sub(i + 3, i + 3) == "=" and 0 or ((b:find(data:sub(i + 3, i + 3), 1, true) or 1) - 1)
				local n = c1 * 262144 + c2 * 4096 + c3 * 64 + c4
				result[#result + 1] = string.char(math.floor(n / 65536))
				if data:sub(i + 2, i + 2) ~= "=" then
					result[#result + 1] = string.char(math.floor((n % 65536) / 256))
				end
				if data:sub(i + 3, i + 3) ~= "=" then
					result[#result + 1] = string.char(n % 256)
				end
				i = i + 4
			end
			writefile(path, table.concat(result))
		end)
		local ok, asset = pcall(getcustomasset, path)
		if ok and asset and asset ~= "" then
			_ICON_ASSET = asset
			return asset
		end
	end
	_ICON_ASSET = ""
	return ""
end
local function _makeIconImage(parent, size, zIndex)
	local img = Instance.new("ImageLabel", parent)
	img.Size = UDim2.fromOffset(size, size)
	img.Position = UDim2.new(0.5, -size / 2, 0.5, -size / 2)
	img.BackgroundTransparency = 1
	img.Image = ""
	img.ZIndex = zIndex or 2
	img.ScaleType = Enum.ScaleType.Fit
	task.spawn(function()
		local asset = _getIconAsset()
		img.Image = asset
	end)
	return img
end
function TI:Minimize()
	local ui = self.State.UI
	if not ui or ui.Minimized then
		return
	end
	ui.Minimized = true
	ui._savedPosition = ui.Main.Position
	local offX = ui.Main.Position.X.Offset + ui.Main.AbsoluteSize.X + 40
	local slideOut = TweenService:Create(ui.Main, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(ui.Main.Position.X.Scale, offX, ui.Main.Position.Y.Scale, ui.Main.Position.Y.Offset),
	})
	slideOut:Play()
	slideOut.Completed:Connect(function()
		ui.Main.Visible = false
		ui.RestoreTab.Position = UDim2.new(1, 14, ui.RestoreTab.Position.Y.Scale, ui.RestoreTab.Position.Y.Offset)
		ui.RestoreTab.Visible = true
		TweenService:Create(ui.RestoreTab, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, -34, ui.RestoreTab.Position.Y.Scale, ui.RestoreTab.Position.Y.Offset),
		}):Play()
	end)
end
function TI:Restore()
	local ui = self.State.UI
	if not ui or not ui.Minimized then
		return
	end
	ui.Minimized = false
	local savedPos = ui._savedPosition or UDim2.new(0.5, -530, 0.5, -360)
	TweenService:Create(ui.RestoreTab, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(1, 14, ui.RestoreTab.Position.Y.Scale, ui.RestoreTab.Position.Y.Offset),
	}):Play()
	task.delay(0.15, function()
		ui.RestoreTab.Visible = false
	end)
	ui.Main.Position = UDim2.new(
		savedPos.X.Scale,
		savedPos.X.Offset + ui.Main.AbsoluteSize.X + 40,
		savedPos.Y.Scale,
		savedPos.Y.Offset
	)
	ui.Main.Visible = true
	TweenService:Create(ui.Main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = savedPos,
	}):Play()
end
function TI:CreateUI()
	if self.State.UI and self.State.UI.Main then
		self.State.UI.Main.Visible = true
		return
	end
	pcall(function()
		local old = CoreGui:FindFirstChild("TableInspector")
		if old then
			old:Destroy()
		end
	end)
	local sg = Instance.new("ScreenGui", CoreGui)
	sg.Name = "TableInspector"
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local main = Instance.new("Frame", sg)
	main.Name = "Main"
	main.Size = UDim2.fromOffset(1060, 720)
	main.Position = UDim2.new(0.5, -530, 0.5, -360)
	main.BackgroundColor3 = self.Config.BG_PANEL
	main.BorderSizePixel = 0
	main.ClipsDescendants = false
	self:_createBorder(main, false)
	local titleBar = Instance.new("Frame", main)
	titleBar.Size = UDim2.new(1, 0, 0, 24)
	titleBar.BackgroundColor3 = self.Config.BG_DARK
	titleBar.BorderSizePixel = 0
	self:_createBorder(titleBar, true)
	local title = Instance.new("TextLabel", titleBar)
	title.Size = UDim2.new(1, -72, 1, 0)
	title.Position = UDim2.fromOffset(6, 0)
	title.BackgroundTransparency = 1
	title.Text = "Table Inspector  ·  Editor  ·  Freeze  ·  Dive"
	title.TextColor3 = self.Config.TEXT_BLACK
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	self:_createButton(titleBar, "×", UDim2.fromOffset(20, 18), UDim2.new(1, -22, 0, 2), function()
		main.Visible = false
	end)
	local minimizeBtn = self:_createButton(
		titleBar,
		"─",
		UDim2.fromOffset(20, 18),
		UDim2.new(1, -44, 0, 2),
		function()
			self:Minimize()
		end
	)
	local dragging, dragStart, startPos
	titleBar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = i.Position
			startPos = main.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - dragStart
			main.Position =
				UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	local content = Instance.new("Frame", main)
	content.Size = UDim2.new(1, -4, 1, -28)
	content.Position = UDim2.fromOffset(2, 26)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	local modPanel = Instance.new("Frame", content)
	modPanel.Size = UDim2.fromOffset(210, 688)
	modPanel.Position = UDim2.fromOffset(0, 0)
	modPanel.BackgroundColor3 = self.Config.BG_PANEL
	modPanel.BorderSizePixel = 0
	self:_createBorder(modPanel, false)
	local modTitle = Instance.new("TextLabel", modPanel)
	modTitle.Size = UDim2.new(1, -4, 0, 18)
	modTitle.Position = UDim2.fromOffset(2, 2)
	modTitle.BackgroundColor3 = self.Config.BG_DARK
	modTitle.BorderSizePixel = 0
	modTitle.Text = "Modules"
	modTitle.TextColor3 = self.Config.TEXT_BLACK
	modTitle.Font = Enum.Font.SourceSansBold
	modTitle.TextSize = 11
	modTitle.TextXAlignment = Enum.TextXAlignment.Left
	local mp = Instance.new("UIPadding", modTitle)
	mp.PaddingLeft = UDim.new(0, 4)
	self:_createBorder(modTitle, true)
	local modSearch = Instance.new("TextBox", modPanel)
	modSearch.Size = UDim2.new(1, -8, 0, 22)
	modSearch.Position = UDim2.fromOffset(4, 24)
	modSearch.BackgroundColor3 = self.Config.BG_WHITE
	modSearch.Text = ""
	modSearch.PlaceholderText = "Search modules..."
	modSearch.TextColor3 = self.Config.TEXT_BLACK
	modSearch.Font = Enum.Font.SourceSans
	modSearch.TextSize = 12
	modSearch.TextXAlignment = Enum.TextXAlignment.Left
	modSearch.BorderSizePixel = 0
	modSearch.ClearTextOnFocus = false
	local msp = Instance.new("UIPadding", modSearch)
	msp.PaddingLeft = UDim.new(0, 4)
	self:_createBorder(modSearch, true)
	local rescanBtn = self:_createButton(
		modPanel,
		"Rescan",
		UDim2.new(1, -8, 0, 20),
		UDim2.fromOffset(4, 50),
		function()
			self:ScanModules()
		end
	)
	rescanBtn.TextSize = 10
	local modScroll = Instance.new("ScrollingFrame", modPanel)
	modScroll.Size = UDim2.new(1, -8, 1, -78)
	modScroll.Position = UDim2.fromOffset(4, 74)
	modScroll.BackgroundColor3 = self.Config.BG_WHITE
	modScroll.BorderSizePixel = 0
	modScroll.ScrollBarThickness = 10
	modScroll.ScrollBarImageColor3 = self.Config.BG_DARK
	modScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	modScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	self:_createBorder(modScroll, true)
	local modList = Instance.new("UIListLayout", modScroll)
	modList.Padding = UDim.new(0, 1)
	local debounce
	modSearch.Changed:Connect(function(prop)
		if prop == "Text" then
			if debounce then
				task.cancel(debounce)
			end
			debounce = task.delay(0.25, function()
				self:FilterModules(modSearch.Text)
			end)
		end
	end)
	local inspPanel = Instance.new("Frame", content)
	inspPanel.Size = UDim2.fromOffset(650, 688)
	inspPanel.Position = UDim2.fromOffset(214, 0)
	inspPanel.BackgroundColor3 = self.Config.BG_PANEL
	inspPanel.BorderSizePixel = 0
	self:_createBorder(inspPanel, false)
	local inspTitle = Instance.new("TextLabel", inspPanel)
	inspTitle.Size = UDim2.new(1, -4, 0, 18)
	inspTitle.Position = UDim2.fromOffset(2, 2)
	inspTitle.BackgroundColor3 = self.Config.BG_DARK
	inspTitle.BorderSizePixel = 0
	inspTitle.Text = "Table Inspector"
	inspTitle.TextColor3 = self.Config.TEXT_BLACK
	inspTitle.Font = Enum.Font.SourceSansBold
	inspTitle.TextSize = 11
	inspTitle.TextXAlignment = Enum.TextXAlignment.Left
	local itp = Instance.new("UIPadding", inspTitle)
	itp.PaddingLeft = UDim.new(0, 4)
	self:_createBorder(inspTitle, true)
	local svTabStrip = Instance.new("Frame", inspPanel)
	svTabStrip.Size = UDim2.new(1, -4, 0, 20)
	svTabStrip.Position = UDim2.fromOffset(2, 20)
	svTabStrip.BackgroundColor3 = self.Config.BG_DARK
	svTabStrip.BorderSizePixel = 0
	self:_createBorder(svTabStrip, true)
	local svActiveTab = "inspector"
	local svInspTab = Instance.new("TextButton", svTabStrip)
	svInspTab.Size = UDim2.fromOffset(110, 20)
	svInspTab.Position = UDim2.fromOffset(0, 0)
	svInspTab.BackgroundColor3 = self.Config.BG_LIGHT
	svInspTab.Text = "Table Inspector"
	svInspTab.TextColor3 = self.Config.TEXT_BLACK
	svInspTab.Font = Enum.Font.SourceSansBold
	svInspTab.TextSize = 10
	svInspTab.BorderSizePixel = 0
	svInspTab.AutoButtonColor = false
	self:_createBorder(svInspTab, false)
	local svScriptTab = Instance.new("TextButton", svTabStrip)
	svScriptTab.Size = UDim2.fromOffset(100, 20)
	svScriptTab.Position = UDim2.fromOffset(111, 0)
	svScriptTab.BackgroundColor3 = self.Config.BG_PANEL
	svScriptTab.Text = "Script Viewer"
	svScriptTab.TextColor3 = self.Config.TEXT_BLACK
	svScriptTab.Font = Enum.Font.SourceSans
	svScriptTab.TextSize = 10
	svScriptTab.BorderSizePixel = 0
	svScriptTab.AutoButtonColor = false
	self:_createBorder(svScriptTab, true)
	local toolbar = Instance.new("Frame", inspPanel)
	toolbar.Size = UDim2.new(1, -8, 0, 26)
	toolbar.Position = UDim2.fromOffset(4, 42)
	toolbar.BackgroundColor3 = self.Config.BG_DARK
	toolbar.BorderSizePixel = 0
	self:_createBorder(toolbar, true)
	self:_createButton(toolbar, "< Back", UDim2.fromOffset(58, 20), UDim2.fromOffset(2, 2), function()
		self:GoBack()
	end)
	self:_createButton(toolbar, "Refresh", UDim2.fromOffset(58, 20), UDim2.fromOffset(62, 2), function()
		self:RefreshInspector()
	end)
	local pathLabel = Instance.new("TextLabel", toolbar)
	pathLabel.Size = UDim2.new(1, -128, 1, -4)
	pathLabel.Position = UDim2.fromOffset(124, 2)
	pathLabel.BackgroundTransparency = 1
	pathLabel.Text = "Root"
	pathLabel.TextColor3 = self.Config.TEXT_BLACK
	pathLabel.Font = Enum.Font.Code
	pathLabel.TextSize = 11
	pathLabel.TextXAlignment = Enum.TextXAlignment.Left
	pathLabel.TextTruncate = Enum.TextTruncate.AtEnd
	local hdr = Instance.new("Frame", inspPanel)
	hdr.Size = UDim2.new(1, -8, 0, self.Config.ROW_HEIGHT)
	hdr.Position = UDim2.fromOffset(4, 72)
	hdr.BackgroundColor3 = self.Config.BG_DARK
	hdr.BorderSizePixel = 0
	self:_createBorder(hdr, true)
	local hdrs = { "Active", "Key", "Type", "Value", "Actions" }
	local hW = { 0.07, 0.26, 0.12, 0.35, 0.20 }
	local xp = 0
	for i, ht in ipairs(hdrs) do
		local h = Instance.new("TextLabel", hdr)
		h.Size = UDim2.new(hW[i], -2, 1, 0)
		h.Position = UDim2.new(xp, 1, 0, 0)
		h.BackgroundTransparency = 1
		h.Text = ht
		h.TextColor3 = self.Config.TEXT_BLACK
		h.Font = Enum.Font.SourceSansBold
		h.TextSize = 11
		h.TextXAlignment = Enum.TextXAlignment.Left
		local hp = Instance.new("UIPadding", h)
		hp.PaddingLeft = UDim.new(0, 4)
		xp = xp + hW[i]
	end
	local inspScroll = Instance.new("ScrollingFrame", inspPanel)
	inspScroll.Size = UDim2.new(1, -8, 1, -100)
	inspScroll.Position = UDim2.fromOffset(4, 96)
	inspScroll.BackgroundColor3 = self.Config.BG_WHITE
	inspScroll.BorderSizePixel = 0
	inspScroll.ScrollBarThickness = 12
	inspScroll.ScrollBarImageColor3 = self.Config.BG_DARK
	inspScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	inspScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	self:_createBorder(inspScroll, true)
	local inspList = Instance.new("UIListLayout", inspScroll)
	inspList.Padding = UDim.new(0, 0)
	local scriptPanel = Instance.new("Frame", inspPanel)
	scriptPanel.Size = UDim2.new(1, -8, 1, -100)
	scriptPanel.Position = UDim2.fromOffset(4, 96)
	scriptPanel.BackgroundColor3 = self.Config.BG_WHITE
	scriptPanel.BorderSizePixel = 0
	scriptPanel.Visible = false
	self:_createBorder(scriptPanel, true)
	local svToolbar = Instance.new("Frame", scriptPanel)
	svToolbar.Size = UDim2.new(1, 0, 0, 28)
	svToolbar.Position = UDim2.fromOffset(0, 0)
	svToolbar.BackgroundColor3 = self.Config.BG_DARK
	svToolbar.BorderSizePixel = 0
	self:_createBorder(svToolbar, true)
	local svScriptNameLbl = Instance.new("TextLabel", svToolbar)
	svScriptNameLbl.Size = UDim2.new(1, -260, 1, -4)
	svScriptNameLbl.Position = UDim2.fromOffset(4, 2)
	svScriptNameLbl.BackgroundTransparency = 1
	svScriptNameLbl.Text = "No module selected"
	svScriptNameLbl.TextColor3 = self.Config.TEXT_BLACK
	svScriptNameLbl.Font = Enum.Font.SourceSansBold
	svScriptNameLbl.TextSize = 11
	svScriptNameLbl.TextXAlignment = Enum.TextXAlignment.Left
	svScriptNameLbl.TextTruncate = Enum.TextTruncate.AtEnd
	local svnPad = Instance.new("UIPadding", svScriptNameLbl)
	svnPad.PaddingLeft = UDim.new(0, 4)
	local svStatusLbl = Instance.new("TextLabel", svToolbar)
	svStatusLbl.Size = UDim2.fromOffset(100, 20)
	svStatusLbl.Position = UDim2.new(1, -256, 0, 4)
	svStatusLbl.BackgroundTransparency = 1
	svStatusLbl.Text = ""
	svStatusLbl.TextColor3 = self.Config.TEXT_GRAY
	svStatusLbl.Font = Enum.Font.SourceSans
	svStatusLbl.TextSize = 10
	svStatusLbl.TextXAlignment = Enum.TextXAlignment.Right
	local svModeBtn =
		self:_createButton(svToolbar, "Mode: Disasm", UDim2.fromOffset(86, 20), UDim2.new(1, -148, 0, 4), nil)
	svModeBtn.TextSize = 10
	local svCurrentMode = "disasm"
	svModeBtn.MouseButton1Click:Connect(function()
		if svCurrentMode == "disasm" then
			svCurrentMode = "raw"
			svModeBtn.Text = "Mode: Raw"
		elseif svCurrentMode == "raw" then
			svCurrentMode = "report"
			svModeBtn.Text = "Mode: Report"
		else
			svCurrentMode = "disasm"
			svModeBtn.Text = "Mode: Disasm"
		end
	end)
	local svCopyBtn = self:_createButton(
		svToolbar,
		"Copy",
		UDim2.fromOffset(44, 20),
		UDim2.new(1, -100, 0, 4),
		function()
			if self.State.UI and self.State.UI.ScriptViewerOutput then
				local txt = self.State.UI.ScriptViewerOutput.Text
				if txt ~= "" then
					pcall(setclipboard, txt)
					self:_showNotification("Copied to clipboard", "success")
				end
			end
		end
	)
	svCopyBtn.TextSize = 10
	local svDecompBtn = self:_createButton(
		svToolbar,
		"Decompile",
		UDim2.fromOffset(66, 20),
		UDim2.new(1, -52, 0, 4),
		function()
			self:SVDecompile()
		end
	)
	svDecompBtn.TextSize = 10
	local svScroll = Instance.new("ScrollingFrame", scriptPanel)
	svScroll.Size = UDim2.new(1, 0, 1, -30)
	svScroll.Position = UDim2.fromOffset(0, 30)
	svScroll.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	svScroll.BorderSizePixel = 0
	svScroll.ScrollBarThickness = 10
	svScroll.ScrollBarImageColor3 = self.Config.BG_DARK
	svScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	svScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	svScroll.ClipsDescendants = true
	local svOutput = Instance.new("TextLabel", svScroll)
	svOutput.Name = "SVOutput"
	svOutput.Size = UDim2.new(1, -8, 0, 0)
	svOutput.AutomaticSize = Enum.AutomaticSize.Y
	svOutput.Position = UDim2.fromOffset(4, 4)
	svOutput.BackgroundTransparency = 1
	svOutput.Text = "← Select a module then click Decompile"
	svOutput.TextColor3 = Color3.fromRGB(180, 180, 180)
	svOutput.Font = Enum.Font.Code
	svOutput.TextSize = 11
	svOutput.TextXAlignment = Enum.TextXAlignment.Left
	svOutput.TextYAlignment = Enum.TextYAlignment.Top
	svOutput.TextWrapped = true
	svOutput.RichText = false
	local function svSwitchTab(toTab)
		svActiveTab = toTab
		if toTab == "inspector" then
			inspScroll.Visible = true
			hdr.Visible = true
			toolbar.Visible = true
			scriptPanel.Visible = false
			svInspTab.BackgroundColor3 = self.Config.BG_LIGHT
			svInspTab.Font = Enum.Font.SourceSansBold
			svScriptTab.BackgroundColor3 = self.Config.BG_PANEL
			svScriptTab.Font = Enum.Font.SourceSans
		else
			inspScroll.Visible = false
			hdr.Visible = false
			toolbar.Visible = false
			scriptPanel.Visible = true
			svInspTab.BackgroundColor3 = self.Config.BG_PANEL
			svInspTab.Font = Enum.Font.SourceSans
			svScriptTab.BackgroundColor3 = self.Config.BG_LIGHT
			svScriptTab.Font = Enum.Font.SourceSansBold
		end
	end
	svInspTab.MouseButton1Click:Connect(function()
		svSwitchTab("inspector")
	end)
	svScriptTab.MouseButton1Click:Connect(function()
		svSwitchTab("scriptviewer")
	end)
	local patchPanel = Instance.new("Frame", content)
	patchPanel.Size = UDim2.fromOffset(190, 688)
	patchPanel.Position = UDim2.fromOffset(868, 0)
	patchPanel.BackgroundColor3 = self.Config.BG_PANEL
	patchPanel.BorderSizePixel = 0
	self:_createBorder(patchPanel, false)
	local patchTitle = Instance.new("TextLabel", patchPanel)
	patchTitle.Size = UDim2.new(1, -4, 0, 18)
	patchTitle.Position = UDim2.fromOffset(2, 2)
	patchTitle.BackgroundColor3 = self.Config.BG_DARK
	patchTitle.BorderSizePixel = 0
	patchTitle.Text = "Active Patches"
	patchTitle.TextColor3 = self.Config.TEXT_BLACK
	patchTitle.Font = Enum.Font.SourceSansBold
	patchTitle.TextSize = 11
	patchTitle.TextXAlignment = Enum.TextXAlignment.Left
	local ptp = Instance.new("UIPadding", patchTitle)
	ptp.PaddingLeft = UDim.new(0, 4)
	self:_createBorder(patchTitle, true)
	local patchControls = Instance.new("Frame", patchPanel)
	patchControls.Size = UDim2.new(1, -8, 0, 26)
	patchControls.Position = UDim2.fromOffset(4, 22)
	patchControls.BackgroundColor3 = self.Config.BG_DARK
	patchControls.BorderSizePixel = 0
	self:_createBorder(patchControls, true)
	self:_createButton(patchControls, "Clear All", UDim2.fromOffset(72, 20), UDim2.fromOffset(2, 2), function()
		for id in pairs(self.State.ActivePatches) do
			self:RemovePatch(id)
		end
	end)
	local patchCount = Instance.new("TextLabel", patchControls)
	patchCount.Size = UDim2.new(1, -78, 1, 0)
	patchCount.Position = UDim2.fromOffset(76, 0)
	patchCount.BackgroundTransparency = 1
	patchCount.Text = "Patches: 0"
	patchCount.TextColor3 = self.Config.TEXT_BLACK
	patchCount.Font = Enum.Font.SourceSans
	patchCount.TextSize = 12
	patchCount.TextXAlignment = Enum.TextXAlignment.Left
	local phdr = Instance.new("Frame", patchPanel)
	phdr.Size = UDim2.new(1, -8, 0, self.Config.ROW_HEIGHT)
	phdr.Position = UDim2.fromOffset(4, 52)
	phdr.BackgroundColor3 = self.Config.BG_DARK
	phdr.BorderSizePixel = 0
	self:_createBorder(phdr, true)
	local pHdrs = { "Frz", "Key", "Value", "Del" }
	local pHW = { 0.13, 0.38, 0.35, 0.14 }
	local pxp = 0
	for i, ph in ipairs(pHdrs) do
		local h = Instance.new("TextLabel", phdr)
		h.Size = UDim2.new(pHW[i], -2, 1, 0)
		h.Position = UDim2.new(pxp, 1, 0, 0)
		h.BackgroundTransparency = 1
		h.Text = ph
		h.TextColor3 = self.Config.TEXT_BLACK
		h.Font = Enum.Font.SourceSansBold
		h.TextSize = 11
		h.TextXAlignment = Enum.TextXAlignment.Left
		local hp = Instance.new("UIPadding", h)
		hp.PaddingLeft = UDim.new(0, 4)
		pxp = pxp + pHW[i]
	end
	local patchScroll = Instance.new("ScrollingFrame", patchPanel)
	patchScroll.Size = UDim2.new(1, -8, 1, -78)
	patchScroll.Position = UDim2.fromOffset(4, 76)
	patchScroll.BackgroundColor3 = self.Config.BG_WHITE
	patchScroll.BorderSizePixel = 0
	patchScroll.ScrollBarThickness = 10
	patchScroll.ScrollBarImageColor3 = self.Config.BG_DARK
	patchScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	patchScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	self:_createBorder(patchScroll, true)
	local patchList = Instance.new("UIListLayout", patchScroll)
	patchList.Padding = UDim.new(0, 0)
	local tab = Instance.new("Frame", sg)
	tab.Name = "RestoreTab"
	tab.Size = UDim2.fromOffset(34, 110)
	tab.Position = UDim2.new(1, -34, 0.5, -55)
	tab.BackgroundColor3 = self.Config.BG_DARK
	tab.BorderSizePixel = 0
	tab.Visible = false
	tab.ZIndex = 300
	self:_createBorder(tab, false)
	local iconFrame = Instance.new("Frame", tab)
	iconFrame.Size = UDim2.fromOffset(22, 22)
	iconFrame.Position = UDim2.new(0.5, -11, 0, 6)
	iconFrame.BackgroundTransparency = 1
	iconFrame.ZIndex = 301
	local cellSz = 6
	local gap = 1
	for row = 0, 2 do
		for col = 0, 2 do
			local cell = Instance.new("Frame", iconFrame)
			cell.Size = UDim2.fromOffset(cellSz, cellSz)
			cell.Position = UDim2.fromOffset(col * (cellSz + gap), row * (cellSz + gap))
			cell.BackgroundColor3 = row == 0 and Color3.fromRGB(180, 180, 180) or self.Config.BG_WHITE
			cell.BorderSizePixel = 0
			cell.ZIndex = 302
		end
	end
	local tabLabel = Instance.new("TextLabel", tab)
	tabLabel.Size = UDim2.new(1, 0, 0, 14)
	tabLabel.Position = UDim2.fromOffset(0, 32)
	tabLabel.BackgroundTransparency = 1
	tabLabel.Text = "TI"
	tabLabel.TextColor3 = self.Config.TEXT_BLACK
	tabLabel.Font = Enum.Font.SourceSansBold
	tabLabel.TextSize = 11
	tabLabel.TextXAlignment = Enum.TextXAlignment.Center
	tabLabel.ZIndex = 301
	local tabVertLabel = Instance.new("TextLabel", tab)
	tabVertLabel.Size = UDim2.fromOffset(14, 80)
	tabVertLabel.Position = UDim2.new(0.5, -7, 0, 50)
	tabVertLabel.BackgroundTransparency = 1
	tabVertLabel.Text = "TABLE\nINSP"
	tabVertLabel.TextColor3 = self.Config.TEXT_GRAY
	tabVertLabel.Font = Enum.Font.SourceSans
	tabVertLabel.TextSize = 9
	tabVertLabel.TextXAlignment = Enum.TextXAlignment.Center
	tabVertLabel.TextYAlignment = Enum.TextYAlignment.Top
	tabVertLabel.TextWrapped = true
	tabVertLabel.ZIndex = 301
	local tabBtn = Instance.new("TextButton", tab)
	tabBtn.Size = UDim2.new(1, 0, 1, 0)
	tabBtn.BackgroundTransparency = 1
	tabBtn.Text = ""
	tabBtn.ZIndex = 303
	tabBtn.MouseButton1Click:Connect(function()
		self:Restore()
	end)
	tabBtn.MouseEnter:Connect(function()
		TweenService:Create(tab, TweenInfo.new(0.1), { BackgroundColor3 = self.Config.BG_LIGHT }):Play()
	end)
	tabBtn.MouseLeave:Connect(function()
		TweenService:Create(tab, TweenInfo.new(0.1), { BackgroundColor3 = self.Config.BG_DARK }):Play()
	end)
	local tabDragging, tabDragStart, tabStartPos
	tabBtn.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			tabDragging = true
			tabDragStart = i.Position
			tabStartPos = tab.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if tabDragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local dy = i.Position.Y - tabDragStart.Y
			tab.Position =
				UDim2.new(tabStartPos.X.Scale, tabStartPos.X.Offset, tabStartPos.Y.Scale, tabStartPos.Y.Offset + dy)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			tabDragging = false
		end
	end)
	self.State.UI = {
		ScreenGui = sg,
		Main = main,
		Content = content,
		TitleBar = titleBar,
		RestoreTab = tab,
		ModuleScroll = modScroll,
		InspectorScroll = inspScroll,
		PathLabel = pathLabel,
		PatchScroll = patchScroll,
		PatchCount = patchCount,
		Minimized = false,
		ScriptViewerOutput = svOutput,
		ScriptViewerStatus = svStatusLbl,
		ScriptViewerName = svScriptNameLbl,
		ScriptViewerScroll = svScroll,
		SVMode = function()
			return svCurrentMode
		end,
		SVSwitchTab = svSwitchTab,
	}
	self:ScanModules()
end
function TI:SVDecompile()
	local ui = self.State.UI
	if not ui then
		return
	end
	local ms = self.State.SelectedModule
	if not ms then
		self:_showNotification("No module selected", "warning")
		return
	end
	local decompFn = getgenv and getgenv()._ZUK_DECOMPILE
	local prettyFn = getgenv and getgenv()._ZUK_PRETTYPRINT
	local cleanFn = getgenv and getgenv()._ZUK_CLEANOUTPUT
	if not decompFn then
		self:_showNotification("zukv2 not loaded — run it first", "error")
		ui.ScriptViewerOutput.Text = "-- zukv2 decompiler not found in getgenv().\n-- Load zukv2 first, then try again."
		return
	end
	local mode = ui.SVMode()
	ui.ScriptViewerOutput.Text = "-- Decompiling '" .. ms.Name .. "' ..."
	ui.ScriptViewerStatus.Text = "Working..."
	ui.ScriptViewerScroll.CanvasPosition = Vector2.new(0, 0)
	task.spawn(function()
		local bytecode
		local ok, err = pcall(function()
			bytecode = getscriptbytecode(ms)
		end)
		if not ok or not bytecode or bytecode == "" then
			ui.ScriptViewerOutput.Text = "-- getscriptbytecode failed:\n-- " .. tostring(err or "empty result")
			ui.ScriptViewerStatus.Text = "Error"
			return
		end
		local result
		local opts = {
			EnabledRemarks = { ColdRemark = false, InlineRemark = true },
			DecompilerTimeout = 15,
			DecompilerMode = "disasm",
			ReaderFloatPrecision = 7,
			ShowDebugInformation = false,
			ShowInstructionLines = false,
			ShowOperationIndex = false,
			ShowOperationNames = false,
			ShowTrivialOperations = false,
			UseTypeInfo = true,
			ListUsedGlobals = true,
			ReturnElapsedTime = false,
			CleanMode = true,
		}
		if mode == "raw" then
			opts.CleanMode = false
			opts.ShowOperationNames = true
			opts.ShowOperationIndex = true
			opts.ShowInstructionLines = true
			opts.ShowTrivialOperations = true
		end
		local t0 = os.clock()
		ok, result = pcall(decompFn, bytecode, opts)
		local elapsed = math.floor((os.clock() - t0) * 1000)
		if not ok then
			ui.ScriptViewerOutput.Text = "-- Decompiler error:\n-- " .. tostring(result)
			ui.ScriptViewerStatus.Text = "Error"
			return
		end
		if mode == "disasm" and prettyFn and cleanFn then
			local ok2, pp = pcall(prettyFn, result)
			if ok2 then
				local ok3, cl = pcall(cleanFn, pp)
				if ok3 then
					result = cl
				end
			end
		end
		local MAX = 180000
		if #result > MAX then
			result = result:sub(1, MAX) .. "\n\n-- [Output truncated at " .. MAX .. " chars]"
		end
		local lineCount = select(2, result:gsub("\n", "")) + 1
		ui.ScriptViewerOutput.Text = result
		ui.ScriptViewerStatus.Text = lineCount .. " lines · " .. elapsed .. "ms"
		ui.ScriptViewerScroll.CanvasPosition = Vector2.new(0, 0)
		self:_showNotification("Decompiled: " .. ms.Name, "success")
	end)
end
function TI:Open()
	self:CreateUI()
end
function TI:InspectTable(tbl, label)
	self:CreateUI()
	if type(tbl) ~= "table" then
		self:_showNotification("Not a table: " .. type(tbl), "error")
		return
	end
	self.State._RootTable = tbl
	self.State.CurrentTable = tbl
	self.State.PathStack = {}
	self.State.VisitedTables = {}
	self:RefreshInspector()
	if self.State.UI then
		self.State.UI.PathLabel.Text = label or "Custom Table"
	end
end
TI:Open()
