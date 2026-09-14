if not shared then
	return warn("No shared, no script.")
end

-- Initialize Luraph globals for development bundles.
if type(LPH_NO_VIRTUALIZE) ~= "function" then
	getfenv().LPH_NO_VIRTUALIZE = function(...) return ... end
end
getfenv().PP_SCRAMBLE_NUM = getfenv().PP_SCRAMBLE_NUM or function(...) return ... end
getfenv().PP_SCRAMBLE_STR = getfenv().PP_SCRAMBLE_STR or function(...) return ... end
getfenv().PP_SCRAMBLE_RE_NUM = getfenv().PP_SCRAMBLE_RE_NUM or function(...) return ... end

-- Constants.
local LOADER_URL = "https://raw.githubusercontent.com/weregoingtoofar-spec/x64ui/refs/heads/main/loader.luau"

---Report a library loading failure.
---@param errorMessage string
local function onLoadError(errorMessage)
	warn("[example] unable to load x64ui")
	warn(tostring(errorMessage))
	warn(debug.traceback())
end

---Load and verify the matching repository build.
---@return table?
local function loadLibrary()
	if type(request) ~= "function" then
		onLoadError("custom request function is unavailable")
		return nil
	end

	local response = request({
		Url = LOADER_URL .. "?v=" .. tostring(os.time()),
		Method = "GET",
		Headers = {
			["Accept"] = "text/plain",
			["Cache-Control"] = "no-cache",
		},
	})
	local statusCode = type(response) == "table" and tonumber(response.StatusCode) or 0
	if statusCode < 200 or statusCode >= 300 then
		onLoadError("loader request failed with status " .. tostring(statusCode))
		return nil
	end

	local chunk, compileError = loadstring(response.Body, "x64ui/loader.luau")
	if not chunk then
		onLoadError("loader compile error: " .. tostring(compileError))
		return nil
	end
	local success, library = xpcall(chunk, onLoadError)
	if not success or type(library) ~= "table" then return nil end
	if library.Version ~= "1.0.1" or type(library.CreateDebuggerWindow) ~= "function" then
		onLoadError("stale or incompatible x64ui build loaded")
		return nil
	end
	return library
end

local X64UI = loadLibrary()
if not X64UI then return end

local cpu = {
	Info = "RIP points to demo.main+0x19 · branch destination: demo.main+0x31",
	Instructions = {
		{ Address = "00007FF6`14001000", Bytes = "48 89 5C 24 08", Instruction = "mov qword ptr ss:[rsp+8], rbx", Comment = "demo.main" },
		{ Address = "00007FF6`14001005", Bytes = "57", Instruction = "push rdi" },
		{ Address = "00007FF6`14001006", Bytes = "48 83 EC 20", Instruction = "sub rsp, 20" },
		{ Address = "00007FF6`1400100D", Bytes = "48 85 C9", Instruction = "test rcx, rcx" },
		{ Address = "00007FF6`14001010", Bytes = "74 1F", Instruction = "je demo.00007FF614001031", Branch = "└" },
		{ Address = "00007FF6`14001012", Bytes = "48 8D 15 E7 1F 00 00", Instruction = "lea rdx, qword ptr ds:[140003000]", Comment = "L\"x64ui ready\"" },
		{ Address = "00007FF6`14001019", Bytes = "48 8B CF", Instruction = "mov rcx, rdi", Current = true },
		{ Address = "00007FF6`1400101C", Bytes = "E8 5F 03 00 00", Instruction = "call demo.00007FF614001380", Comment = "demo.initialize" },
		{ Address = "00007FF6`14001023", Bytes = "75 09", Instruction = "jne demo.00007FF61400102E", Breakpoint = true, Branch = "│" },
		{ Address = "00007FF6`14001025", Bytes = "33 C0", Instruction = "xor eax, eax" },
		{ Address = "00007FF6`1400102C", Bytes = "C3", Instruction = "ret" },
	},
	Registers = {
		{ Name = "RAX", Value = "0000000000000001", Modified = true }, { Name = "RBX", Value = "0000000000000000" },
		{ Name = "RCX", Value = "000001D84A7B1030", Hint = "demo.context" }, { Name = "RDX", Value = "00007FF614003000", Hint = "L\"x64ui ready\"" },
		{ Name = "RSP", Value = "000000D4CE8FF7C0", Modified = true }, { Name = "RDI", Value = "000001D84A7B1030" },
		{ Name = "RIP", Value = "00007FF614001019", Modified = true, Hint = "demo.main+19" }, { Name = "EFLAGS", Value = "00000246", Hint = "ZF PF IF" },
	},
	Dump = {
		{ Address = "000001D8`4A7B1030", Bytes = "78 36 34 75 69 00 00 00 10 00 14 00 00 00 00 00", Ascii = "x64ui..........." },
		{ Address = "000001D8`4A7B1040", Bytes = "52 65 61 64 79 00 00 00 40 10 7B 4A D8 01 00 00", Ascii = "Ready...@.{J...." },
	},
	Stack = {
		{ Address = "000000D4`CE8FF7C0", Value = "00007FF6`14001021", Comment = "return to demo.main+21" },
		{ Address = "000000D4`CE8FF7D0", Value = "00007FFD`9A1A26AD", Comment = "kernel32.BaseThreadInitThunk+1D" },
	},
}

local window
local actions = {
	Run = function() window:SetDebugState("Running", "Running demo.exe") window:Log("debuggee resumed", "good") end,
	Pause = function() window:SetDebugState("Paused", "Paused at demo.main+0x19") window:Log("debuggee paused", "warn") end,
	["Step Into"] = function() window:SetDebugState("Paused", "Stepped into demo.initialize") end,
	["Step Over"] = function() window:SetDebugState("Paused", "Stepped over current instruction") end,
}
window = X64UI:CreateDebuggerWindow({
	Title = "x64dbg — demo.exe — PID: 1A2C — Module: demo.exe",
	State = "Paused",
	StatusText = "System breakpoint reached",
	Actions = actions,
	Data = {
		CPU = cpu,
		Graph = {
			Nodes = {
				{ Id = "entry", Title = "demo.main", X = 420, Y = 70, Lines = { "14001000  push rdi", "14001010  je 14001031" } },
				{ Id = "body", Title = "loc_14001012", X = 220, Y = 245, Lines = { "14001012  lea rdx, [140003000]", "1400101C  call demo.initialize" } },
				{ Id = "exit", Title = "loc_14001025", X = 650, Y = 245, Lines = { "14001025  xor eax, eax", "1400102C  ret" } },
			},
			Edges = { { From = "entry", To = "body", Kind = "False" }, { From = "entry", To = "exit", Kind = "True" } },
		},
		Log = "[00:00:00] x64ui initialized\n[00:00:00] system breakpoint reached",
		Notes = "Investigation notes\n\n- Entry point validated\n- Breakpoint set after initialize()",
		Breakpoints = { { Type = "Software", Address = "00007FF6`14001023", ["Module/Label"] = "demo.main+23", State = "Enabled", Comment = "branch after initialize" } },
		MemoryMap = { { Address = "00007FF6`14000000", Size = "00005000", Info = "demo.exe", Type = "IMG", Protection = "ER---", Initial = "ER---" } },
		Symbols = { { Address = "00007FF6`14001000", Type = "Export", Ordinal = "1", Symbol = "demo.main" } },
		Threads = { { Number = "0", ID = "1A2C", Entry = "demo.main", TEB = "000000D4`CE8EE000", State = "Paused", Priority = "Normal", Name = "Main Thread" } },
	},
})
if not window then return warn("[example] CreateDebuggerWindow failed") end

local settings = window:AddTab("Settings")
local appearance = settings:AddLeftGroupbox("Appearance")
local behavior = settings:AddRightGroupbox("Behavior")
appearance:AddColorPicker("AccentColor", { Text = "Accent color", Default = X64UI.Theme.Accent, Callback = function(color) X64UI:SetThemeKey("Accent", color) end })
appearance:AddSlider("InterfaceScale", { Text = "Interface scale", Min = .75, Max = 1.25, Default = 1, Rounding = 2, Callback = function(value) window:SetScale(value) end })
behavior:AddToggle("ShowConsole", { Text = "Show docked log console", Default = false, Callback = function(value) if window.ConsoleVisible ~= value then window:ToggleConsole() end end })
behavior:AddButton({ Text = "Save layout", Callback = function() window:SaveConfig("x64ui_example.json") end })
behavior:AddButton({ Text = "Load layout", Callback = function() window:LoadConfig("x64ui_example.json") end })
window:SelectTab("CPU")
X64UI:Notify({ Title = "x64ui", Description = "F9 run · F7 step · G graph · Ctrl+P commands", Time = 4 })
