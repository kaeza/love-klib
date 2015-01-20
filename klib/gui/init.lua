
local classes = require "klib.classes"

local m = classes.module "klib.gui"

classes.import(m, "klib.gui.core")
classes.import(m, "klib.gui.widget")
classes.import(m, "klib.gui.button")
classes.import(m, "klib.gui.checkbox")
classes.import(m, "klib.gui.radiobutton")
classes.import(m, "klib.gui.label")
classes.import(m, "klib.gui.textfield")

classes.import(m, "klib.gui.listbox")
classes.import(m, "klib.gui.scrollbar")

classes.import(m, "klib.gui.composite")
classes.import(m, "klib.gui.container")
classes.import(m, "klib.gui.window")
classes.import(m, "klib.gui.desktop")
classes.import(m, "klib.gui.box")

classes.import(m, "klib.gui.notebook")

classes.import(m, "klib.gui.dialog")
classes.import(m, "klib.gui.dialog.messagedialog")
classes.import(m, "klib.gui.dialog.filedialog")
classes.import(m, "klib.gui.dialog.colordialog")
classes.import(m, "klib.gui.dialog.aboutdialog")

--classes.import(m, "klib.gui.menu") -- Broken.

classes.import(m, "klib.gui.graphics")
classes.import(m, "klib.gui.theme")

classes.import(m, "klib.gui.mixins")

return m
