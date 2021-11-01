module(..., package.seeall)

require("lQuery")
local configurator = require("configurator.configurator")

function addUserFieldsToolbarElements()
	local project_dgr_type = lQuery("GraphDiagramType[id=projectDiagram]")
	local owl_dgr_type = lQuery("GraphDiagramType[id=OWL]")

	-- get or create toolbar type
	local toolbarType = project_dgr_type:find("/toolbarType")
	if toolbarType:is_empty() then
	  toolbarType = lQuery.create("ToolbarType", {graphDiagramType = project_dgr_type})
	end

	local toolbarTypeOwl = owl_dgr_type:find("/toolbarType")
	if toolbarTypeOwl:is_empty() then
	  toolbarTypeOwl = lQuery.create("ToolbarType", {graphDiagramType = owl_dgr_type})
	end

	-- add plugin manager toolbar element
	local pl_manager_toolbar_el = lQuery.create("ToolbarElementType", {
	  toolbarType = toolbarType,
	  id = "OWLGrEd_UserFields_Toolbar_Element",
	  caption = "Profiles in project",
	  picture = "OWLGrEd_UserFields_aa.bmp",
	  procedureName = "OWLGrEd_UserFields.profileMechanism.profileMechanism"
	})

	local pl_manager_toolbar_el = lQuery.create("ToolbarElementType", {
	  toolbarType = toolbarType,
	  id = "OWLGrEd_UserFields_Toolbar_Element_View",
	  caption = "Views in profiles",
	  picture = "OWLGrEd_UserFields_aaView.bmp",
	  procedureName = "OWLGrEd_UserFields.viewMechanism.viewsForToolBar"
	})

	local view_manager_toolbar_el = lQuery.create("ToolbarElementType", {
	  toolbarType = toolbarTypeOwl,
	  id = "OWLGrEd_UserFields_View_Toolbar_Element",
	  caption = "Views in diagram",
	  picture = "OWLGrEd_UserFields_aaView.bmp",
	  procedureName = "OWLGrEd_UserFields.styleMechanism.viewsInDiagram"
	})

	-- refresh project diagram toolbar
	configurator.make_toolbar(project_dgr_type)
	configurator.make_toolbar(owl_dgr_type)
end

function addUserFieldsStylePalette()
	local project_dgr_type = lQuery("GraphDiagramType[id=projectDiagram]")
	local owl_dgr_type = lQuery("GraphDiagramType[id=OWL]")

	-- get or create toolbar type
	local toolbarType = project_dgr_type:find("/toolbarType")
	if toolbarType:is_empty() then
	  toolbarType = lQuery.create("ToolbarType", {graphDiagramType = project_dgr_type})
	end

	local toolbarTypeOwl = owl_dgr_type:find("/toolbarType")
	if toolbarTypeOwl:is_empty() then
	  toolbarTypeOwl = lQuery.create("ToolbarType", {graphDiagramType = owl_dgr_type})
	end
	
	local pl_manager_toolbar_el = lQuery.create("ToolbarElementType", {
	  toolbarType = toolbarType,
	  id = "OWLGrEd_UserFields_Toolbar_Element_Styles",
	  caption = "Style Palette",
	  picture = "OWLGrEd_UserFields_aaStyles.bmp",
	  procedureName = "OWLGrEd_UserFields.stylePalette.stylePaletteProgect"
	})

	local view_manager_toolbar_el = lQuery.create("ToolbarElementType", {
	  toolbarType = toolbarTypeOwl,
	  id = "OWLGrEd_UserFields_Toolbar_Element_Styles_Dia",
	  caption = "Style Palette",
	  picture = "OWLGrEd_UserFields_aaStyles.bmp",
	  procedureName = "OWLGrEd_UserFields.stylePalette.stylePaletteOWL"
	})
	-- refresh project diagram toolbar
	configurator.make_toolbar(project_dgr_type)
	configurator.make_toolbar(owl_dgr_type)
end

function removeUserFieldsToolbarElements()
	-- delete toolbar element
	lQuery("ToolbarElementType[id=OWLGrEd_UserFields_Toolbar_Element]"):delete()
	lQuery("ToolbarElementType[id=OWLGrEd_UserFields_Toolbar_Element_View]"):delete()
	lQuery("ToolbarElementType[id=OWLGrEd_UserFields_View_Toolbar_Element]"):delete()
	-- refresh project diagram
	configurator.make_toolbar(lQuery("GraphDiagramType[id=projectDiagram]"))
	configurator.make_toolbar(lQuery("GraphDiagramType[id=OWL]"))
end

function removeUserFieldsStylePalette()
	-- delete toolbar element
	lQuery("ToolbarElementType[id=OWLGrEd_UserFields_Toolbar_Element_Styles]"):delete()
	lQuery("ToolbarElementType[id=OWLGrEd_UserFields_Toolbar_Element_Styles_Dia]"):delete()
	-- refresh project diagram
	configurator.make_toolbar(lQuery("GraphDiagramType[id=projectDiagram]"))
	configurator.make_toolbar(lQuery("GraphDiagramType[id=OWL]"))
end