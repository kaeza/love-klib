
local classes = require "klib.classes"

local Dialog = require("klib.gui.dialog").Dialog
local Button = require("klib.gui.button").Button
local ListBox = require("klib.gui.listbox").ListBox
local TextField = require("klib.gui.textfield").TextField
local Composite = require("klib.gui.composite").Composite

local math_max, math_min = math.max, math.min

local m = classes.module "klib.gui.dialog.filedialog"

local FileDialog = classes.class(m, "FileDialog", Dialog)

-- Public fields.
FileDialog.mode = nil
FileDialog.filter = nil

-- Private fields.
local p_dirlist = { }
local p_filelist = { }
local p_namefield = { }

local function FileDialog_activate(self)
	local filename = ((self[p_namefield].text or "")
			:gsub("^%s+", ""):gsub("%s+$", ""))
	local dirmode = self.mode:match("^([^_]+)_dir")
	if dirmode == "open" then
		filename = self.path
		if love.filesystem.isDir(filename) then
			return filename
		end
	elseif dirmode == "save" then
		if filename ~= "" then
			filename = self.path.."/"..filename
			return filename
		end
	elseif filename ~= "" then
		if self.mode == "open" then
			if not love.filesystem.isFile(filename) then
				print("FileDialog: TODO: show 'file doesn't exist' error")
			end
		elseif self.mode == "save" then
			if love.filesystem.isFile(filename) then
				print("FileDialog: TODO: show 'overwrite?' dialog")
			end
		end
	end
	if filename and (filename ~= "") then
		if not self:on_file_select(self.path.."/"..filename) then
			self:close()
		end
	end
end

function FileDialog:init(title, mode, path, filter)
	local bok = Button("OK")
	local bcl = Button("Cancel")
	local dl = ListBox()
	local fl = ListBox()
	local tf = TextField("")
	local client = Composite({ bok, bcl, dl, fl, tf })
	function client:layout_items()
		local w, h = self.w, self.h
		local halfw = w/2
		dl:reshape(0, 0, halfw, h-20)
		fl:reshape(halfw,  0, halfw, h-20)
		tf:reshape(0, h-20, w-128, 20)
		bok:reshape(w-128, h-20, 64, 20)
		bcl:reshape(w- 64, h-20, 64, 20)
	end
	function client:calc_min_size()
		return 200, 150
	end
	self[p_dirlist] = dl
	self[p_filelist] = fl
	self[p_namefield] = tf
	Dialog.init(self, title, client)
	classes.check_types(2, 2, "s?s?f?", mode, path, filter)
	self.mode = mode
	self.filter = filter
	local fdlg = self
	function bok:on_activate()
		if fl.selection_start then
			FileDialog_activate(fdlg)
		end
	end
	function bcl:on_activate()
		fdlg:close()
	end
	function dl:on_selection_activate(ss, se)
		if ss then
			fdlg.path = fdlg.path or "."
			fdlg:refresh(fdlg.path.."/"..self.items[ss])
		end
	end
	function fl:on_selection_change(ss, se)
		if ss then
			tf.text = self.items[ss]
		end
	end
	function fl:on_selection_activate(ss, se)
		if ss then
			tf.text = self.items[ss]
			FileDialog_activate(fdlg)
		end
	end
	self:refresh(path)
end

function FileDialog:update(dtime)
	self[p_namefield].enabled = ((self.mode == "save")
			or (self.mode == "save_dir"))
end

local enumerate = (love.filesystem.enumerate
		or love.filesystem.getDirectoryItems)
local isdir = love.filesystem.isDirectory

local function split_path(path)
	local pos, len = 1, #path
	local parts = { }
	while pos and (pos <= len) do
		local np = path:find("/", pos, true)
		table.insert(parts, path:sub(pos, np and (np-1)))
		pos = np and np + 1
	end
	return parts
end

local function collapse_path(path)
	path = path:gsub("[\\/]+", "/")
	local parts = split_path(path)
	local newparts = { }
	for _, part in ipairs(parts) do
		if part == ".." then
			if #newparts > 0 then
				table.remove(newparts, #newparts)
			end
		elseif part ~= "." then
			table.insert(newparts, part)
		end
	end
	return table.concat(newparts, "/")
end

function FileDialog:refresh(path)
	path = collapse_path(path or self.path or "")
	self.path = path
	local files = enumerate(path)
	local dl, fl = self[p_dirlist], self[p_filelist]
	dl:clear()
	fl:clear()
	if path ~= "" then
		dl:insert("..")
	end
	for _, file in ipairs(files) do
		local full = path.."/"..file
		local dir = isdir(full)
		if (not self.filter) or (self.filter and self.filter(file, dir)) then
			if dir then
				dl:insert(file)
			else
				fl:insert(file)
			end
		end
	end
end

function FileDialog:on_file_select(path)
end

return m
