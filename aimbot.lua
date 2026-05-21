--[[              #                                
--  #  #          #                                
--  #  #         #                                 
--  #  #   ##         # ##   ##          ###   ##  
--  #  #  #  #        ##    #  #        #     #  # 
--  ####  ####        #     ####         ##   #  # 
--  ####  #           #     #              #  #  # 
--  #  #   ##         #      ##         ###    ##  
--                                                 
--                                                 
--                               
--  #                 #          
--  #                 #          
--  ###    ###   ###  #  #       
--  #  #  #  #  #     # #        
--  #  #  #  #  #     ##         
--  #  #  # ##  #     # #    #   
--  ###    # #   ###  #  #   #   
--                               
]]                           

local function loadAimbotGUI(args)
	local CoreGui = game:GetService("CoreGui")
	if CoreGui:FindFirstChild("UTS_CGE_Suite") and not args then
		if DoNotif then
			DoNotif("Aimbot GUI is already open.", 2)
		else
			warn("Aimbot GUI is already open.")
		end
		return
	end
	if CoreGui:FindFirstChild("UTS_CGE_Suite") then
	end
	local success, err = pcall(function()
		local UserInputService = game:GetService("UserInputService")
		local RunService = game:GetService("RunService")
		local Players = game:GetService("Players")
		local Workspace = game:GetService("Workspace")
		local TweenService = game:GetService("TweenService")
		local LocalPlayer = Players.LocalPlayer
		local Camera = Workspace.CurrentCamera
		local janitor = {}
		local function makeUICorner(element, cornerRadius)
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, cornerRadius or 6)
			corner.Parent = element
		end
		local MainScreenGui = CoreGui:FindFirstChild("UTS_CGE_Suite") or Instance.new("ScreenGui")
		MainScreenGui.Name = "UTS_CGE_Suite"
		MainScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
		MainScreenGui.ResetOnSpawn = false
		if not MainScreenGui.Parent then
			table.insert(
				janitor,
				MainScreenGui.Destroying:Connect(function()
					for _, connection in ipairs(janitor) do
						connection:Disconnect()
					end
				end)
			)
			MainScreenGui.Parent = CoreGui
		end
		local MainWindow = MainScreenGui:FindFirstChild("MainWindow")
		if MainWindow then
			MainWindow:Destroy()
		end
		getgenv().TargetScope = Workspace
		getgenv().TargetIndex = {}
		local explorerWindow = nil
		local function createExplorerWindow(statusLabel, indexerUpdateSignal)
			if explorerWindow and explorerWindow.Parent then
				explorerWindow.Visible = not explorerWindow.Visible
				return explorerWindow
			end
			local explorerFrame = Instance.new("Frame")
			explorerFrame.Name = "ExplorerWindow"
			explorerFrame.Size = UDim2.new(0, 300, 0, 450)
			explorerFrame.Position = UDim2.new(0.5, 305, 0.5, -225)
			explorerFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
			explorerFrame.BorderSizePixel = 1
			explorerFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
			explorerFrame.Draggable = true
			explorerFrame.Active = true
			explorerFrame.ClipsDescendants = true
			explorerFrame.Parent = MainScreenGui
			makeUICorner(explorerFrame, 8)
			local topBar = Instance.new("Frame", explorerFrame)
			topBar.Name = "TopBar"
			topBar.Size = UDim2.new(1, 0, 0, 30)
			topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
			makeUICorner(topBar, 8)
			local title = Instance.new("TextLabel", topBar)
			title.Size = UDim2.new(1, -30, 1, 0)
			title.Position = UDim2.new(0, 10, 0, 0)
			title.BackgroundTransparency = 1
			title.Font = Enum.Font.Code
			title.Text = "Game Explorer"
			title.TextColor3 = Color3.fromRGB(200, 220, 255)
			title.TextSize = 16
			title.TextXAlignment = Enum.TextXAlignment.Left
			local closeButton = Instance.new("TextButton", topBar)
			closeButton.Size = UDim2.new(0, 24, 0, 24)
			closeButton.Position = UDim2.new(1, -28, 0.5, -12)
			closeButton.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
			closeButton.Font = Enum.Font.Code
			closeButton.Text = "X"
			closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			closeButton.TextSize = 14
			makeUICorner(closeButton, 6)
			table.insert(
				janitor,
				closeButton.MouseButton1Click:Connect(function()
					explorerFrame.Visible = false
				end)
			)
			local treeScrollView = Instance.new("ScrollingFrame", explorerFrame)
			treeScrollView.Position = UDim2.new(0, 0, 0, 30)
			treeScrollView.Size = UDim2.new(1, 0, 1, -30)
			treeScrollView.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
			treeScrollView.BorderSizePixel = 0
			local uiListLayout = Instance.new("UIListLayout", treeScrollView)
			uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			uiListLayout.Padding = UDim.new(0, 1)
			local contextMenu = nil
			local function closeContextMenu()
				if contextMenu and contextMenu.Parent then
					contextMenu:Destroy()
				end
			end
			table.insert(
				janitor,
				UserInputService.InputBegan:Connect(function(input)
					if
						not (contextMenu and contextMenu:IsAncestorOf(input.UserInputType))
						and input.UserInputType ~= Enum.UserInputType.MouseButton2
					then
						closeContextMenu()
					end
				end)
			)
			local function createTree(parentInstance, parentUi, indentLevel)
				for _, child in ipairs(parentInstance:GetChildren()) do
					local itemFrame = Instance.new("Frame")
					itemFrame.Name = child.Name
					itemFrame.Size = UDim2.new(1, 0, 0, 22)
					itemFrame.BackgroundTransparency = 1
					itemFrame.Parent = parentUi
					local hasChildren = #child:GetChildren() > 0
					local toggleButton = Instance.new("TextButton")
					toggleButton.Size = UDim2.new(0, 20, 0, 20)
					toggleButton.Position = UDim2.fromOffset(indentLevel * 12, 1)
					toggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
					toggleButton.Font = Enum.Font.Code
					toggleButton.TextSize = 14
					toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
					toggleButton.Text = hasChildren and "[+]" or "[-]"
					toggleButton.Parent = itemFrame
					local nameButton = Instance.new("TextButton")
					nameButton.Size = UDim2.new(1, -((indentLevel * 12) + 22), 0, 20)
					nameButton.Position = UDim2.fromOffset((indentLevel * 12) + 22, 1)
					nameButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
					nameButton.Font = Enum.Font.Code
					nameButton.TextSize = 14
					nameButton.TextColor3 = Color3.fromRGB(220, 220, 220)
					nameButton.Text = " " .. child.Name .. " [" .. child.ClassName .. "]"
					nameButton.TextXAlignment = Enum.TextXAlignment.Left
					nameButton.Parent = itemFrame
					local childContainer = Instance.new("Frame", itemFrame)
					childContainer.Name = "ChildContainer"
					childContainer.Size = UDim2.new(1, 0, 0, 0)
					childContainer.Position = UDim2.new(0, 0, 1, 0)
					childContainer.BackgroundTransparency = 1
					childContainer.ClipsDescendants = true
					local childLayout = Instance.new("UIListLayout", childContainer)
					childLayout.SortOrder = Enum.SortOrder.LayoutOrder
					table.insert(
						janitor,
						itemFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
							childContainer.Size = UDim2.new(1, 0, 0, childLayout.AbsoluteContentSize.Y)
							itemFrame.Size = UDim2.new(1, 0, 0, 22 + childContainer.AbsoluteSize.Y)
						end)
					)
					table.insert(
						janitor,
						childLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
							childContainer.Size = UDim2.new(1, 0, 0, childLayout.AbsoluteContentSize.Y)
							itemFrame.Size = UDim2.new(1, 0, 0, 22 + childContainer.AbsoluteSize.Y)
						end)
					)
					table.insert(
						janitor,
						toggleButton.MouseButton1Click:Connect(function()
							local isExpanded = childContainer:FindFirstChildOfClass("Frame") ~= nil
							if not hasChildren then
								return
							end
							if isExpanded then
								for _, v in ipairs(childContainer:GetChildren()) do
									if v:IsA("Frame") then
										v:Destroy()
									end
								end
								toggleButton.Text = "[+]"
							else
								createTree(child, childContainer, indentLevel + 1)
								toggleButton.Text = "[-]"
							end
						end)
					)
					table.insert(
						janitor,
						nameButton.MouseButton2Click:Connect(function()
							closeContextMenu()
							if child:IsA("Folder") or child:IsA("Model") or child:IsA("Workspace") then
								contextMenu = Instance.new("Frame")
								contextMenu.Size = UDim2.new(0, 150, 0, 30)
								contextMenu.Position = UDim2.fromOffset(
									UserInputService:GetMouseLocation().X,
									UserInputService:GetMouseLocation().Y
								)
								contextMenu.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
								contextMenu.BorderSizePixel = 1
								contextMenu.BorderColor3 = Color3.fromRGB(80, 80, 80)
								contextMenu.Parent = MainScreenGui
								local setScopeBtn = Instance.new("TextButton", contextMenu)
								setScopeBtn.Size = UDim2.new(1, 0, 1, 0)
								setScopeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
								setScopeBtn.TextColor3 = Color3.fromRGB(200, 220, 255)
								setScopeBtn.Font = Enum.Font.Code
								setScopeBtn.Text = "Set as Target Scope"
								table.insert(
									janitor,
									setScopeBtn.MouseButton1Click:Connect(function()
										getgenv().TargetScope = child
										statusLabel.Text = "Scope set to: " .. child.Name
										indexerUpdateSignal:Fire()
										closeContextMenu()
									end)
								)
							end
						end)
					)
				end
			end
			createTree(game, treeScrollView, 0)
			explorerWindow = explorerFrame
			return explorerFrame
		end
		MainWindow = Instance.new("Frame")
		MainWindow.Name = "MainWindow"
		MainWindow.Size = UDim2.new(0, 520, 0, 420)
		MainWindow.Position = UDim2.new(0.5, -260, 0.5, -210)
		MainWindow.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
		MainWindow.BackgroundTransparency = 0.3
		MainWindow.BorderSizePixel = 0
		MainWindow.Active = true
		MainWindow.ClipsDescendants = true
		MainWindow.Parent = MainScreenGui
		makeUICorner(MainWindow, 8)
		local isDragging = false
		local dragStart, startPosition
		table.insert(
			janitor,
			MainWindow.InputBegan:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					isDragging = true
					dragStart = input.Position
					startPosition = MainWindow.Position
					local changedConn
					changedConn = input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then
							isDragging = false
							if changedConn then
								changedConn:Disconnect()
							end
						end
					end)
				end
			end)
		)
		table.insert(
			janitor,
			UserInputService.InputChanged:Connect(function(input)
				if
					(
						input.UserInputType == Enum.UserInputType.MouseMovement
						or input.UserInputType == Enum.UserInputType.Touch
					) and isDragging
				then
					local delta = input.Position - dragStart
					MainWindow.Position = UDim2.new(
						startPosition.X.Scale,
						startPosition.X.Offset + delta.X,
						startPosition.Y.Scale,
						startPosition.Y.Offset + delta.Y
					)
				end
			end)
		)
		local TopBar = Instance.new("Frame")
		TopBar.Name = "TopBar"
		TopBar.Size = UDim2.new(1, 0, 0, 30)
		TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
		TopBar.BorderSizePixel = 0
		TopBar.Parent = MainWindow
		makeUICorner(TopBar, 8)
		local TitleLabel = Instance.new("TextLabel")
		TitleLabel.Name = "TitleLabel"
		TitleLabel.Size = UDim2.new(1, -90, 1, 0)
		TitleLabel.Position = UDim2.new(0, 10, 0, 0)
		TitleLabel.BackgroundTransparency = 1
		TitleLabel.Font = Enum.Font.Code
		TitleLabel.Text = "GC"
		TitleLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
		TitleLabel.TextSize = 16
		TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
		TitleLabel.Parent = TopBar
		local CloseButton = Instance.new("TextButton")
		CloseButton.Name = "CloseButton"
		CloseButton.Size = UDim2.new(0, 24, 0, 24)
		CloseButton.Position = UDim2.new(1, -28, 0.5, -12)
		CloseButton.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
		CloseButton.Font = Enum.Font.Code
		CloseButton.Text = "X"
		CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		CloseButton.TextSize = 14
		CloseButton.Parent = TopBar
		makeUICorner(CloseButton, 6)
		table.insert(
			janitor,
			CloseButton.MouseButton1Click:Connect(function()
				MainScreenGui:Destroy()
			end)
		)
		local MinimizeButton = Instance.new("TextButton")
		MinimizeButton.Name = "MinimizeButton"
		MinimizeButton.Size = UDim2.new(0, 24, 0, 24)
		MinimizeButton.Position = UDim2.new(1, -56, 0.5, -12)
		MinimizeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
		MinimizeButton.Font = Enum.Font.Code
		MinimizeButton.Text = "-"
		MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		MinimizeButton.TextSize = 14
		MinimizeButton.Parent = TopBar
		makeUICorner(MinimizeButton, 6)
		local ExplorerButton = Instance.new("TextButton")
		ExplorerButton.Name = "ExplorerButton"
		ExplorerButton.Size = UDim2.new(0, 24, 0, 24)
		ExplorerButton.Position = UDim2.new(1, -84, 0.5, -12)
		ExplorerButton.BackgroundColor3 = Color3.fromRGB(80, 120, 180)
		ExplorerButton.Font = Enum.Font.Code
		ExplorerButton.Text = "E"
		ExplorerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		ExplorerButton.TextSize = 14
		ExplorerButton.Parent = TopBar
		makeUICorner(ExplorerButton, 6)
		local ContentContainer = Instance.new("Frame")
		ContentContainer.Name = "ContentContainer"
		ContentContainer.Size = UDim2.new(1, 0, 1, -30)
		ContentContainer.Position = UDim2.new(0, 0, 0, 30)
		ContentContainer.BackgroundTransparency = 1
		ContentContainer.Parent = MainWindow
		local isMinimized = false
		table.insert(
			janitor,
			MinimizeButton.MouseButton1Click:Connect(function()
				isMinimized = not isMinimized
				ContentContainer.Visible = not isMinimized
				if isMinimized then
					local tween =
						TweenService:Create(MainWindow, TweenInfo.new(0.2), { Size = UDim2.new(0, 200, 0, 30) })
					tween:Play()
					MinimizeButton.Text = "+"
				else
					local tween =
						TweenService:Create(MainWindow, TweenInfo.new(0.2), { Size = UDim2.new(0, 520, 0, 420) })
					tween:Play()
					MinimizeButton.Text = "-"
				end
			end)
		)
		do
			local statusLabel, selectLabel
			local AimbotPage = Instance.new("Frame", ContentContainer)
			AimbotPage.Name = "AimbotPage"
			AimbotPage.Size = UDim2.new(1, 0, 1, -50)
			AimbotPage.BackgroundTransparency = 1
			local PagePadding = Instance.new("UIPadding", AimbotPage)
			PagePadding.PaddingTop = UDim.new(0, 10)
			PagePadding.PaddingLeft = UDim.new(0, 10)
			PagePadding.PaddingRight = UDim.new(0, 10)
			local LeftColumn = Instance.new("Frame", AimbotPage)
			LeftColumn.Name = "LeftColumn"
			LeftColumn.Size = UDim2.new(0.5, -5, 1, 0)
			LeftColumn.BackgroundTransparency = 1
			local LeftLayout = Instance.new("UIListLayout", LeftColumn)
			LeftLayout.Padding = UDim.new(0, 8)
			LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
			local RightColumn = Instance.new("Frame", AimbotPage)
			RightColumn.Name = "RightColumn"
			RightColumn.Size = UDim2.new(0.5, -5, 1, 0)
			RightColumn.Position = UDim2.new(0.5, 5, 0, 0)
			RightColumn.BackgroundTransparency = 1
			local RightLayout = Instance.new("UIListLayout", RightColumn)
			RightLayout.Padding = UDim.new(0, 8)
			RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
			local StatusBar = Instance.new("Frame", ContentContainer)
			StatusBar.Name = "StatusBar"
			StatusBar.Size = UDim2.new(1, -20, 0, 40)
			StatusBar.Position = UDim2.new(0, 10, 1, -45)
			StatusBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
			makeUICorner(StatusBar, 6)
			local StatusLayout = Instance.new("UIListLayout", StatusBar)
			StatusLayout.Padding = UDim.new(0, 2)
			local StatusPadding = Instance.new("UIPadding", StatusBar)
			StatusPadding.PaddingLeft = UDim.new(0, 8)
			StatusPadding.PaddingRight = UDim.new(0, 8)
			local function createSectionHeader(parent, text)
				local header = Instance.new("TextLabel", parent)
				header.Size = UDim2.new(1, 0, 0, 24)
				header.BackgroundTransparency = 1
				header.Font = Enum.Font.Code
				header.Text = text
				header.TextColor3 = Color3.fromRGB(200, 220, 255)
				header.TextSize = 16
				header.TextXAlignment = Enum.TextXAlignment.Left
				return header
			end
			local function createSettingRow(parent, labelText)
				local row = Instance.new("Frame", parent)
				row.Size = UDim2.new(1, 0, 0, 24)
				row.BackgroundTransparency = 1
				local label = Instance.new("TextLabel", row)
				label.Size = UDim2.new(0.4, 0, 1, 0)
				label.BackgroundTransparency = 1
				label.Font = Enum.Font.Code
				label.Text = labelText .. ":"
				label.TextColor3 = Color3.fromRGB(180, 220, 255)
				label.TextSize = 15
				label.TextXAlignment = Enum.TextXAlignment.Left
				return row
			end
			createSectionHeader(LeftColumn, "General Settings")
			local toggleKeyRow = createSettingRow(LeftColumn, "Toggle Key")
			local toggleKeyBox = Instance.new("TextBox", toggleKeyRow)
			toggleKeyBox.Size = UDim2.new(0.6, 0, 1, 0)
			toggleKeyBox.Position = UDim2.new(0.4, 0, 0, 0)
			toggleKeyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			toggleKeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
			toggleKeyBox.Font = Enum.Font.Code
			toggleKeyBox.TextSize = 15
			toggleKeyBox.Text = "MouseButton2"
			makeUICorner(toggleKeyBox, 6)
			local aimPartRow = createSettingRow(LeftColumn, "Aim Part")
			local partDropdown = Instance.new("TextButton", aimPartRow)
			partDropdown.Size = UDim2.new(0.6, 0, 1, 0)
			partDropdown.Position = UDim2.new(0.4, 0, 0, 0)
			partDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			partDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
			partDropdown.Font = Enum.Font.Code
			partDropdown.TextSize = 15
			partDropdown.Text = "Head"
			makeUICorner(partDropdown, 6)
			createSectionHeader(LeftColumn, "Field of View")
			local fovRow = createSettingRow(LeftColumn, "FOV Radius")
			local fovValueLabel = Instance.new("TextLabel", fovRow)
			fovValueLabel.Size = UDim2.new(0.6, 0, 1, 0)
			fovValueLabel.Position = UDim2.new(0.4, 0, 0, 0)
			fovValueLabel.BackgroundTransparency = 1
			fovValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			fovValueLabel.Font = Enum.Font.Code
			fovValueLabel.TextSize = 15
			fovValueLabel.TextXAlignment = Enum.TextXAlignment.Left
			fovValueLabel.TextYAlignment = Enum.TextYAlignment.Center
			local sliderTrack = Instance.new("Frame", LeftColumn)
			sliderTrack.Size = UDim2.new(1, 0, 0, 4)
			sliderTrack.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
			sliderTrack.BorderSizePixel = 0
			makeUICorner(sliderTrack, 2)
			local sliderHandle = Instance.new("TextButton", sliderTrack)
			sliderHandle.Size = UDim2.new(0, 12, 0, 12)
			sliderHandle.Position = UDim2.new(0, 0, 0.5, -6)
			sliderHandle.BackgroundColor3 = Color3.fromRGB(180, 220, 255)
			sliderHandle.BorderSizePixel = 0
			sliderHandle.Text = ""
			makeUICorner(sliderHandle, 6)
			createSectionHeader(LeftColumn, "Smoothing")
			local smoothingToggle = Instance.new("TextButton", LeftColumn)
			smoothingToggle.Size = UDim2.new(1, 0, 0, 28)
			smoothingToggle.Text = "Smoothing: OFF"
			smoothingToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			smoothingToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
			smoothingToggle.Font = Enum.Font.Code
			smoothingToggle.TextSize = 15
			makeUICorner(smoothingToggle, 6)
			local smoothingRow = createSettingRow(LeftColumn, "Smoothness")
			local smoothingValueLabel = Instance.new("TextLabel", smoothingRow)
			smoothingValueLabel.Size = UDim2.new(0.6, 0, 1, 0)
			smoothingValueLabel.Position = UDim2.new(0.4, 0, 0, 0)
			smoothingValueLabel.BackgroundTransparency = 1
			smoothingValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			smoothingValueLabel.Font = Enum.Font.Code
			smoothingValueLabel.TextSize = 15
			smoothingValueLabel.TextXAlignment = Enum.TextXAlignment.Left
			smoothingValueLabel.TextYAlignment = Enum.TextYAlignment.Center
			local smoothingSliderTrack = Instance.new("Frame", LeftColumn)
			smoothingSliderTrack.Size = UDim2.new(1, 0, 0, 4)
			smoothingSliderTrack.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
			smoothingSliderTrack.BorderSizePixel = 0
			makeUICorner(smoothingSliderTrack, 2)
			local smoothingSliderHandle = Instance.new("TextButton", smoothingSliderTrack)
			smoothingSliderHandle.Size = UDim2.new(0, 12, 0, 12)
			smoothingSliderHandle.Position = UDim2.new(0, 0, 0.5, -6)
			smoothingSliderHandle.BackgroundColor3 = Color3.fromRGB(180, 220, 255)
			smoothingSliderHandle.BorderSizePixel = 0
			smoothingSliderHandle.Text = ""
			makeUICorner(smoothingSliderHandle, 6)
			createSectionHeader(RightColumn, "Prediction")
			local projSpeedRow = createSettingRow(RightColumn, "Proj Speed")
			local projSpeedBox = Instance.new("TextBox", projSpeedRow)
			projSpeedBox.Size = UDim2.new(0.6, 0, 1, 0)
			projSpeedBox.Position = UDim2.new(0.4, 0, 0, 0)
			projSpeedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			projSpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
			projSpeedBox.Font = Enum.Font.Code
			projSpeedBox.TextSize = 15
			projSpeedBox.Text = "600"
			makeUICorner(projSpeedBox, 6)
			local gravityToggle = Instance.new("TextButton", RightColumn)
			gravityToggle.Size = UDim2.new(1, 0, 0, 28)
			gravityToggle.Text = "Gravity Drop: ON"
			gravityToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			gravityToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
			gravityToggle.Font = Enum.Font.Code
			gravityToggle.TextSize = 15
			makeUICorner(gravityToggle, 6)
			createSectionHeader(RightColumn, "Targeting")
			local playerRow = createSettingRow(RightColumn, "Target Player")
			local playerDropdown = Instance.new("TextButton", playerRow)
			playerDropdown.Size = UDim2.new(0.6, 0, 1, 0)
			playerDropdown.Position = UDim2.new(0.4, 0, 0, 0)
			playerDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			playerDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
			playerDropdown.Font = Enum.Font.Code
			playerDropdown.TextSize = 15
			playerDropdown.Text = "None"
			makeUICorner(playerDropdown, 6)
			local targetPlayerToggle = Instance.new("TextButton", RightColumn)
			targetPlayerToggle.Size = UDim2.new(1, 0, 0, 28)
			targetPlayerToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			targetPlayerToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
			targetPlayerToggle.Font = Enum.Font.Code
			targetPlayerToggle.TextSize = 15
			targetPlayerToggle.Text = "Target Selected: OFF"
			makeUICorner(targetPlayerToggle, 6)
			createSectionHeader(RightColumn, "Modifiers")
			local ignoreTeamToggle = Instance.new("TextButton", RightColumn)
			ignoreTeamToggle.Size = UDim2.new(1, 0, 0, 28)
			ignoreTeamToggle.Text = "Ignore Team: OFF"
			ignoreTeamToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			ignoreTeamToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
			ignoreTeamToggle.Font = Enum.Font.Code
			ignoreTeamToggle.TextSize = 15
			makeUICorner(ignoreTeamToggle, 6)
			local wallCheckToggle = Instance.new("TextButton", RightColumn)
			wallCheckToggle.Size = UDim2.new(1, 0, 0, 28)
			wallCheckToggle.Text = "Wall Check: ON"
			wallCheckToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			wallCheckToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
			wallCheckToggle.Font = Enum.Font.Code
			wallCheckToggle.TextSize = 15
			makeUICorner(wallCheckToggle, 6)
			statusLabel = Instance.new("TextLabel", StatusBar)
			statusLabel.Size = UDim2.new(1, 0, 0, 18)
			statusLabel.BackgroundTransparency = 1
			statusLabel.TextColor3 = Color3.fromRGB(180, 220, 180)
			statusLabel.Font = Enum.Font.Code
			statusLabel.TextSize = 14
			statusLabel.Text = "Aimbot ready. Hold toggle key to aim."
			statusLabel.TextXAlignment = Enum.TextXAlignment.Left
			selectLabel = Instance.new("TextLabel", StatusBar)
			selectLabel.Size = UDim2.new(1, 0, 0, 18)
			selectLabel.BackgroundTransparency = 1
			selectLabel.TextColor3 = Color3.fromRGB(220, 220, 180)
			selectLabel.Font = Enum.Font.Code
			selectLabel.TextSize = 14
			selectLabel.Text = "Press V to delete any block / model under mouse."
			selectLabel.TextXAlignment = Enum.TextXAlignment.Left
			local parts = { "Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso" }
			local partDropdownOpen, partDropdownFrame = false, nil
			local playerDropdownOpen, playerDropdownFrame = false, nil
			table.insert(
				janitor,
				UserInputService.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if
							partDropdownOpen
							and not (
								input.SourceUserInputProcessor
								and (
									input.SourceUserInputProcessor:IsDescendantOf(partDropdownFrame)
									or input.SourceUserInputProcessor == partDropdown
								)
							)
						then
							if partDropdownFrame then
								partDropdownFrame:Destroy()
							end
							partDropdownOpen = false
						end
						if
							playerDropdownOpen
							and not (
								input.SourceUserInputProcessor
								and (
									input.SourceUserInputProcessor:IsDescendantOf(playerDropdownFrame)
									or input.SourceUserInputProcessor == playerDropdown
								)
							)
						then
							if playerDropdownFrame then
								playerDropdownFrame:Destroy()
							end
							playerDropdownOpen = false
						end
					end
				end)
			)
			table.insert(
				janitor,
				partDropdown.MouseButton1Click:Connect(function()
					if partDropdownOpen then
						if partDropdownFrame then
							partDropdownFrame:Destroy()
						end
						partDropdownOpen = false
						return
					end
					partDropdownOpen = true
					partDropdownFrame = Instance.new("Frame", AimbotPage)
					local absolutePos = partDropdown.AbsolutePosition
					local guiPos = MainWindow.AbsolutePosition
					partDropdownFrame.Size = UDim2.new(0, partDropdown.AbsoluteSize.X, 0, #parts * 22)
					partDropdownFrame.Position =
						UDim2.new(0, absolutePos.X - guiPos.X, 0, absolutePos.Y - guiPos.Y + 22)
					partDropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
					partDropdownFrame.BackgroundTransparency = 0.3
					partDropdownFrame.BorderSizePixel = 0
					partDropdownFrame.ZIndex = 5
					makeUICorner(partDropdownFrame, 6)
					local stroke = Instance.new("UIStroke", partDropdownFrame)
					stroke.Color = Color3.fromRGB(80, 80, 90)
					stroke.Thickness = 1
					for i, part in ipairs(parts) do
						local btn = Instance.new("TextButton", partDropdownFrame)
						btn.Size = UDim2.new(1, 0, 0, 22)
						btn.Position = UDim2.new(0, 0, 0, (i - 1) * 22)
						btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
						btn.TextColor3 = Color3.fromRGB(255, 255, 255)
						btn.Font = Enum.Font.Code
						btn.TextSize = 15
						btn.Text = part
						makeUICorner(btn, 6)
						table.insert(
							janitor,
							btn.MouseButton1Click:Connect(function()
								partDropdown.Text = part
								if partDropdownFrame then
									partDropdownFrame:Destroy()
								end
								partDropdownOpen = false
							end)
						)
					end
				end)
			)
			local fovRadius = 75
			local smoothingEnabled = false
			local smoothingFactor = 0.2
			local PROJECTILE_SPEED = 4500
			local gravityEnabled = false
			local selectedPlayerTarget, selectedPart = nil, nil
			local playerTargetEnabled = false
			local aiming = false
			local ignoreTeamEnabled = false
			local wallCheckEnabled = true
			local wallCheckParams = RaycastParams.new()
			wallCheckParams.FilterType = Enum.RaycastFilterType.Exclude
			local activeESPs = {}
			table.insert(
				janitor,
				gravityToggle.MouseButton1Click:Connect(function()
					gravityEnabled = not gravityEnabled
					gravityToggle.Text = "Gravity Drop: " .. (gravityEnabled and "ON" or "OFF")
				end)
			)
			table.insert(
				janitor,
				projSpeedBox.FocusLost:Connect(function()
					local val = tonumber(projSpeedBox.Text)
					if val and val > 0 then
						PROJECTILE_SPEED = val
					else
						projSpeedBox.Text = tostring(PROJECTILE_SPEED)
					end
				end)
			)
			local FovCircle = nil
			if Drawing and typeof(Drawing.new) == "function" then
				FovCircle = Drawing.new("Circle")
				FovCircle.Visible = false
				FovCircle.Thickness = 0.5
				FovCircle.NumSides = 64
				FovCircle.Color = Color3.fromRGB(255, 255, 255)
				FovCircle.Transparency = 0.7
				FovCircle.Filled = false
			else
				warn("Zuka's Log: 'Drawing' library not found. FOV circle visualization will be disabled.")
			end
			local minFov, maxFov = 50, 500
			local function updateFovFromHandlePosition()
				local trackWidth = sliderTrack.AbsoluteSize.X
				local handleX = sliderHandle.Position.X.Offset
				local ratio = math.clamp(handleX / (trackWidth - sliderHandle.AbsoluteSize.X), 0, 1)
				fovRadius = minFov + (maxFov - minFov) * ratio
				fovValueLabel.Text = tostring(math.floor(fovRadius)) .. "px"
				if FovCircle then
					FovCircle.Radius = fovRadius
				end
			end
			local function updateHandleFromFovValue()
				local trackWidth = sliderTrack.AbsoluteSize.X
				if trackWidth == 0 then
					return
				end
				local ratio = (fovRadius - minFov) / (maxFov - minFov)
				local handleX = ratio * (trackWidth - sliderHandle.AbsoluteSize.X)
				sliderHandle.Position = UDim2.new(0, handleX, 0.5, -6)
			end
			local isDraggingSlider = false
			table.insert(
				janitor,
				sliderHandle.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						isDraggingSlider = true
					end
				end)
			)
			table.insert(
				janitor,
				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						isDraggingSlider = false
					end
				end)
			)
			table.insert(
				janitor,
				UserInputService.InputChanged:Connect(function(input)
					if isDraggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
						local mouseX = UserInputService:GetMouseLocation().X
						local trackStartX = sliderTrack.AbsolutePosition.X
						local handleWidth = sliderHandle.AbsoluteSize.X
						local trackWidth = sliderTrack.AbsoluteSize.X
						local newHandleX = mouseX - trackStartX - (handleWidth / 2)
						local clampedX = math.clamp(newHandleX, 0, trackWidth - handleWidth)
						sliderHandle.Position = UDim2.new(0, clampedX, 0.5, -6)
						updateFovFromHandlePosition()
					end
				end)
			)
			table.insert(
				janitor,
				smoothingToggle.MouseButton1Click:Connect(function()
					smoothingEnabled = not smoothingEnabled
					smoothingToggle.Text = "Smoothing: " .. (smoothingEnabled and "ON" or "OFF")
				end)
			)
			local minSmooth, maxSmooth = 0.05, 1.0
			local function updateSmoothFromHandlePosition()
				local trackWidth = smoothingSliderTrack.AbsoluteSize.X
				local handleX = smoothingSliderHandle.Position.X.Offset
				local ratio = math.clamp(handleX / (trackWidth - smoothingSliderHandle.AbsoluteSize.X), 0, 1)
				smoothingFactor = minSmooth + (maxSmooth - minSmooth) * ratio
				smoothingValueLabel.Text = string.format("%.2f", smoothingFactor)
			end
			local function updateHandleFromSmoothValue()
				local trackWidth = smoothingSliderTrack.AbsoluteSize.X
				if trackWidth == 0 then
					return
				end
				local ratio = (smoothingFactor - minSmooth) / (maxSmooth - minSmooth)
				local handleX = ratio * (trackWidth - smoothingSliderHandle.AbsoluteSize.X)
				smoothingSliderHandle.Position = UDim2.new(0, handleX, 0.5, -6)
			end
			local isDraggingSmoothSlider = false
			table.insert(
				janitor,
				smoothingSliderHandle.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						isDraggingSmoothSlider = true
					end
				end)
			)
			table.insert(
				janitor,
				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						isDraggingSmoothSlider = false
					end
				end)
			)
			table.insert(
				janitor,
				UserInputService.InputChanged:Connect(function(input)
					if isDraggingSmoothSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
						local mouseX = UserInputService:GetMouseLocation().X
						local trackStartX = smoothingSliderTrack.AbsolutePosition.X
						local handleWidth = smoothingSliderHandle.AbsoluteSize.X
						local trackWidth = smoothingSliderTrack.AbsoluteSize.X
						local newHandleX = mouseX - trackStartX - (handleWidth / 2)
						local clampedX = math.clamp(newHandleX, 0, trackWidth - handleWidth)
						smoothingSliderHandle.Position = UDim2.new(0, clampedX, 0.5, -6)
						updateSmoothFromHandlePosition()
					end
				end)
			)
			task.wait()
			updateHandleFromFovValue()
			updateFovFromHandlePosition()
			updateHandleFromSmoothValue()
			updateSmoothFromHandlePosition()
			local function isTeammate(player)
				if not ignoreTeamEnabled or not player then
					return false
				end
				if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
					return true
				end
				if LocalPlayer.TeamColor and player.TeamColor and LocalPlayer.TeamColor == player.TeamColor then
					return true
				end
				return false
			end
			local function isPartVisible(targetPart)
				if not LocalPlayer.Character or not targetPart or not targetPart.Parent then
					return false
				end
				local targetCharacter = targetPart:FindFirstAncestorOfClass("Model") or targetPart.Parent
				local origin = Camera.CFrame.Position
				wallCheckParams.FilterDescendantsInstances = { LocalPlayer.Character, targetCharacter }
				local result = Workspace:Raycast(origin, targetPart.Position - origin, wallCheckParams)
				return not result
			end
			local function manageESP(part, color, name)
				if not part or not part.Parent then
					return
				end
				if activeESPs[part] then
					activeESPs[part].Color3 = color
					activeESPs[part].Name = name
					activeESPs[part].Adornee = part
					activeESPs[part].Size = part.Size
				else
					local espBox = Instance.new("BoxHandleAdornment")
					espBox.Name = name
					espBox.Adornee = part
					espBox.AlwaysOnTop = true
					espBox.ZIndex = 10
					espBox.Size = part.Size
					espBox.Color3 = color
					espBox.Transparency = 0.4
					espBox.Parent = part
					activeESPs[part] = espBox
				end
			end
			local function clearESP(part)
				if part then
					if activeESPs[part] then
						activeESPs[part]:Destroy()
						activeESPs[part] = nil
					end
				else
					for _, espBox in pairs(activeESPs) do
						pcall(function()
							espBox:Destroy()
						end)
					end
					activeESPs = {}
				end
			end
			local function getClosestTargetInScope()
				local mousePos = UserInputService:GetMouseLocation()
				local minScore, closestTargetModel = math.huge, nil
				local aimPartName = partDropdown.Text
				for _, model in ipairs(getgenv().TargetIndex) do
					if model and model.Parent then
						local player = Players:GetPlayerFromCharacter(model)
						if not (player and player == LocalPlayer) and not (player and isTeammate(player)) then
							local targetPart = model:FindFirstChild(aimPartName)
							if targetPart and (not wallCheckEnabled or isPartVisible(targetPart)) then
								local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
								if onScreen then
									local screenDist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
									if screenDist <= fovRadius then
										local humanoid = model:FindFirstChildOfClass("Humanoid")
										local healthPenalty = humanoid
												and (humanoid.Health / math.max(humanoid.MaxHealth, 1)) * 10
											or 0
										local score = screenDist + healthPenalty
										if score < minScore then
											minScore = score
											closestTargetModel = model
										end
									end
								end
							end
						end
					end
				end
				return closestTargetModel
			end
			local function buildPlayerDropdownFrame()
				if playerDropdownFrame then
					playerDropdownFrame:Destroy()
				end
				local playersList = Players:GetPlayers()
				playerDropdownFrame = Instance.new("Frame", AimbotPage)
				local absolutePos = playerDropdown.AbsolutePosition
				local guiPos = MainWindow.AbsolutePosition
				playerDropdownFrame.Size = UDim2.new(0, playerDropdown.AbsoluteSize.X, 0, #playersList * 22)
				playerDropdownFrame.Position = UDim2.new(0, absolutePos.X - guiPos.X, 0, absolutePos.Y - guiPos.Y + 22)
				playerDropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
				playerDropdownFrame.BackgroundTransparency = 0.2
				playerDropdownFrame.BorderSizePixel = 0
				playerDropdownFrame.ZIndex = 5
				makeUICorner(playerDropdownFrame, 6)
				local stroke = Instance.new("UIStroke", playerDropdownFrame)
				stroke.Color = Color3.fromRGB(80, 80, 90)
				stroke.Thickness = 1
				for i, plr in ipairs(playersList) do
					local btn = Instance.new("TextButton", playerDropdownFrame)
					btn.Size = UDim2.new(1, 0, 0, 22)
					btn.Position = UDim2.new(0, 0, 0, (i - 1) * 22)
					btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					btn.TextColor3 = Color3.fromRGB(255, 255, 255)
					btn.Font = Enum.Font.Code
					btn.TextSize = 15
					btn.Text = plr.Name
					makeUICorner(btn, 6)
					table.insert(
						janitor,
						btn.MouseButton1Click:Connect(function()
							selectedPlayerTarget = plr
							playerDropdown.Text = plr.Name
							if playerDropdownFrame then
								playerDropdownFrame:Destroy()
							end
							playerDropdownOpen = false
							if playerTargetEnabled then
								statusLabel.Text = "Aimbot: Will target " .. plr.Name
							end
						end)
					)
				end
			end
			table.insert(
				janitor,
				targetPlayerToggle.MouseButton1Click:Connect(function()
					playerTargetEnabled = not playerTargetEnabled
					targetPlayerToggle.Text = "Target Selected: " .. (playerTargetEnabled and "ON" or "OFF")
					if not playerTargetEnabled then
						statusLabel.Text = "Aimbot ready. Hold toggle key to aim."
					elseif selectedPlayerTarget then
						statusLabel.Text = "Aimbot: Will target " .. selectedPlayerTarget.Name
					end
				end)
			)
			table.insert(
				janitor,
				playerDropdown.MouseButton1Click:Connect(function()
					if playerDropdownOpen then
						if playerDropdownFrame then
							playerDropdownFrame:Destroy()
						end
						playerDropdownOpen = false
						return
					end
					playerDropdownOpen = true
					buildPlayerDropdownFrame()
				end)
			)
			table.insert(
				janitor,
				Players.PlayerAdded:Connect(function()
					if playerDropdownOpen then
						buildPlayerDropdownFrame()
					end
				end)
			)
			table.insert(
				janitor,
				Players.PlayerRemoving:Connect(function(plr)
					if selectedPlayerTarget == plr then
						selectedPlayerTarget = nil
						playerDropdown.Text = "None"
						if playerTargetEnabled then
							playerTargetEnabled = false
							targetPlayerToggle.Text = "Target Selected: OFF"
						end
					end
					if playerDropdownOpen then
						buildPlayerDropdownFrame()
					end
				end)
			)
			table.insert(
				janitor,
				UserInputService.InputBegan:Connect(function(input, processed)
					if processed or toggleKeyBox:IsFocused() then
						return
					end
					if input.KeyCode == Enum.KeyCode.V then
						local target = LocalPlayer:GetMouse().Target
						if target and target.Parent then
							local modelAncestor = target:FindFirstAncestorOfClass("Model")
							if
								(modelAncestor and modelAncestor == LocalPlayer.Character)
								or target:IsDescendantOf(LocalPlayer.Character)
							then
								statusLabel.Text = "Cannot delete your own character."
								return
							end
							if modelAncestor and modelAncestor ~= Workspace then
								local modelName = modelAncestor.Name
								modelAncestor:Destroy()
								statusLabel.Text = "Deleted model: " .. modelName
							else
								if target.Parent ~= Workspace then
									local targetName = target.Name
									target:Destroy()
									statusLabel.Text = "Deleted part: " .. targetName
								else
									statusLabel.Text = "Cannot delete baseplate or map."
								end
							end
						else
							statusLabel.Text = "No target under mouse to delete."
						end
					end
					local key = toggleKeyBox.Text:upper()
					if
						(key == "MOUSEBUTTON2" and input.UserInputType == Enum.UserInputType.MouseButton2)
						or (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name:upper() == key)
					then
						aiming = true
						if FovCircle then
							FovCircle.Visible = true
						end
					end
				end)
			)
			table.insert(
				janitor,
				UserInputService.InputEnded:Connect(function(input)
					local key = toggleKeyBox.Text:upper()
					if
						(key == "MOUSEBUTTON2" and input.UserInputType == Enum.UserInputType.MouseButton2)
						or (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name:upper() == key)
					then
						aiming = false
						if FovCircle then
							FovCircle.Visible = false
						end
						clearESP()
					end
				end)
			)
			local currentTarget = nil
			table.insert(
				janitor,
				RunService.RenderStepped:Connect(function(deltaTime)
					if FovCircle and FovCircle.Visible then
						FovCircle.Position = UserInputService:GetMouseLocation()
					end
					local isCurrentTargetValid = currentTarget
						and currentTarget.Parent
						and currentTarget:FindFirstChildOfClass("Humanoid")
						and currentTarget:FindFirstChildOfClass("Humanoid").Health > 0
					if aiming then
						local freshTarget = getClosestTargetInScope()
						if freshTarget then
							currentTarget = freshTarget
						elseif not isCurrentTargetValid then
							currentTarget = nil
						end
					else
						currentTarget = nil
					end
					local aimPart, targetPlayer, targetModel = nil, nil, nil
					local partsToDrawESPFor = {}
					if
						playerTargetEnabled
						and selectedPlayerTarget
						and selectedPlayerTarget.Character
						and selectedPlayerTarget ~= LocalPlayer
					then
						if not isTeammate(selectedPlayerTarget) then
							targetModel = selectedPlayerTarget.Character
							targetPlayer = selectedPlayerTarget
						else
							targetModel = nil
						end
					elseif aiming and currentTarget then
						targetModel = currentTarget
						targetPlayer = Players:GetPlayerFromCharacter(targetModel)
					end
					if targetModel then
						aimPart = targetModel:FindFirstChild(partDropdown.Text)
					end
					if aiming and aimPart and targetModel then
						if not wallCheckEnabled or isPartVisible(aimPart) then
							table.insert(
								partsToDrawESPFor,
								{ Part = aimPart, Color = Color3.fromRGB(255, 80, 80), Name = "AimbotESP" }
							)
							local velocity = aimPart.AssemblyLinearVelocity
							local distance = (Camera.CFrame.Position - aimPart.Position).Magnitude
							local travelTime = distance / math.max(PROJECTILE_SPEED, 1)
							local predictedPosition = aimPart.Position + (velocity * travelTime)
							if gravityEnabled then
								local gravity = Workspace.Gravity
								predictedPosition = predictedPosition
									+ Vector3.new(0, 0.5 * gravity * travelTime * travelTime, 0)
							end
							if smoothingEnabled then
								local SLERP_SPEED = 20
								local currentDir = Camera.CFrame.LookVector
								local goalDir = (predictedPosition - Camera.CFrame.Position).Unit
								local angle = math.acos(math.clamp(currentDir:Dot(goalDir), -1, 1))
								if angle > 0.0001 then
									local maxStep = SLERP_SPEED * deltaTime * smoothingFactor
									local t = math.min(1, maxStep / angle)
									local newDir = currentDir:Lerp(goalDir, t).Unit
									Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + newDir)
								end
							else
								Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, predictedPosition)
							end
							statusLabel.Text = "Aimbot: Targeting "
								.. (targetPlayer and targetPlayer.Name or targetModel.Name)
						else
							statusLabel.Text = "Aimbot: Target is behind a wall"
							currentTarget = nil
						end
					elseif aiming then
						statusLabel.Text = "Aimbot: No visible target in index"
					elseif not aiming then
						statusLabel.Text = "Aimbot ready. Hold toggle key to aim."
					end
					for part, espBox in pairs(activeESPs) do
						local found = false
						for _, data in ipairs(partsToDrawESPFor) do
							if data.Part == part then
								found = true
								break
							end
						end
						if not found or not part.Parent then
							clearESP(part)
						end
					end
					for _, data in ipairs(partsToDrawESPFor) do
						manageESP(data.Part, data.Color, data.Name)
					end
				end)
			)
			table.insert(
				janitor,
				ignoreTeamToggle.MouseButton1Click:Connect(function()
					ignoreTeamEnabled = not ignoreTeamEnabled
					ignoreTeamToggle.Text = "Ignore Team: " .. (ignoreTeamEnabled and "ON" or "OFF")
				end)
			)
			table.insert(
				janitor,
				wallCheckToggle.MouseButton1Click:Connect(function()
					wallCheckEnabled = not wallCheckEnabled
					wallCheckToggle.Text = "Wall Check: " .. (wallCheckEnabled and "ON" or "OFF")
				end)
			)
			local indexerUpdateSignal = Instance.new("BindableEvent")
			table.insert(
				janitor,
				ExplorerButton.MouseButton1Click:Connect(function()
					createExplorerWindow(statusLabel, indexerUpdateSignal)
				end)
			)
			task.spawn(function()
				local function RebuildTargetIndex()
					local newIndex = {}
					if not getgenv().TargetScope or not getgenv().TargetScope.Parent then
						getgenv().TargetScope = Workspace
					end
					for _, descendant in ipairs(getgenv().TargetScope:GetDescendants()) do
						if descendant:IsA("Model") and descendant:FindFirstChildOfClass("Humanoid") then
							table.insert(newIndex, descendant)
						end
					end
					getgenv().TargetIndex = newIndex
				end
				table.insert(janitor, indexerUpdateSignal.Event:Connect(RebuildTargetIndex))
				while task.wait(2) and MainScreenGui.Parent do
					RebuildTargetIndex()
				end
			end)
			indexerUpdateSignal:Fire()
			if args and args[1] then
				task.wait(0.1)
				local targetName = args[1]
				if targetName:lower() == "clear" or targetName:lower() == "reset" or targetName:lower() == "off" then
					playerTargetEnabled = false
					selectedPlayerTarget = nil
					targetPlayerToggle.Text = "Target Selected: OFF"
					playerDropdown.Text = "None"
					statusLabel.Text = "Aimbot ready. Hold toggle key to aim."
					DoNotif("Aimbot target lock cleared.", 2)
				else
					local foundPlayer = Utilities.findPlayer(targetName)
					if foundPlayer then
						playerTargetEnabled = true
						selectedPlayerTarget = foundPlayer
						targetPlayerToggle.Text = "Target Selected: ON"
						playerDropdown.Text = foundPlayer.Name
						statusLabel.Text = "Aimbot: Will target " .. foundPlayer.Name
						DoNotif("Aimbot locked onto target: " .. foundPlayer.Name, 3)
					else
						DoNotif("Target player '" .. targetName .. "' not found.", 3)
					end
				end
			end
		end
	end)
	if not success then
		warn("Failed to load Aimbot GUI:", err)
		if DoNotif then
			DoNotif("Error loading Aimbot: " .. tostring(err), 5)
		end
		local gui = CoreGui:FindFirstChild("UTS_CGE_Suite")
		if gui then
			gui:Destroy()
		end
	end
end
RegisterCommand({
	Name = "aimbot",
	Aliases = {},
	Description = "Loads the aimbot GUI. Optional: [player name] to lock target.",
}, function(args)
	if not game:GetService("CoreGui"):FindFirstChild("UTS_CGE_Suite") then
		loadAimbotGUI(args)
	else
		if args and args[1] then
			DoNotif("Aimbot is already open. Re-open to set a command-line target.", 4)
		else
			DoNotif("Aimbot GUI is already open.", 2)
		end
	end
end)
