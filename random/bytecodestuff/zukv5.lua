--[[
 _____     _            ____  
|__  /   _| | __ __   _| ___| 
  / / | | | |/ / \ \ / /___ \ 
 / /| |_| |   <   \ V / ___) |
/____\__,_|_|\_\   \_/ |____/ 
                              
]]


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
			local blen = buffer.len(stream)
			local self = {}
			local function guard(n)
				if cursor + n > blen then
					error(
						string.format(
							"Uh oh! OOB: it needs %d byte(s) at offset %d (buf len %d)  maybe an opcode issue?",
							n,
							cursor,
							blen
						),
						2
					)
				end
			end
			function self:len()
				return blen
			end
			function self:nextByte()
				guard(1)
				local r = buffer.readu8(stream, cursor)
				cursor += 1
				return r
			end
			function self:nextSignedByte()
				guard(1)
				local r = buffer.readi8(stream, cursor)
				cursor += 1
				return r
			end
			function self:nextBytes(count)
				local t = {}
				for i = 1, count do
					t[i] = self:nextByte()
				end
				return t
			end
			function self:nextChar()
				return string.char(self:nextByte())
			end
			function self:nextUInt32()
				guard(4)
				local r = buffer.readu32(stream, cursor)
				cursor += 4
				return r
			end
			function self:nextInt32()
				guard(4)
				local r = buffer.readi32(stream, cursor)
				cursor += 4
				return r
			end
			function self:nextFloat()
				guard(4)
				local r = buffer.readf32(stream, cursor)
				cursor += 4
				return tonumber(string.format("%0." .. FLOAT_PRECISION .. "f", r))
			end
			function self:nextVarInt()
				local result = 0
				for i = 0, 4 do
					local b = self:nextByte()
					result = bit32.bor(result, bit32.lshift(bit32.band(b, 0x7F), i * 7))
					if not bit32.btest(b, 0x80) then
						break
					end
				end
				return result
			end
			function self:nextString(slen)
				slen = slen or self:nextVarInt()
				if slen == 0 then
					return ""
				end
				guard(slen)
				local r = buffer.readstring(stream, cursor, slen)
				cursor += slen
				return r
			end
			function self:nextDouble()
				guard(8)
				local r = buffer.readf64(stream, cursor)
				cursor += 8
				return r
			end
			return self
		end
		function Reader:Set(fp)
			FLOAT_PRECISION = fp
		end
		local Strings = {
			SUCCESS = "%s",
			TIMEOUT = "-- DECOMPILER TIMEOUT",
			COMPILATION_FAILURE = "-- SCRIPT FAILED TO COMPILE, ERROR:\n%s",
			UNSUPPORTED_LBC_VERSION = "-- BYTECODE VERSION %d IS NOT SUPPORTED (EXPECTED %d-%d)",
			USED_GLOBALS = "-- USED GLOBALS: %s.\n",
			DECOMPILER_REMARK = "-- DECOMPILER REMARK: %s\n",
		}
		local CASE_MULTIPLIER = 227
		local Luau = {
			OpCode = {
				{ name = "NOP", type = "none" },
				{ name = "BREAK", type = "none" },
				{ name = "LOADNIL", type = "A" },
				{ name = "LOADB", type = "ABC" },
				{ name = "LOADN", type = "AsD" },
				{ name = "LOADK", type = "AD" },
				{ name = "MOVE", type = "AB" },
				{ name = "GETGLOBAL", type = "AC", aux = true },
				{ name = "SETGLOBAL", type = "AC", aux = true },
				{ name = "GETUPVAL", type = "AB" },
				{ name = "SETUPVAL", type = "AB" },
				{ name = "CLOSEUPVALS", type = "A" },
				{ name = "GETIMPORT", type = "AD", aux = true },
				{ name = "GETTABLE", type = "ABC" },
				{ name = "SETTABLE", type = "ABC" },
				{ name = "GETTABLEKS", type = "ABC", aux = true },
				{ name = "SETTABLEKS", type = "ABC", aux = true },
				{ name = "GETTABLEN", type = "ABC" },
				{ name = "SETTABLEN", type = "ABC" },
				{ name = "NEWCLOSURE", type = "AD" },
				{ name = "NAMECALL", type = "ABC", aux = true },
				{ name = "CALL", type = "ABC" },
				{ name = "RETURN", type = "AB" },
				{ name = "JUMP", type = "sD" },
				{ name = "JUMPBACK", type = "sD" },
				{ name = "JUMPIF", type = "AsD" },
				{ name = "JUMPIFNOT", type = "AsD" },
				{ name = "JUMPIFEQ", type = "AsD", aux = true },
				{ name = "JUMPIFLE", type = "AsD", aux = true },
				{ name = "JUMPIFLT", type = "AsD", aux = true },
				{ name = "JUMPIFNOTEQ", type = "AsD", aux = true },
				{ name = "JUMPIFNOTLE", type = "AsD", aux = true },
				{ name = "JUMPIFNOTLT", type = "AsD", aux = true },
				{ name = "ADD", type = "ABC" },
				{ name = "SUB", type = "ABC" },
				{ name = "MUL", type = "ABC" },
				{ name = "DIV", type = "ABC" },
				{ name = "MOD", type = "ABC" },
				{ name = "POW", type = "ABC" },
				{ name = "ADDK", type = "ABC" },
				{ name = "SUBK", type = "ABC" },
				{ name = "MULK", type = "ABC" },
				{ name = "DIVK", type = "ABC" },
				{ name = "MODK", type = "ABC" },
				{ name = "POWK", type = "ABC" },
				{ name = "AND", type = "ABC" },
				{ name = "OR", type = "ABC" },
				{ name = "ANDK", type = "ABC" },
				{ name = "ORK", type = "ABC" },
				{ name = "CONCAT", type = "ABC" },
				{ name = "NOT", type = "AB" },
				{ name = "MINUS", type = "AB" },
				{ name = "LENGTH", type = "AB" },
				{ name = "NEWTABLE", type = "AB", aux = true },
				{ name = "DUPTABLE", type = "AD" },
				{ name = "SETLIST", type = "ABC", aux = true },
				{ name = "FORNPREP", type = "AsD" },
				{ name = "FORNLOOP", type = "AsD" },
				{ name = "FORGLOOP", type = "AsD", aux = true },
				{ name = "FORGPREP_INEXT", type = "A" },
				{ name = "FASTCALL3", type = "ABC", aux = true },
				{ name = "FORGPREP_NEXT", type = "A" },
				{ name = "NATIVECALL", type = "none" },
				{ name = "GETVARARGS", type = "AB" },
				{ name = "DUPCLOSURE", type = "AD" },
				{ name = "PREPVARARGS", type = "A" },
				{ name = "LOADKX", type = "A", aux = true },
				{ name = "JUMPX", type = "E" },
				{ name = "FASTCALL", type = "AC" },
				{ name = "COVERAGE", type = "E" },
				{ name = "CAPTURE", type = "AB" },
				{ name = "SUBRK", type = "ABC" },
				{ name = "DIVRK", type = "ABC" },
				{ name = "FASTCALL1", type = "ABC" },
				{ name = "FASTCALL2", type = "ABC", aux = true },
				{ name = "FASTCALL2K", type = "ABC", aux = true },
				{ name = "FORGPREP", type = "AsD" },
				{ name = "JUMPXEQKNIL", type = "AsD", aux = true },
				{ name = "JUMPXEQKB", type = "AsD", aux = true },
				{ name = "JUMPXEQKN", type = "AsD", aux = true },
				{ name = "JUMPXEQKS", type = "AsD", aux = true },
				{ name = "IDIV", type = "ABC" },
				{ name = "IDIVK", type = "ABC" },
				{ name = "GETUDATAKS", type = "ABC", aux = true },
				{ name = "SETUDATAKS", type = "ABC", aux = true },
				{ name = "NAMECALLUDATA", type = "ABC", aux = true },
				{ name = "NEWCLASSMEMBER", type = "ABC", aux = true },
				{ name = "CALLFB", type = "ABC", aux = true },
				{ name = "CMPPROTO", type = "AsD", aux = true },
				{ name = "_COUNT", type = "none" },
			},
			BytecodeTag = {
				LBC_VERSION_MIN = 1,
				LBC_VERSION_MAX = 11,
				LBC_TYPE_VERSION_MIN = 1,
				LBC_TYPE_VERSION_MAX = 3,
				LBC_CONSTANT_NIL = 0,
				LBC_CONSTANT_BOOLEAN = 1,
				LBC_CONSTANT_NUMBER = 2,
				LBC_CONSTANT_STRING = 3,
				LBC_CONSTANT_IMPORT = 4,
				LBC_CONSTANT_TABLE = 5,
				LBC_CONSTANT_CLOSURE = 6,
				LBC_CONSTANT_VECTOR = 7,
				LBC_CONSTANT_TABLE_WITH_CONSTANTS = 8,
				LBC_CONSTANT_INTEGER = 9,
			},
			BytecodeType = {
				LBC_TYPE_NIL = 0,
				LBC_TYPE_BOOLEAN = 1,
				LBC_TYPE_NUMBER = 2,
				LBC_TYPE_STRING = 3,
				LBC_TYPE_TABLE = 4,
				LBC_TYPE_FUNCTION = 5,
				LBC_TYPE_THREAD = 6,
				LBC_TYPE_USERDATA = 7,
				LBC_TYPE_VECTOR = 8,
				LBC_TYPE_BUFFER = 9,
				LBC_TYPE_INTEGER = 10,
				LBC_TYPE_ANY = 15,
				LBC_TYPE_TAGGED_USERDATA_BASE = 64,
				LBC_TYPE_TAGGED_USERDATA_END = 64 + 32,
				LBC_TYPE_OPTIONAL_BIT = bit32.lshift(1, 7),
				LBC_TYPE_INVALID = 256,
			},
			CaptureType = { LCT_VAL = 0, LCT_REF = 1, LCT_UPVAL = 2 },
			BuiltinFunction = {
				LBF_NONE = 0,
				LBF_ASSERT = 1,
				LBF_MATH_ABS = 2,
				LBF_MATH_ACOS = 3,
				LBF_MATH_ASIN = 4,
				LBF_MATH_ATAN2 = 5,
				LBF_MATH_ATAN = 6,
				LBF_MATH_CEIL = 7,
				LBF_MATH_COSH = 8,
				LBF_MATH_COS = 9,
				LBF_MATH_DEG = 10,
				LBF_MATH_EXP = 11,
				LBF_MATH_FLOOR = 12,
				LBF_MATH_FMOD = 13,
				LBF_MATH_FREXP = 14,
				LBF_MATH_LDEXP = 15,
				LBF_MATH_LOG10 = 16,
				LBF_MATH_LOG = 17,
				LBF_MATH_MAX = 18,
				LBF_MATH_MIN = 19,
				LBF_MATH_MODF = 20,
				LBF_MATH_POW = 21,
				LBF_MATH_RAD = 22,
				LBF_MATH_SINH = 23,
				LBF_MATH_SIN = 24,
				LBF_MATH_SQRT = 25,
				LBF_MATH_TANH = 26,
				LBF_MATH_TAN = 27,
				LBF_BIT32_ARSHIFT = 28,
				LBF_BIT32_BAND = 29,
				LBF_BIT32_BNOT = 30,
				LBF_BIT32_BOR = 31,
				LBF_BIT32_BXOR = 32,
				LBF_BIT32_BTEST = 33,
				LBF_BIT32_EXTRACT = 34,
				LBF_BIT32_LROTATE = 35,
				LBF_BIT32_LSHIFT = 36,
				LBF_BIT32_REPLACE = 37,
				LBF_BIT32_RROTATE = 38,
				LBF_BIT32_RSHIFT = 39,
				LBF_TYPE = 40,
				LBF_STRING_BYTE = 41,
				LBF_STRING_CHAR = 42,
				LBF_STRING_LEN = 43,
				LBF_TYPEOF = 44,
				LBF_STRING_SUB = 45,
				LBF_MATH_CLAMP = 46,
				LBF_MATH_SIGN = 47,
				LBF_MATH_ROUND = 48,
				LBF_RAWSET = 49,
				LBF_RAWGET = 50,
				LBF_RAWEQUAL = 51,
				LBF_TABLE_INSERT = 52,
				LBF_TABLE_UNPACK = 53,
				LBF_VECTOR = 54,
				LBF_BIT32_COUNTLZ = 55,
				LBF_BIT32_COUNTRZ = 56,
				LBF_SELECT_VARARG = 57,
				LBF_RAWLEN = 58,
				LBF_BIT32_EXTRACTK = 59,
				LBF_GETMETATABLE = 60,
				LBF_SETMETATABLE = 61,
				LBF_TONUMBER = 62,
				LBF_TOSTRING = 63,
				LBF_BIT32_BYTESWAP = 64,
				LBF_BUFFER_READI8 = 65,
				LBF_BUFFER_READU8 = 66,
				LBF_BUFFER_WRITEU8 = 67,
				LBF_BUFFER_READI16 = 68,
				LBF_BUFFER_READU16 = 69,
				LBF_BUFFER_WRITEU16 = 70,
				LBF_BUFFER_READI32 = 71,
				LBF_BUFFER_READU32 = 72,
				LBF_BUFFER_WRITEU32 = 73,
				LBF_BUFFER_READF32 = 74,
				LBF_BUFFER_WRITEF32 = 75,
				LBF_BUFFER_READF64 = 76,
				LBF_BUFFER_WRITEF64 = 77,
				LBF_VECTOR_MAGNITUDE = 78,
				LBF_VECTOR_NORMALIZE = 79,
				LBF_VECTOR_CROSS = 80,
				LBF_VECTOR_DOT = 81,
				LBF_VECTOR_FLOOR = 82,
				LBF_VECTOR_CEIL = 83,
				LBF_VECTOR_ABS = 84,
				LBF_VECTOR_SIGN = 85,
				LBF_VECTOR_CLAMP = 86,
				LBF_VECTOR_MIN = 87,
				LBF_VECTOR_MAX = 88,
				LBF_MATH_LERP = 89,
				LBF_VECTOR_LERP = 90,
				LBF_MATH_ISNAN = 91,
				LBF_MATH_ISINF = 92,
				LBF_MATH_ISFINITE = 93,
				LBF_INTEGER_CREATE = 94,
				LBF_INTEGER_TONUMBER = 95,
				LBF_INTEGER_NEG = 96,
				LBF_INTEGER_ADD = 97,
				LBF_INTEGER_SUB = 98,
				LBF_INTEGER_MUL = 99,
				LBF_INTEGER_DIV = 100,
				LBF_INTEGER_MIN = 101,
				LBF_INTEGER_MAX = 102,
				LBF_INTEGER_REM = 103,
				LBF_INTEGER_IDIV = 104,
				LBF_INTEGER_UDIV = 105,
				LBF_INTEGER_UREM = 106,
				LBF_INTEGER_MOD = 107,
				LBF_INTEGER_CLAMP = 108,
				LBF_INTEGER_BAND = 109,
				LBF_INTEGER_BOR = 110,
				LBF_INTEGER_BNOT = 111,
				LBF_INTEGER_BXOR = 112,
				LBF_INTEGER_LT = 113,
				LBF_INTEGER_LE = 114,
				LBF_INTEGER_ULT = 115,
				LBF_INTEGER_ULE = 116,
				LBF_INTEGER_GT = 117,
				LBF_INTEGER_GE = 118,
				LBF_INTEGER_UGT = 119,
				LBF_INTEGER_UGE = 120,
				LBF_INTEGER_LSHIFT = 121,
				LBF_INTEGER_RSHIFT = 122,
				LBF_INTEGER_ARSHIFT = 123,
				LBF_INTEGER_LROTATE = 124,
				LBF_INTEGER_RROTATE = 125,
				LBF_INTEGER_EXTRACT = 126,
				LBF_INTEGER_BTEST = 127,
				LBF_INTEGER_COUNTRZ = 128,
				LBF_INTEGER_COUNTLZ = 129,
				LBF_INTEGER_BSWAP = 130,
				LBF_BUFFER_READINTEGER = 131,
				LBF_BUFFER_WRITEINTEGER = 132,
			},
			ProtoFlag = {
				LPF_NATIVE_MODULE = bit32.lshift(1, 0),
				LPF_NATIVE_COLD = bit32.lshift(1, 1),
				LPF_NATIVE_FUNCTION = bit32.lshift(1, 2),
			},
		}
		function Luau:INSN_OP(i)
			return bit32.band(i, 0xFF)
		end
		function Luau:INSN_A(i)
			return bit32.band(bit32.rshift(i, 8), 0xFF)
		end
		function Luau:INSN_B(i)
			return bit32.band(bit32.rshift(i, 16), 0xFF)
		end
		function Luau:INSN_C(i)
			return bit32.band(bit32.rshift(i, 24), 0xFF)
		end
		function Luau:INSN_D(i)
			return bit32.rshift(i, 16)
		end
		function Luau:INSN_sD(i)
			local D = self:INSN_D(i)
			return (D > 0x7FFF and D <= 0xFFFF) and (-(0xFFFF - D) - 1) or D
		end
		function Luau:INSN_E(i)
			return bit32.rshift(i, 8)
		end
		function Luau:GetBaseTypeString(t, checkOpt)
			local BT = self.BytecodeType
			local tag = bit32.band(t, bit32.bnot(BT.LBC_TYPE_OPTIONAL_BIT))
			local names = {
				[BT.LBC_TYPE_NIL] = "nil",
				[BT.LBC_TYPE_BOOLEAN] = "boolean",
				[BT.LBC_TYPE_NUMBER] = "number",
				[BT.LBC_TYPE_STRING] = "string",
				[BT.LBC_TYPE_TABLE] = "table",
				[BT.LBC_TYPE_FUNCTION] = "function",
				[BT.LBC_TYPE_THREAD] = "thread",
				[BT.LBC_TYPE_USERDATA] = "userdata",
				[BT.LBC_TYPE_VECTOR] = "Vector3",
				[BT.LBC_TYPE_BUFFER] = "buffer",
				[BT.LBC_TYPE_ANY] = "any",
			}
			local r = names[tag] or "unknown"
			if checkOpt then
				r ..= (bit32.band(t, BT.LBC_TYPE_OPTIONAL_BIT) == 0) and "" or "?"
			end
			return r
		end
		function Luau:GetBuiltinInfo(bfid)
			local BF = self.BuiltinFunction
			local map = {
				[BF.LBF_NONE] = "none",
				[BF.LBF_ASSERT] = "assert",
				[BF.LBF_TYPE] = "type",
				[BF.LBF_TYPEOF] = "typeof",
				[BF.LBF_RAWSET] = "rawset",
				[BF.LBF_RAWGET] = "rawget",
				[BF.LBF_RAWEQUAL] = "rawequal",
				[BF.LBF_RAWLEN] = "rawlen",
				[BF.LBF_TABLE_UNPACK] = "unpack",
				[BF.LBF_SELECT_VARARG] = "select",
				[BF.LBF_GETMETATABLE] = "getmetatable",
				[BF.LBF_SETMETATABLE] = "setmetatable",
				[BF.LBF_TONUMBER] = "tonumber",
				[BF.LBF_TOSTRING] = "tostring",
				[BF.LBF_MATH_ABS] = "math.abs",
				[BF.LBF_MATH_ACOS] = "math.acos",
				[BF.LBF_MATH_ASIN] = "math.asin",
				[BF.LBF_MATH_ATAN2] = "math.atan2",
				[BF.LBF_MATH_ATAN] = "math.atan",
				[BF.LBF_MATH_CEIL] = "math.ceil",
				[BF.LBF_MATH_COSH] = "math.cosh",
				[BF.LBF_MATH_COS] = "math.cos",
				[BF.LBF_MATH_DEG] = "math.deg",
				[BF.LBF_MATH_EXP] = "math.exp",
				[BF.LBF_MATH_FLOOR] = "math.floor",
				[BF.LBF_MATH_FMOD] = "math.fmod",
				[BF.LBF_MATH_FREXP] = "math.frexp",
				[BF.LBF_MATH_LDEXP] = "math.ldexp",
				[BF.LBF_MATH_LOG10] = "math.log10",
				[BF.LBF_MATH_LOG] = "math.log",
				[BF.LBF_MATH_MAX] = "math.max",
				[BF.LBF_MATH_MIN] = "math.min",
				[BF.LBF_MATH_MODF] = "math.modf",
				[BF.LBF_MATH_POW] = "math.pow",
				[BF.LBF_MATH_RAD] = "math.rad",
				[BF.LBF_MATH_SINH] = "math.sinh",
				[BF.LBF_MATH_SIN] = "math.sin",
				[BF.LBF_MATH_SQRT] = "math.sqrt",
				[BF.LBF_MATH_TANH] = "math.tanh",
				[BF.LBF_MATH_TAN] = "math.tan",
				[BF.LBF_MATH_CLAMP] = "math.clamp",
				[BF.LBF_MATH_SIGN] = "math.sign",
				[BF.LBF_MATH_ROUND] = "math.round",
				[BF.LBF_BIT32_ARSHIFT] = "bit32.arshift",
				[BF.LBF_BIT32_BAND] = "bit32.band",
				[BF.LBF_BIT32_BNOT] = "bit32.bnot",
				[BF.LBF_BIT32_BOR] = "bit32.bor",
				[BF.LBF_BIT32_BXOR] = "bit32.bxor",
				[BF.LBF_BIT32_BTEST] = "bit32.btest",
				[BF.LBF_BIT32_EXTRACT] = "bit32.extract",
				[BF.LBF_BIT32_EXTRACTK] = "bit32.extract",
				[BF.LBF_BIT32_LROTATE] = "bit32.lrotate",
				[BF.LBF_BIT32_LSHIFT] = "bit32.lshift",
				[BF.LBF_BIT32_REPLACE] = "bit32.replace",
				[BF.LBF_BIT32_RROTATE] = "bit32.rrotate",
				[BF.LBF_BIT32_RSHIFT] = "bit32.rshift",
				[BF.LBF_BIT32_COUNTLZ] = "bit32.countlz",
				[BF.LBF_BIT32_COUNTRZ] = "bit32.countrz",
				[BF.LBF_BIT32_BYTESWAP] = "bit32.byteswap",
				[BF.LBF_STRING_BYTE] = "string.byte",
				[BF.LBF_STRING_CHAR] = "string.char",
				[BF.LBF_STRING_LEN] = "string.len",
				[BF.LBF_STRING_SUB] = "string.sub",
				[BF.LBF_TABLE_INSERT] = "table.insert",
				[BF.LBF_VECTOR] = "Vector3.new",
				[BF.LBF_BUFFER_READI8] = "buffer.readi8",
				[BF.LBF_BUFFER_READU8] = "buffer.readu8",
				[BF.LBF_BUFFER_WRITEU8] = "buffer.writeu8",
				[BF.LBF_BUFFER_READI16] = "buffer.readi16",
				[BF.LBF_BUFFER_READU16] = "buffer.readu16",
				[BF.LBF_BUFFER_WRITEU16] = "buffer.writeu16",
				[BF.LBF_BUFFER_READI32] = "buffer.readi32",
				[BF.LBF_BUFFER_READU32] = "buffer.readu32",
				[BF.LBF_BUFFER_WRITEU32] = "buffer.writeu32",
				[BF.LBF_BUFFER_READF32] = "buffer.readf32",
				[BF.LBF_BUFFER_WRITEF32] = "buffer.writef32",
				[BF.LBF_BUFFER_READF64] = "buffer.readf64",
				[BF.LBF_BUFFER_WRITEF64] = "buffer.writef64",
				[BF.LBF_VECTOR_MAGNITUDE] = "vector.magnitude",
				[BF.LBF_VECTOR_NORMALIZE] = "vector.normalize",
				[BF.LBF_VECTOR_CROSS] = "vector.cross",
				[BF.LBF_VECTOR_DOT] = "vector.dot",
				[BF.LBF_VECTOR_FLOOR] = "vector.floor",
				[BF.LBF_VECTOR_CEIL] = "vector.ceil",
				[BF.LBF_VECTOR_ABS] = "vector.abs",
				[BF.LBF_VECTOR_SIGN] = "vector.sign",
				[BF.LBF_VECTOR_CLAMP] = "vector.clamp",
				[BF.LBF_VECTOR_MIN] = "vector.min",
				[BF.LBF_VECTOR_MAX] = "vector.max",
				[BF.LBF_MATH_LERP] = "math.lerp",
				[BF.LBF_VECTOR_LERP] = "vector.lerp",
				[BF.LBF_MATH_ISNAN] = "math.isnan",
				[BF.LBF_MATH_ISINF] = "math.isinf",
				[BF.LBF_MATH_ISFINITE] = "math.isfinite",
				[BF.LBF_INTEGER_CREATE] = "integer.create",
				[BF.LBF_INTEGER_TONUMBER] = "integer.tonumber",
				[BF.LBF_INTEGER_NEG] = "integer.neg",
				[BF.LBF_INTEGER_ADD] = "integer.add",
				[BF.LBF_INTEGER_SUB] = "integer.sub",
				[BF.LBF_INTEGER_MUL] = "integer.mul",
				[BF.LBF_INTEGER_DIV] = "integer.div",
				[BF.LBF_INTEGER_MIN] = "integer.min",
				[BF.LBF_INTEGER_MAX] = "integer.max",
				[BF.LBF_INTEGER_REM] = "integer.rem",
				[BF.LBF_INTEGER_IDIV] = "integer.idiv",
				[BF.LBF_INTEGER_UDIV] = "integer.udiv",
				[BF.LBF_INTEGER_UREM] = "integer.urem",
				[BF.LBF_INTEGER_MOD] = "integer.mod",
				[BF.LBF_INTEGER_CLAMP] = "integer.clamp",
				[BF.LBF_INTEGER_BAND] = "integer.band",
				[BF.LBF_INTEGER_BOR] = "integer.bor",
				[BF.LBF_INTEGER_BNOT] = "integer.bnot",
				[BF.LBF_INTEGER_BXOR] = "integer.bxor",
				[BF.LBF_INTEGER_LT] = "integer.lt",
				[BF.LBF_INTEGER_LE] = "integer.le",
				[BF.LBF_INTEGER_ULT] = "integer.ult",
				[BF.LBF_INTEGER_ULE] = "integer.ule",
				[BF.LBF_INTEGER_GT] = "integer.gt",
				[BF.LBF_INTEGER_GE] = "integer.ge",
				[BF.LBF_INTEGER_UGT] = "integer.ugt",
				[BF.LBF_INTEGER_UGE] = "integer.uge",
				[BF.LBF_INTEGER_LSHIFT] = "integer.lshift",
				[BF.LBF_INTEGER_RSHIFT] = "integer.rshift",
				[BF.LBF_INTEGER_ARSHIFT] = "integer.arshift",
				[BF.LBF_INTEGER_LROTATE] = "integer.lrotate",
				[BF.LBF_INTEGER_RROTATE] = "integer.rrotate",
				[BF.LBF_INTEGER_EXTRACT] = "integer.extract",
				[BF.LBF_INTEGER_BTEST] = "integer.btest",
				[BF.LBF_INTEGER_COUNTRZ] = "integer.countrz",
				[BF.LBF_INTEGER_COUNTLZ] = "integer.countlz",
				[BF.LBF_INTEGER_BSWAP] = "integer.bswap",
				[BF.LBF_BUFFER_READINTEGER] = "buffer.readinteger",
				[BF.LBF_BUFFER_WRITEINTEGER] = "buffer.writeinteger",
			}
			return map[bfid] or ("builtin#" .. tostring(bfid))
		end
		do
			local raw = Luau.OpCode
			local encoded = {}
			for i, v in raw do
				local case = bit32.band((i - 1) * CASE_MULTIPLIER, 0xFF)
				encoded[case] = v
			end
			Luau.OpCode = encoded
		end
		local DEFAULT_OPTIONS = {
			EnabledRemarks = { ColdRemark = false, InlineRemark = true },
			DecompilerTimeout = 10,
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
		local LuauCompileUserdataInfo = true
		pcall(function()
			local ok, r = pcall(function()
				return game:GetFastFlag("LuauCompileUserdataInfo")
			end)
			if ok then
				LuauCompileUserdataInfo = r
			end
		end)
		local LuauOpCode = Luau.OpCode
		local LuauBytecodeTag = Luau.BytecodeTag
		local LuauBytecodeType = Luau.BytecodeType
		local LuauCaptureType = Luau.CaptureType
		local LuauProtoFlag = Luau.ProtoFlag
		local function toBoolean(v)
			return v ~= 0
		end
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
			local s = tostring(v)
			return string.rep(ch, math.max(0, n - #s)) .. s
		end
		local function padRight(v, ch, n)
			local s = tostring(v)
			return s .. string.rep(ch, math.max(0, n - #s))
		end
		local ROBLOX_GLOBALS = {
			"game",
			"workspace",
			"script",
			"plugin",
			"settings",
			"shared",
			"UserSettings",
			"print",
			"warn",
			"error",
			"assert",
			"pcall",
			"xpcall",
			"require",
			"select",
			"pairs",
			"ipairs",
			"next",
			"unpack",
			"type",
			"typeof",
			"tostring",
			"tonumber",
			"setmetatable",
			"getmetatable",
			"rawset",
			"rawget",
			"rawequal",
			"rawlen",
			"math",
			"table",
			"string",
			"bit32",
			"coroutine",
			"os",
			"utf8",
			"task",
			"buffer",
			"Instance",
			"Enum",
			"Vector3",
			"Vector2",
			"CFrame",
			"Color3",
			"BrickColor",
			"UDim",
			"UDim2",
			"Ray",
			"Axes",
			"Faces",
			"NumberRange",
			"NumberSequence",
			"ColorSequence",
			"TweenInfo",
			"RaycastParams",
			"OverlapParams",
			"tick",
			"time",
			"wait",
			"delay",
			"spawn",
			"_G",
			"_VERSION",
		}
		local function isGlobal(key)
			for _, v in ipairs(ROBLOX_GLOBALS) do
				if v == key then
					return true
				end
			end
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
					for i = 1, n do
						stringTable[i] = reader:nextString()
					end
				end
				local userdataTypes = {}
				local function readUserdataTypes()
					if LuauCompileUserdataInfo then
						while true do
							local idx = reader:nextByte()
							if idx == 0 then
								break
							end
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
							id = protoId,
							instructions = {},
							constants = {},
							captures = {},
							innerProtos = {},
							instructionLineInfo = {},
						}
						protoTable[protoId] = proto
						proto.maxStackSize = reader:nextByte()
						proto.numParams = reader:nextByte()
						proto.numUpvalues = reader:nextByte()
						proto.isVarArg = toBoolean(reader:nextByte())
						if bytecodeVersion >= 4 then
							proto.flags = reader:nextByte()
							local resultTypedParams, resultTypedUpvalues, resultTypedLocals = {}, {}, {}
							local allTypeInfoSize = reader:nextVarInt()
							local hasTypeInfo = allTypeInfoSize > 0
							proto.hasTypeInfo = hasTypeInfo
							if hasTypeInfo then
								if typeEncodingVersion and typeEncodingVersion > 1 then
									for _ = 1, allTypeInfoSize do
										reader:nextByte()
									end
								else
									local blob = reader:nextBytes(allTypeInfoSize)
									table.remove(blob, 1)
									table.remove(blob, 1)
									resultTypedParams = blob
								end
							end
							proto.typedParams = resultTypedParams
							proto.typedUpvalues = resultTypedUpvalues
							proto.typedLocals = resultTypedLocals
						end
						proto.sizeInstructions = reader:nextVarInt()
						for j = 1, proto.sizeInstructions do
							proto.instructions[j] = reader:nextUInt32()
						end
						proto.sizeConstants = reader:nextVarInt()
						for j = 1, proto.sizeConstants do
							local constType = reader:nextByte()
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
								local ci1 = bit32.band(bit32.rshift(id, 20), 0x3FF)
								local ci2 = bit32.band(bit32.rshift(id, 10), 0x3FF)
								local ci3 = bit32.band(id, 0x3FF)
								local tag = ""
								local function kv(idx)
									return proto.constants[idx + 1]
								end
								if idxCount == 1 then
									tag = tostring(kv(ci1) and kv(ci1).value or "")
								elseif idxCount == 2 then
									tag = tostring(kv(ci1) and kv(ci1).value or "")
										.. "."
										.. tostring(kv(ci2) and kv(ci2).value or "")
								elseif idxCount == 3 then
									tag = tostring(kv(ci1) and kv(ci1).value or "")
										.. "."
										.. tostring(kv(ci2) and kv(ci2).value or "")
										.. "."
										.. tostring(kv(ci3) and kv(ci3).value or "")
								end
								constValue = tag
							elseif constType == BT.LBC_CONSTANT_TABLE then
								local sz = reader:nextVarInt()
								local keys = {}
								for k = 1, sz do
									keys[k] = reader:nextVarInt() + 1
								end
								constValue = { size = sz, keys = keys }
							elseif constType == BT.LBC_CONSTANT_CLOSURE then
								constValue = reader:nextVarInt() + 1
							elseif constType == BT.LBC_CONSTANT_VECTOR then
								local x, y, z, w =
									reader:nextFloat(), reader:nextFloat(), reader:nextFloat(), reader:nextFloat()
								constValue = w == 0 and ("Vector3.new(" .. x .. "," .. y .. "," .. z .. ")")
									or ("vector.create(" .. x .. "," .. y .. "," .. z .. "," .. w .. ")")
							elseif constType == BT.LBC_CONSTANT_TABLE_WITH_CONSTANTS then
								local sz = reader:nextVarInt()
								local keys = {}
								for k = 1, sz do
									keys[k] = reader:nextVarInt() + 1
									reader:nextVarInt()
								end
								constValue = { size = sz, keys = keys }
							elseif constType == BT.LBC_CONSTANT_INTEGER then
								local lo = reader:nextUInt32()
								local hi = reader:nextUInt32()
								constValue = hi * 4294967296 + lo
							end
							proto.constants[j] = { type = constType, value = constValue }
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
							local baselineSize = bit32.rshift(proto.sizeInstructions - 1, lgap) + 1
							local smallLineInfo, absLineInfo = {}, {}
							local lastOffset, lastLine = 0, 0
							for j = 1, proto.sizeInstructions do
								local b = reader:nextSignedByte()
								lastOffset += b
								smallLineInfo[j] = lastOffset
							end
							for j = 1, baselineSize do
								local lc = lastLine + reader:nextInt32()
								absLineInfo[j - 1] = lc
								lastLine = lc
							end
							local resultLineInfo = {}
							for j, line in ipairs(smallLineInfo) do
								local absIdx = bit32.rshift(j - 1, lgap)
								local absLine = absLineInfo[absIdx]
								local rl = line + absLine
								if lgap <= 1 and (-line == absLine) then
									rl += absLineInfo[absIdx + 1] or 0
								end
								if rl <= 0 then
									rl += 0x100
								end
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
									name = stringTable[reader:nextVarInt()],
									startPC = reader:nextVarInt(),
									endPC = reader:nextVarInt(),
									register = reader:nextByte(),
								}
							end
							proto.debugLocals = debugLocals
							local totalUpvals = reader:nextVarInt()
							local debugUpvalues = {}
							for j = 1, totalUpvals do
								debugUpvalues[j] = { name = stringTable[reader:nextVarInt()] }
							end
							proto.debugUpvalues = debugUpvalues
						end
					end
				end
				readStringTable()
				if bytecodeVersion and bytecodeVersion > 5 then
					readUserdataTypes()
				end
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
					registerActions[proto.id] = { proto = proto, actions = protoRegisterActions }
					local instructions = proto.instructions
					local innerProtos = proto.innerProtos
					local constants = proto.constants
					local captures = proto.captures
					local flags = proto.flags
					local function collectCaptures(baseIdx, p)
						local nup = p.numUpvalues
						if nup > 0 then
							local _c = p.captures
							for j = 1, nup do
								local cap = instructions[baseIdx + j]
								local ctype = Luau:INSN_A(cap)
								local sreg = Luau:INSN_B(cap)
								if ctype == LuauCaptureType.LCT_VAL or ctype == LuauCaptureType.LCT_REF then
									_c[j - 1] = sreg
								elseif ctype == LuauCaptureType.LCT_UPVAL then
									_c[j - 1] = captures[sreg]
								end
							end
						end
					end
					local function writeFlags()
						if type(flags) == "table" then
							return
						end
						local rawFlags = type(flags) == "number" and flags or 0
						local df = {}
						if proto.main then
							df.native = toBoolean(bit32.band(rawFlags, LuauProtoFlag.LPF_NATIVE_MODULE))
						else
							df.native = toBoolean(bit32.band(rawFlags, LuauProtoFlag.LPF_NATIVE_FUNCTION))
							df.cold = toBoolean(bit32.band(rawFlags, LuauProtoFlag.LPF_NATIVE_COLD))
						end
						flags = df
						proto.flags = df
					end
					local function writeInstructions()
						local auxSkip = false
						local function reg(act, regs, extra, hide)
							table.insert(protoRegisterActions, {
								usedRegisters = regs or {},
								extraData = extra,
								opCode = act,
								hide = hide,
							})
						end
						for idx, instruction in ipairs(instructions) do
							if auxSkip then
								auxSkip = false
								continue
							end
							local oci = LuauOpCode[Luau:INSN_OP(instruction)]
							if not oci then
								continue
							end
							local opn = oci.name
							local opt = oci.type
							local isAux = oci.aux == true
							local A, B, C, sD, D, E, aux
							if opt == "A" then
								A = Luau:INSN_A(instruction)
							elseif opt == "E" then
								E = Luau:INSN_E(instruction)
							elseif opt == "AB" then
								A = Luau:INSN_A(instruction)
								B = Luau:INSN_B(instruction)
							elseif opt == "AC" then
								A = Luau:INSN_A(instruction)
								C = Luau:INSN_C(instruction)
							elseif opt == "ABC" then
								A = Luau:INSN_A(instruction)
								B = Luau:INSN_B(instruction)
								C = Luau:INSN_C(instruction)
							elseif opt == "AD" then
								A = Luau:INSN_A(instruction)
								D = Luau:INSN_D(instruction)
							elseif opt == "AsD" then
								A = Luau:INSN_A(instruction)
								sD = Luau:INSN_sD(instruction)
							elseif opt == "sD" then
								sD = Luau:INSN_sD(instruction)
							end
							if isAux then
								auxSkip = true
								reg(oci, nil, nil, true)
								aux = instructions[idx + 1]
							end
							local st = not options.ShowTrivialOperations
							if opn == "NOP" or opn == "BREAK" or opn == "NATIVECALL" then
								reg(oci, nil, nil, st)
							elseif opn == "LOADNIL" then
								reg(oci, { A })
							elseif opn == "LOADB" then
								reg(oci, { A }, { B, C })
							elseif opn == "LOADN" then
								reg(oci, { A }, { sD })
							elseif opn == "LOADK" then
								reg(oci, { A }, { D })
							elseif opn == "MOVE" then
								reg(oci, { A, B })
							elseif opn == "GETGLOBAL" or opn == "SETGLOBAL" then
								reg(oci, { A }, { aux })
							elseif opn == "GETUPVAL" or opn == "SETUPVAL" then
								reg(oci, { A }, { B })
							elseif opn == "CLOSEUPVALS" then
								reg(oci, { A }, nil, st)
							elseif opn == "GETIMPORT" then
								reg(oci, { A }, { D, aux })
							elseif opn == "GETTABLE" or opn == "SETTABLE" then
								reg(oci, { A, B, C })
							elseif opn == "GETTABLEKS" or opn == "SETTABLEKS" then
								reg(oci, { A, B }, { C, aux })
							elseif opn == "GETTABLEN" or opn == "SETTABLEN" then
								reg(oci, { A, B }, { C })
							elseif opn == "NEWCLOSURE" then
								reg(oci, { A }, { D })
								local p2 = innerProtos[D + 1]
								if p2 then
									collectCaptures(idx, p2)
									baseProto(p2)
								end
							elseif opn == "DUPCLOSURE" then
								reg(oci, { A }, { D })
								local c = constants[D + 1]
								if c then
									local p2 = protoTable[c.value - 1]
									if p2 then
										collectCaptures(idx, p2)
										baseProto(p2)
									end
								end
							elseif opn == "NAMECALL" then
								reg(oci, { A, B }, { C, aux }, st)
							elseif opn == "CALL" then
								reg(oci, { A }, { B, C })
							elseif opn == "RETURN" then
								reg(oci, { A }, { B })
							elseif opn == "JUMP" or opn == "JUMPBACK" then
								reg(oci, {}, { sD })
							elseif opn == "JUMPIF" or opn == "JUMPIFNOT" then
								reg(oci, { A }, { sD })
							elseif
								opn == "JUMPIFEQ"
								or opn == "JUMPIFLE"
								or opn == "JUMPIFLT"
								or opn == "JUMPIFNOTEQ"
								or opn == "JUMPIFNOTLE"
								or opn == "JUMPIFNOTLT"
							then
								reg(oci, { A, aux }, { sD })
							elseif
								opn == "ADD"
								or opn == "SUB"
								or opn == "MUL"
								or opn == "DIV"
								or opn == "MOD"
								or opn == "POW"
							then
								reg(oci, { A, B, C })
							elseif
								opn == "ADDK"
								or opn == "SUBK"
								or opn == "MULK"
								or opn == "DIVK"
								or opn == "MODK"
								or opn == "POWK"
							then
								reg(oci, { A, B }, { C })
							elseif opn == "AND" or opn == "OR" then
								reg(oci, { A, B, C })
							elseif opn == "ANDK" or opn == "ORK" then
								reg(oci, { A, B }, { C })
							elseif opn == "CONCAT" then
								local regs = { A }
								for r = B, C do
									table.insert(regs, r)
								end
								reg(oci, regs)
							elseif opn == "NOT" or opn == "MINUS" or opn == "LENGTH" then
								reg(oci, { A, B })
							elseif opn == "NEWTABLE" then
								reg(oci, { A }, { B, aux })
							elseif opn == "DUPTABLE" then
								reg(oci, { A }, { D })
							elseif opn == "SETLIST" then
								if C ~= 0 then
									local regs = { A, B }
									for k = 1, C - 1 do
										table.insert(regs, B + k)
									end
									reg(oci, regs, { aux, C })
								else
									reg(oci, { A, B }, { aux, C })
								end
							elseif opn == "FORNPREP" then
								reg(oci, { A, A + 1, A + 2 }, { sD })
							elseif opn == "FORNLOOP" then
								reg(oci, { A }, { sD })
							elseif opn == "FORGLOOP" then
								local nv = bit32.band(aux or 0, 0xFF)
								local regs = {}
								for k = 1, nv do
									table.insert(regs, A + k)
								end
								reg(oci, regs, { sD, aux })
							elseif opn == "FORGPREP_INEXT" or opn == "FORGPREP_NEXT" then
								reg(oci, { A, A + 1 })
							elseif opn == "FORGPREP" then
								reg(oci, { A }, { sD })
							elseif opn == "GETVARARGS" then
								if B ~= 0 then
									local regs = { A }
									for k = 1, B - 1 do
										table.insert(regs, A + k)
									end
									reg(oci, regs, { B })
								else
									reg(oci, { A }, { B })
								end
							elseif opn == "PREPVARARGS" then
								reg(oci, {}, { A }, st)
							elseif opn == "LOADKX" then
								reg(oci, { A }, { aux })
							elseif opn == "JUMPX" then
								reg(oci, {}, { E })
							elseif opn == "COVERAGE" then
								reg(oci, {}, { E }, st)
							elseif
								opn == "JUMPXEQKNIL"
								or opn == "JUMPXEQKB"
								or opn == "JUMPXEQKN"
								or opn == "JUMPXEQKS"
							then
								reg(oci, { A }, { sD, aux })
							elseif opn == "CAPTURE" then
								reg(oci, nil, nil, st)
							elseif opn == "SUBRK" or opn == "DIVRK" then
								reg(oci, { A, C }, { B })
							elseif opn == "IDIV" then
								reg(oci, { A, B, C })
							elseif opn == "IDIVK" then
								reg(oci, { A, B }, { C })
							elseif opn == "GETUDATAKS" then
								reg(oci, { A, B }, { C, aux })
							elseif opn == "SETUDATAKS" then
								reg(oci, { A, B }, { C, aux })
							elseif opn == "NAMECALLUDATA" then
								reg(oci, { A, B }, { C, aux }, st)
							elseif opn == "NEWCLASSMEMBER" then
								reg(oci, { A, C }, { aux })
							elseif opn == "CALLFB" then
								reg(oci, { A }, { B, C, aux })
							elseif opn == "CMPPROTO" then
								reg(oci, { A }, { sD, aux })
							elseif opn == "FASTCALL" then
								reg(oci, {}, { A, C }, st)
							elseif opn == "FASTCALL1" then
								reg(oci, { B }, { A, C }, st)
							elseif opn == "FASTCALL2" then
								local r2 = bit32.band(aux or 0, 0xFF)
								reg(oci, { B, r2 }, { A, C }, st)
							elseif opn == "FASTCALL2K" then
								reg(oci, { B }, { A, C, aux }, st)
							elseif opn == "FASTCALL3" then
								local r2 = bit32.band(aux or 0, 0xFF)
								local r3 = bit32.band(bit32.rshift(aux or 0, 8), 0xFF)
								reg(oci, { B, r2, r3 }, { A, C }, st)
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
				local usedGlobals = {}
				local usedGlobalsSet = {}
				local function isValidGlobal(key)
					if usedGlobalsSet[key] then
						return false
					end
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
					local function emit(s)
						resultParts[#resultParts + 1] = s
					end
					local function writeActions(protoActions)
						local actions = protoActions.actions
						local proto = protoActions.proto
						local lineInfo = proto.instructionLineInfo
						local inner = proto.innerProtos
						local consts = proto.constants
						local caps = proto.captures
						local pflags = proto.flags
						local numParams = proto.numParams
						local jumpMarkers = {}
						local function makeJump(idx)
							jumpMarkers[idx] = (jumpMarkers[idx] or 0) + 1
						end
						local indentLevel = 0
						local function ind()
							return string.rep("\t", indentLevel)
						end
						totalParameters += numParams
						if proto.main and pflags and pflags.native then
							emit("--!native\n")
						end

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
							if r == nil then
								return "upv_?"
							end
							local du = proto.debugUpvalues
							if du and du[r + 1] and du[r + 1].name ~= "" then
								return du[r + 1].name
							end
							return "upv_" .. tostring(r)
						end
						local function getSourceRegisters(opName, ur2)
							if opName == "CALL" or opName == "CALLFB" then
								local srcs = {}
								if ur2 then
									for k = 1, #ur2 do
										srcs[#srcs + 1] = ur2[k]
									end
								end
								return srcs
							end
							if opName == "NAMECALL" then
								if ur2 and ur2[1] ~= nil then
									return { ur2[1] }
								end
								return {}
							end
							if opName == "MOVE" then
								if ur2 and ur2[2] ~= nil then
									return { ur2[2] }
								end
								return {}
							end
							local srcs = {}
							if ur2 then
								for k = 2, #ur2 do
									srcs[#srcs + 1] = ur2[k]
								end
							end
							return srcs
						end
						local NO_DEF_OPS = {
							SETTABLE = true,
							SETTABLEKS = true,
							SETTABLEN = true,
							SETGLOBAL = true,
							SETUPVAL = true,
							SETUDATAKS = true,
							RETURN = true,
							JUMP = true,
							JUMPBACK = true,
							JUMPIF = true,
							JUMPIFNOT = true,
							JUMPIFEQ = true,
							JUMPIFLE = true,
							JUMPIFLT = true,
							JUMPIFNOTEQ = true,
							JUMPIFNOTLE = true,
							JUMPIFNOTLT = true,
							JUMPXEQKNIL = true,
							JUMPXEQKB = true,
							JUMPXEQKN = true,
							JUMPXEQKS = true,
							NAMECALL = true,
							NAMECALLUDATA = true,
							CLOSEUPVALS = true,
							SETLIST = true,
							FORNLOOP = true,
							FORGLOOP = true,
							COVERAGE = true,
							CAPTURE = true,
							NOP = true,
							BREAK = true,
							PREPVARARGS = true,
							CMPPROTO = true,
							FASTCALL = true,
							FASTCALL1 = true,
							FASTCALL2 = true,
							FASTCALL2K = true,
							FASTCALL3 = true,
							JUMPX = true,
							NEWCLASSMEMBER = true,
						}
						local function getDefinedRegisters(opName, ur2, ed2)
							if NO_DEF_OPS[opName] then
								return {}
							end
							if opName == "CALL" or opName == "CALLFB" then
								local baseR = ur2[1]
								local nRes = (ed2 and ed2[2] or 1) - 1
								if nRes == -1 then
									return { baseR }
								elseif nRes == 0 then
									return {}
								end
								local defs = {}
								for k = 1, nRes do
									defs[#defs + 1] = baseR + k - 1
								end
								return defs
							end
							if opName == "GETVARARGS" then
								local baseR = ur2[1]
								local vc = (ed2 and ed2[1] or 1) - 1
								if vc == -1 then
									return { baseR }
								end
								local defs = {}
								for k = 1, vc do
									defs[#defs + 1] = baseR + k - 1
								end
								return defs
							end
							if ur2 and ur2[1] ~= nil then
								return { ur2[1] }
							end
							return {}
						end
						local function isChainedRedefine(opName, ur2, ed2, defR, priorAct)
							local srcs = getSourceRegisters(opName, ur2)
							for k = 1, #srcs do
								if srcs[k] == defR then
									return true
								end
							end
							if priorAct and priorAct.opCode and priorAct.opCode.name == "NAMECALL" then
								if priorAct.usedRegisters and priorAct.usedRegisters[1] == defR then
									return true
								end
							end
							return false
						end
						local regGeneration = {}
						local regGenTimeline = {}
						local function ensureRegTimeline(r)
							if not regGenTimeline[r] then
								regGenTimeline[r] = {}
								regGeneration[r] = 0
							end
						end
						for ai, act in ipairs(actions) do
							local actOpn = act.opCode and act.opCode.name
							if actOpn then
								local aur, aed = act.usedRegisters, act.extraData
								local srcs = getSourceRegisters(actOpn, aur)
								for k = 1, #srcs do
									local r = srcs[k]
									ensureRegTimeline(r)
									local g = regGeneration[r]
									local tl = regGenTimeline[r]
									if tl[#tl] and tl[#tl].gen == g then
										tl[#tl].endIdx = ai
									end
								end
								local defs = getDefinedRegisters(actOpn, aur, aed)
								local priorAct = actions[ai - 1]
								for k = 1, #defs do
									local r = defs[k]
									ensureRegTimeline(r)
									local chained = isChainedRedefine(actOpn, aur, aed, r, priorAct)
									local tl = regGenTimeline[r]
									if chained and tl[#tl] then
										tl[#tl].endIdx = ai
										tl[#tl].defAi = ai
									else
										regGeneration[r] += 1
										tl[#tl + 1] = { gen = regGeneration[r], startIdx = ai, endIdx = ai, defAi = ai }
									end
								end
							end
						end
						local regNeedsSuffix = {}
						for r, tl in pairs(regGenTimeline) do
							if #tl > 1 then
								regNeedsSuffix[r] = true
							end
						end
						local function regGenAt(r, instrIdx)
							local tl = regGenTimeline[r]
							if not tl then
								return 0
							end
							local best = 0
							for k = 1, #tl do
								local entry = tl[k]
								if entry.startIdx <= instrIdx then
									best = entry.gen
								else
									break
								end
							end
							return best
						end

						local function constStr(idx)
							local c = consts[idx + 1]
							if c and type(c.value) == "string" then
								return c.value
							end
							return nil
						end
						local function findRecentStringLiteral(r, beforeAi)
							for j = beforeAi - 1, math.max(1, beforeAi - 6), -1 do
								local a = actions[j]
								if not a or not a.opCode then
									continue
								end
								local an = a.opCode.name
								local au = a.usedRegisters
								if au and au[1] == r then
									if an == "LOADK" then
										return constStr(a.extraData[1])
									end
									return nil
								end
							end
							return nil
						end
						local SERVICE_LIKE_METHODS = { GetService = true }
						local CHILD_LOOKUP_METHODS = {
							WaitForChild = true,
							FindFirstChild = true,
							FindFirstChildOfClass = true,
							FindFirstChildWhichIsA = true,
						}
						local KNOWN_GLOBAL_NAMES = {
							game = false,
							workspace = true,
							script = true,
							shared = false,
						}
						local function sanitizeName(s)
							if not s or s == "" then
								return nil
							end
							if not s:match("^[%a_][%w_]*$") then
								return nil
							end
							return s
						end
						local regInferredName = {}
						for r, tl in pairs(regGenTimeline) do
							for _, entry in ipairs(tl) do
								local defAi = entry.defAi
								local act = actions[defAi]
								if act and act.opCode then
									local opn2 = act.opCode.name
									local ed2 = act.extraData
									local name = nil
									if opn2 == "CALL" then
										local prevAct = actions[defAi - 1]
										if prevAct and prevAct.opCode and prevAct.opCode.name == "NAMECALL" then
											local method = constStr(prevAct.extraData[2])
											if
												method
												and (SERVICE_LIKE_METHODS[method] or CHILD_LOOKUP_METHODS[method])
											then
												local argReg = act.usedRegisters[1] + 1
												local lit = findRecentStringLiteral(argReg, defAi)
												name = sanitizeName(lit)
											end
										end
									elseif opn2 == "GETGLOBAL" or opn2 == "GETIMPORT" then
										local gname = constStr(ed2[1])
										if gname and KNOWN_GLOBAL_NAMES[gname] == true then
											name = gname
										end
									end
									if name then
										regInferredName[r .. ":" .. entry.gen] = name
									end
								end
							end
						end
						do
							local seenNames = {}
							for r, tl in pairs(regGenTimeline) do
								for _, entry in ipairs(tl) do
									local key = r .. ":" .. entry.gen
									local nm = regInferredName[key]
									if nm then
										if seenNames[nm] then
											regInferredName[key] = nil
										else
											seenNames[nm] = true
										end
									end
								end
							end
						end

						local regNameCache = {}
						local function fmtReg(r, instrIdx)
							if r == nil then
								return "v?"
							end
							local safeNumParams = numParams or 0
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
							local pr = r + 1
							if pr < safeNumParams + 1 then
								return "p" .. tostring((totalParameters - safeNumParams) + pr)
							end
							if instrIdx then
								local g = regGenAt(r, instrIdx)
								local inferred = regInferredName[r .. ":" .. g]
								if inferred then
									return inferred
								end
							end
							local baseName = "v" .. tostring(r - safeNumParams)
							if instrIdx and regNeedsSuffix[r] then
								local g = regGenAt(r, instrIdx)
								if g > 1 then
									return baseName .. "_" .. g
								end
							end
							return baseName
						end
						local function paramName(j)
							if proto.debugLocals then
								for _, dl in ipairs(proto.debugLocals) do
									if dl.startPC == 0 and dl.register == j - 1 then
										return dl.name
									end
								end
							end
							return "p" .. (totalParameters + j)
						end
						local function fmtConst(k)
							if not k then
								return "nil"
							end
							if k.type == LuauBytecodeTag.LBC_CONSTANT_VECTOR then
								return tostring(k.value)
							end
							if k.value == nil then
								return "nil"
							end
							if type(tonumber(k.value)) == "number" then
								local prec = tostring(options.ReaderFloatPrecision or 14)
								return tostring(tonumber(string.format("%0." .. prec .. "f", k.value)))
							end
							return toEscapedString(k.value)
						end
						local function fmtProto(p)
							local body = ""
							local nativePrefix = ""
							if p.flags and p.flags.native then
								if p.flags.cold and options.EnabledRemarks.ColdRemark then
									nativePrefix ..= string.format(
										Strings.DECOMPILER_REMARK,
										"This function is marked cold and is not compiled natively"
									)
								end
								nativePrefix ..= "@native "
							end
							if p.name then
								body = nativePrefix .. "local function " .. p.name
							else
								body = nativePrefix .. "function"
							end
							body ..= "("
							for j = 1, p.numParams do
								local pb = paramName(j)
								if p.hasTypeInfo and options.UseTypeInfo and p.typedParams and p.typedParams[j] then
									pb ..= ": " .. Luau:GetBaseTypeString(p.typedParams[j], true)
								end
								if j ~= p.numParams then
									pb ..= ", "
								end
								body ..= pb
							end
							if p.isVarArg then
								body ..= (p.numParams > 0) and ", ..." or "..."
							end
							body ..= ")\n"
							if options.ShowDebugInformation then
								body ..= "-- proto pool id: " .. tostring(p.id or "?") .. "\n"
								body ..= "-- num upvalues: " .. tostring(p.numUpvalues or "?") .. "\n"
								body ..= "-- num inner protos: " .. (p.sizeInnerProtos or 0) .. "\n"
								body ..= "-- size instructions: " .. (p.sizeInstructions or 0) .. "\n"
								body ..= "-- size constants: " .. (p.sizeConstants or 0) .. "\n"
								body ..= "-- lineinfo gap: " .. (p.lineInfoSize or "n/a") .. "\n"
								body ..= "-- max stack size: " .. tostring(p.maxStackSize or "?") .. "\n"
								body ..= "-- is typed: " .. tostring(p.hasTypeInfo) .. "\n"
							end
							return body
						end
						local function writeProto(reg, p)
							local body = fmtProto(p)
							if p.name then
								emit("\n" .. body)

								writeActions(registerActions[p.id])
								emit("end\n" .. fmtReg(reg) .. " = " .. p.name)
							else
								emit(fmtReg(reg) .. " = " .. body)

								writeActions(registerActions[p.id])
								emit("end")
							end
						end
						local CLEAN_SUPPRESS = {
							CLOSEUPVALS = true,
							PREPVARARGS = true,
							COVERAGE = true,
							CAPTURE = true,
							FASTCALL = true,
							FASTCALL1 = true,
							FASTCALL2 = true,
							FASTCALL2K = true,
							FASTCALL3 = true,
							JUMPX = true,
							NOP = true,
							JUMPBACK = true,
							NAMECALLUDATA = true,
							NAMECALL = true,
							FORNLOOP = true,
							FORGLOOP = true,
						}
						for i, action in ipairs(actions) do
							if action.hide then
								continue
							end
							local ur = action.usedRegisters
							local ed = action.extraData
							local oci = action.opCode
							if not oci then
								continue
							end
							local opn = oci.name
							if options.CleanMode and CLEAN_SUPPRESS[opn] then
								continue
							end
							if options.CleanMode and opn == "RETURN" then
								local b = ed and ed[1] or 0
								if b == 1 then
									continue
								end
							end
							if
								options.CleanMode
								and opn == "MOVE"
								and i > 1
								and actions[i - 1]
								and (
									actions[i - 1].opCode.name == "NEWCLOSURE"
									or actions[i - 1].opCode.name == "DUPCLOSURE"
								)
							then
								continue
							end
							local function R(r)
								return fmtReg(r, i)
							end
							local function handleJumps()
								local n = jumpMarkers[i]
								if n then
									jumpMarkers[i] = nil
									for _ = 1, n do
										indentLevel = math.max(0, indentLevel - 1)
										emit(ind() .. "end\n")
									end
								end
							end
							handleJumps()
							if not options.CleanMode then
								if options.ShowOperationIndex then
									emit("[" .. padLeft(i, "0", 3) .. "] ")
								end
								if options.ShowInstructionLines and lineInfo and lineInfo[i] then
									emit(":" .. padLeft(lineInfo[i], "0", 3) .. ":")
								end
								if options.ShowOperationNames then
									emit(padRight(opn, " ", 15))
								end
							end
							if opn == "LOADNIL" then
								emit(ind() .. R(ur[1]) .. " = nil")
							elseif opn == "LOADB" then
								emit(ind() .. R(ur[1]) .. " = " .. toEscapedString(toBoolean(ed[1])))

								if ed[2] ~= 0 then
									emit(" +" .. ed[2])
								end
							elseif opn == "LOADN" then
								emit(ind() .. R(ur[1]) .. " = " .. ed[1])
							elseif opn == "LOADK" then
								emit(ind() .. R(ur[1]) .. " = " .. fmtConst(consts[ed[1] + 1]))
							elseif opn == "MOVE" then
								emit(ind() .. R(ur[1]) .. " = " .. R(ur[2]))
							elseif opn == "GETGLOBAL" then
								local gk = tostring(consts[ed[1] + 1] and consts[ed[1] + 1].value or "")
								if options.ListUsedGlobals and isValidGlobal(gk) then
									table.insert(usedGlobals, gk)
									usedGlobalsSet[gk] = true
								end
								emit(ind() .. R(ur[1]) .. " = " .. gk)
							elseif opn == "SETGLOBAL" then
								local gk = tostring(consts[ed[1] + 1] and consts[ed[1] + 1].value or "")
								if options.ListUsedGlobals and isValidGlobal(gk) then
									table.insert(usedGlobals, gk)
									usedGlobalsSet[gk] = true
								end
								emit(ind() .. gk .. " = " .. R(ur[1]))
							elseif opn == "GETUPVAL" then
								emit(ind() .. R(ur[1]) .. " = " .. fmtUpv(caps[ed[1]]))
							elseif opn == "SETUPVAL" then
								emit(ind() .. fmtUpv(caps[ed[1]]) .. " = " .. R(ur[1]))
							elseif opn == "CLOSEUPVALS" then
								emit(ind() .. "-- clear captures from back until: " .. ur[1])
							elseif opn == "GETIMPORT" then
								local imp = tostring(consts[ed[1] + 1] and consts[ed[1] + 1].value or "")
								local totalIdx = bit32.rshift(ed[2] or 0, 30)
								if totalIdx == 1 and options.ListUsedGlobals and isValidGlobal(imp) then
									table.insert(usedGlobals, imp)
									usedGlobalsSet[imp] = true
								end
								emit(R(ur[1]) .. " = " .. imp)
							elseif opn == "GETTABLE" then
								emit(ind() .. R(ur[1]) .. " = " .. R(ur[2]) .. "[" .. R(ur[3]) .. "]")
							elseif opn == "SETTABLE" then
								emit(ind() .. R(ur[2]) .. "[" .. R(ur[3]) .. "] = " .. R(ur[1]))
							elseif opn == "GETTABLEKS" then
								local key = consts[ed[2] + 1] and consts[ed[2] + 1].value
								emit(ind() .. R(ur[1]) .. " = " .. R(ur[2]) .. formatIndexString(key))
							elseif opn == "SETTABLEKS" then
								local key = consts[ed[2] + 1] and consts[ed[2] + 1].value
								emit(ind() .. R(ur[2]) .. formatIndexString(key) .. " = " .. R(ur[1]))
							elseif opn == "GETTABLEN" then
								emit(ind() .. R(ur[1]) .. " = " .. R(ur[2]) .. "[" .. (ed[1] + 1) .. "]")
							elseif opn == "SETTABLEN" then
								emit(ind() .. R(ur[2]) .. "[" .. (ed[1] + 1) .. "] = " .. R(ur[1]))
							elseif opn == "NEWCLOSURE" then
								local p2 = inner[ed[1] + 1]
								if p2 then
									writeProto(ur[1], p2)
								end
							elseif opn == "DUPCLOSURE" then
								local c = consts[ed[1] + 1]
								if c then
									local p2 = protoTable[c.value - 1]
									if p2 then
										writeProto(ur[1], p2)
									end
								end
							elseif opn == "NAMECALL" then
								local method = tostring(consts[ed[2] + 1] and consts[ed[2] + 1].value or "")
								emit(ind() .. "-- :" .. method)
							elseif opn == "CALL" then
								local baseR = ur[1]
								local nArgs = ed[1] - 1
								local nRes = ed[2] - 1
								local nmMethod = ""
								local argOff = 0
								local prev = actions[i - 1]
								if prev and prev.opCode and prev.opCode.name == "NAMECALL" then
									nmMethod = ":"
										.. tostring(
											consts[prev.extraData[2] + 1] and consts[prev.extraData[2] + 1].value or ""
										)
									nArgs -= 1
									argOff += 1
								end
								local callBody = ""
								if nRes == -1 then
									callBody = "... = "
								elseif nRes > 0 then
									local rb = ""
									for k = 1, nRes do
										rb ..= R(baseR + k - 1)
										if k ~= nRes then
											rb ..= ", "
										end
									end
									callBody = rb .. " = "
								end
								callBody ..= R(baseR) .. nmMethod .. "("
								if nArgs == -1 then
									callBody ..= "..."
								elseif nArgs > 0 then
									local ab = ""
									for k = 1, nArgs do
										ab ..= R(baseR + k + argOff)
										if k ~= nArgs then
											ab ..= ", "
										end
									end
									callBody ..= ab
								end
								callBody ..= ")"
								emit(ind() .. callBody)
							elseif opn == "RETURN" then
								local baseR = ur[1]
								local tot = ed[1] - 2
								local rb = ""
								if tot == -2 then
									rb = " " .. R(baseR) .. ", ..."
								elseif tot > -1 then
									rb = " "
									for k = 0, tot do
										rb ..= R(baseR + k)
										if k ~= tot then
											rb ..= ", "
										end
									end
								end
								emit(ind() .. "return" .. rb)
							elseif opn == "JUMP" then
								emit("-- jump to #" .. (i + ed[1]))
							elseif opn == "JUMPBACK" then
								emit(ind() .. "-- jump back to #" .. (i + ed[1] + 1))
							elseif opn == "JUMPIF" then
								local ei = i + ed[1]
								makeJump(ei)
								emit("if not " .. R(ur[1]) .. " then -- goto #" .. ei)
							elseif opn == "JUMPIFNOT" then
								local ei = i + ed[1]
								makeJump(ei)
								emit("if " .. R(ur[1]) .. " then -- goto #" .. ei)
							elseif opn == "JUMPIFEQ" then
								local ei = i + ed[1]
								makeJump(ei)
								emit("if " .. R(ur[1]) .. " ~= " .. R(ur[2]) .. " then -- goto #" .. ei)
							elseif opn == "JUMPIFLE" then
								local ei = i + ed[1]
								makeJump(ei)
								emit("if " .. R(ur[1]) .. " > " .. R(ur[2]) .. " then -- goto #" .. ei)
							elseif opn == "JUMPIFLT" then
								local ei = i + ed[1]
								makeJump(ei)
								emit("if " .. R(ur[1]) .. " >= " .. R(ur[2]) .. " then -- goto #" .. ei)
							elseif opn == "JUMPIFNOTEQ" then
								local ei = i + ed[1]
								makeJump(ei)
								emit("if " .. R(ur[1]) .. " == " .. R(ur[2]) .. " then -- goto #" .. ei)
							elseif opn == "JUMPIFNOTLE" then
								local ei = i + ed[1]
								makeJump(ei)
								emit("if " .. R(ur[1]) .. " <= " .. R(ur[2]) .. " then -- goto #" .. ei)
							elseif opn == "JUMPIFNOTLT" then
								local ei = i + ed[1]
								makeJump(ei)
								emit("if " .. R(ur[1]) .. " < " .. R(ur[2]) .. " then -- goto #" .. ei)
							elseif opn == "ADD" then
								emit(R(ur[1]) .. " = " .. R(ur[2]) .. " + " .. R(ur[3]))
							elseif opn == "SUB" then
								emit(R(ur[1]) .. " = " .. R(ur[2]) .. " - " .. R(ur[3]))
							elseif opn == "MUL" then
								emit(R(ur[1]) .. " = " .. R(ur[2]) .. " * " .. R(ur[3]))
							elseif opn == "DIV" then
								emit(R(ur[1]) .. " = " .. R(ur[2]) .. " / " .. R(ur[3]))
							elseif opn == "MOD" then
								emit(R(ur[1]) .. " = " .. R(ur[2]) .. " % " .. R(ur[3]))
							elseif opn == "POW" then
								emit(R(ur[1]) .. " = " .. R(ur[2]) .. " ^ " .. R(ur[3]))
							elseif opn == "ADDK" then
								emit(R(ur[1]) .. " = " .. R(ur[2]) .. " + " .. fmtConst(consts[ed[1] + 1]))
							elseif opn == "SUBK" then
								emit(R(ur[1]) .. " = " .. R(ur[2]) .. " - " .. fmtConst(consts[ed[1] + 1]))
							elseif opn == "MULK" then
								emit(R(ur[1]) .. " = " .. R(ur[2]) .. " * " .. fmtConst(consts[ed[1] + 1]))
							elseif opn == "DIVK" then
								emit(R(ur[1]) .. " = " .. R(ur[2]) .. " / " .. fmtConst(consts[ed[1] + 1]))
							elseif opn == "MODK" then
								emit(R(ur[1]) .. " = " .. R(ur[2]) .. " % " .. fmtConst(consts[ed[1] + 1]))
							elseif opn == "POWK" then
								emit(R(ur[1]) .. " = " .. R(ur[2]) .. " ^ " .. fmtConst(consts[ed[1] + 1]))
							elseif opn == "AND" then
								emit(R(ur[1]) .. " = " .. R(ur[2]) .. " and " .. R(ur[3]))
							elseif opn == "OR" then
								emit(R(ur[1]) .. " = " .. R(ur[2]) .. " or " .. R(ur[3]))
							elseif opn == "ANDK" then
								emit(R(ur[1]) .. " = " .. R(ur[2]) .. " and " .. fmtConst(consts[ed[1] + 1]))
							elseif opn == "ORK" then
								emit(R(ur[1]) .. " = " .. R(ur[2]) .. " or " .. fmtConst(consts[ed[1] + 1]))
							elseif opn == "CONCAT" then
								local tgt = table.remove(ur, 1)
								local cb = ""
								for k, r in ipairs(ur) do
									cb ..= fmtReg(r, i)
									if k ~= #ur then
										cb ..= " .. "
									end
								end
								emit(ind() .. R(tgt) .. " = " .. cb)
							elseif opn == "NOT" then
								emit(ind() .. R(ur[1]) .. " = not " .. R(ur[2]))
							elseif opn == "MINUS" then
								emit(ind() .. R(ur[1]) .. " = -" .. R(ur[2]))
							elseif opn == "LENGTH" then
								emit(ind() .. R(ur[1]) .. " = #" .. R(ur[2]))
							elseif opn == "NEWTABLE" then
								emit(R(ur[1]) .. " = {}")

								if options.ShowDebugInformation and ed[2] and ed[2] > 0 then
									emit(" ")
								end
							elseif opn == "DUPTABLE" then
								local cv = consts[ed[1] + 1]
								if cv and type(cv.value) == "table" then
									local tb = "{"
									for k = 1, cv.value.size do
										tb ..= fmtConst(consts[cv.value.keys[k]])
										if k ~= cv.value.size then
											tb ..= ", "
										end
									end
									emit(R(ur[1]) .. " = {} -- " .. tb .. "}")
								else
									emit(R(ur[1]) .. " = {}")
								end
							elseif opn == "SETLIST" then
								local tgt = ur[1]
								local src = ur[2]
								local si = ed[1]
								local vc = ed[2]
								if vc == 0 then
									emit(R(tgt) .. "[" .. si .. "] = [...]")
								else
									local prevNewTable = false
									for back = i - 1, math.max(1, i - 8), -1 do
										local pa = actions[back]
										if not pa or pa.hide then
											continue
										end
										if pa.opCode then
											if
												pa.opCode.name == "NEWTABLE"
												and pa.usedRegisters
												and pa.usedRegisters[1] == tgt
											then
												prevNewTable = true
											end
										end
										break
									end
									local tot2 = #ur - 1
									if prevNewTable and si == 1 and tot2 > 0 then
										local vals = {}
										for k = 1, tot2 do
											vals[k] = fmtReg(src + k - 1, i)
										end
										local tgtName = R(tgt)
										for rp = #resultParts, math.max(1, #resultParts - 10), -1 do
											if
												resultParts[rp]
												and resultParts[rp]:find(tgtName .. " = {}", 1, true)
											then
												if tot2 <= 4 then
													resultParts[rp] = tgtName
														.. " = { "
														.. table.concat(vals, ", ")
														.. " }"
												else
													local sep = ",\n\t"
													resultParts[rp] = tgtName
														.. " = {\n\t"
														.. table.concat(vals, sep)
														.. "\n}"
												end
												break
											end
										end
									else
										local cb = ""
										for k = 1, tot2 do
											cb ..= R(tgt) .. "[" .. (si + k - 1) .. "] = " .. R(src + k - 1)
											if k ~= tot2 then
												cb ..= "\n"
											end
										end
										emit(cb)
									end
								end
							elseif opn == "FORNPREP" then
								emit(
									"for "
										.. R(ur[1])
										.. " = "
										.. R(ur[1])
										.. ", "
										.. R(ur[2])
										.. ", "
										.. R(ur[3])
										.. " do -- end at #"
										.. (i + ed[1])
								)
							elseif opn == "FORNLOOP" then
								emit("end -- iterate + jump to #" .. (i + ed[1]))
							elseif opn == "FORGLOOP" then
								emit("end -- iterate + jump to #" .. (i + ed[1]))
							elseif opn == "FORGPREP_INEXT" then
								local tr = ur[1] + 1
								emit("for " .. R(tr + 2) .. ", " .. R(tr + 3) .. " in ipairs(" .. R(tr) .. ") do")
							elseif opn == "FORGPREP_NEXT" then
								local tr = ur[1] + 1
								emit("for " .. R(tr + 2) .. ", " .. R(tr + 3) .. " in pairs(" .. R(tr) .. ") do")
							elseif opn == "FORGPREP" then
								local ei = i + ed[1] + 2
								local ea = actions[ei]
								local vb = ""
								if ea then
									for k, r in ipairs(ea.usedRegisters) do
										vb ..= fmtReg(r, i)
										if k ~= #ea.usedRegisters then
											vb ..= ", "
										end
									end
								end
								emit("for " .. vb .. " in " .. R(ur[1]) .. " do -- end at #" .. ei)
							elseif opn == "GETVARARGS" then
								local vc2 = ed[1] - 1
								local rb = ""
								if vc2 == -1 then
									rb = R(ur[1])
								else
									for k = 1, vc2 do
										rb ..= R(ur[k])
										if k ~= vc2 then
											rb ..= ", "
										end
									end
								end
								emit(ind() .. rb .. " = ...")
							elseif opn == "PREPVARARGS" then
								emit(ind() .. "-- ... ; number of fixed args: " .. ed[1])
							elseif opn == "LOADKX" then
								emit(ind() .. R(ur[1]) .. " = " .. fmtConst(consts[ed[1] + 1]))
							elseif opn == "JUMPX" then
								emit(ind() .. "-- jump to #" .. (i + ed[1]))
							elseif opn == "COVERAGE" then
								emit(ind() .. "-- coverage (" .. ed[1] .. ")")
							elseif opn == "JUMPXEQKNIL" then
								local rev = bit32.rshift(ed[2] or 0, 0x1F) ~= 1
								local sign = rev and "~=" or "=="
								local ei = i + ed[1]
								makeJump(ei)
								emit("if " .. R(ur[1]) .. " " .. sign .. " nil then -- goto #" .. ei)
							elseif opn == "JUMPXEQKB" then
								local val = tostring(toBoolean(bit32.band(ed[2] or 0, 1)))
								local rev = bit32.rshift(ed[2] or 0, 0x1F) ~= 1
								local sign = rev and "~=" or "=="
								local ei = i + ed[1]
								makeJump(ei)
								emit("if " .. R(ur[1]) .. " " .. sign .. " " .. val .. " then -- goto #" .. ei)
							elseif opn == "JUMPXEQKN" or opn == "JUMPXEQKS" then
								local cidx = bit32.band(ed[2] or 0, 0xFFFFFF)
								local val = fmtConst(consts[cidx + 1])
								local rev = bit32.rshift(ed[2] or 0, 0x1F) ~= 1
								local sign = rev and "~=" or "=="
								local ei = i + ed[1]
								makeJump(ei)
								emit("if " .. R(ur[1]) .. " " .. sign .. " " .. val .. " then -- goto #" .. ei)
							elseif opn == "CAPTURE" then
								emit(ind() .. "-- upvalue capture")
							elseif opn == "SUBRK" then
								emit(ind() .. R(ur[1]) .. " = " .. fmtConst(consts[ed[1] + 1]) .. " - " .. R(ur[2]))
							elseif opn == "DIVRK" then
								emit(ind() .. R(ur[1]) .. " = " .. fmtConst(consts[ed[1] + 1]) .. " / " .. R(ur[2]))
							elseif opn == "IDIV" then
								emit(ind() .. R(ur[1]) .. " = " .. R(ur[2]) .. " // " .. R(ur[3]))
							elseif opn == "IDIVK" then
								emit(ind() .. R(ur[1]) .. " = " .. R(ur[2]) .. " // " .. fmtConst(consts[ed[1] + 1]))
							elseif opn == "GETUDATAKS" then
								local key = consts[ed[2] + 1] and consts[ed[2] + 1].value
								emit(ind() .. R(ur[1]) .. " = " .. R(ur[2]) .. formatIndexString(key))
							elseif opn == "SETUDATAKS" then
								local key = consts[ed[2] + 1] and consts[ed[2] + 1].value
								emit(ind() .. R(ur[2]) .. formatIndexString(key) .. " = " .. R(ur[1]))
							elseif opn == "NAMECALLUDATA" then
								local method = tostring(consts[ed[2] + 1] and consts[ed[2] + 1].value or "")
								emit(ind() .. "-- :" .. method .. " (udata)")
							elseif opn == "NEWCLASSMEMBER" then
								local name = consts[(ed[1] or 0) + 1] and consts[(ed[1] or 0) + 1].value or "?"
								emit(ind() .. R(ur[1]) .. "." .. tostring(name) .. " = " .. R(ur[2]))
							elseif opn == "CALLFB" then
								local baseR = ur[1]
								local nArgs = (ed[1] or 1) - 1
								local nRes = (ed[2] or 1) - 1
								local callBody = ""
								if nRes == -1 then
									callBody = "... = "
								elseif nRes > 0 then
									local rb = ""
									for k = 1, nRes do
										rb ..= R(baseR + k - 1)
										if k ~= nRes then
											rb ..= ", "
										end
									end
									callBody = rb .. " = "
								end
								callBody ..= R(baseR) .. "("
								if nArgs == -1 then
									callBody ..= "..."
								elseif nArgs > 0 then
									local ab = ""
									for k = 1, nArgs do
										ab ..= R(baseR + k)
										if k ~= nArgs then
											ab ..= ", "
										end
									end
									callBody ..= ab
								end
								callBody ..= ")"
								emit(ind() .. callBody)
							elseif opn == "CMPPROTO" then
								local ei = i + (ed[1] or 0)
								makeJump(ei)
								emit(
									"if not proto_match("
										.. R(ur[1])
										.. ", proto#"
										.. tostring(ed[2] or "?")
										.. ") then -- goto #"
										.. ei
								)
							elseif opn == "FASTCALL" then
								emit("-- FASTCALL; " .. Luau:GetBuiltinInfo(ed[1]) .. "()")
							elseif opn == "FASTCALL1" then
								emit("-- FASTCALL1; " .. Luau:GetBuiltinInfo(ed[1]) .. "(" .. R(ur[1]) .. ")")
							elseif opn == "FASTCALL2" then
								emit(
									"-- FASTCALL2; "
										.. Luau:GetBuiltinInfo(ed[1])
										.. "("
										.. R(ur[1])
										.. ", "
										.. R(ur[2])
										.. ")"
								)
							elseif opn == "FASTCALL2K" then
								emit(
									"-- FASTCALL2K; "
										.. Luau:GetBuiltinInfo(ed[1])
										.. "("
										.. R(ur[1])
										.. ", "
										.. fmtConst(consts[(ed[3] or 0) + 1])
										.. ")"
								)
							elseif opn == "FASTCALL3" then
								emit(
									"-- FASTCALL3; "
										.. Luau:GetBuiltinInfo(ed[1])
										.. "("
										.. R(ur[1])
										.. ", "
										.. R(ur[2])
										.. ", "
										.. R(ur[3])
										.. ")"
								)
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
					local ok, res = pcall(function()
						return finalize(organize())
					end)
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
						return string.format(
							Strings.UNSUPPORTED_LBC_VERSION,
							bytecodeVersion,
							LuauBytecodeTag.LBC_VERSION_MIN,
							LuauBytecodeTag.LBC_VERSION_MAX
						)
					end
				end
			end
			bytecodeVersion = reader:nextByte()
			if bytecodeVersion == 0 then
				return manager(false, "COMPILATION_FAILURE")
			elseif
				bytecodeVersion >= LuauBytecodeTag.LBC_VERSION_MIN
				and bytecodeVersion <= LuauBytecodeTag.LBC_VERSION_MAX
			then
				return manager(true)
			else
				return manager(false, "UNSUPPORTED_LBC_VERSION")
			end
		end
		local CONST_TYPE = {
			[0] = "nil",
			[1] = "boolean",
			[2] = "number(f64)",
			[3] = "string",
			[4] = "import",
			[5] = "table",
			[6] = "closure",
			[7] = "vector",
			[8] = "table_with_constants",
			[9] = "integer",
			[10] = "class_shape",
		}
		local function parseProto(p, stringTable, depth, bytecodeVer)
			local result = {
				depth = depth or 0,
				maxStack = p:nextByte(),
				numParams = p:nextByte(),
				numUpvals = p:nextByte(),
				isVararg = p:nextByte() ~= 0,
				constants = {},
				protos = {},
				upvalues = {},
				debugName = "",
				strings = {},
				imports = {},
			}
			if (bytecodeVer or 4) >= 4 then
				result.flags = p:nextByte()
				local typeSize = p:nextVarInt()
				if typeSize > 0 then
					for _ = 1, typeSize do
						p:nextByte()
					end
				end
			end
			local instrCount = p:nextVarInt()
			for _ = 1, instrCount do
				p:nextUInt32()
			end
			local constCount = p:nextVarInt()
			for i = 1, constCount do
				local kind = p:nextByte()
				local name = CONST_TYPE[kind] or ("unknown(" .. kind .. ")")
				local value
				if kind == 0 then
					value = "nil"
				elseif kind == 1 then
					value = p:nextByte() ~= 0 and "true" or "false"
				elseif kind == 2 then
					value = tostring(p:nextDouble())
				elseif kind == 7 then
					value = tostring(p:nextFloat())
				elseif kind == 8 then
					local lo, hi = p:nextByte(), p:nextByte()
					local n = lo + hi * 256
					if n >= 32768 then
						n = n - 65536
					end
					value = tostring(n)
				elseif kind == 3 then
					local idx = p:nextVarInt()
					value = stringTable[idx] or ("<string #" .. idx .. ">")
					table.insert(result.strings, value)
				elseif kind == 4 then
					local id = p:nextUInt32()
					local k0 = bit32.band(bit32.rshift(id, 20), 0x3FF)
					local k1 = bit32.band(bit32.rshift(id, 10), 0x3FF)
					local k2 = bit32.band(id, 0x3FF)
					local parts = {}
					for _, k in ipairs({ k0, k1, k2 }) do
						if stringTable[k] then
							table.insert(parts, stringTable[k])
						end
					end
					value = table.concat(parts, ".")
					table.insert(result.imports, value)
				elseif kind == 5 then
					local keys, ks = p:nextVarInt(), {}
					for _ = 1, keys do
						local kidx = p:nextVarInt()
						table.insert(ks, stringTable[kidx] or "?")
					end
					value = "{" .. table.concat(ks, ", ") .. "}"
				elseif kind == 6 then
					value = "<proto #" .. p:nextVarInt() .. ">"
				else
					value = "?"
				end
				table.insert(result.constants, { kind = name, value = value, index = i - 1 })
			end
			local innerProtoCount = p:nextVarInt()
			for _ = 1, innerProtoCount do
				table.insert(result.protos, p:nextVarInt())
			end
			result.lineDefined = p:nextVarInt()
			local nameId = p:nextVarInt()
			result.debugName = stringTable[nameId] or ""
			local hasLines = p:nextByte()
			if hasLines ~= 0 then
				local lgap = p:nextByte()
				local baselineSize = bit32.rshift(instrCount - 1, lgap) + 1
				for _ = 1, instrCount do
					p:nextSignedByte()
				end
				for _ = 1, baselineSize do
					p:nextInt32()
				end
			end
			local hasDebug = p:nextByte()
			if hasDebug ~= 0 then
				local lc = p:nextVarInt()
				for _ = 1, lc do
					p:nextVarInt()
					p:nextVarInt()
					p:nextVarInt()
					p:nextByte()
				end
				local uc = p:nextVarInt()
				for j = 1, uc do
					local ui = p:nextVarInt()
					table.insert(result.upvalues, stringTable[ui] or ("upval_" .. j))
				end
			end
			return result
		end
		local function parseBytecode(bytes)
			local reader2 = Reader.new(bytes)
			local ver = reader2:nextByte()
			if ver == 0 then
				return nil, "Compile error: " .. reader2:nextString(reader2:len() - 1)
			end
			local typesVer = 0
			if ver >= 4 then
				typesVer = reader2:nextByte()
			end
			local stringCount = reader2:nextVarInt()
			local stringTable = {}
			for i = 1, stringCount do
				local len = reader2:nextVarInt()
				stringTable[i] = reader2:nextString(len)
			end
			local protoCount = reader2:nextVarInt()
			local protos = {}
			for i = 1, protoCount do
				local ok, proto = pcall(parseProto, reader2, stringTable, 0, ver)
				table.insert(protos, ok and proto or { error = tostring(proto), depth = 0 })
			end
			local entryProto = reader2:nextVarInt()
			return {
				version = ver,
				typesVersion = typesVer,
				stringTable = stringTable,
				protos = protos,
				entryProto = entryProto,
			}
		end
		local function buildReport(parsed, scriptName)
			local lines = {}
			local function w(s)
				table.insert(lines, s or "")
			end
			w("  code reconstructor — " .. (scriptName or "unknown"))
			w("  Luau version : " .. parsed.version)
			w("  Types version: " .. parsed.typesVersion)
			w("  Proto count  : " .. #parsed.protos)
			w("  Entry proto  : #" .. parsed.entryProto)
			w("  Strings total: " .. #parsed.stringTable)
			w("  STRING TABLE ")
			for i, s in ipairs(parsed.stringTable) do
				w(string.format("  [%3d] %q", i, s))
			end
			w("")
			local function walkProto(proto, idx)
				if proto.error then
					w("  [Proto #" .. idx .. "] PARSE ERROR: " .. proto.error)
					return
				end
				local ind = string.rep("  ", proto.depth + 1)
				local dn = proto.debugName ~= "" and (" '" .. proto.debugName .. "'") or ""
				w(string.format("%s Proto #%d%s", ind, idx, dn))
				w(
					string.format(
						"%s   params=%d  upvals=%d  maxStack=%d  vararg=%s",
						ind,
						proto.numParams,
						proto.numUpvals,
						proto.maxStack,
						tostring(proto.isVararg)
					)
				)
				if #proto.upvalues > 0 then
					w(ind .. "   Upvalues: " .. table.concat(proto.upvalues, ", "))
				end
				if #proto.imports > 0 then
					w(ind .. "   Imports:")
					for _, imp in ipairs(proto.imports) do
						w(ind .. "     " .. imp)
					end
				end
				if #proto.strings > 0 then
					w(ind .. "   String literals:")
					for _, s in ipairs(proto.strings) do
						w(ind .. '     "' .. s .. '"')
					end
				end
				if #proto.constants > 0 then
					w(ind .. "   All constants:")
					for _, c in ipairs(proto.constants) do
						w(string.format("%s     [%2d] %-14s %s", ind, c.index, c.kind, tostring(c.value)))
					end
				end
				w("")
				for i2, inner in ipairs(proto.protos) do
					walkProto(inner, i2)
				end
			end
			w(" PROTO TREE ")
			for i, proto in ipairs(parsed.protos) do
				walkProto(proto, i)
			end
			return table.concat(lines, "\n")
		end

		local function _ppImpl(text)
			local result = {}
			local depth = 0
			local DEDENT_BEFORE = { ["end"] = true, ["until"] = true }
			local INDENT_AFTER = { ["then"] = true, ["do"] = true, ["repeat"] = true }
			local DEDENT_THEN_INDENT = { ["else"] = true, ["elseif"] = true }
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
				if fw == "elseif" or fw == "else" then
					return false
				end
				for w2 in clean:gmatch("[%a_][%w_]*") do
					if INDENT_AFTER[w2] then
						return true
					end
					if w2 == "function" then
						return true
					end
				end
				return false
			end
			local function stripDisasm(line)
				return line:match("^%[%d+%]%s*:?%d*:?%s*%u[%u_]*%s+(.*)") or line
			end
			for line in (text .. "\n"):gmatch("[^\n]*\n") do
				local bare = line:gsub("\n$", "")
				if bare == "" then
					result[#result + 1] = "\n"
					continue
				end
				local expr = stripDisasm(bare)
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
					if containsOpener(expr) then
						depth += 1
					end
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

			local function escrep(s)
				return (s:gsub("%%", "%%%%"))
			end

			local function nextNonBlank(start)
				local j = start
				while j <= #rawLines and (rawLines[j] == nil or rawLines[j]:match("^%s*$")) do
					j += 1
				end
				return j
			end

			do
				local i = 1
				while i <= #rawLines do
					local line = rawLines[i]
					if line then
						local cond = line:match("^%s*if%s+(.-)%s+then%s*%-%-.*$")
							or line:match("^%s*if%s+(.-)%s+then%s*$")
						if cond then
							local gt = tonumber(line:match("%-%-.*goto #(%d+)"))
							if gt then
								for j = i + 1, math.min(i + 400, #rawLines) do
									local jl = rawLines[j]
									if jl and jl:match("^%s*%-%- jump back to #%d+%s*$") then
										if gt >= j then
											local ind = line:match("^(%s*)")
											rawLines[i] = ind .. "while " .. cond .. " do"
											rawLines[j] = ind .. "end"
										end
										break
									end
								end
							end
						end
					end
					i += 1
				end
			end

			do
				local i = 1
				while i <= #rawLines do
					local line = rawLines[i]
					if line and line:match("^%s*%-%- jump back to #%d+%s*$") then
						for back = 1, 4 do
							local prev = rawLines[i - back]
							if not prev then
								break
							end
							local cond, tgt = prev:match("^%s*if%s+(.-)%s+then%s*%-%- goto #(%d+)%s*$")
							if cond and tonumber(tgt) == i + 1 then
								local ind = prev:match("^(%s*)")
								rawLines[i - back] = ind .. "until " .. cond
								rawLines[i] = nil
								break
							end
						end
					end
					i += 1
				end
			end

			local function tryCollapse(i)
				local line = rawLines[i]
				if not line then
					return false
				end
				local reg, lit
				reg, lit = line:match('^%s*(v%d+) = (".-")%s*$')
				if not reg then
					reg, lit = line:match("^%s*(v%d+) = (%-?%d+%.?%d*)%s*$")
				end
				if not reg then
					reg, lit = line:match("^%s*(v%d+) = (true)%s*$")
				end
				if not reg then
					reg, lit = line:match("^%s*(v%d+) = (false)%s*$")
				end
				if not reg then
					reg, lit = line:match("^%s*(v%d+) = (nil)%s*$")
				end
				if not reg then
					reg, lit = line:match("^%s*(v%d+) = ([%a_][%w_%.]*)%s*$")
				end
				if not reg then
					return false
				end
				local ep = escpat(reg)
				local j = i + 1
				local skipped = 0
				while j <= #rawLines and skipped < 32 do
					local mid = rawLines[j]
					if mid == nil then
						j += 1
						continue
					end
					if mid:match("^%s*$") then
						j += 1
						skipped += 1
						continue
					end
					if mid:find(ep) then
						break
					end
					local isSimpleAssign = mid:match('^%s*v%d+%s*=%s*".-"%s*$')
						or mid:match("^%s*v%d+%s*=%s*%-?%d+%.?%d*%s*$")
						or mid:match("^%s*v%d+%s*=%s*true%s*$")
						or mid:match("^%s*v%d+%s*=%s*false%s*$")
						or mid:match("^%s*v%d+%s*=%s*nil%s*$")
						or mid:match("^%s*v%d+%s*=%s*[%a_][%w_%.]*%s*$")
					if isSimpleAssign then
						j += 1
						skipped += 1
						continue
					end
					break
				end
				if j > #rawLines or not rawLines[j] then
					return false
				end
				local nxt = rawLines[j]
				local cnt = 0
				for _ in nxt:gmatch(ep) do
					cnt += 1
				end
				if cnt ~= 1 then
					return false
				end
				if nxt:match("^%s*" .. ep .. "%s*=") then
					return false
				end
				rawLines[j] = nxt:gsub(ep, escrep(lit), 1)
				rawLines[i] = nil
				return true
			end
			local function tryFoldField(i)
				local line = rawLines[i]
				if not line then
					return false
				end
				local lreg, src, field = line:match("^%s*(v%d+) = (v%d+)%.([%a_][%w_]*)%s*$")
				if not lreg then
					lreg, src, field = line:match("^%s*(v%d+) = (v%d+)%[(.-)%]%s*$")
					if lreg then
						field = "[" .. field .. "]"
					else
						return false
					end
				else
					field = "." .. field
				end
				local j = nextNonBlank(i + 1)
				if j > #rawLines then
					return false
				end
				local nxt = rawLines[j]
				local ep = escpat(lreg)
				local cnt = 0
				for _ in nxt:gmatch(ep) do
					cnt += 1
				end
				if cnt ~= 1 then
					return false
				end
				if nxt:match("^%s*" .. ep .. "%s*=") then
					return false
				end
				rawLines[j] = nxt:gsub(ep, escrep(src .. field), 1)
				rawLines[i] = nil
				return true
			end

			local function tryFoldUpv(i)
				local line = rawLines[i]
				if not line then
					return false
				end
				local reg = line:match("^%s*(upv_%d+)%s*=")
				if not reg then
					return false
				end
				local val = line:match("^%s*upv_%d+%s*=%s*(.-)%s*$")
				if not val or val == "" then
					return false
				end
				local j = nextNonBlank(i + 1)
				if j > #rawLines or not rawLines[j] then
					return false
				end
				local nxt = rawLines[j]
				local ep = escpat(reg)
				local cnt = 0
				for _ in nxt:gmatch(ep) do
					cnt += 1
				end
				if cnt ~= 1 then
					return false
				end
				if nxt:match("^%s*" .. ep .. "%s*=") then
					return false
				end
				rawLines[j] = nxt:gsub(ep, escrep(val), 1)
				rawLines[i] = nil
				return true
			end

			do
				local changed = true
				local guard = 0
				while changed and guard < 20 do
					changed = false
					guard += 1
					for i = 1, #rawLines do
						if tryCollapse(i) then
							changed = true
						end
					end
					for i = 1, #rawLines do
						if tryFoldField(i) then
							changed = true
						end
					end
					for i = 1, #rawLines do
						if tryFoldUpv(i) then
							changed = true
						end
					end
				end
			end

			do
				local i = 1
				while i <= #rawLines do
					local line = rawLines[i]
					if line and line:match("^%s*v%d+ = {}%s*$") then
						local tbl = line:match("^%s*(v%d+)")
						local ep = escpat(tbl)
						local entries, j = {}, i + 1
						while j <= #rawLines do
							local nl = rawLines[j]
							if nl == nil then
								j += 1
								continue
							end
							if nl:match("^%s*$") then
								j += 1
								continue
							end
							local key, val = nl:match("^%s*" .. ep .. "%.([%a_][%w_]*)%s*=%s*(.+)$")
							if not key then
								key, val = nl:match("^%s*" .. ep .. '%["([^"]+)"%]%s*=%s*(.+)$')
							end
							local numkey
							if not key then
								numkey, val = nl:match("^%s*" .. ep .. "%[(%d+)%]%s*=%s*(.+)$")
								key = numkey
							end
							if key and val then
								entries[#entries + 1] =
									{ key = key, val = val:match("^(.-)%s*$"), idx = j, num = numkey ~= nil }
								j += 1
							else
								break
							end
						end
						if #entries >= 1 then
							local parts, allNum = {}, true
							for _, e in ipairs(entries) do
								if not e.num then
									allNum = false
								end
							end
							for _, e in ipairs(entries) do
								parts[#parts + 1] = allNum and e.val or (e.key .. " = " .. e.val)
								rawLines[e.idx] = nil
							end
							local ind = line:match("^(%s*)")
							if #parts <= 4 then
								rawLines[i] = ind .. tbl .. " = { " .. table.concat(parts, ", ") .. " }"
							else
								rawLines[i] = ind
									.. tbl
									.. " = {\n"
									.. ind
									.. "\t"
									.. table.concat(parts, ",\n" .. ind .. "\t")
									.. "\n"
									.. ind
									.. "}"
							end
						end
					end
					i += 1
				end
			end

			do
				local changed = true
				local guard = 0
				while changed and guard < 10 do
					changed = false
					guard += 1
					for i = 1, #rawLines do
						if tryCollapse(i) then
							changed = true
						end
					end
					for i = 1, #rawLines do
						if tryFoldField(i) then
							changed = true
						end
					end
					for i = 1, #rawLines do
						if tryFoldUpv(i) then
							changed = true
						end
					end
				end
			end

			local pass2 = {}
			for idx = 1, #rawLines do
				local line = rawLines[idx]
				if not line then
					continue
				end
				local s = line:match("^%s*(.-)%s*$")
				if s:match("^%-%- goto #%d+$") then
					continue
				end
				if s:match("^%-%- jump") then
					continue
				end
				if s:match("^%-%- :.*%(udata%)$") then
					continue
				end
				if s:match("^%-%- upvalue capture$") then
					continue
				end
				if s:match("^%-%- clear captures") then
					continue
				end
				if s:match("^%-%- FASTCALL") then
					continue
				end
				if s:match("^%-%- coverage") then
					continue
				end
				if s:match("^%-%- :[%a_][%w_]*%s*$") then
					continue
				end
				if s:match("^%-%- :[%a_][%w_]* %(udata%)%s*$") then
					continue
				end
				line = line:gsub("%s*%-%- goto #%d+", "")
				line = line:gsub("%s*%-%- end at #%d+", "")
				line = line:gsub("%s*%-%- iterate %+ jump to #%d+", "")
				pass2[#pass2 + 1] = line
			end

			local pass2b = {}
			for _, line in ipairs(pass2) do
				local r = line
				do
					local ind, rest = r:match("^(%s*)for v%d+ = (.+)$")
					if ind then
						r = ind .. "for i = " .. rest
					end
				end
				do
					local ind, rest = r:match("^(%s*)for v%d+, v%d+ in pairs(.+)$")
					if ind then
						r = ind .. "for k, v in pairs" .. rest
					end
				end
				do
					local ind, rest = r:match("^(%s*)for v%d+, v%d+ in ipairs(.+)$")
					if ind then
						r = ind .. "for i, v in ipairs" .. rest
					end
				end
				do
					local ind, iter = r:match("^(%s*)for v%d+, v%d+ in (v%d+) do%s*$")
					if ind then
						r = ind .. "for k, v in " .. iter .. " do"
					end
				end
				pass2b[#pass2b + 1] = r
			end

			local pass3 = {}
			local i3 = 1
			while i3 <= #pass2b do
				local line = pass2b[i3]
				local nxt = pass2b[i3 + 1]
				local s = line and line:match("^%s*(.-)%s*$") or ""
				local isNil = s:match("^v%d+ = nil") or s:match("^local v%d+ = nil")
				local nxtFor = nxt and nxt:match("^%s*for%s+")
				if isNil and nxtFor then
					i3 += 1
				else
					pass3[#pass3 + 1] = line
					i3 += 1
				end
			end

			local pass3b = {}
			local i3b = 1
			while i3b <= #pass3 do
				local line = pass3[i3b]
				local nxt = pass3[i3b + 1]
				if line and nxt then
					local ind, expr = line:match("^(%s*)%.%.%. = (.+)$")
					if ind and expr and nxt:match("^%s*return %.%.%.$") then
						pass3b[#pass3b + 1] = ind .. "return " .. expr
						i3b += 2
						continue
					end
				end
				pass3b[#pass3b + 1] = line
				i3b += 1
			end

			local seen4 = {}
			local pass4 = {}
			for _, line in ipairs(pass3b) do
				local reg = line:match("^%s*(v%d+)%s*=")
				if reg and not seen4[reg] then
					seen4[reg] = true
					line = line:gsub("^(%s*)(v%d+%s*=)", "%1local %2", 1)
				end
				pass4[#pass4 + 1] = line
			end

			local seen4b = {}
			local pass4b = {}
			for _, line in ipairs(pass4) do
				local reg = line:match("^%s*(upv_%d+)%s*=")
				if reg and not seen4b[reg] then
					seen4b[reg] = true
					line = line:gsub("^(%s*)(upv_%d+%s*=)", "%1local %2", 1)
				end
				pass4b[#pass4b + 1] = line
			end

			local final = {}
			local lastBlank = false
			for _, line in ipairs(pass4b) do
				local isBlank = line:match("^%s*$") ~= nil
				if isBlank and lastBlank then
					continue
				end
				lastBlank = isBlank
				final[#final + 1] = line
			end

			return table.concat(final, "\n")
		end
		ZukDecompile = Decompile
		prettyPrint = _ppImpl
		cleanOutput = _coImpl
		getgenv()._ZUK_DECOMPILE = Decompile
		getgenv()._ZUK_PRETTYPRINT = _ppImpl
		getgenv()._ZUK_CLEANOUTPUT = _coImpl
	end)
end
main()
if not (env.ZukDecompile or getgenv()._ZUK_DECOMPILE) then
	task.wait()
end

local function fmtNum(n)
	if n == math.floor(n) then
		return tostring(math.floor(n))
	end
	return string.format("%.10g", n)
end

local function serialize(v)
	local t = typeof(v)
	if t == "string" then
		return string.format("%q", v)
	elseif t == "number" then
		return fmtNum(v)
	elseif t == "boolean" then
		return tostring(v)
	elseif t == "nil" then
		return "nil"
	elseif t == "Vector3" then
		return ("Vector3.new(%s,%s,%s)"):format(fmtNum(v.X), fmtNum(v.Y), fmtNum(v.Z))
	elseif t == "Vector2" then
		return ("Vector2.new(%s,%s)"):format(fmtNum(v.X), fmtNum(v.Y))
	elseif t == "UDim2" then
		local xs, xo, ys, yo = v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset
		if xs == 0 and ys == 0 then
			return ("UDim2.fromOffset(%s,%s)"):format(fmtNum(xo), fmtNum(yo))
		end
		if xo == 0 and yo == 0 then
			return ("UDim2.fromScale(%s,%s)"):format(fmtNum(xs), fmtNum(ys))
		end
		return ("UDim2.new(%s,%s,%s,%s)"):format(fmtNum(xs), fmtNum(xo), fmtNum(ys), fmtNum(yo))
	elseif t == "UDim" then
		return ("UDim.new(%s,%s)"):format(fmtNum(v.Scale), fmtNum(v.Offset))
	elseif t == "CFrame" then
		if v == CFrame.identity then
			return "CFrame.identity"
		end
		local c = { v:GetComponents() }
		local s = {}
		for _, n in ipairs(c) do
			s[#s + 1] = fmtNum(n)
		end
		return "CFrame.new(" .. table.concat(s, ",") .. ")"
	elseif t == "Color3" then
		return ("Color3.fromRGB(%d,%d,%d)"):format(
			math.floor(v.R * 255 + 0.5),
			math.floor(v.G * 255 + 0.5),
			math.floor(v.B * 255 + 0.5)
		)
	elseif t == "BrickColor" then
		return ("BrickColor.new(%q)"):format(v.Name)
	elseif t == "EnumItem" then
		return tostring(v)
	elseif t == "Rect" then
		return ("Rect.new(%s,%s,%s,%s)"):format(fmtNum(v.Min.X), fmtNum(v.Min.Y), fmtNum(v.Max.X), fmtNum(v.Max.Y))
	elseif t == "FontFace" then
		local family = v.Family or ""
		local wn = v.Weight and v.Weight.Name or "Regular"
		local sn = v.Style and v.Style.Name or "Normal"
		if family:sub(1, 17) == "rbxasset://fonts/" then
			local en = family:match("/([%w_]+)%.json$")
			if en then
				local ok, ei = pcall(function()
					return Enum.Font[en]
				end)
				if ok and ei then
					return ("Font.fromEnum(Enum.Font.%s)"):format(en)
				end
			end
		end
		return ("Font.new(%q,Enum.FontWeight.%s,Enum.FontStyle.%s)"):format(family, wn, sn)
	elseif t == "NumberRange" then
		return ("NumberRange.new(%s,%s)"):format(fmtNum(v.Min), fmtNum(v.Max))
	elseif t == "NumberSequence" then
		local kps = {}
		for _, kp in ipairs(v.Keypoints) do
			kps[#kps + 1] = ("NumberSequenceKeypoint.new(%s,%s,%s)"):format(
				fmtNum(kp.Time),
				fmtNum(kp.Value),
				fmtNum(kp.Envelope)
			)
		end
		return "NumberSequence.new({" .. table.concat(kps, ",") .. "})"
	elseif t == "ColorSequence" then
		local kps = {}
		for _, kp in ipairs(v.Keypoints) do
			kps[#kps + 1] = ("ColorSequenceKeypoint.new(%s,Color3.fromRGB(%d,%d,%d))"):format(
				fmtNum(kp.Time),
				math.floor(kp.Value.R * 255 + 0.5),
				math.floor(kp.Value.G * 255 + 0.5),
				math.floor(kp.Value.B * 255 + 0.5)
			)
		end
		return "ColorSequence.new({" .. table.concat(kps, ",") .. "})"
	elseif t == "Vector3int16" then
		return ("Vector3int16.new(%d,%d,%d)"):format(v.X, v.Y, v.Z)
	elseif t == "Vector2int16" then
		return ("Vector2int16.new(%d,%d)"):format(v.X, v.Y)
	end
	return "nil"
end

local function merge(...)
	local r = {}
	for _, t in ipairs({ ... }) do
		for _, v in ipairs(t) do
			r[#r + 1] = v
		end
	end
	return r
end
local function dedup(t)
	local seen, r = {}, {}
	for _, v in ipairs(t) do
		if not seen[v] then
			seen[v] = true
			r[#r + 1] = v
		end
	end
	return r
end

local COMMON = {
	"Name",
	"Size",
	"Position",
	"AnchorPoint",
	"Visible",
	"ZIndex",
	"LayoutOrder",
	"BackgroundColor3",
	"BackgroundTransparency",
	"BorderColor3",
	"BorderSizePixel",
	"ClipsDescendants",
	"Active",
	"Selectable",
	"Rotation",
	"AutomaticSize",
}
local TEXT_COMMON = {
	"Text",
	"RichText",
	"TextSize",
	"Font",
	"FontFace",
	"TextColor3",
	"TextTransparency",
	"TextWrapped",
	"TextScaled",
	"TextXAlignment",
	"TextYAlignment",
	"TextTruncate",
	"TextStrokeColor3",
	"TextStrokeTransparency",
	"LineHeight",
}
local IMAGE_COMMON = {
	"Image",
	"ImageColor3",
	"ImageTransparency",
	"ImageRectOffset",
	"ImageRectSize",
	"ResampleMode",
	"ScaleType",
	"SliceCenter",
	"SliceScale",
	"TileSize",
}
local SOUND_PROPS = {
	"Name",
	"SoundId",
	"Volume",
	"Looped",
	"Playing",
	"TimePosition",
	"RollOffMaxDistance",
	"RollOffMinDistance",
	"RollOffMode",
	"PlaybackSpeed",
	"PlayOnRemove",
	"EmitterSize",
}

local propertyMap = {
	ScreenGui = {
		"Name",
		"Enabled",
		"ResetOnSpawn",
		"DisplayOrder",
		"IgnoreGuiInset",
		"ZIndexBehavior",
		"ScreenInsets",
		"SafeAreaCompatibility",
	},
	TextLabel = dedup(merge(COMMON, TEXT_COMMON, { "MaxVisibleGraphemes", "AutoLocalize" })),
	TextButton = dedup(merge(COMMON, TEXT_COMMON, { "AutoButtonColor", "Modal", "Style" })),
	TextBox = dedup(merge(COMMON, TEXT_COMMON, {
		"PlaceholderText",
		"PlaceholderColor3",
		"ClearTextOnFocus",
		"MultiLine",
		"TextEditable",
		"ShowNativeInput",
	})),
	Frame = merge(COMMON, { "Style" }),
	ScrollingFrame = merge(COMMON, {
		"CanvasSize",
		"CanvasPosition",
		"ScrollBarThickness",
		"ScrollBarImageColor3",
		"ScrollBarImageTransparency",
		"ScrollingDirection",
		"ScrollingEnabled",
		"ElasticBehavior",
		"VerticalScrollBarInset",
		"HorizontalScrollBarInset",
		"VerticalScrollBarPosition",
		"BottomImage",
		"MidImage",
		"TopImage",
		"AutomaticCanvasSize",
	}),
	ImageLabel = merge(COMMON, IMAGE_COMMON),
	ImageButton = merge(COMMON, IMAGE_COMMON, {
		"HoverImage",
		"PressedImage",
		"Style",
		"AutoButtonColor",
		"Modal",
	}),
	VideoFrame = merge(COMMON, { "Video", "Looped", "Playing", "TimePosition", "Volume" }),
	ViewportFrame = merge(COMMON, {
		"Ambient",
		"LightColor",
		"LightDirection",
		"ImageColor3",
		"ImageTransparency",
	}),
	BillboardGui = {
		"Name",
		"Active",
		"AlwaysOnTop",
		"Brightness",
		"ClipsDescendants",
		"Enabled",
		"LightInfluence",
		"MaxDistance",
		"Size",
		"SizeOffset",
		"StudsOffset",
		"StudsOffsetWorldSpace",
		"ZIndexBehavior",
		"ExtentsOffset",
	},
	SurfaceGui = {
		"Name",
		"Active",
		"AlwaysOnTop",
		"Brightness",
		"ClipsDescendants",
		"Enabled",
		"LightInfluence",
		"PixelsPerStud",
		"SizingMode",
		"ZIndexBehavior",
		"ToolPunchThroughDistance",
		"ZOffset",
	},
	Sound = SOUND_PROPS,
	StringValue = { "Name", "Value" },
	IntValue = { "Name", "Value" },
	NumberValue = { "Name", "Value" },
	BoolValue = { "Name", "Value" },
	Vector3Value = { "Name", "Value" },
	CFrameValue = { "Name", "Value" },
	Color3Value = { "Name", "Value" },
	ObjectValue = { "Name" },
	BindableEvent = { "Name" },
	BindableFunction = { "Name" },
	UICorner = { "CornerRadius" },
	UIStroke = {
		"Color3",
		"Thickness",
		"Transparency",
		"LineJoinMode",
		"ApplyStrokeMode",
		"Enabled",
	},
	UIGradient = { "Color", "Offset", "Rotation", "Transparency", "Enabled" },
	UIPadding = { "PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom" },
	UIListLayout = {
		"Padding",
		"FillDirection",
		"HorizontalAlignment",
		"VerticalAlignment",
		"SortOrder",
		"HorizontalFlex",
		"VerticalFlex",
		"ItemLineAlignment",
		"Wraps",
	},
	UIGridLayout = {
		"CellPadding",
		"CellSize",
		"FillDirectionMaxCells",
		"FillDirection",
		"HorizontalAlignment",
		"VerticalAlignment",
		"SortOrder",
		"StartCorner",
	},
	UITableLayout = {
		"FillEmptySpaceColumns",
		"FillEmptySpaceRows",
		"FillDirection",
		"HorizontalAlignment",
		"VerticalAlignment",
		"MajorAxis",
		"Padding",
		"SortOrder",
	},
	UIAspectRatioConstraint = { "AspectRatio", "AspectType", "DominantAxis" },
	UISizeConstraint = { "MinSize", "MaxSize" },
	UITextSizeConstraint = { "MinTextSize", "MaxTextSize" },
	UIScale = { "Scale" },
	UIFlexItem = { "FlexMode", "GrowRatio", "ShrinkRatio" },
	UIPageLayout = {
		"Animated",
		"CircularEnabled",
		"EasingDirection",
		"EasingStyle",
		"GamepadInputEnabled",
		"Padding",
		"ScrollWheelInputEnabled",
		"SortOrder",
		"TouchInputEnabled",
		"TweenTime",
		"FillDirection",
		"HorizontalAlignment",
		"VerticalAlignment",
	},
}
local function getProps(obj)
	return propertyMap[obj.ClassName] or merge(COMMON, {})
end

local SKIP_DEFAULTS = {
	BackgroundTransparency = 0,
	TextTransparency = 0,
	ImageTransparency = 0,
	TextStrokeTransparency = 1,
	BorderSizePixel = 1,
	ZIndex = 1,
	LayoutOrder = 0,
	Rotation = 0,
	AutomaticSize = Enum.AutomaticSize.None,
	AutomaticCanvasSize = Enum.AutomaticSize.None,
	AnchorPoint = Vector2.new(0, 0),
	ClipsDescendants = false,
	Active = false,
	Selectable = false,
	RichText = false,
	TextWrapped = false,
	TextScaled = false,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	AutoButtonColor = true,
	Enabled = true,
	ResetOnSpawn = true,
	DisplayOrder = 0,
	IgnoreGuiInset = false,
	ScrollingEnabled = true,
	Modal = false,
	MultiLine = false,
	TextEditable = true,
	ClearTextOnFocus = true,
	LineHeight = 1,
	MaxVisibleGraphemes = -1,
	ScrollBarThickness = 12,
	Volume = 0.5,
	Looped = false,
	Playing = false,
	PlaybackSpeed = 1,
	PlayOnRemove = false,
	TimePosition = 0,
}
local function shouldSkip(propName, val)
	local def = SKIP_DEFAULTS[propName]
	if def == nil then
		return false
	end
	local tv, td = typeof(val), typeof(def)
	if tv ~= td then
		return false
	end
	if tv == "Vector2" then
		return val.X == def.X and val.Y == def.Y
	end
	if tv == "UDim2" then
		return val.X.Scale == def.X.Scale
			and val.X.Offset == def.X.Offset
			and val.Y.Scale == def.Y.Scale
			and val.Y.Offset == def.Y.Offset
	end
	if tv == "UDim" then
		return val.Scale == def.Scale and val.Offset == def.Offset
	end
	if tv == "Color3" then
		return math.floor(val.R * 255 + 0.5) == math.floor(def.R * 255 + 0.5)
			and math.floor(val.G * 255 + 0.5) == math.floor(def.G * 255 + 0.5)
			and math.floor(val.B * 255 + 0.5) == math.floor(def.B * 255 + 0.5)
	end
	return val == def
end

local ZUK_OPTS = {
	DecompilerMode = "disasm",
	DecompilerTimeout = 20,
	CleanMode = false,
	ReaderFloatPrecision = 7,
	ShowDebugInformation = false,
	ShowTrivialOperations = true,
	ShowInstructionLines = true,
	ShowOperationIndex = false,
	ShowOperationNames = true,
	ListUsedGlobals = true,
	UseTypeInfo = true,
	EnabledRemarks = { ColdRemark = false, InlineRemark = true },
	ReturnElapsedTime = true,
	prettyPrint = true,
}

local function decompileObj(obj)
	local source, method = "", "unknown"
	local zuk = env.ZukDecompile or getgenv()._ZUK_DECOMPILE
	if zuk and env.getscriptbytecode then
		local okBC, bc = pcall(env.getscriptbytecode, obj)
		if okBC and bc and bc ~= "" then
			local okD, res = pcall(zuk, bc, ZUK_OPTS)
			if okD and res and res ~= "" then
				local pp = getgenv()._ZUK_PRETTYPRINT
				source = (pp and pp(res)) or res
				method = "zukv2"
			end
		end
	end
	if source == "" then
		local ok, src = pcall(function()
			return obj.Source
		end)
		if ok and src and src ~= "" then
			source = src
			method = "Source"
		end
	end
	if source == "" and env.decompile then
		local ok, res = pcall(env.decompile, obj)
		if ok and res and res ~= "" then
			source = res
			method = "decompile"
		end
	end
	if source == "" and env.getscriptclosure then
		local ok, fn = pcall(env.getscriptclosure, obj)
		if ok and fn then
			local ok2, bc = pcall(string.dump, fn)
			if ok2 and bc then
				source = "-- [BYTECODE ONLY — paste into a decompiler]\n"
					.. "-- string.dump length: "
					.. #bc
					.. " bytes\n"
				method = "dump"
			end
		end
	end
	if source == "" then
		source = "-- [PROTECTED] Could not extract source via any method\n"
		method = "ZukDecompile"
	end
	return source, method
end

local function buildPath(inst)
	local parts = {}
	local cur = inst
	for _ = 1, 32 do
		local okN, nm = pcall(function()
			return cur.Name
		end)
		if not okN then
			break
		end
		table.insert(parts, 1, nm)
		local okP, par = pcall(function()
			return cur.Parent
		end)
		if not okP or par == nil then
			break
		end
		if par == game then
			break
		end
		cur = par
	end
	return table.concat(parts, ".")
end

local function buildScreenGuiExport(gui)
	local extractedScripts = {}
	local extractedModules = {}
	local seenModules = {}
	local remoteRefs = {}
	local seenRemotes = {}
	local globalWarnings = {}
	local seenGlobals = {}
	local bindableWarnings = {}
	local instanceToVar = {}
	local varToRealName = {}
	local visitedObjects = {}

	local flatCounter = { n = 0 }
	local usedNames = {}
	local function newVar(base)
		flatCounter.n += 1
		local safe = (base or "obj"):gsub("[^%w_]", "_"):gsub("^(%d)", "_%1")
		local candidate = safe .. "_" .. flatCounter.n
		usedNames[candidate] = true
		return candidate
	end

	local codeLines = {}
	local indentLevel = 0
	local function emit(s)
		codeLines[#codeLines + 1] = string.rep("\t", indentLevel) .. s
	end
	local function emitRaw(s)
		codeLines[#codeLines + 1] = s
	end
	local function emitBlank()
		codeLines[#codeLines + 1] = ""
	end

	local function analyseSource(src, scriptName)
		for name in src:gmatch("_G%.([%w_]+)") do
			if not seenGlobals[name] then
				seenGlobals[name] = true
				globalWarnings[#globalWarnings + 1] = { name = "_G." .. name, via = scriptName }
			end
		end
		for name in src:gmatch('_G%["([^"]+)"%]') do
			if not seenGlobals[name] then
				seenGlobals[name] = true
				globalWarnings[#globalWarnings + 1] = { name = '_G["' .. name .. '"]', via = scriptName }
			end
		end
		for name in src:gmatch("shared%.([%w_]+)") do
			if not seenGlobals["shared." .. name] then
				seenGlobals["shared." .. name] = true
				globalWarnings[#globalWarnings + 1] = { name = "shared." .. name, via = scriptName }
			end
		end
		for name in src:gmatch("getgenv%(%)%.([%w_]+)") do
			if not seenGlobals["getgenv." .. name] then
				seenGlobals["getgenv." .. name] = true
				globalWarnings[#globalWarnings + 1] = { name = "getgenv()." .. name, via = scriptName }
			end
		end
	end

	local REMOTE_CLASSES = {
		RemoteEvent = true,
		RemoteFunction = true,
		UnreliableRemoteEvent = true,
	}
	local function scanRemotesInSource(src)
		local REMOTE_METHODS = {
			"FireServer",
			"InvokeServer",
			"FireClient",
			"FireAllClients",
			"OnClientEvent",
			"OnServerEvent",
			"OnClientInvoke",
			"OnServerInvoke",
		}
		for _, method in ipairs(REMOTE_METHODS) do
			for path in src:gmatch("([%w%.%:_]+)%s*:%s*" .. method) do
				local ok, inst = pcall(function()
					local cur = game
					for part in path:gmatch("[^%.]+") do
						local ok2, child = pcall(function()
							return cur:FindFirstChild(part) or (cur == game and game:GetService(part))
						end)
						if ok2 and child then
							cur = child
						else
							return nil
						end
					end
					return cur
				end)
				if ok and inst and typeof(inst) == "Instance" and REMOTE_CLASSES[inst.ClassName] then
					local fullPath = buildPath(inst)
					if not seenRemotes[fullPath] then
						seenRemotes[fullPath] = true
						remoteRefs[#remoteRefs + 1] = {
							path = fullPath,
							className = inst.ClassName,
							method = method,
						}
					end
				end
			end
		end
	end

	local function noteBindable(obj)
		bindableWarnings[#bindableWarnings + 1] = {
			name = obj.Name,
			cls = obj.ClassName,
			path = buildPath(obj),
		}
	end

	local SCRIPT_CLASSES = { LocalScript = true, Script = true, ModuleScript = true }

	local function extractScript(scriptObj, parentVar)
		local source, method = decompileObj(scriptObj)

		local enabled = true
		pcall(function()
			enabled = not scriptObj.Disabled
		end)

		analyseSource(source, scriptObj.Name)
		scanRemotesInSource(source)

		table.insert(extractedScripts, {
			parent = parentVar,
			className = scriptObj.ClassName,
			name = scriptObj.Name,
			source = source,
			enabled = enabled,
			method = method,
		})
	end

	local MODULE_SEARCH_ROOTS = {
		game:GetService("ReplicatedStorage"),
		game:GetService("StarterPlayerScripts"),
		game:GetService("StarterGui"),
	}
	do
		local ok, ps = pcall(function()
			return game.Players.LocalPlayer:FindFirstChild("PlayerScripts")
		end)
		if ok and ps then
			MODULE_SEARCH_ROOTS[#MODULE_SEARCH_ROOTS + 1] = ps
		end
	end

	local function traceModulesFromScript(scriptObj, depth)
		depth = depth or 0
		if depth > 8 then
			return
		end
		if not (env.getscriptclosure and env.getupvalues and env.getconstants) then
			return
		end

		local okFn, closure = pcall(env.getscriptclosure, scriptObj)
		if not okFn or not closure then
			return
		end

		local function registerModule(modInst, via)
			if seenModules[modInst] then
				return
			end
			seenModules[modInst] = true
			local src, meth = decompileObj(modInst)
			local parts, cur = {}, modInst
			for _ = 1, 24 do
				local okN, nm = pcall(function()
					return cur.Name
				end)
				if not okN then
					break
				end
				table.insert(parts, 1, nm)
				local okP, par = pcall(function()
					return cur.Parent
				end)
				if not okP or par == game or par == nil then
					break
				end
				cur = par
			end
			table.insert(extractedModules, {
				obj = modInst,
				name = modInst.Name,
				path = table.concat(parts, "."),
				source = src,
				method = meth,
				depth = depth,
				via = via,
			})
			analyseSource(src, modInst.Name)
			scanRemotesInSource(src)
			traceModulesFromScript(modInst, depth + 1)
		end

		local okUV, upvals = pcall(env.getupvalues, closure)
		if okUV and upvals then
			for _, uv in pairs(upvals) do
				local okT = pcall(function()
					if typeof(uv) ~= "Instance" then
						error()
					end
					if uv.ClassName ~= "ModuleScript" then
						error()
					end
				end)
				if okT then
					registerModule(uv, scriptObj.Name)
				end
			end
		end

		local okC, consts = pcall(env.getconstants, closure)
		if okC and consts then
			for _, c in pairs(consts) do
				if type(c) == "string" and #c > 0 and #c < 128 then
					for _, root in ipairs(MODULE_SEARCH_ROOTS) do
						local okF, found = pcall(function()
							return root:FindFirstChild(c, true)
						end)
						if okF and found and found.ClassName == "ModuleScript" then
							registerModule(found, scriptObj.Name .. ' (const "' .. c .. '")')
						end
					end
				end
			end
		end

		local okC2, consts2 = pcall(env.getconstants, closure)
		if okC2 and consts2 then
			for _, c in pairs(consts2) do
				if type(c) == "number" and c == math.floor(c) and c > 1e6 then
					local key = tostring(c)
					if not seenGlobals["require_asset_" .. key] then
						seenGlobals["require_asset_" .. key] = true
						globalWarnings[#globalWarnings + 1] = {
							name = "require(" .. key .. ") [numeric asset ID — unresolvable]",
							via = scriptObj.Name,
						}
					end
				end
			end
		end
	end

	local function findScriptInTree(root, name, cls)
		for _, d in ipairs(root:GetDescendants()) do
			if d.Name == name and d.ClassName == cls then
				return d
			end
		end
		return nil
	end

	local BINDABLE_CLASSES = { BindableEvent = true, BindableFunction = true }

	local function generateGuiCode(obj, parentVar)
		if visitedObjects[obj] then
			return
		end
		visitedObjects[obj] = true

		local cls = obj.ClassName
		if SCRIPT_CLASSES[cls] then
			extractScript(obj, parentVar)
			return
		end

		if BINDABLE_CLASSES[cls] then
			noteBindable(obj)
		end

		local varName = newVar(obj.Name)
		instanceToVar[obj] = varName
		varToRealName[varName] = obj.Name

		emit(("local %s = Instance.new(%q)"):format(varName, cls))
		emit(("%s.Parent = %s"):format(varName, parentVar))
		if obj.Name ~= cls then
			emit(("%s.Name = %q"):format(varName, obj.Name))
		end

		for _, propName in ipairs(getProps(obj)) do
			if propName == "Name" then
				continue
			end
			local ok, val = pcall(function()
				return obj[propName]
			end)
			if ok and val ~= nil and not shouldSkip(propName, val) then
				local s = serialize(val)
				if s ~= "nil" then
					emit(("%s.%s = %s"):format(varName, propName, s))
				end
			end
		end

		local children = obj:GetChildren()
		if #children > 0 then
			emitBlank()
			for _, child in ipairs(children) do
				generateGuiCode(child, varName)
			end
		end
	end

	emitRaw('local Players    = game:GetService("Players")')
	emitRaw('local RunService = game:GetService("RunService")')
	emitRaw('local TweenService = game:GetService("TweenService")')
	emitRaw("local player    = Players.LocalPlayer")
	emitRaw('local playerGui = player:WaitForChild("PlayerGui")')
	emitBlank()
	emitRaw("-- Remove existing copy to allow re-injection")
	emitRaw(("local _existing = playerGui:FindFirstChild(%q)"):format(gui.Name))
	emitRaw("if _existing then _existing:Destroy() end")
	emitBlank()

	emitRaw("--  GUI Structure ")
	emitRaw("local function createGui()")
	indentLevel = 1

	local sgVar = newVar(gui.Name)
	instanceToVar[gui] = sgVar
	varToRealName[sgVar] = gui.Name
	emit(('local %s = Instance.new("ScreenGui")'):format(sgVar))

	for _, propName in ipairs(getProps(gui)) do
		if propName == "Name" then
			continue
		end
		local ok, val = pcall(function()
			return gui[propName]
		end)
		if ok and val ~= nil and not shouldSkip(propName, val) then
			local s = serialize(val)
			if s ~= "nil" then
				emit(("%s.%s = %s"):format(sgVar, propName, s))
			end
		end
	end
	if gui.Name ~= "ScreenGui" then
		emit(("%s.Name = %q"):format(sgVar, gui.Name))
	end
	emitBlank()

	for _, child in ipairs(gui:GetChildren()) do
		generateGuiCode(child, sgVar)
	end

	emitBlank()
	emit(("%s.Parent = playerGui"):format(sgVar))
	emit(("return %s"):format(sgVar))
	indentLevel = 0
	emitRaw("end")
	emitBlank()

	if env.getscriptclosure and env.getupvalues and env.getconstants then
		for _, sd in ipairs(extractedScripts) do
			local liveObj = findScriptInTree(gui, sd.name, sd.className)
			if liveObj then
				traceModulesFromScript(liveObj, 0)
			end
		end
	end

	if #extractedScripts > 0 then
		emitRaw(("--  Extracted Scripts (%d found) "):format(#extractedScripts))
		for i, sd in ipairs(extractedScripts) do
			emitRaw(
				("-- [%d] %s  (%s)  method: %s  enabled: %s"):format(
					i,
					sd.name,
					sd.className,
					sd.method,
					tostring(sd.enabled)
				)
			)
			emitRaw(("local function runScript_%d(script_obj)"):format(i))
			emitRaw("\tlocal script       = script_obj")
			emitRaw("\tlocal scriptParent = script_obj.Parent")
			if not sd.enabled then
				emitRaw("\t--[[ DISABLED SCRIPT — uncomment body to enable")
			end
			for line in (sd.source .. "\n"):gmatch("[^\n]*\n") do
				emitRaw("\t" .. line:gsub("^[\t ]*", ""):gsub("\n$", ""))
			end
			if not sd.enabled then
				emitRaw("\t--]]")
			end
			emitRaw("end")
			emitBlank()
		end
	end

	emitRaw("--  Init ")
	emitRaw("local gui = createGui()")
	emitBlank()

	if #extractedModules > 0 then
		emitRaw(("--  Linked ModuleScripts (%d found) "):format(#extractedModules))
		emitRaw("-- Discovered via closure upvalue + constant trace.")
		emitBlank()

		for i, md in ipairs(extractedModules) do
			emitRaw(
				("-- [M%d] %s  path: %s  method: %s  via: %s  depth: %d"):format(
					i,
					md.name,
					md.path,
					md.method,
					md.via,
					md.depth
				)
			)
			emitRaw(("local function loadmodule_%d()"):format(i))
			for line in (md.source .. "\n"):gmatch("[^\n]*\n") do
				emitRaw("\t" .. line:gsub("^[\t ]*", ""):gsub("\n$", ""))
			end
			emitRaw("end")
			emitBlank()
		end

		emitRaw("-- Module cache keyed by name AND Instance for maximum require() compat")
		emitRaw("local _moduleCache = {}")
		for i, md in ipairs(extractedModules) do
			emitRaw(("_moduleCache[%q] = loadmodule_%d()"):format(md.name, i))
		end
		emitBlank()

		emitRaw("-- require() shim — redirect module lookups to extracted cache")
		emitRaw("local _realRequire = require")
		emitRaw("getgenv().require = function(mod)")
		emitRaw("\tif type(mod) == 'string' and _moduleCache[mod] ~= nil then")
		emitRaw("\t\treturn _moduleCache[mod]")
		emitRaw("\telseif typeof(mod) == 'Instance' and mod.ClassName == 'ModuleScript' then")
		emitRaw("\t\tif _moduleCache[mod.Name] ~= nil then return _moduleCache[mod.Name] end")
		emitRaw("\tend")
		emitRaw("\treturn _realRequire(mod)")
		emitRaw("end")
		emitBlank()
	end

	if #extractedScripts > 0 then
		for i, sd in ipairs(extractedScripts) do
			local parentRef
			if sd.parent == sgVar then
				parentRef = "gui"
			else
				local realName = varToRealName[sd.parent] or sd.parent
				parentRef = ("gui:FindFirstChild(%q, true)"):format(realName)
			end
			emitRaw(("-- Run: %s [%s]"):format(sd.name, sd.className))
			emitRaw("task.spawn(function()")
			emitRaw(("\tlocal parent = %s"):format(parentRef))
			emitRaw("\tif parent then")
			emitRaw(("\t\trunScript_%d(parent)"):format(i))
			emitRaw("\telse")
			emitRaw(('\t\twarn("[G2S] Parent not found for script: %s")'):format(sd.name))
			emitRaw("\tend")
			emitRaw("end)")
			emitBlank()
		end
	end

	local hasWarnings = (#remoteRefs + #globalWarnings + #bindableWarnings) > 0

	if hasWarnings then
		emitBlank()
		emitRaw("--[[")
		emitRaw(
			"  ╔══════════════════════════════════════════════════════╗"
		)
		emitRaw("  ║              EXTRACTION WARNINGS  (v5)              ║")
		emitRaw(
			"  ╚══════════════════════════════════════════════════════╝"
		)

		if #remoteRefs > 0 then
			emitRaw("")
			emitRaw("  REMOTES referenced by extracted scripts:")
			emitRaw("  These Instances must exist at runtime or the scripts will error.")
			emitRaw("  Stub lines are emitted below — uncomment to create dummy Remotes.")
			for _, r in ipairs(remoteRefs) do
				emitRaw(("  • %s  [%s]  (seen via :%s)"):format(r.path, r.className, r.method))
			end
		end

		if #globalWarnings > 0 then
			emitRaw("")
			emitRaw("  GLOBAL STATE referenced (_G / shared / getgenv):")
			emitRaw("  These are set by other scripts at runtime and cannot be extracted.")
			emitRaw("  You may need to initialise them manually before running this script.")
			for _, g in ipairs(globalWarnings) do
				emitRaw(("  • %s  (via: %s)"):format(g.name, g.via))
			end
		end

		if #bindableWarnings > 0 then
			emitRaw("")
			emitRaw("  BINDABLE INSTANCES found (connections NOT preserved):")
			emitRaw("  BindableEvent/BindableFunction fire/connect wiring is lost.")
			emitRaw("  The Instance is recreated but you must rewire .Event:Connect() manually.")
			for _, b in ipairs(bindableWarnings) do
				emitRaw(("  • %s  [%s]  path: %s"):format(b.name, b.cls, b.path))
			end
		end

		emitRaw("--]]")
		emitBlank()
	end

	if #remoteRefs > 0 then
		emitRaw("--[[ REMOTE STUBS — uncomment if the game's Remotes are missing at runtime")
		emitRaw("-- local RS = game:GetService('ReplicatedStorage')")
		for _, r in ipairs(remoteRefs) do
			emitRaw(("-- local _stub_%s = Instance.new(%q)"):format(r.path:gsub("[^%w_]", "_"), r.className))
			emitRaw(("-- _stub_%s.Name = %q"):format(r.path:gsub("[^%w_]", "_"), r.path:match("[^%.]+$") or r.path))
			emitRaw(("-- _stub_%s.Parent = RS"):format(r.path:gsub("[^%w_]", "_")))
		end
		emitRaw("--]]")
		emitBlank()
	end

	emitRaw("-- Self-test: runs 1 second after injection and warns if GUI looks wrong")
	emitRaw("task.delay(1, function()")
	emitRaw(("\tlocal g = playerGui:FindFirstChild(%q)"):format(gui.Name))
	emitRaw("\tif not g then")
	emitRaw(('\t\twarn("[G2S] Self-test FAIL: ScreenGui %q not found in PlayerGui")'):format(gui.Name))
	emitRaw("\t\treturn")
	emitRaw("\tend")
	local expectedChildCount = 0
	for _, c in ipairs(gui:GetChildren()) do
		if not SCRIPT_CLASSES[c.ClassName] then
			expectedChildCount += 1
		end
	end
	emitRaw(("\tlocal expectedChildren = %d"):format(expectedChildCount))
	emitRaw("\tlocal actualChildren = #g:GetChildren()")
	emitRaw("\tif actualChildren ~= expectedChildren then")
	emitRaw('\t\twarn(("[G2S] Self-test WARN: expected %d children, got "):format(expectedChildren)..actualChildren)')
	emitRaw("\telse")
	emitRaw(('\t\tprint("[G2S] Self-test OK: %q injected correctly")'):format(gui.Name))
	emitRaw("\tend")
	emitRaw("end)")
	emitBlank()

	local totalProps = 0
	for _, l in ipairs(codeLines) do
		if l:find("%.%a+ = ") then
			totalProps += 1
		end
	end

	local dateStr = "unknown"
	pcall(function()
		dateStr = os.date("%Y-%m-%d %H:%M:%S")
	end)

	local header = table.concat({
		"--[[",
		"GUI -> SCRIPT CONVERTER  v5  (zukv2)",
		"",
		"ScreenGui : " .. gui.Name,
		"Extracted : " .. dateStr,
		"Elements  : " .. flatCounter.n,
		"Props     : " .. totalProps,
		"Scripts   : " .. #extractedScripts,
		"Modules   : " .. #extractedModules,
		"Remotes   : " .. #remoteRefs,
		"Globals   : " .. #globalWarnings,
		"Bindables : " .. #bindableWarnings,
		"",
		"--]]",
		"",
	}, "\n")

	local output = header .. table.concat(codeLines, "\n")

	return output
end

local function copyToClipboard(text)
	local copied = false
	if env.setclipboard then
		copied = pcall(env.setclipboard, text)
	end
	if not copied and setclipboard then
		copied = pcall(setclipboard, text)
	end
	if not copied and toclipboard then
		copied = pcall(toclipboard, text)
	end
	return copied
end

local function buildScriptExport(obj)
	local source, method = decompileObj(obj)
	local enabled = true
	pcall(function()
		enabled = not obj.Disabled
	end)

	local dateStr = "unknown"
	pcall(function()
		dateStr = os.date("%Y-%m-%d %H:%M:%S")
	end)

	local header = table.concat({
		"--[[",
		("SCRIPT DISASM  (%s)"):format(method),
		"",
		"Name      : " .. obj.Name,
		"Class     : " .. obj.ClassName,
		"Path      : " .. buildPath(obj),
		"Enabled   : " .. tostring(enabled),
		"Extracted : " .. dateStr,
		"--]]",
		"",
	}, "\n")

	return header .. source
end

local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SCAN_ROOTS = { playerGui, game:GetService("ReplicatedStorage") }
do
	local ok, ps = pcall(function()
		return player:FindFirstChild("PlayerScripts")
	end)
	if ok and ps then
		SCAN_ROOTS[#SCAN_ROOTS + 1] = ps
	end
end

local function scanTargets()
	local screenGuis, localScripts, moduleScripts = {}, {}, {}
	local seen = {}

	for _, child in ipairs(playerGui:GetChildren()) do
		if child:IsA("ScreenGui") then
			screenGuis[#screenGuis + 1] = child
		end
	end

	for _, root in ipairs(SCAN_ROOTS) do
		local okD, descendants = pcall(function()
			return root:GetDescendants()
		end)
		if okD then
			for _, d in ipairs(descendants) do
				if not seen[d] then
					seen[d] = true
					if d.ClassName == "LocalScript" then
						localScripts[#localScripts + 1] = d
					elseif d.ClassName == "ModuleScript" then
						moduleScripts[#moduleScripts + 1] = d
					end
				end
			end
		end
	end

	return screenGuis, localScripts, moduleScripts
end

local explorerGui = Instance.new("ScreenGui")
explorerGui.Name = "DisasmExplorer"
explorerGui.ResetOnSpawn = false
explorerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
explorerGui.DisplayOrder = 999
explorerGui.Parent = playerGui

local window = Instance.new("Frame")
window.Name = "Window"
window.Size = UDim2.fromOffset(760, 480)
window.Position = UDim2.fromScale(0.5, 0.5)
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
window.BorderSizePixel = 0
window.Active = true
window.Parent = explorerGui

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Color3.fromRGB(38, 38, 42)
titleBar.BorderSizePixel = 0
titleBar.Active = true
titleBar.Parent = window

local titleLabel = Instance.new("TextLabel")
titleLabel.BackgroundTransparency = 1
titleLabel.Size = UDim2.new(1, -70, 1, 0)
titleLabel.Position = UDim2.fromOffset(10, 0)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 15
titleLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "Disasm Explorer"
titleLabel.Parent = titleBar

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(28, 28)
closeButton.Position = UDim2.new(1, -30, 0, 2)
closeButton.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
closeButton.TextColor3 = Color3.fromRGB(255, 200, 200)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 16
closeButton.Text = "X"
closeButton.Parent = titleBar

do
	local dragging, dragStart, startPos = false, nil, nil
	titleBar.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragStart = input.Position
			startPos = window.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	game:GetService("UserInputService").InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local delta = input.Position - dragStart
			window.Position =
				UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

local listPanel = Instance.new("ScrollingFrame")
listPanel.Name = "ListPanel"
listPanel.Size = UDim2.new(0, 230, 1, -40)
listPanel.Position = UDim2.fromOffset(0, 32)
listPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
listPanel.BorderSizePixel = 0
listPanel.ScrollBarThickness = 6
listPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
listPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
listPanel.Parent = window

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = listPanel

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 4)
listPadding.PaddingLeft = UDim.new(0, 4)
listPadding.PaddingRight = UDim.new(0, 4)
listPadding.Parent = listPanel

local codePanel = Instance.new("ScrollingFrame")
codePanel.Name = "CodePanel"
codePanel.Size = UDim2.new(1, -230, 1, -40)
codePanel.Position = UDim2.fromOffset(230, 32)
codePanel.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
codePanel.BorderSizePixel = 0
codePanel.ScrollBarThickness = 8
codePanel.CanvasSize = UDim2.new(0, 0, 0, 0)
codePanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
codePanel.Parent = window

local codeLabel = Instance.new("TextBox")
codeLabel.Name = "CodeText"
codeLabel.BackgroundTransparency = 1
codeLabel.Size = UDim2.new(1, -16, 0, 0)
codeLabel.AutomaticSize = Enum.AutomaticSize.Y
codeLabel.Position = UDim2.fromOffset(8, 4)
codeLabel.Font = Enum.Font.Code
codeLabel.TextSize = 14
codeLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
codeLabel.TextXAlignment = Enum.TextXAlignment.Left
codeLabel.TextYAlignment = Enum.TextYAlignment.Top
codeLabel.TextWrapped = true
codeLabel.ClearTextOnFocus = false
codeLabel.MultiLine = true
codeLabel.TextEditable = false
codeLabel.Text = "Select a ScreenGui, LocalScript, or ModuleScript on the left."
codeLabel.Parent = codePanel

local statusBar = Instance.new("TextLabel")
statusBar.Name = "StatusBar"
statusBar.Size = UDim2.new(1, 0, 0, 28)
statusBar.Position = UDim2.new(0, 0, 1, -28)
statusBar.BackgroundColor3 = Color3.fromRGB(38, 38, 42)
statusBar.BorderSizePixel = 0
statusBar.Font = Enum.Font.Gotham
statusBar.TextSize = 12
statusBar.TextColor3 = Color3.fromRGB(180, 180, 180)
statusBar.TextXAlignment = Enum.TextXAlignment.Left
statusBar.Text = "  Ready"
statusBar.Parent = window

local copyButton = Instance.new("TextButton")
copyButton.Size = UDim2.fromOffset(90, 22)
copyButton.Position = UDim2.new(1, -96, 1, -25)
copyButton.BackgroundColor3 = Color3.fromRGB(50, 90, 60)
copyButton.TextColor3 = Color3.fromRGB(220, 255, 220)
copyButton.Font = Enum.Font.GothamBold
copyButton.TextSize = 12
copyButton.Text = "Copy"
copyButton.ZIndex = 2
copyButton.Parent = statusBar

local currentOutput = ""
copyButton.MouseButton1Click:Connect(function()
	if currentOutput == "" then
		return
	end
	local ok = copyToClipboard(currentOutput)
	statusBar.Text = ok and "  Copied to clipboard." or "  Copy failed (no clipboard API available)."
end)

closeButton.MouseButton1Click:Connect(function()
	explorerGui:Destroy()
end)

local selectedButton = nil
local function setSelected(btn)
	if selectedButton then
		selectedButton.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
	end
	selectedButton = btn
	if btn then
		btn.BackgroundColor3 = Color3.fromRGB(55, 65, 90)
	end
end

local function addHeader(text)
	local h = Instance.new("TextLabel")
	h.Size = UDim2.new(1, 0, 0, 22)
	h.BackgroundTransparency = 1
	h.Font = Enum.Font.GothamBold
	h.TextSize = 12
	h.TextColor3 = Color3.fromRGB(140, 160, 210)
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.Text = text
	h.LayoutOrder = #listPanel:GetChildren()
	h.Parent = listPanel
end

local function addEntry(displayName, onClick)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 24)
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 13
	btn.TextColor3 = Color3.fromRGB(220, 220, 220)
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.TextTruncate = Enum.TextTruncate.AtEnd
	btn.Text = "  " .. displayName
	btn.LayoutOrder = #listPanel:GetChildren()
	btn.Parent = listPanel

	btn.MouseButton1Click:Connect(function()
		setSelected(btn)
		statusBar.Text = "  Disassembling " .. displayName .. " ..."
		codeLabel.Text = "-- working..."
		task.spawn(function()
			local ok, result = pcall(onClick)
			if ok and result then
				currentOutput = result
				codeLabel.Text = result
				statusBar.Text = "  Done: " .. displayName
			else
				currentOutput = ""
				codeLabel.Text = "-- Failed to disassemble " .. displayName .. "\n-- " .. tostring(result)
				statusBar.Text = "  Error disassembling " .. displayName
			end
		end)
	end)

	return btn
end

local function populateList()
	for _, c in ipairs(listPanel:GetChildren()) do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end

	local screenGuis, localScripts, moduleScripts = scanTargets()

	if #screenGuis > 0 then
		addHeader(("SCREENGUIS (%d)"):format(#screenGuis))
		for _, sg in ipairs(screenGuis) do
			addEntry(sg.Name, function()
				return buildScreenGuiExport(sg)
			end)
		end
	end

	if #localScripts > 0 then
		addHeader(("LOCALSCRIPTS (%d)"):format(#localScripts))
		for _, ls in ipairs(localScripts) do
			addEntry(ls.Name, function()
				return buildScriptExport(ls)
			end)
		end
	end

	if #moduleScripts > 0 then
		addHeader(("MODULESCRIPTS (%d)"):format(#moduleScripts))
		for _, ms in ipairs(moduleScripts) do
			addEntry(ms.Name, function()
				return buildScriptExport(ms)
			end)
		end
	end
end

populateList()
