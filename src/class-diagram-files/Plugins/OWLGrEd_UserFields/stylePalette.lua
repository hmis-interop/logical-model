module(..., package.seeall)

require("lua_tda")
require "lpeg"
require "core"
-- require "progress_reporter"
require "dialog_utilities"

local owl_fields_specific = require "OWLGrEd_UserFields.owl_fields_specific"
local profileMechanism = require "OWLGrEd_UserFields.profileMechanism"
local styleMechanism = require "OWLGrEd_UserFields.styleMechanism"
local configurator = require "configurator.configurator"
require("graph_diagram_style_utils")


function stylePaletteProgect()
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.stylePalette.close()")
  })

  local custom_views = lQuery.create("D#Button", {
    caption = "Manage views and profiles"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.stylePalette.CustomViews()")
  })
  
  local form = lQuery.create("D#Form", {
    id = "stylePalette"
    ,caption = "Style Palette"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.stylePalette.close()")
	,component = {
		lQuery.create("D#HorizontalBox", {
			horizontalAlignment = -1
			,component = { 
				lQuery.create("D#Label", {caption = "Views in Palette:"})
			}
		})
		,lQuery.create("D#HorizontalBox", {
			id = "HorFormStylePalette"
			--,minimumWidth = 300
			,topMargin = 10
			,component = { 
				createRowsForViews()
			}
		})
      ,lQuery.create("D#HorizontalBox", {
       -- horizontalAlignment = 1
		id = "closeForm"
		,topMargin = 15
        ,component = {
		  custom_views
		  ,close_button
		  }
      })
    }
  })
  dialog_utilities.show_form(form)
end

function stylePaletteOWL()
		local close_button = lQuery.create("D#Button", {
    caption = "Close"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.stylePalette.close()")
  })

  local custom_views = lQuery.create("D#Button", {
    caption = "All views"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.stylePalette.CustomViews()")
  })
  
  
  local form = lQuery.create("D#Form", {
    id = "stylePalette"
    ,caption = "Style Palette"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.stylePalette.close()")
	,component = {
		lQuery.create("D#HorizontalBox", {
			id = "HorForm"
			,minimumWidth = 250
			,component = { 
				createRowsForViewsOWL()
			}
		})
      ,lQuery.create("D#HorizontalBox", {
       -- horizontalAlignment = 1
		id = "closeForm"
        ,component = {
		  custom_views
		  ,close_button
		  }
      })
    }
  })
  dialog_utilities.show_form(form)
end

function createRowsForViewsOWL()
	--local values = lQuery("AA#Profile[name='PaletteViews']/view"):map(
	local values = lQuery("AA#View[showInPalette='true']"):map(
	  function(obj)
		return {obj:attr("name"), obj:attr("isDefault"), obj:attr("inActiveIcon"), obj:id()}
	end)  

	local diagram = utilities.current_diagram()
	return lQuery.map(values, function(obj) 
		local checked
		local ext = lQuery("Extension[type='aa#View'][id='" .. obj[1] .. "']") 
		local l = 0
			ext:find("/graphDiagram"):each(function(gd)
				if gd:id() ==diagram:id() then
					l=1
				end
			end)
			if l == 1 then
				checked="true"
			end
			if obj[2]=="true" then 
				local l=0
				local diaWithView = ext:find("/aa#graphDiagram"):each(function(dia)
					if dia:id()==diagram:id() then l=1 end
				end)
				if l==0 then checked="true" end
			end
		return lQuery.create("D#Row", {component={
			lQuery.create("D#Label", {caption=obj[1]})
			--,lQuery.create("D#ImageButton", {fileName = tda.GetProjectPath() .. "\\Pictures\\" .. obj[3]})
			,lQuery.create("D#Label", {caption="Apply"})
			,lQuery.create("D#CheckBox", {
				id=obj[4]
				,editable = "true" 
				,checked = checked
				,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.stylePalette.applyView()")}})
		}})
	end)
end

function createRowsForViews()
	--local values = lQuery("AA#Profile[name='PaletteViews']/view"):map(
	local values = lQuery("AA#View[showInPalette='true']"):map(
	  function(obj)
		return {obj:attr("name"), obj:attr("isDefault"), obj:attr("inActiveIcon"), obj:id()}
	  end)  
	
	return lQuery.map(values, function(obj) 
		return lQuery.create("D#Row", {id = obj[4],component={
			lQuery.create("D#Label", {caption=obj[1]})
			--,lQuery.create("D#ImageButton", {fileName = tda.GetProjectPath() .. "\\Pictures\\" .. obj[3]})
			
			,lQuery.create("D#CheckBox", {
				id=obj[4]
				,editable = "true" 
				,checked = obj[2]
				,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.stylePalette.setAsDefault()")}})
			,lQuery.create("D#Label", {caption="Default (for new diagrams)"})
		}})
	end)
end

function applyView()
	-- tda.CallFunctionWithPleaseWaitWindow("OWLGrEd_UserFields.stylePalette.applyViewProgressBar")
	applyViewProgressBar()
	--utilities.execute_cmd("AfterConfigCmd", {graphDiagram = diagram})
end

function applyViewProgressBar()
	
	-- print("--------- START applyViewProgressBar")
	-- print(os.date("%m_%d_%Y_%H_%M_%S"))
	--local focus = lQuery("D#Event/source"):attr("id")
	local checked = lQuery("D#Event/source"):attr("checked")
	local diagram = utilities.current_diagram()
--	print("111")
	utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
	local viewId = lQuery("D#Event/source"):attr("id")
	local viewV = lQuery("AA#View"):filter(
		function(obj)
			return lQuery(obj):id() == tonumber(viewId)
		end)
	local view
		--atrast view exteision
	view = lQuery("Extension[id='" .. viewV:attr("name") .. "'][type='aa#View']")
	
	--print("222")
	local el = lQuery(diagram):find("/element:has(/elemType/elementStyleSetting)"):filter(function(obj)
		local l = 0
		local ex = obj:find("/elemType/elementStyleSetting/extension"):each(function(ext)
			if ext:id() == view:id() then l =1 end
		end)
		return l == 1
	end)
	local values = lQuery(diagram):find("/element/compartment:has(/compartType/compartmentStyleSetting)")
	values = values:add(lQuery(diagram):find("/element/compartment/subCompartment:has(/compartType/compartmentStyleSetting)"))
	values = values:filter(function(obj)
		local l = 0
		local ex = obj:find("/compartType/compartmentStyleSetting/extension"):each(function(ext)
			if ext:id() == view:id() then l =1 end
		end)
		return l == 1
	end)
	--print("333")
	local numberOfSteps = el:size()
	
	numberOfSteps = numberOfSteps + values:size()
	
	-- local progress_reporter = progress_reporter.create_progress_logger(numberOfSteps, "Recalculating styles...")
	
	--print("444")
	if checked=="true" then
		-- print("--------- APPLY VIEW")
	--	print("444aaa")
		--atrast view exteision
		view = lQuery("Extension[id='" .. viewV:attr("name") .. "'][type='aa#View']")
		--izveidot saiti uz diagramu
		if lQuery("AA#View[name='" .. view:attr("id") .. "']"):attr("isDefault") == "true" then view:remove_link("aa#graphDiagram", diagram) 
		else
			local view_table = diagram:find("/activeExtension")
			diagram:remove_link("activeExtension", diagram:find("/activeExtension"))
			
			view:link("graphDiagram", diagram)
			view_table:each(function(v)
				v:link("graphDiagram", diagram)
			end)
		end
		--pielieto view
		if view~=nil and view:find("/elementStyleSetting"):is_not_empty() then
			-- print("--------- ELEMENT STYLE SETTING")
			local el = lQuery(diagram):find("/element:has(/elemType/elementStyleSetting)"):filter(function(obj)
				local l = 0
				local ex = obj:find("/elemType/elementStyleSetting/extension"):each(function(ext)
					if ext:id() == view:id() then l =1 end
				end)
				return l == 1
			end)
			el:each(function(obj)
				-- progress_reporter()
				-- print("--------- START owl_fields_specific.ElemStyleBySettings")
				owl_fields_specific.ElemStyleBySettings(obj, "ViewApply")
				-- print("--------- END owl_fields_specific.ElemStyleBySettings")
			end)
		end
		if view~=nil and view:find("/compartmentStyleSetting"):is_not_empty() then
			-- print("--------- COMPARTMENT STYLE SETTING")
			local values = lQuery(diagram):find("/element/compartment:has(/compartType/compartmentStyleSetting)")
			values = values:add(lQuery(diagram):find("/element/compartment/subCompartment:has(/compartType/compartmentStyleSetting)"))
			values = values:filter(function(obj)
				local l = 0
				local ex = obj:find("/compartType/compartmentStyleSetting/extension"):each(function(ext)
					if ext:id() == view:id() then l =1 end
				end)
				return l == 1
			end)
			values:each(function(obj)
				-- progress_reporter()
				-- print("--------- START owl_fields_specific.CompartStyleBySetting")
				owl_fields_specific.CompartStyleBySetting(obj, "ViewApply")
				-- print("--------- END owl_fields_specific.CompartStyleBySetting")
			end)
		end
		
		--nomainit pogu uz pielietotu ikonu
		--print(lQuery("ToolbarElementType[id='" .. viewV:id() .. "']"):size())
		local diagram = utilities.current_diagram()

		diagram:find("/toolbar/toolbarElement:has(/type[id='" .. viewV:id() .. "'])"):attr("picture", viewV:attr("activeIcon"))
--		utilities.execute_cmd("AfterConfigCmd", {graphDiagram = diagram})
		
		--lQuery("ToolbarElementType[id='" .. viewV:id() .. "']"):attr("picture", viewV:attr("activeIcon"))
		--configurator.make_toolbar(lQuery("GraphDiagramType[id=OWL]"))
	else
		-- print("--------- RAMOVE VIEW")
		--ja nonemts noklusetais stils
		view:remove_link("graphDiagram", diagram)
		if lQuery("AA#View[name='" .. view:attr("id") .. "']"):attr("isDefault") == "true" then view:link("aa#graphDiagram", diagram) end

		--pielieto view
		if view~=nil and view:find("/elementStyleSetting"):is_not_empty() then
			-- print("--------- ELEMENT STYLE SETTING")
			local el = lQuery(diagram):find("/element:has(/elemType/elementStyleSetting)"):filter(function(obj)
				local l = 0
				local ex = obj:find("/elemType/elementStyleSetting/extension"):each(function(ext)
					if ext:id() == view:id() then l =1 end
				end)
				return l == 1
			end)
			el:each(function(obj)
				-- progress_reporter()
				-- print("--------- START owl_fields_specific.ElemStyleBySettings")
				owl_fields_specific.ElemStyleBySettings(obj, "ViewRemove", view)
				-- print("--------- END owl_fields_specific.ElemStyleBySettings")
			end)
		end
		if view~=nil and view:find("/compartmentStyleSetting"):is_not_empty() then
		-- print("--------- COMPARTMENT STYLE SETTING")
			local values = lQuery(diagram):find("/element/compartment:has(/compartType/compartmentStyleSetting)")
			values = values:add(lQuery(diagram):find("/element/compartment/subCompartment:has(/compartType/compartmentStyleSetting)"))
			values = values:filter(function(obj)
				local l = 0
				local ex = obj:find("/compartType/compartmentStyleSetting/extension"):each(function(ext)
					if ext:id() == view:id() then l =1 end
				end)
				return l == 1
			end)
			values:each(function(obj)
				-- progress_reporter()
				-- print("--------- START owl_fields_specific.CompartStyleBySetting")
				owl_fields_specific.CompartStyleBySetting(obj,"ViewRemove", view)
				-- print("--------- END owl_fields_specific.CompartStyleBySetting")
			end)
		end
		--nomainit pogu uz pielietotu ikonu
		local diagram = utilities.current_diagram()

		diagram:find("/toolbar/toolbarElement:has(/type[id='" .. viewV:id() .. "'])"):attr("picture", viewV:attr("inActiveIcon"))
--		utilities.execute_cmd("AfterConfigCmd", {graphDiagram = diagram})
		--lQuery("ToolbarElementType[id='" .. viewV:id() .. "']"):attr("picture", viewV:attr("inActiveIcon"))
		--configurator.make_toolbar(lQuery("GraphDiagramType[id=OWL]"))
	end
	
	--atjaunojam tos elementus, kur bija stila izmaina
	local elem = lQuery(diagram):find("/element:has(/compartment/compartType/compartmentStyleSetting)")
	elem:add(lQuery(diagram):find("/element:has(/compartment/subCompartment/compartType/compartmentStyleSetting)"))
		
	-- setCompartmentValueWithTextStyle(diagram:find("/element/compartment"))
	
	lQuery("Compartment:has(/compartType/compartmentStyleSetting[procCondition='setTextStyle'])"):each(function(obj)
		local dia = core.get_compartment_element(obj):find("/graphDiagram")
		if dia:id()== diagram:id() then
			core.make_compart_value_from_sub_comparts(obj)
			-- print("--------- core.make_compart_value_from_sub_comparts")
			core.set_parent_value(obj)
			-- print("--------- core.set_parent_value")
		end
	end)

	utilities.refresh_element(elem, diagram) 
		
	local cmd = lQuery.create("OkCmd")
	cmd:link("graphDiagram", diagram)
	utilities.execute_cmd_obj(cmd)
	styleMechanism.deleteIsDeletedStyleSetting()
	
	graph_diagram_style_utils.save_diagram_element_and_compartment_styles(diagram)
	
	-- print("--------- deleteIsDeletedStyleSetting")
	
	if view:find("/elementStyleSetting[setting='lineDirection']"):is_not_empty() then 
		require("lua_graphDiagram")
		lua_graphDiagram.SetDiagramAlignmentStyle(utilities.current_diagram():id(), 3)
	end
	 -- print("--------- END applyViewProgressBar")
end

function setCompartmentValueWithTextStyle(compartments)
	compartments:each(function(obj)
		if obj:find("/compartType/compartmentStyleSetting[procCondition='setTextStyle']"):is_not_empty() then
			core.make_compart_value_from_sub_comparts(obj)
			-- print("--------- core.make_compart_value_from_sub_comparts")
			print("kkkkk", obj:find("/compartType/parentCompartType"):attr("id"), obj:attr("value"))
			core.set_parent_value(obj)
		end
	end)
	setCompartmentValueWithTextStyle(compartments:find("/subCompartment"))
end

function CustomViews()
	local graphDiagramType = utilities.current_diagram():find("/graphDiagramType"):attr("id")
	if graphDiagramType == "projectDiagram" then 
		profileMechanism.profileMechanism()
	else
		styleMechanism.viewsInDiagram()
	end
end

function setAsDefault()
	local focus = lQuery("D#Event/source"):attr("id")
	local checked = lQuery("D#Event/source"):attr("checked")
	local view = lQuery("AA#View"):filter(function(obj)
			return obj:id() == tonumber(focus)
		end)
	view:attr("isDefault", checked)
end

function close()
  lQuery("D#Event"):delete()
  utilities.close_form("stylePalette")
end