# x64ui

Desktop-only Luau UI library rebuilt around the x64dbg UI/UX: Windows-style chrome, complete debugger menus, compact toolbar, tabbed views, resizable CPU panes, control-flow graph, data tables, notes/log/source views, status bar, and keyboard shortcuts.

## Load

```luau
local X64UI = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/territorialism/x64ui/main/loader.luau"
))()n```

The loader uses the executor `request` function first, validates the complete source, then compiles it. `game:HttpGet` remains a compatibility fallback.

## Debugger workspace

```luau
local window = X64UI:CreateDebuggerWindow({
	Title = "x64dbg — target.exe — PID: 1A2C",
	State = "Paused",
	Actions = {
		Run = function()
			print("run")
		end,
		["Step Into"] = function()
			print("step")
		end,
	},
	Data = {
		CPU = {
			Info = "RIP points to target.main+0x19",
			Instructions = {
				{ Address = "00007FF6`14001000", Bytes = "48 89 5C 24 08", Instruction = "mov [rsp+8], rbx", Current = true },
			},
			Registers = {
				{ Name = "RIP", Value = "00007FF6`14001000", Modified = true },
			},
			Dump = {},
			Stack = {},
		},
	},
})
```

Standard views are available through `window.DebuggerViews`: CPU, Graph, Log, Notes, Breakpoints, Memory Map, Call Stack, SEH, Script, Symbols, Source, References, Threads, and Handles.

## Updating views

```luau
local cpu = window.DebuggerViews.CPU
cpu:SetInstructions(instructions)
cpu:SetRegisters(registers)
cpu:SetDump(dumpRows)
cpu:SetStack(stackRows)
cpu:SetInfo("Paused at target.main+0x19")
cpu:SetSplit(0.69, 0.61)

window.DebuggerViews.Breakpoints:SetRows(rows)
window.DebuggerViews.Graph:SetGraph(nodes, edges)
window.DebuggerViews.Log:Append("debuggee resumed")
window:SetDebugState("Running", "Running target.exe")
```

## Actions and shortcuts

```luau
window:SetActionHandler("Pause", function()
	window:SetDebugState("Paused")
end)
```

| Shortcut | Action |
| --- | --- |
| `F2` | Toggle breakpoint |
| `Ctrl+F2` | Restart |
| `F7` | Step into |
| `F8` | Step over |
| `F9` | Run |
| `Shift+F9` | Run to user code |
| `Ctrl+F9` | Execute till return |
| `F12` | Pause |
| `G` | Graph view |
| `Ctrl+P` | Command palette |
| `RightShift` | Show/hide window |

## Generic controls

`CreateWindow`, `AddTab`, left/right groupboxes, labels, buttons, toggles, sliders, dropdowns, inputs, keypickers, color pickers, numeric inputs, list boxes, trees, tables, dependency boxes, notifications, dialogs, profiles, undo/redo, themes, watermark, and keybind lists remain supported.

Run `example.luau` for a populated debugger demo.

## Requirements

- Desktop keyboard and mouse
- Luau executor with `loadstring`
- `request` recommended
- File APIs only for saved configurations

The obsolete chunk path is not used or included.
