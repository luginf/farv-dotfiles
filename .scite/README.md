# SciTE Lua scripts

Lua extensions for SciTE.

## Installation

SciTE only supports **one** `ext.lua.startup.script`. Load all scripts from a single startup file (e.g. `SciteStartup.lua`):

```lua
dofile(props["SciteDefaultHome"] .. "/t2t_navigator.lua")
dofile(props["SciteDefaultHome"] .. "/snippets.lua")
```

Or with a user-local path:

```lua
dofile(props["SciteUserHome"] .. "/.scite/t2t_navigator.lua")
dofile(props["SciteUserHome"] .. "/.scite/snippets.lua")
```

---

## t2t_navigator.lua — Heading navigator

Navigate document headings (txt2tags and Markdown) via a popup list or a clickable TOC in the output pane.

### Keybindings

Add to your `.properties` file:

```properties
command.name.11.*=Goto Heading
command.11.*=GotoT2TAnyHeading
command.mode.11.*=subsystem:lua,savebefore:no
command.shortcut.11.*=Ctrl+Shift+H

command.name.12.*=Table of Contents
command.12.*=T2TTableOfContents
command.mode.12.*=subsystem:lua,savebefore:no
command.shortcut.12.*=Ctrl+Shift+M
```

### Usage

| Shortcut | Action |
|----------|--------|
| **Ctrl+Shift+H** | Popup list of all headings — select one to jump to it |
| **Ctrl+Shift+M** | Print a clickable TOC in the output pane |

Clicking a TOC entry scrolls the heading to the top of the view. Jumping to a heading line from the TOC also scrolls it to the top automatically.

### Configuration

Edit the top of `t2t_navigator.lua`:

```lua
-- Symbol for symmetric headings: = Title =  or == Title ==
-- Set to nil to disable.
local HEADING_SYMBOL = "="

-- Also detect Markdown headings: # Title, ## Title …
local MARKDOWN_HEADINGS = false
```

### Heading formats supported

| Style | Example |
|-------|---------|
| txt2tags symmetric | `= Title =`, `== Title ==`, … |
| Markdown (optional) | `# Title`, `## Title`, … |

---

## snippets.lua — Snippet expansion

Insert reusable text snippets with dynamic variables including a configurable Zettelkasten ID (`$ZK_ID`).

### Keybinding

```properties
command.name.10.*=Show Snippets
command.10.*=ShowSnippets
command.mode.10.*=subsystem:lua,savebefore:no
command.shortcut.10.*=Ctrl+Shift+S
```

Adjust the command number if it conflicts with an existing command.

### Usage

Two ways to insert a snippet:

| Method | Steps |
|--------|-------|
| **Popup list** | Press Ctrl+Shift+S, select a snippet |
| **Inline Tab** | Type a trigger word (e.g. `zk`) then press Tab |

Note: trigger words must be alphanumeric + underscore only (`[%w_]`). Keys with hyphens (e.g. `date-H2`) are only accessible via the popup list.

### Snippet variables

| Variable | Expands to |
|----------|------------|
| `$ZK_ID` | Unique timestamp ID (see format below) |
| `$CURSOR` | Caret is placed here after insertion. Without it, the caret lands at the end of the snippet. |
| `$SELECTION` | Text selected when the snippet was invoked |

Date tokens can also be used directly in snippet bodies:

| Token | Value |
|-------|-------|
| `%Y`  | 4-digit year |
| `%M`  | 2-digit month |
| `%D`  | 2-digit day |
| `%h`  | 2-digit hour |
| `%m`  | 2-digit minute |
| `%s`  | 2-digit second |

### $ZK_ID format

The default format is `id%Y%M%Dx%h%m%s`, producing IDs like `id20260526x143022`.

Override in your `.properties` file:

```properties
zk.id.format=id%Y%M%Dx%h%m%s
```

### Defining snippets

Edit the `SNIPPETS` table at the top of `snippets.lua`:

```lua
SNIPPETS = {
    zk      = "$ZK_ID",
    date    = "%Y-%M-%D",
    date_H2 = "== %Y-%M-%D ==",
    todo    = "TODO($ZK_ID): $CURSOR",
    link    = "[[$ZK_ID $CURSOR]]",
}
```

Add snippets at runtime from any script:

```lua
AddSnippet("sig", "-- $ZK_ID  Alan")
```

### Public API

All symbols are globals, accessible from any script loaded after `snippets.lua`.

**Variables**

| Symbol | Type | Description |
|--------|------|-------------|
| `ZK_ID_FORMAT` | string | Default format for `$ZK_ID` — read/write |
| `SNIPPETS` | table | Snippet table — add entries directly: `SNIPPETS["foo"] = "bar"` |

**Functions**

| Function | Description |
|----------|-------------|
| `GetZkId()` | Return the current `$ZK_ID` string |
| `ExpandDate(fmt)` | Apply `%Y` `%M` `%D` `%h` `%m` `%s` tokens to a format string |
| `ExpandVars(body [, sel])` | Expand `$ZK_ID`, `%Y`…, `$CURSOR`, `$SELECTION` in a string |
| `InsertSnippet(body [, sel])` | Insert a snippet at the caret with full variable expansion |
| `AddSnippet(trigger, body)` | Add or update a snippet at runtime |
| `ShowSnippets()` | Open the popup snippet picker |

**Examples**

```lua
-- format a date string
local s = ExpandDate("%Y-%M-%D")          -- "2026-05-26"

-- override the ZK_ID format
ZK_ID_FORMAT = "%Y%M%D"

-- insert a snippet from another script
InsertSnippet("= $ZK_ID =\n\n$CURSOR")

-- expand variables without inserting
local ref = ExpandVars("ref: $ZK_ID")
```
