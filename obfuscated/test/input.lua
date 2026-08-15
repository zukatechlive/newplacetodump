local PASS = "PASS"
local FAIL = "FAIL"
local results: { string } = {}

type CheckResult = boolean

local function check(label: string, got: any, expected: any): CheckResult
	if got == expected then
		results[#results + 1] = `{PASS} | {label}`
		return true
	else
		results[#results + 1] = `{FAIL} | {label} | expected={tostring(expected)} got={tostring(got)}`
		return false
	end
end

do
	check("add", 1 + 2, 3)
	check("sub", 10 - 4, 6)
	check("mul", 3 * 7, 21)
	check("div", 20 / 4, 5)
	check("mod", 17 % 5, 2)
	check("pow", 2 ^ 8, 256)
	check("unm", -(-9), 9)
	check("precedence", 2 + 3 * 4, 14)
end

do
	local s: string = "Hello, World!"
	check("str_len", #s, 13)
	check("str_sub", string.sub(s, 1, 5), "Hello")
	check("str_upper", string.upper("abc"), "ABC")
	check("str_rep", string.rep("ab", 3), "ababab")
	check("str_concat", "foo" .. "bar", "foobar")
	check("str_byte", string.byte("A"), 65)
	check("str_char", string.char(65), "A")
	check("str_format", string.format("%d %.2f", 7, 3.14), "7 3.14")
	check("str_interp", `{1 + 1} apples`, "2 apples")
end

do
	type Point = { x: number, y: number }
	local t: { [number]: number, key: string } = { 10, 20, 30, key = "value" }
	check("tbl_index", t[1], 10)
	check("tbl_index2", t[3], 30)
	check("tbl_key", t.key, "value")
	check("tbl_len", #t, 3)
	t[#t + 1] = 40
	check("tbl_insert", t[4], 40)
	local sum = 0
	for i = 1, #t do
		sum += t[i] :: number
	end
	check("tbl_sum", sum, 100)

	local p: Point = { x = 1, y = 2 }
	check("point_x", p.x, 1)
	check("point_y", p.y, 2)
end

do
	local function makeCounter(start: number)
		local n = start
		return function(): number
			n += 1
			return n
		end
	end
	local c = makeCounter(0)
	check("closure1", c(), 1)
	check("closure2", c(), 2)
	check("closure3", c(), 3)
	local d = makeCounter(10)
	check("closure_sep", d(), 11)
	check("closure_c", c(), 4)
end

do
	local function sum(...: number): number
		local t = { ... }
		local s = 0
		for i = 1, #t do
			s += t[i]
		end
		return s
	end
	check("vararg_0", sum(), 0)
	check("vararg_3", sum(1, 2, 3), 6)
	check("vararg_5", sum(1, 2, 3, 4, 5), 15)
	local function first(...: any): any
		return (...)
	end
	check("vararg_first", first(99, 88, 77), 99)
end

do
	local function swap<T, U>(a: T, b: U): (U, T)
		return b, a
	end
	local x, y = swap(1, 2)
	check("multiret_x", x, 2)
	check("multiret_y", y, 1)
	local function trio(): (number, number, number)
		return 10, 20, 30
	end
	local a, b, c = trio()
	check("multiret_trio_a", a, 10)
	check("multiret_trio_b", b, 20)
	check("multiret_trio_c", c, 30)
end

do
	local function fib(n: number): number
		if n <= 1 then
			return n
		end
		return fib(n - 1) + fib(n - 2)
	end
	check("fib0", fib(0), 0)
	check("fib1", fib(1), 1)
	check("fib5", fib(5), 5)
	check("fib10", fib(10), 55)
	local function fact(n: number): number
		if n == 0 then
			return 1
		end
		return n * fact(n - 1)
	end
	check("fact0", fact(0), 1)
	check("fact5", fact(5), 120)
	check("fact10", fact(10), 3628800)
end

do
	local s = 0
	for i = 1, 100 do
		s += i
	end
	check("forloop", s, 5050)
	local s2 = 0
	local i = 1
	while i <= 10 do
		s2 += i
		i += 1
	end
	check("whileloop", s2, 55)
	local s3 = 0
	local j = 1
	repeat
		s3 += j
		j += 1
	until j > 10
	check("repeatloop", s3, 55)
	local t: { number } = { 3, 1, 4, 1, 5, 9 }
	local s4 = 0
	for _, v in ipairs(t) do
		s4 += v
	end
	check("ipairs", s4, 23)
end

do
	type Vector = {
		x: number,
		y: number,
		length: (self: Vector) -> number,
	}
	local Vec = {}
	Vec.__index = Vec
	function Vec.new(x: number, y: number): Vector
		return setmetatable({ x = x, y = y }, Vec) :: Vector
	end
	function Vec:length(): number
		return math.sqrt(self.x ^ 2 + self.y ^ 2)
	end
	function Vec:__tostring(): string
		return `{self.x},{self.y}`
	end
	function Vec.__add(a: Vector, b: Vector): Vector
		return Vec.new(a.x + b.x, a.y + b.y)
	end
	local v1 = Vec.new(3, 4)
	local v2 = Vec.new(1, 2)
	local v3 = v1 + v2
	check("meta_length", v1:length(), 5)
	check("meta_add_x", v3.x, 4)
	check("meta_add_y", v3.y, 6)
	check("meta_tostring", tostring(v1), "3,4")
end

do
	local ok, err = pcall(function()
		error("boom")
	end)
	check("pcall_catch", ok, false)
	check("pcall_errmsg", type(err), "string")
	local ok2, val = pcall(function()
		return 42
	end)
	check("pcall_ok", ok2, true)
	check("pcall_retval", val, 42)
end

do
	_G.__test_zuka = "hello"
	check("getglobal", _G.__test_zuka, "hello")
	_G.__test_zuka = nil
end

do
	local acc = 0
	local function add(x: number)
		acc += x
	end
	add(5)
	add(3)
	add(2)
	check("upval_mutate", acc, 10)
	local function outer()
		local v = 1
		local function inner(): number
			v *= 2
			return v
		end
		return inner, function(): number
			return v
		end
	end
	local inc, get = outer()
	inc()
	inc()
	check("upval_shared", get(), 4)
end

do
	local t = { [1] = "a", [2] = "b", x = 10, "c" }
	check("tbl_mixed_1", t[1], "c")
	check("tbl_mixed_2", t[2], "b")
	check("tbl_mixed_key", t.x, 10)
end

local passes, fails = 0, 0
for _, r in ipairs(results) do
	print(r)
	if r:sub(1, 4) == PASS then
		passes += 1
	else
		fails += 1
	end
end
print(`\n{passes} passed, {fails} failed out of {passes + fails} tests`)
