module(..., package.seeall)

require("lua_tda")
require "lpeg"
require "core"
syncProfile = require "OWLGrEd_UserFields.syncProfile"
styleMechanism = require "OWLGrEd_UserFields.styleMechanism"
addRemoveToolbarElements = require "OWLGrEd_UserFields.addRemoveToolbarElements"
axiom = require "OWLGrEd_UserFields.axiom"

function completeMetamodel()
	local path
	local picturePath

	if tda.isWeb then 
		path = tda.FindPath(tda.GetToolPath() .. "/AllPlugins", "OWLGrEd_UserFields") .. "/"
		picturePath = tda.GetToolPath().. "/web-root/Pictures/"
	else
		path = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\"
		picturePath = tda.GetProjectPath() .. "\\Pictures\\"
	end
	
	utils.copy(path .. "aaViewHorizontal.bmp",-------------------
           picturePath .. "OWLGrEd_UserFields_aaViewHorizontal.bmp")-------------------
		   
	utils.copy(path .. "aaViewHorizontalActivated.bmp",----------
			   picturePath .. "OWLGrEd_UserFields_aaViewHorizontalActivated.bmp")----------
			   
	utils.copy(path .. "aaViewVertical.bmp",---------------------
			   picturePath .. "OWLGrEd_UserFields_aaViewVertical.bmp")---------------------
			   
	utils.copy(path .. "aaViewVerticalActivated.bmp",------------
			   picturePath .. "OWLGrEd_UserFields_aaViewVerticalActivated.bmp")------------
			   
	utils.copy(path .. "aaHideAnnotationsActivated.bmp",---------
			   picturePath .. "OWLGrEd_UserFields_aaHideAnnotationsActivated.bmp")---------
			   
	utils.copy(path .. "aaHideAnnotations.bmp",------------------
           picturePath .. "OWLGrEd_UserFields_aaHideAnnotations.bmp")------------------
	
	local owl_dgr_type = lQuery("GraphDiagramType[id=OWL]")
	
	local toolbarTypeOwl = owl_dgr_type:find("/toolbarType")------------------------------------------------------
	if toolbarTypeOwl:is_empty() then-----------------------------------------------------------------------------
	  toolbarTypeOwl = lQuery.create("ToolbarType", {graphDiagramType = owl_dgr_type})----------------------------
	end--
	
	configurator.make_toolbar(owl_dgr_type)---------------------------------------------------------------
	
	
	
	
	local pat = lpeg.P("keepOriginalIsCompositionField") * lpeg.S(" \n\t") ^ 0 * lpeg.P("=") * lpeg.S(" \n\t") ^ 0 * lpeg.C(lpeg.R("09"))-------------
	local pat = anywhere(pat)-------------------------------------------------------------------------------------------------------------------------
	local resultKeepOriginalIsCompositionField = lpeg.match(pat, t)-----------------------------------------------------------------------------------
	
	lQuery.create("AA#ContextType", {
							nr = 01
							,type = "Class"
							,mode = "Element"
							,id = "Class"
							}):link("configuration", lQuery("AA#Configuration"))
	lQuery.create("AA#ContextType", {
							nr = 02
							,type = "Role"
							,elTypeName = "Association"
							,mode = "Group"
							,hasMirror = 1
							,id = "Association/Role"
							}):link("configuration", lQuery("AA#Configuration"))
	lQuery.create("AA#ContextType", {
							nr = 03
							,type = "Attributes"
							,elTypeName = "Class"
							,mode = "Group Item"
							,id = "Class/Attributes"
							}):link("configuration", lQuery("AA#Configuration"))
	lQuery.create("AA#ContextType", {
							nr = 04
							,type = "Object"
							,mode = "Element"
							,id = "Object"
							}):link("configuration", lQuery("AA#Configuration"))
							
	lQuery.create("AA#RowType", {
							typeName = "InputField"})
	lQuery.create("AA#RowType", {
							typeName = "InputField+Button"})
	lQuery.create("AA#RowType", {
							typeName = "CheckBox"})
	lQuery.create("AA#RowType", {
							typeName = "ComboBox"})
	lQuery.create("AA#RowType", {
							typeName = "ListBox"})
	lQuery.create("AA#RowType", {
							typeName = "TextArea"})
	lQuery.create("AA#RowType", {
							typeName = "TextArea+Button"})
	lQuery.create("AA#RowType", {
							typeName = ""})
							
							
	--paslepjam IsComposition
	if resultKeepOriginalIsCompositionField=="0" then----------------------------------------------------------------------------------------------------------
		lQuery("CompartType[caption='IsComposition']"):attr("shouldBeIncluded", "OWLGrEd_UserFields.owl_fields_specific.hide_for_OWL_Fields")------------------
		lQuery("CompartType[caption='IsComposition']/propertyRow"):attr("shouldBeIncluded", "OWLGrEd_UserFields.owl_fields_specific.hide_for_OWL_Fields")------
		lQuery("Compartment:has(/compartType[caption='IsComposition'])"):delete()------------------------------------------------------------------------------
		lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)-------------------------------------------------------------------------
			local cmd = lQuery.create("OkCmd")-----------------------------------------------------------------------------------------------------------------
			cmd:link("graphDiagram", diagram)------------------------------------------------------------------------------------------------------------------
			utilities.execute_cmd_obj(cmd)---------------------------------------------------------------------------------------------------------------------
		end)---------------------------------------------------------------------------------------------------------------------------------------------------
	end--------------------------------------------------------------------------------------------------------------------------------------------------------
	
	--pievienojam tagus pie toolType prieks importa/eksporta
	lQuery.create("Tag", {value = "OWLGrEd_UserFields.axiom.axiom", key = "owlgred_export"}):link("type", lQuery("ToolType"))
	lQuery.create("Tag", {value = "owlFields:=<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#>", key = "owl_NamespaceDef"}):link("type", lQuery("ToolType"))
	lQuery.create("Tag", {value = "owlgred:=<http://lumii.lv/2011/1.0/owlgred#>", key = "owl_NamespaceDef"}):link("type", lQuery("ToolType"))
	lQuery.create("Tag", {key = "owl_Annotation_Import"}):link("type", lQuery("ToolType"))
	lQuery.create("Tag", {key = "owl_Import_Prefixes"}):link("type", lQuery("ToolType"))
	lQuery.create("Translet", {extensionPoint='RecalculateStylesInImport', procedureName='OWLGrEd_UserFields.owl_fields_specific.setImportStyles'}):link("type", lQuery("ToolType"))
	
	
	--savienojam tiesos un inversos compartType
	local compartTypeRole = lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType"):each(function(ct)
		local compatTypeInv = lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id = '" .. ct:attr("id") .. "']"):link("aa#mirrorInv", ct)
	end)
	
	local compartTypeRole = lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType/subCompartType"):each(function(ct)
		local compatTypeInv = lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType/subCompartType[id = '" .. ct:attr("id") .. "']"):link("aa#mirrorInv", ct)
	end)

	local compartTypeLink = lQuery("ElemType[id='Link']/compartType[id='Direct']/subCompartType"):each(function(ct)
		local compatTypeInv = lQuery("ElemType[id='Link']/compartType[id='Inverse']/subCompartType[caption = '" .. ct:attr("caption") .. "']"):link("aa#mirrorInv", ct)
	end)
	
	lQuery("ElemType[id='Association']/compartType[id='Role']"):link("aa#mirror", lQuery("ElemType[id='Association']/compartType[id='InvRole']"))
	lQuery("ElemType[id='Link']/compartType[id='Direct']"):link("aa#mirror", lQuery("ElemType[id='Link']/compartType[id='Inverse']"))
	
	local dependentStylesTable = styleMechanism.dependentStylesTable()
	for i,v in pairs(dependentStylesTable) do
		local pathTable = styleMechanism.split(v[1], "/")
		local elem--lauks kuram ir translets
		for j,b in pairs(pathTable) do
			if j == 1 then elem = lQuery("ElemType[id='" .. b  .. "']")
			elseif j == 2 then elem = elem:find("/compartType[id='" .. b .. "']")
			else
				elem = elem:find("/subCompartType[id='" .. b .. "']")
			end
		end
		elem:find("/translet[extensionPoint='procFieldEntered']"):attr("procedureName", "OWLGrEd_UserFields.owl_fields_specific.setDependentStyleSetting")
	end
	
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
	
	lQuery.create("PopUpElementType", {id="Style Palette", caption="Style Palette", nr=10, visibility=true, procedureName="OWLGrEd_UserFields.stylePalette.stylePaletteOWL"})
		:link("popUpDiagramType", lQuery("GraphDiagramType[id='OWL']/rClickEmpty"))
	
end




function anywhere (p)
  return lpeg.P{ p + 1 * lpeg.V(1) }
end
