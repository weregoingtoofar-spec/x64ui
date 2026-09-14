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

local SOURCE_URL = "https://raw.githubusercontent.com/territorialism/x64ui/main/main.luau"
local REQUIRED_MARKERS = {
	"local X64UI =",
	"function X64UI:CreateWindow",
	"function X64UI:CreateDebuggerWindow",
	"function Window:AddCPUView",
}

---Report a loader failure with a traceback.
---@param error string
local function onLoadError(error)
	warn("[x64ui] failed to initialize")
	warn(tostring(error))
	if debug and debug.traceback then warn(debug.traceback()) end
end

---Resolve the executor request implementation.
local function getRequestClient()
	if type(request) == "function" then return request end
	if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
	if type(http) == "table" and type(http.request) == "function" then return http.request end
	if type(http_request) == "function" then return http_request end
	return nil
end

---Fetch the complete library with request first.
local function fetchSource()
	local client = getRequestClient()
	if client then
		local ok, response = pcall(client, {
			Url = SOURCE_URL .. "?v=" .. tostring(os.time()),
			Method = "GET",
			Headers = { ["Accept"] = "text/plain", ["Cache-Control"] = "no-cache" },
		})
		if ok and type(response) == "table" then
			local status = tonumber(response.StatusCode) or 0
			if status >= 200 and status < 300 and type(response.Body) == "string" and response.Body ~= "" then
				return response.Body
			end
		end
	end
	local ok, source = pcall(function() return game:HttpGet(SOURCE_URL, true) end)
	if ok and type(source) == "string" and source ~= "" then return source end
	error("request failed for main.luau")
end

local function initialize()
	local source = fetchSource()
	if #source < 100000 then error("downloaded source is truncated") end
	for _, marker in ipairs(REQUIRED_MARKERS) do
		if not source:find(marker, 1, true) then error("source is missing marker: " .. marker) end
	end
	local compiler = loadstring or load
	if type(compiler) ~= "function" then error("loadstring is unavailable") end
	local chunk, compileError = compiler(source, "x64ui/main.luau")
	if not chunk then error("compile error: " .. tostring(compileError)) end
	local library = chunk()
	if type(library) ~= "table" or type(library.CreateDebuggerWindow) ~= "function" then error("invalid library result") end
	return library
end

local ok, library = xpcall(initialize, onLoadError)
if ok then return library end
return nil
