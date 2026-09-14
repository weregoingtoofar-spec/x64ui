-- Check for table that is shared between executions.
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
local SOURCE_URL = "https://raw.githubusercontent.com/weregoingtoofar-spec/x64ui/refs/heads/main/main.luau"
local REQUIRED_MARKERS = {
	"Version = \"1.0.2\"",
	"function X64UI:CreateWindow",
	"function X64UI:CreateDebuggerWindow",
	"function Window:AddCPUView",
}

---Report a loader failure with its traceback.
---@param errorMessage string
local function onLoadError(errorMessage)
	warn("[x64ui] failed to initialize")
	warn(tostring(errorMessage))
	warn(debug.traceback())
end

---Download the current full library through the executor request API.
---@return string
local function fetchSource()
	if type(request) ~= "function" then
		error("custom request function is unavailable")
	end

	local response = request({
		Url = SOURCE_URL .. "?v=" .. tostring(os.time()),
		Method = "GET",
		Headers = {
			["Accept"] = "text/plain",
			["Cache-Control"] = "no-cache",
		},
	})
	local statusCode = type(response) == "table" and tonumber(response.StatusCode) or 0
	if statusCode < 200 or statusCode >= 300 then
		error("main.luau request failed with status " .. tostring(statusCode))
	end
	if type(response.Body) ~= "string" or response.Body == "" then
		error("main.luau returned an empty body")
	end
	return response.Body
end

---Compile and verify the requested x64ui build.
---@return table
local function initializeLibrary()
	local source = fetchSource()
	if #source < 150000 then
		error("downloaded main.luau is truncated")
	end
	for _, marker in ipairs(REQUIRED_MARKERS) do
		if not source:find(marker, 1, true) then
			error("main.luau is stale or incompatible: missing " .. marker)
		end
	end

	local chunk, compileError = loadstring(source, "x64ui/main.luau")
	if not chunk then
		error("compile error: " .. tostring(compileError))
	end
	local library = chunk()
	if type(library) ~= "table" or type(library.CreateDebuggerWindow) ~= "function" then
		error("main.luau returned an incompatible library")
	end
	return library
end

local success, library = xpcall(initializeLibrary, onLoadError)
if not success then return nil end
return library
