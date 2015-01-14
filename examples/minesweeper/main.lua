
package.path = "../../?/init.lua;../../?.lua;"..package.path

print = require("klib.utils.debug").trace

local classes = require "klib.classes"

local Application = require("klib.app").Application

local gui = require "klib.gui"

local gui_core = require "klib.gui.core"

local MineSweeper = classes.class("MineSweeper", gui.Grid)

MineSweeper.default_board_w = 10
MineSweeper.default_board_h = 10
MineSweeper.default_bomb_count = 10

MineSweeper.bomb_button_bg_color = gui_core.get_color(128, 0, 0)
MineSweeper.open_button_bg_color = gui_core.get_color(0, 128, 0)
MineSweeper.button_fg_color = gui_core.get_color(255, 255, 255)

function MineSweeper:init(board_w, board_h, bomb_count)
	board_w = board_w or self.default_board_w
	board_h = board_h or self.default_board_h
	bomb_count = bomb_count or self.default_bomb_count
	gui.Grid.init(self, { }, board_w, board_h)
	self:new_game(board_w, board_h, bomb_count)
end

function MineSweeper:new_game(board_w, board_h, bomb_count)
	board_w = board_w or self.default_board_w
	board_h = board_h or self.default_board_h
	bomb_count = bomb_count or self.default_bomb_count
	self.board_w, self.board_h = board_w, board_h
	self.bomb_count = bomb_count
	local cell_count = board_w * board_h
	local field = { }
	for x = 1, cell_count do
		field[x] = false
	end
	local bc = bomb_count
	while bc > 0 do
		local p = math.random(1, cell_count)
		if not field[p] then
			field[p] = true
			bc = bc - 1
		end
	end
	local buttons = { }
	local ms = self
	for ci = 1, cell_count do
		local b = gui.Button("")
		local bombs_around = 0
		local cx, cy = (ci-1) % board_w, math.floor((ci-1) / board_w)
		for yy = math.max(0, cy-1), math.min(board_h-1, cy+1) do
			for xx = math.max(0, cx-1), math.min(board_w-1, cx+1) do
				if field[(yy * board_w) + xx + 1] then
					bombs_around = bombs_around + 1
				end
			end
		end
		b.has_bomb = field[ci]
		b.index = ci
		b.bomb_count = bombs_around
		b.parent = self

		function b:on_activate()
			local bw = ms.board_w
			local index = self.index - 1
			local x, y = index % bw, math.floor(index / bw)
			ms:open_cell(x, y)
		end

		function b:on_click(mb)
			if mb == "r"  and (not self.open) then
				if self.flag == nil then
					self.flag, self.text = "!", "!"
				elseif self.flag == "!" then
					self.flag, self.text = "?", "?"
				elseif self.flag == "?" then
					self.flag, self.text = nil, ""
				end
			elseif mb == "m" then
				local ci = self.index
				local x, y = (ci-1) % ms.board_w,
						math.floor((ci-1) / ms.board_w)
				ms:open_around(x, y)
			end
		end
		table.insert(buttons, b)
	end
	self.children = buttons
	self.cells_left = cell_count - bomb_count
	self:layout_items()
end

function MineSweeper:reset_game()
	for _, b in ipairs(self.buttons) do
		b.bg_color = nil
		b.open = false
		b.flag = nil
		b.enabled = true
		b.text = nil
	end
end

function MineSweeper:get_preferred_size()
	return self.board_w * 16, self.board_h * 16
end

function MineSweeper:open_cell(x, y)
	local bw, bh = self.board_w, self.board_h
	if (x < 0) or (x >= bw) or (y < 0) or (y >= bh) then
		return
	end
	local i = (y*bw)+x+1
	local btn = self.children[i]
	if (not btn) or btn.flag or btn.open then return end
	btn.open = true
	if btn.has_bomb then
		self:end_game(btn, false)
		return
	end
	btn.fg_color = btn.button_fg_color
	btn.text = (btn.bomb_count > 0) and tostring(btn.bomb_count) or ""
	self.cells_left = self.cells_left - 1
	btn.bg_color = self.open_button_bg_color
	if self.cells_left == 0 then
		self:end_game(btn, true)
		return
	end
	if btn.bomb_count == 0 then
		self:open_around(x, y)
	end
end

function MineSweeper:open_around(x, y)
	for yy = -1, 1 do
		for xx = -1, 1 do
			if not ((xx == 0) and (yy == 0)) then
				self:open_cell(x+xx, y+yy)
			end
		end
	end
end

function MineSweeper:end_game(btn, win)
	local r = self:on_game_end(win)
	if r then return end
	for _, b in ipairs(self.children) do
		b.enabled = false
		b.text = (b.has_bomb and "O"
			or (b.bomb_count > 0) and tostring(b.bomb_count)
			or "")
	end
	if not win then
		btn.text = "X"
		btn.fg_color = self.button_fg_color
		btn.bg_color = self.bomb_button_bg_color
	end
end

function MineSweeper:on_game_end(win)
end

local MainWindow = classes.class("MainWindow", gui.Window)

function MainWindow:init()
	local ms = MineSweeper()
	gui.Window.init(self, "MineSweeper", ms)
end

local MineSweeperApp = classes.class("MineSweeperApp", Application)

MineSweeperApp.title = "MineSweeper"

function MineSweeperApp:init()
	Application.init(self)
	local wnd = MainWindow()
	wnd:resize_client(320, 320)
	self.desktop:insert(wnd)
end

function love.load(arg)
	MineSweeperApp():set_as_foreground()
end
