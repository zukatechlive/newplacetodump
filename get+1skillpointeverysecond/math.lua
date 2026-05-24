local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local MathQuizQuestion = ReplicatedStorage:WaitForChild("MathQuizQuestion")
local MathQuizWinner = ReplicatedStorage:WaitForChild("MathQuizWinner")


local ANSWER_DELAY = 1.7
local quizActive = false


local function solveEquation(question)
	local q = question
	q = q:gsub("\195\151", "*")
	q = q:gsub("\195\183", "/")
	q = q:gsub("[xX]", "*")
	q = q:gsub("[%(%)%[%]]", "")
	q = q:gsub("%s+", " "):match("^%s*(.-)%s*$")
	local tokens = {}
	for tok in q:gmatch("[%+%-%*/]?%s*%-?%d+%.?%d*") do
		local op, num = tok:match("^([%+%-%*/])%s*(%-?%d+%.?%d*)$")
		if op and num then
			table.insert(tokens, op)
			table.insert(tokens, tonumber(num))
		else
			local n = tonumber(tok:match("%-?%d+%.?%d*"))
			if n then
				table.insert(tokens, n)
			end
		end
	end
	if #tokens == 0 then
		return nil
	end
	local result = tokens[1]
	if type(result) ~= "number" then
		return nil
	end
	local i = 2
	while i <= #tokens do
		local op = tokens[i]
		local rhs = tokens[i + 1]
		if type(op) ~= "string" or type(rhs) ~= "number" then
			break
		end
		if op == "+" then
			result = result + rhs
		elseif op == "-" then
			result = result - rhs
		elseif op == "*" then
			result = result * rhs
		elseif op == "/" then
			if rhs == 0 then
				return nil
			end
			result = result / rhs
		end
		i = i + 2
	end
	local rounded = math.round(result)
	return (math.abs(result - rounded) < 0.0001) and rounded or result
end
MathQuizQuestion.OnClientEvent:Connect(function(question, isInsane)
	if not question or question == "" then
		return
	end
	quizActive = true
	local answer = solveEquation(question)
	if not answer then
		return
	end
	task.delay(ANSWER_DELAY, function()
		if not quizActive then
			return
		end
		TextChatService.TextChannels.RBXGeneral:SendAsync(tostring(answer))
	end)
end)
MathQuizWinner.OnClientEvent:Connect(function()
	quizActive = false
end)

-- made by zuka math is hard on god
