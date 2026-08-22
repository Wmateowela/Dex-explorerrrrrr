-- Roblox Executor ChatBot Script using OpenRouter API
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- API Configuration
local API_URL = "https://openrouter.ai/api/v1/chat/completions"
local API_KEY = "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"
local MODEL_NAME = "inclusionai/ling-3.0-flash:free"

-- Chat History to maintain context
local chatHistory = {
    { role = "system", content = "You are a helpful AI assistant. Respond naturally in English or Roman Urdu based on the user's input." }
}

-- Destroy existing UI if running again
if game:GetService("CoreGui"):FindFirstChild("OpenRouterChatBot") then
    game:GetService("CoreGui").OpenRouterChatBot:Destroy()
end

-- Create GUI Elements
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OpenRouterChatBot"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 380, 0, 450)
MainFrame.Position = UDim2.new(0.5, -190, 0.5, -225)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Allows moving the GUI
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 10)
HeaderCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Text = "AI ChatBot (Ling-3.0-Flash)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.BackgroundTransparency = 1
Title.Parent = Header

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 16
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Chat Logs Area
local ChatLog = Instance.new("ScrollingFrame")
ChatLog.Size = UDim2.new(1, -20, 1, -110)
ChatLog.Position = UDim2.new(0, 10, 0, 50)
ChatLog.BackgroundTransparency = 1
ChatLog.CanvasSize = UDim2.new(0, 0, 0, 0)
ChatLog.ScrollBarThickness = 6
ChatLog.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = ChatLog

-- Input Area
local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(1, -90, 0, 40)
InputBox.Position = UDim2.new(0, 10, 1, -50)
InputBox.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputBox.PlaceholderText = "Type message here..."
InputBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
InputBox.Text = ""
InputBox.TextSize = 14
InputBox.Font = Enum.Font.SourceSans
InputBox.TextXAlignment = Enum.TextXAlignment.Left
InputBox.ClearTextOnFocus = false
InputBox.Parent = MainFrame
Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 8)

local SendBtn = Instance.new("TextButton")
SendBtn.Size = UDim2.new(0, 70, 0, 40)
SendBtn.Position = UDim2.new(1, -80, 1, -50)
SendBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
SendBtn.Text = "Send"
SendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SendBtn.Font = Enum.Font.SourceSansBold
SendBtn.TextSize = 14
SendBtn.Parent = MainFrame
Instance.new("UICorner", SendBtn).CornerRadius = UDim.new(0, 8)

-- Function to append text safely in UI
local function addMessage(sender, message, color)
    local MsgLabel = Instance.new("TextLabel")
    MsgLabel.Size = UDim2.new(1, -10, 0, 0)
    MsgLabel.BackgroundTransparency = 1
    MsgLabel.Text = "<b>" .. sender .. ":</b> " .. message
    MsgLabel.TextColor3 = color
    MsgLabel.TextSize = 14
    MsgLabel.Font = Enum.Font.SourceSans
    MsgLabel.RichText = true
    MsgLabel.TextWrapped = true
    MsgLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Automatic height calculation
    MsgLabel.Size = UDim2.new(1, -10, 0, MsgLabel.TextBounds.Y + 10)
    MsgLabel.Parent = ChatLog
    
    -- Auto scroll to bottom
    ChatLog.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
    ChatLog.CanvasPosition = Vector2.new(0, ChatLog.CanvasSize.Y.Offset)
end

-- Async Function to call OpenRouter API using Executor Request
local function callOpenRouterAPI(prompt)
    table.insert(chatHistory, { role = "user", content = prompt })
    
    local headers = {
        ["Authorization"] = "Bearer " .. API_KEY,
        ["Content-Type"] = "application/json",
        ["HTTP-Referer"] = "https://roblox.com", 
        ["X-Title"] = "Roblox Executor ChatBot"
    }
    
    local body = {
        model = MODEL_NAME,
        messages = chatHistory
    }
    
    -- Using request/syn.request which is standard in executors for bypassing Roblox HttpService Domain restrictions
    local requestFunction = syn and syn.request or http and http.request or request
    
    if not requestFunction then
        return "Error: Your executor does not support external HTTP Requests (Missing request function)."
    end
    
    local success, response = pcall(function()
        return requestFunction({
            Url = API_URL,
            Method = "POST",
            Headers = headers,
            Body = HttpService:JSONEncode(body)
        })
    end)
    
    if success and response.StatusCode == 200 then
        local data = HttpService:JSONDecode(response.Body)
        if data and data.choices and data.choices[1] and data.choices[1].message then
            local aiResponse = data.choices[1].message.content
            table.insert(chatHistory, { role = "assistant", content = aiResponse })
            return aiResponse
        end
    end
    
    return "API Error: Unable to fetch response. Make sure your key is active."
end

-- Handle Send Action
local function onSend()
    local text = InputBox.Text
    if text == "" then return end
    
    InputBox.Text = ""
    addMessage("You", text, Color3.fromRGB(200, 250, 200))
    
    addMessage("AI", "Typing...", Color3.fromRGB(200, 200, 200))
    local loadingLabel = ChatLog:GetChildren()[#ChatLog:GetChildren() - 1] -- Get the last text label
    
    task.spawn(function()
        local aiReply = callOpenRouterAPI(text)
        if loadingLabel and loadingLabel:IsA("TextLabel") then
            loadingLabel.Text = "<b>AI:</b> " .. aiReply
            loadingLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
            -- Recalculate height
            loadingLabel.Size = UDim2.new(1, -10, 0, loadingLabel.TextBounds.Y + 10)
            ChatLog.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
        end
    end)
end

SendBtn.MouseButton1Click:Connect(onSend)
InputBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then onSend() end
end)

addMessage("System", "Chatbot connected via OpenRouter. Type your message below!", Color3.fromRGB(255, 200, 100))
