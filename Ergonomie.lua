task.wait(3)

if _G.NexHubBypassed then warn("ta deja executé trdc")return end
_G.NexHubBypassed=true
local LogService=game:GetService("LogService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Stats=game:GetService("Stats")
local Players=game:GetService("Players")
local CoreGui=game:GetService("CoreGui")
local deletedScripts={}
local heartbeatActive=false
local function setupHeartbeatImmediate()
task.spawn(function()
local success,Ping=pcall(function()
return ReplicatedStorage:WaitForChild("SACHeartbeatPing",3)
end)
local success2,Pong=pcall(function()
return ReplicatedStorage:WaitForChild("SACHeartbeatPong",3)
end)
if success and success2 and Ping and Pong then
Ping.OnClientEvent:Connect(function()
heartbeatActive=true
task.spawn(function()
pcall(function()
Pong:FireServer()
end)
end)
end)
end
end)
end
setupHeartbeatImmediate()
local loadingGui=Instance.new("ScreenGui")
loadingGui.Name="NexHubLoading"
loadingGui.ResetOnSpawn=false
if gethui then
loadingGui.Parent=gethui()
elseif syn and syn.protect_gui then
syn.protect_gui(loadingGui)
loadingGui.Parent=CoreGui
else
loadingGui.Parent=CoreGui
end
local image=Instance.new("ImageLabel")
image.Parent=loadingGui
image.Size=UDim2.new(1.4,0,1.4,0)
image.Position=UDim2.new(-0.2,0,-0.2,0)
image.BackgroundTransparency=1
image.Image="rbxassetid://7988775017"
local text=Instance.new("TextLabel")
text.Parent=loadingGui
text.Size=UDim2.new(1,0,0,200)
text.Position=UDim2.new(0,0,0.5,-100)
text.BackgroundTransparency=1
text.TextColor3=Color3.new(1,1,1)
text.TextSize=80
text.Font=Enum.Font.SourceSansBold
text.TextXAlignment=Enum.TextXAlignment.Center
text.TextStrokeTransparency=0
text.TextStrokeColor3=Color3.new(0,0,0)
text.Text="SAC Bypass En Cours..."
local function checkHooksSupport()
if not(getrawmetatable and setreadonly and newcclosure and getnamecallmethod)then
return false
end
local success=pcall(function()
local mt=getrawmetatable(game)
setreadonly(mt,false)
setreadonly(mt,true)
end)
return success
end
local function setupMetatableHooks()
if not(getrawmetatable and setreadonly and newcclosure)then
return false
end
local success=pcall(function()
local mt=getrawmetatable(game)
local oldNamecall=mt.__namecall
local oldIndex=mt.__index
local oldNewIndex=mt.__newindex
setreadonly(mt,false)
mt.__namecall=newcclosure(function(self,...)
local method=getnamecallmethod()
local args={...}
if self==Stats then
if method=="GetTotalMemoryUsageMb"then
return 500+math.random(0,100)
end
if method=="GetMemoryUsageMbForTag"then
return 5+math.random(0,5)
end
end
if method=="HttpGet"or method=="HttpPost"or method=="HttpGetAsync"or method=="HttpPostAsync"then
local url=tostring(args[1]or"")
if url:find("sentinel")or url:find("sac")or url:find("log")or url:find("report")then
return""
end
end
if method=="FireServer"then
if self.Name=="SACHeartbeatPong"then
return oldNamecall(self,...)
end
local blockedNames={
["ClientLogEvent"]=true,
["HandshakeEvent"]=true,
["Report"]=true,
["Plat"]=true,
["SACReport"]=true,
["AntiCheat"]=true,
["SACLog"]=true,
["SentinelReport"]=true,
["DetectionReport"]=true,
}
if blockedNames[self.Name]or
self.Name:find("Report")or
self.Name:find("Log")or
self.Name:find("Detection")or
(self.Name:find("SAC")and self.Name~="SACHeartbeatPong")then
pcall(function()
local caller=getcallingscript()
if caller and not deletedScripts[caller]then
deletedScripts[caller]=true
task.defer(function()
pcall(function()caller:Destroy()end)
end)
end
end)
return nil
end
end
if method=="InvokeServer"then
local blockedInvokes={
["SACCheck"]=true,
["MemoryCheck"]=true,
["ValidateClient"]=true,
["ClientCheck"]=true,
}
if blockedInvokes[self.Name]or self.Name:find("SAC")or self.Name:find("Check")then
return nil
end
end
return oldNamecall(self,...)
end)
mt.__index=newcclosure(function(self,key)
if self==Stats then
if key=="GetTotalMemoryUsageMb"then
return function()return 500+math.random(0,100)end
end
if key=="GetMemoryUsageMbForTag"then
return function()return 5+math.random(0,5)end
end
end
if typeof(key)=="string"then
if key:find("SAC")or key:find("Sentinel")or key:find("AntiCheat")then
return nil
end
end
return oldIndex(self,key)
end)
mt.__newindex=newcclosure(function(self,key,value)
if typeof(key)=="string"then
if key:find("SAC")or key:find("Detected")or key:find("Flagged")then
return nil
end
end
return oldNewIndex(self,key,value)
end)
setreadonly(mt,true)
end)
return success
end
local function blockLogService()
pcall(function()
local mt=getrawmetatable(game)
setreadonly(mt,false)
local oldNamecall=mt.__namecall
mt.__namecall=newcclosure(function(self,...)
local method=getnamecallmethod()
if self==LogService then
if method=="GetLogHistory"then
return{}
end
end
return oldNamecall(self,...)
end)
setreadonly(mt,true)
end)
end
local function isSACScript(obj)
if not obj:IsA("LocalScript")then return false end
local name=obj.Name:lower()
local suspicious={
"sac","sentinel","contentprov","detec","gui lyks",
"logs","log req","monit","save instance",
"workin","_g","asset","solara",
"fluxus","rayfield","scan","assetid",
"submit","plat","service","memory",
"dev console","xeno","check","validate",
"anti","cheat","report"
}
for _,pattern in ipairs(suspicious)do
if name:find(pattern)then
return true
end
end
if name=="LocalScript"or name=="Client"then
local parent=obj.Parent
if parent and(parent.Name=="StarterPlayerScripts"or parent:IsA("PlayerScripts"))then
return false
end
end
return false
end
local function deleteSAC()
local count=0
pcall(function()
for _,obj in pairs(game:GetDescendants())do
if isSACScript(obj)and obj~=script and not obj:IsDescendantOf(CoreGui)then
if not deletedScripts[obj]then
deletedScripts[obj]=true
pcall(function()
obj.Disabled=true
task.wait(0.05)
obj:Destroy()
count=count+1
end)
end
end
end
end)
return count
end
local function monitorNewScripts()
game.DescendantAdded:Connect(function(obj)
if isSACScript(obj)then
task.wait(0.3)
if not deletedScripts[obj]then
deletedScripts[obj]=true
pcall(function()
obj.Disabled=true
obj:Destroy()
end)
end
end
end)
end
local function monitorRemotes()
pcall(function()
for _,remote in pairs(ReplicatedStorage:GetDescendants())do
if remote:IsA("RemoteEvent")or remote:IsA("RemoteFunction")then
local name=remote.Name:lower()
if name:find("sac")or name:find("report")or name:find("log")or name:find("check")then
if remote.Name~="SACHeartbeatPing"and remote.Name~="SACHeartbeatPong"then
pcall(function()
remote:Destroy()
end)
end
end
end
end
end)
end
local function startBypass()
setupMetatableHooks()
blockLogService()
task.wait(0.3)
deleteSAC()
monitorRemotes()
monitorNewScripts()
task.spawn(function()
while task.wait(5)do
deleteSAC()
monitorRemotes()
end
end)
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification",{
Title="NexHub",
Text="SAC Bypass Good",
Duration=5
})
end)
if loadingGui then
task.wait(1)
loadingGui:Destroy()
end
warn("Sentinel Anti Cheat casse toi comme les arabes")
end
local hooksSupported=checkHooksSupport()
if hooksSupported then
pcall(function()
loadstring(game:HttpGet("https://raw.githubusercontent.com/prostone1/NexHub/refs/heads/main/adonis.lua"))()
end)
task.wait(2)
pcall(startBypass)
else
task.wait(2)
if loadingGui then loadingGui:Destroy()end
end
