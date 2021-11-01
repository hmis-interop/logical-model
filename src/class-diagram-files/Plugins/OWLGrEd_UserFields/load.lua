require("lQuery")
local configurator = require("configurator.configurator")
local utils = require "plugin_mechanism.utils"
local completeMetamodel = require "OWLGrEd_UserFields.completeMetamodel"
local completeMetamodelOWLGrEdSpecific = require "OWLGrEd_UserFields.completeMetamodelOWLGrEdSpecific"

-- copy icon to pictures
local path
local picturePath

if tda.isWeb then 
	path = tda.FindPath(tda.GetToolPath() .. "/AllPlugins", "OWLGrEd_UserFields") .. "/"
	picturePath = tda.GetToolPath().. "/web-root/Pictures/"
else
	path = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\"
	picturePath = tda.GetProjectPath() .. "\\Pictures\\"
end

utils.copy(path .. "aa.bmp",
           picturePath .. "OWLGrEd_UserFields_aa.bmp")
		   
utils.copy(path ..  .. "aaView.bmp",
           picturePath .. "OWLGrEd_UserFields_aaView.bmp")

utils.copy(path ..  .. "aaStyles.bmp",
            picturePath .. "OWLGrEd_UserFields_aaStyles.bmp")

			local project_dgr_type = lQuery("GraphDiagramType[id=projectDiagram]")
-- local owl_dgr_type = lQuery("GraphDiagramType[id=OWL]")-----------------------------------------------------

-- get or create toolbar type
local toolbarType = project_dgr_type:find("/toolbarType")
if toolbarType:is_empty() then
  toolbarType = lQuery.create("ToolbarType", {graphDiagramType = project_dgr_type})
end

--complete metamodel
completeMetamodel.completeMetamodel()
completeMetamodelOWLGrEdSpecific.completeMetamodel()

-- refresh project diagram toolbar
configurator.make_toolbar(project_dgr_type)
-- configurator.make_toolbar(owl_dgr_type)---------------------------------------------------------------



return true
-- return false, error_string