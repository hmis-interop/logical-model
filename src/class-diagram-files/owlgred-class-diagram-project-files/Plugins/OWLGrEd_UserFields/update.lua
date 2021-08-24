require("lQuery")
local configurator = require("configurator.configurator")
local utils = require "plugin_mechanism.utils"
local completeMetamodel = require "OWLGrEd_UserFields.completeMetamodel"
local profileMechanism = require "OWLGrEd_UserFields.profileMechanism"
local syncProfile = require "OWLGrEd_UserFields.syncProfile"
local viewMechanism = require "OWLGrEd_UserFields.viewMechanism"

local plugin_name = "OWLGrEd_UserFields"

local path
if tda.isWeb then
	path = tda.FindPath(tda.GetToolPath() .. "/AllPlugins", plugin_name).."/"
else
	path = tda.GetProjectPath() .. "\\Plugins\\".. plugin_name .. "\\"
end

local plugin_info_path = path .. "info.lua"
local f = io.open(plugin_info_path, "r")
local info = loadstring("return" .. f:read("*all"))()
f:close()
local plugin_version = info.version
local current_version = lQuery("Plugin[id='".. plugin_name .."']"):attr("version")

current_version = tonumber(string.sub(current_version, 3))
plugin_version = string.sub(plugin_version, 3)
-- 0.7
if current_version < 7 then
	lQuery("PopUpElementType[id='Style Palette'][procedureName='OWLGrEd_UserFields.stylePalette.stylePaletteProgect']"):delete()

	lQuery.create("PopUpElementType", {id="Style Palette", caption="Style Palette", nr=5, visibility=true, procedureName="OWLGrEd_UserFields.stylePalette.stylePaletteProgect"})
			:link("popUpDiagramType", lQuery("GraphDiagramType[id='projectDiagram']/rClickEmpty"))
end

if current_version < 8 then
	lQuery("PopUpElementType[id='Style Palette'][procedureName='OWLGrEd_UserFields.stylePalette.stylePaletteProgect']"):delete()

	lQuery.create("PopUpElementType", {id="Manage Plug-ins", caption="Extensions", nr=9, visibility=true, procedureName="OWLGrEd_UserFields.managePlugins.managePlugins"})
			:link("popUpDiagramType", lQuery("GraphDiagramType[id='projectDiagram']/rClickEmpty"))
	
	lQuery.create("PopUpElementType", {id="Style Palette", caption="Style Palette", nr=10, visibility=true, procedureName="OWLGrEd_UserFields.stylePalette.stylePaletteProgect"})
			:link("popUpDiagramType", lQuery("GraphDiagramType[id='projectDiagram']/rClickEmpty"))
end

if current_version < 9 then
	lQuery("AA#Profile[name='PaletteViews']"):attr("name", "Default_Profile")
end

if current_version < 10 then
	lQuery("PopUpElementType[id='Manage Plug-ins']"):attr("caption", "Extensions")
end
--0.6
-- lQuery.create("Tag", {value = "owlgred:=<http://lumii.lv/2011/1.0/owlgred#>", key = "owl_NamespaceDef"}):link("type", lQuery("ToolType"))
	

--0.5
-- lQuery.model.add_property("AA#ViewStyleSetting", "elementTypeId")

--0.4
-- if lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='Name']/translet[extensionPoint = 'procGetPrefix']"):size() > 1 then
-- lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='Name']/translet[extensionPoint = 'procGetPrefix']"):last():delete() end
-- if lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/translet[extensionPoint = 'procGetPrefix']"):size() > 1 then 
-- lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/translet[extensionPoint = 'procGetPrefix']"):last():delete() end

--[[
lQuery.model.add_property("AA#StyleSetting", "procSetValue")
lQuery.model.add_property("AA#Field", "isExistingField")

lQuery.model.add_class("AA#CustomStyleSetting")
	lQuery.model.add_property("AA#CustomStyleSetting", "elementTypeName")
	lQuery.model.add_property("AA#CustomStyleSetting", "compartTypeName")
	lQuery.model.add_property("AA#CustomStyleSetting", "parameterName")
	lQuery.model.add_property("AA#CustomStyleSetting", "parameterValue")
-- lQuery.model.add_class("AA#Parameter")
	-- lQuery.model.add_property("AA#Parameter", "name")
	-- lQuery.model.add_property("AA#Parameter", "value")
lQuery.model.set_super_class("AA#CustomStyleSetting", "AA#StyleSetting")

lQuery.model.add_class("SettingTag")
	lQuery.model.add_property("SettingTag", "tagName")
	lQuery.model.add_property("SettingTag", "tagValue")

lQuery.model.add_link("SettingTag", "settingTag", "elementStyleSetting", "ElementStyleSetting")
lQuery.model.add_link("SettingTag", "settingTag", "compartmentStyleSetting", "CompartmentStyleSetting")
lQuery.model.add_link("SettingTag", "settingTag", "ref", "Thing")
	
-- lQuery.model.add_link("AA#CustomStyleSetting", "styleSetting", "parameter", "AA#Parameter")
lQuery.model.add_composition("AA#CustomStyleSetting", "customStyleSetting", "viewStyleSetting", "AA#ViewStyleSetting")

lQuery.model.add_link("ElementStyleSetting", "dependingElementStyleSetting", "dependsOnCompartType", "CompartType")
lQuery.model.add_link("CompartmentStyleSetting", "dependingCompartmentStyleSetting", "dependsOnCompartType", "CompartType")

utils.copy(tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\aa.bmp",
           tda.GetProjectPath() .. "\\Pictures\\OWLGrEd_UserFields_aa.bmp")
		   
utils.copy(tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\aaView.bmp",
           tda.GetProjectPath() .. "\\Pictures\\OWLGrEd_UserFields_aaView.bmp")

utils.copy(tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\aaStyles.bmp",
           tda.GetProjectPath() .. "\\Pictures\\OWLGrEd_UserFields_aaStyles.bmp")
		   
utils.copy(tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\aaViewHorizontal.bmp",
           tda.GetProjectPath() .. "\\Pictures\\OWLGrEd_UserFields_aaViewHorizontal.bmp")
		   
utils.copy(tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\aaViewHorizontalActivated.bmp",
           tda.GetProjectPath() .. "\\Pictures\\OWLGrEd_UserFields_aaViewHorizontalActivated.bmp")
		   
utils.copy(tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\aaViewVertical.bmp",
           tda.GetProjectPath() .. "\\Pictures\\OWLGrEd_UserFields_aaViewVertical.bmp")
		   
utils.copy(tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\aaViewVerticalActivated.bmp",
           tda.GetProjectPath() .. "\\Pictures\\OWLGrEd_UserFields_aaViewVerticalActivated.bmp")

lQuery("AA#View[showInPalette='true']"):each(function(view)
		lQuery("ToolbarElementType[caption=" .. view:attr("name") .. "]"):delete()
end)
lQuery("AA#View[showInToolBar='true']"):each(function(view)
		lQuery("ToolbarElementType[caption=" .. view:attr("name") .. "]"):delete()
end)
		   
local pathContextType = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\user\\AutoLoad"
local fileTable = syncProfile.attrdir(pathContextType)
for i,v in pairs(fileTable) do
	local profileNameStart = string.find(v, "/")
	local profileName = string.sub(v, profileNameStart+1, string.len(v)-4)

	local profile = lQuery("AA#Profile[name='" .. profileName .. "']")
	--izdzest AA# Dalu
	lQuery(profile):find("/field"):each(function(obj)
		profileMechanism.deleteField(obj)
	end)
	--saglabajam stilus
	lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
		utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
	end)
	--palaist sinhronizaciju
	syncProfile.syncProfile(profileName)
	viewMechanism.deleteViewFromProfile(profileName)
		--izdzest profilu, extension
	lQuery(profile):delete()
	lQuery("Extension[id='" .. profileName .. "'][type='aa#Profile']"):delete()
end

lQuery.model.add_property("AA#View", "showInToolBar")

completeMetamodel.loudAutoLoudProfiles(pathContextType)



lQuery("AA#View[showInToolBar='true']"):each(function(view)
	--local view = lQuery("AA#Profile[name='PaletteViews']/view[name='CompactHorizontalView']")
	--local view = lQuery("AA#Profile[name='PaletteViews']/view[name='Horizontal']")
	local owl_dgr_type = lQuery("GraphDiagramType[id=OWL]")
	local toolbarTypeOwl = owl_dgr_type:find("/toolbarType")
	if toolbarTypeOwl:is_empty() then
	  toolbarTypeOwl = lQuery.create("ToolbarType", {graphDiagramType = owl_dgr_type})
	end
		
	local view_manager_toolbar_el = lQuery.create("ToolbarElementType", {
		toolbarType = toolbarTypeOwl,
		id = view:id(),
		caption = view:attr("name"),
		picture = view:attr("inActiveIcon"),
		procedureName = "OWLGrEd_UserFields.styleMechanism.applyViewFromToolBar"
	})	
end)

configurator.make_toolbar(lQuery("GraphDiagramType[id=projectDiagram]"))
configurator.make_toolbar(lQuery("GraphDiagramType[id=OWL]"))

lQuery.create("PopUpElementType", {id="Style Palette", caption="Style Palette", nr=5, visibility=true, procedureName="OWLGrEd_UserFields.stylePalette.stylePaletteProgect"})
		:link("popUpDiagramType", lQuery("GraphDiagramType[id='projectDiagram']/rClickEmpty"))


		
--0.3
lQuery("AA#TransletTask"):delete()


lQuery.create("AA#TransletTask", {
							taskName = "procFieldEntered"})
lQuery.create("AA#TransletTask", {
							taskName = "procCompose"})
lQuery.create("AA#TransletTask", {
							taskName = "procDecompose"})
lQuery.create("AA#TransletTask", {
							taskName = "procGetPattern"})
lQuery.create("AA#TransletTask", {
							taskName = "procCheckCompartmentFieldEntered"})
lQuery.create("AA#TransletTask", {
							taskName = "procBlockingFieldEntered"})
lQuery.create("AA#TransletTask", {
							taskName = "procGenerateInputValue"})
lQuery.create("AA#TransletTask", {
							taskName = "procGenerateItemsClickBox"})
lQuery.create("AA#TransletTask", {
							taskName = "procForcedValuesEntered"})
lQuery.create("AA#TransletTask", {
							taskName = "procDeleteCompartmentDomain"})
lQuery.create("AA#TransletTask", {
							taskName = "procUpdateCompartmentDomain"})
lQuery.create("AA#TransletTask", {
							taskName = "procCreateCompartmentDomain"})							


lQuery.model.delete_property("AA#Tag", "axiomPattern")
lQuery.model.add_property("AA#Tag", "tagValue")

--]]

							
return true
-- return false, error_string