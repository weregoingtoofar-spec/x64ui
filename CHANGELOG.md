# Changelog

## 1.0.2 — API integrity ordering fix

- Moved API validation after `CreateWindow` and `CreateDebuggerWindow` are installed.
- Cleared the false `CreateWindow` integrity warning.

## 1.0.1 — Loader compatibility fix

- Pointed the example and loader at `weregoingtoofar-spec/x64ui`.
- Added cache busting and explicit API/version validation.
- Removed the legacy `game:HttpGet` fallback; HTTP now uses `request`.

## 1.0.0-d — x64dbg workspace overhaul

### Added
- Complete x64dbg-style window chrome, menu order, debugger toolbar, status bar, and shortcuts.
- Resizable CPU workspace with disassembly, registers, dump, stack, info, branch markers, and breakpoints.
- Zoomable control-flow graph and reusable debugger tables/text views.
- Standard CPU, Graph, Log, Notes, Breakpoints, Memory Map, Call Stack, SEH, Script, Symbols, Source, References, Threads, and Handles tabs.
- Shared action handlers for menus, toolbar buttons, and keyboard shortcuts.

### Changed
- Rebuilt the example around a populated debugger session.
- Replaced runtime source patching with a validated request-first loader.
- Normalized Luau indentation and service naming.

### Fixed
- Reentrant signal events are queued instead of discarded.
- Input listeners remain safe when callbacks disconnect during dispatch.
- Key-picker listeners are cleaned with their window.
- Color-picker callbacks receive the real previous value.
- Destroyed tabs are removed from window state with a safe active-tab fallback.

### Removed
- All use of the obsolete chunk path.
