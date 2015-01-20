
local classes = require "klib.classes"

local Dialog = require("klib.gui.dialog").Dialog
local Button = require("klib.gui.button").Button
local Label = require("klib.gui.label").Label
local Compound = require("klib.gui.compound").Compound
local Notebook = require("klib.gui.notebook").Notebook
local ListBox = require("klib.gui.listbox").ListBox

local stringex = require "klib.utils.stringex"

local math_min, math_max = math.min, math.max

local m = classes.module "klib.gui.dialog.aboutdialog"

local AboutDialog = classes.class(m, "AboutDialog", Dialog)

-- Public fields.
AboutDialog.big_font = love.graphics.newFont(20)
AboutDialog.resizable = true

local function make_textview_t(tbl)
	local lb = ListBox(0, 0, 1, 1)
	for _, line in ipairs(tbl) do
		lb:insert(line)
	end
	return lb
end

local function make_textview(text)
	return make_textview_t(stringex.split_lines(text))
end

function AboutDialog:init(title, appinfo)
	classes.check_types(2, 2, "t", appinfo)
	if type(appinfo.name) ~= "string" then
		error("name field must be a string", 2)
	elseif type(appinfo.version) ~= "string" then
		error("version field must be a string", 2)
	elseif (appinfo.description ~= nil)
			and (type(appinfo.description) ~= "string") then
		error("description field must be a string", 2)
	end
	local nlbl = Label(appinfo.name)
	nlbl.font = self.big_font
	nlbl.text_halign = 0.5
	local dlbl
	if appinfo.description then
		dlbl = Label(appinfo.description)
		dlbl.text_halign = 0.5
	end
	local vlbl = Label("Version "..appinfo.version)
	vlbl.text_halign = 0.5
	local nb = Notebook()
	nb:add_page("license", "License", make_textview(appinfo.license or ""))
	nb:add_page("authors", "Authors", make_textview_t(appinfo.authors or { }))
	local bok = Button("Close")
	bok:set_margins(16, nil, 16, nil)
	local dlg = self
	function bok:on_activate()
		dlg:close()
	end
	local client = Compound({ nlbl, dlbl, vlbl, nb, bok })
	function client:layout_items()
		local w, h = self.w, self.h
		local _, nlh, dlh, vlh
		_, nlh = nlbl:get_min_size()
		nlbl:reshape(0, 0, w, nlh)
		if dlbl then
			_, dlh = dlbl:get_min_size()
			dlbl:reshape(0, nlh, w, dlh)
		else
			dlh = 0
		end
		_, vlh = vlbl:get_min_size()
		vlbl:reshape(0, nlh+dlh, w, vlh)
		local bw, bh = bok:get_min_size()
		bok:reshape(w-bw, h-bh, bw, bh)
		nb:reshape(0, nlh+dlh+vlh, w, h-nlh-dlh-vlh-bh)
	end
	function client:calc_min_size()
		local nlw, nlh = vlbl:get_min_size()
		local vlw, vlh = vlbl:get_min_size()
		local bokw, bokh = bok:get_min_size()
		local nbw, nbh = nb:get_min_size()
		local dlw, dlh = 0, 0
		if dlbl then
			dlw, dlh = dlbl:get_min_size()
		end
		return math_max(nlw, dlw, vlw, nbw, bokw),
				nlh+dlh+vlh+nbh+bokh
	end
	Dialog.init(self, title, client)
end

return m
