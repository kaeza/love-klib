
local classes = require "klib.classes"

local m = classes.module "klib.utils.version"

m.version = "0.1.0"

m.authors = {
	"Diego Martínez <kaeza>",
}

m.about_info = {
	name = "KLib",
	description = "A Graphical User Interface for Löve2D",
	license = require("klib.utils.license"),
	version = m.version,
	authors = m.authors,
}

return m
