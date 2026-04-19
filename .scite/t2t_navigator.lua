-- t2t_navigator.lua
-- Navigate document headings in SciTE
-- Ctrl+Shift+H : popup list for quick jump (heading scrolled to top)
-- Ctrl+Shift+M : persistent TOC panel in output pane (click to jump)

-- ── Configuration ────────────────────────────────────────────────────────────
-- Symbol used for symmetric headings (txt2tags style): = Title =
-- Set to nil to disable symmetric heading detection.
local HEADING_SYMBOL = "="

-- Set to true to also detect Markdown headings: # Title, ## Title, etc.
local MARKDOWN_HEADINGS = false
-- ─────────────────────────────────────────────────────────────────────────────

local _nav_lines = {}   -- ordered list of 0-based heading line numbers
local _nav_set   = {}   -- set for O(1) lookup in OnUpdateUI
local _last_line = -1   -- previous caret line, to detect jumps
local _popup_nav = false -- true when navigation came from popup (suppress OnUpdateUI)

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function scan_headings()
    local headings = {}
    _nav_lines = {}
    _nav_set   = {}

    for i = 0, editor.LineCount - 1 do
        local line = editor:GetLine(i)
        if line then
            line = line:gsub("[\r\n]+$", "")
            local title, markers

            -- Symmetric headings: = Title =  or == Title ==  etc.
            if HEADING_SYMBOL then
                for level = 1, 5 do
                    local sym = string.rep(HEADING_SYMBOL, level)
                    title = line:match("^" .. sym .. " (.+) " .. sym .. "%s*$")
                    if title then
                        markers = sym .. " "
                        break
                    end
                end
            end

            -- Markdown headings: # Title  or ## Title  etc.
            if not title and MARKDOWN_HEADINGS then
                local hashes, t = line:match("^(#+) (.+)$")
                if hashes and #hashes <= 5 then
                    title   = t
                    markers = hashes .. " "
                end
            end

            if title then
                local display = string.format("%5d: %s%s %s", i + 1, markers, trim(title),
                                              markers:gsub("%s+$", ""))
                headings[#headings + 1] = display
                _nav_lines[#_nav_lines + 1] = i
                _nav_set[i] = true
            end
        end
    end
    return headings
end

-- CARET_SLOP(1)|CARET_STRICT(4) with slop=0 forces caret to top of view.
-- Wrap in pcall in case the API behaves differently on this platform.
local function goto_top(line0)
    pcall(function() editor:SetYCaretPolicy(5, 0) end)
    editor:GotoLine(line0)
    pcall(function() editor:SetYCaretPolicy(0, 0) end)
end

-- Popup list (Ctrl+Shift+H)
function GotoT2TAnyHeading()
    local headings = scan_headings()
    if #headings == 0 then
        print("No headings found.  Expected format: = Title =")
        return
    end
    local old_sep = editor.AutoCSeparator
    editor.AutoCSeparator = 10
    editor:UserListShow(101, table.concat(headings, "\n"))
    editor.AutoCSeparator = old_sep
end

-- Persistent TOC in output pane (Ctrl+Shift+M)
-- Each entry is printed as filepath:line: so SciTE makes it clickable.
function T2TTableOfContents()
    local headings = scan_headings()
    local filepath  = props["FileNameExt"]
    local filename  = props["FileNameExt"]

    print("╔══════════════════════════════╗")
    print("║ " .. filename .. " — headings")

    if #headings == 0 then
        print("No headings found.")
    else
        for i, h in ipairs(headings) do
            local linenum = _nav_lines[i] + 1
            local heading = h:match("^%s*%d+:%s*(.*)")
            local indent  = heading:match("^(=*)")
            local level   = indent and #indent or 0
            local pad     = string.rep("  ", level - 1)
            print("║ " .. filepath .. ":" .. linenum .. ":" .. pad .. heading)
        end
    end

    print("╚══════════════════════════════╝")
end

-- When the caret jumps onto a heading line (e.g. via TOC click), scroll it to top.
-- The _popup_nav flag prevents double-scrolling when the popup already handled it.
local old_OnUpdateUI = OnUpdateUI
function OnUpdateUI()
    local cur_line = editor:LineFromPosition(editor.CurrentPos)
    if cur_line ~= _last_line then
        local jumped      = math.abs(cur_line - _last_line) > 3
        local from_popup  = _popup_nav
        _last_line  = cur_line
        _popup_nav  = false
        if jumped and not from_popup and _nav_set[cur_line] then
            goto_top(cur_line)
        end
    end
    if old_OnUpdateUI then old_OnUpdateUI() end
end

local old_OnUserListSelection = OnUserListSelection
function OnUserListSelection(tp, sel)
    if tp == 101 then
        local linenum = tonumber(sel:match("^%s*(%d+):"))
        if linenum then
            _popup_nav = true   -- tell OnUpdateUI not to scroll again
            goto_top(linenum - 1)
        end
        return true
    end
    if old_OnUserListSelection then
        return old_OnUserListSelection(tp, sel)
    end
end
