
local classes = require "klib.classes"

local Window = require("klib.gui.window").Window

local m = classes.module "klib.gui.dialog"

local Dialog = classes.class(m, "Dialog", Window)

Dialog.resizable = false

return m
