module(..., package.seeall)

require("lua_tda")
require "lpeg"
require "core"
require "dialog_utilities"
joProfile = require "OWLGrEd_UserFields.Profile"
syncProfile = require "OWLGrEd_UserFields.syncProfile"
styleMechanism = require "OWLGrEd_UserFields.styleMechanism"
owl_fields_specific = require "OWLGrEd_UserFields.owl_fields_specific"
profileMechanism = require "OWLGrEd_UserFields.profileMechanism"
serialize = require "serialize"
local configurator = require("configurator.configurator")
require("graph_diagram_style_utils")

--atver formu ar skatijumu sarakstu un navigaciju
function viewMechanism()
	local selectedItem = lQuery("D#ListBox[id='ListWithProfiles']/selected")
	if selectedItem:is_not_empty() then
		local profileName = selectedItem:attr("value")
		local viewSize = string.find(profileName, " ")
		if viewSize~=nil then profileName = string.sub(profileName, 1, viewSize-1) end
		local close_button = lQuery.create("D#Button", {
		caption = "Close"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.close()")
	  })
	  
	  local path
	  if tda.isWeb then
			path = tda.FindPath(tda.GetToolPath() .. "/AllPlugins", "OWLGrEd_UserFields") .. "/"
	  else
			path = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\"
	  end
	  
	  local form = lQuery.create("D#Form", {
		id = "viewsInProfile"
		,caption = "Views in Profile"
		,buttonClickOnClose = false
		,cancelButton = close_button
		,defaultButton = close_button
		,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.close()")
		,component = {
			lQuery.create("D#VerticalBox",{
				component = {
					lQuery.create("D#HorizontalBox"	,{
						minimumWidth = 350
						,minimumHeight = 250
						,component = {
							lQuery.create("D#VerticalBox", {
								id = "VerticalBoxWithListBoxView"
								,component = {
									lQuery.create("D#ListBox", {
										id = "ListWithViews"
										,item = collectViews(profileName)
									})
								}
							})
							,lQuery.create("D#VerticalBox", {
								component = {
									lQuery.create("D#ImageButton",{
										fileName = path .. "up.bmp"
										,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.upView()")
									})
									,lQuery.create("D#ImageButton",{
										fileName = path .. "down.bmp"
										,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.downView()")
									})
								}
							})
							,lQuery.create("D#VerticalBox", {
								component = {
									lQuery.create("D#Button", {
										caption = "Properties"
										,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.openViewProperties()")
									})
									,lQuery.create("D#Button", {
										caption = "Apply by default"
										,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.setDefault()")
									})
									,lQuery.create("D#Button", {
										caption = "New view"
										,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.newView()")
									})
									,lQuery.create("D#Button", {
										caption = "Delete"
										,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.deleteView()")
									})
								}
							})
						}
					})
				}
			})
			,lQuery.create("D#HorizontalBox", {
			id = "closeButton"
			,horizontalAlignment = 1
			,component = {close_button}})
		}
	  })
	  dialog_utilities.show_form(form)
	end
end

--atlasa visus profila skatijumus
function collectViews(profile)
	if profile~=nil then 
		local values = lQuery("AA#Profile[name='" .. profile .. "']"):find("/view"):map(
		  function(obj)
			return {lQuery(obj):attr("name"), lQuery(obj):attr("isDefault")}
		  end)  
		
		return lQuery.map(values, function(view) 
			local value = view[1]
			if view[2]=="true" then value = value .. " (Default)" end
			return lQuery.create("D#Item", {
				value = value
			}) 
		end)
	end
end

--uzstada/nonem pazimi, ka skatijums ir noklusets
function setDefault()
	local selectedItem = lQuery("D#ComboBox[id='ListWithProfilesForViews']/selected")
	if selectedItem:is_empty() then selectedItem=lQuery("D#ListBox[id='ListWithProfiles']/selected") end
	local selectedItem = lQuery("D#ListBox[id='ListWithViews']/selected")
	if selectedItem:is_not_empty() then
		local viewSize = string.find(selectedItem:attr("value"), " ")
		local viewName = selectedItem:attr("value")
		if viewSize~=nil then viewName = string.sub(viewName, 1, viewSize-1) end
		local default = lQuery("AA#View[name='" .. viewName .. "']"):attr("isDefault")
		if default=="true" then 
			lQuery("AA#View[name='" .. viewName .. "']"):attr("isDefault", "false")	
			lQuery("GraphDiagramType[id='OWL']/graphDiagram"):each(function(diagram)
				--nomem view
				local view=lQuery("Extension[type='aa#View'][id='" .. viewName .. "']")
				if view~=nil and view:find("/elementStyleSetting"):is_not_empty() then
					local el = lQuery(diagram):find("/element:has(/elemType/elementStyleSetting)"):filter(function(obj)
						local l = 0
						local ex = obj:find("/elemType/elementStyleSetting/extension"):each(function(ext)
							if ext:id() == view:id() then l =1 end
						end)
						return l == 1
					end)
					el:each(function(obj)
						owl_fields_specific.ElemStyleBySettings(obj, "ViewRemove", view)
					end)
				end
				if view~=nil and view:find("/compartmentStyleSetting"):is_not_empty() then
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
						owl_fields_specific.CompartStyleBySetting(obj,"ViewRemove", view)
					end)
				end
				
				--atjaunojam tos elementus, kur bija stila izmaina
				local elem = lQuery(diagram):find("/element:has(/compartment/compartType/compartmentStyleSetting)")
				elem:add(lQuery(diagram):find("/element:has(/compartment/subCompartment/compartType/compartmentStyleSetting)"))
				
				lQuery("Compartment:has(/compartType/compartmentStyleSetting[procCondition='setTextStyle'])"):each(function(obj)
					core.set_parent_value(obj) 
				end)
				
				utilities.refresh_element(elem, diagram) 
				
				local cmd = lQuery.create("OkCmd")
				cmd:link("graphDiagram", diagram)
				utilities.execute_cmd_obj(cmd)
				
				graph_diagram_style_utils.save_diagram_element_and_compartment_styles(diagram)
			end)
		else
			lQuery("AA#View[name='" .. viewName .. "']"):attr("isDefault", "true")
			local view=lQuery("Extension[type='aa#View'][id='" .. viewName .. "']")
			--neuzstadit noklusetos skatijumus jau izveidotajam diagrammam
			lQuery("GraphDiagramType[id='OWL']/graphDiagram"):link("aa#notDefault", view)
		end
		refreshListBox()
	end
end

--atver formu ar skatijuma configuracijas iespejam
function openViewProperties()
	local selectedItem = lQuery("D#ListBox[id='ListWithViews']/selected")
	if selectedItem:is_not_empty() then
		local viewSize = string.find(selectedItem:attr("value"), " ")
		local viewName = selectedItem:attr("value")
		if viewSize~=nil then viewName = string.sub(viewName, 1, viewSize-1) end
		View(viewName)
	else
		pleseSelectView()
	end
end

function pleseSelectView()
	local close_button = lQuery.create("D#Button", {
    caption = "Ok"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.closeContextTypesMissing()")
  })
  
  local form = lQuery.create("D#Form", {
    id = "contextTypesMissing"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = create_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.closeContextTypesMissing()")
	,component = {
		lQuery.create("D#VerticalBox",{
			component = {
				lQuery.create("D#Label", {caption = "Please select a view"})
			}
		})
		,lQuery.create("D#HorizontalBox", {
		id = "closeButton"
		--,horizontalAlignment = 1
		,component = {close_button}})
    }
  })
  dialog_utilities.show_form(form)
end

--izdzes visus skatijumus no profila (profileName - profila vards)
function deleteViewFromProfile(profileName)
	local changeElemStyle = 0
	local changeCompartStyle = 0
	local profile = lQuery("AA#Profile[name='" .. profileName .. "']")
		local view = profile:find("/view"):each(function(objV)
			 lQuery(objV):each(function(obj)
				 obj:find("/styleSetting/customStyleSetting"):delete()
				 obj:find("/styleSetting"):delete()
			end)
			local extension = lQuery("Extension[id='" .. objV:attr("name") .. "'][type='aa#View']")
			local changeElemStyleTemp = styleMechanism.syncViewStyleSettingElement(objV, extension)
			if changeElemStyleTemp~=nil then changeElemStyle = changeElemStyle + changeElemStyleTemp end
			local changeCompartStyleTemp = styleMechanism.syncViewStyleSettingCompartment(objV, extension)
			if changeCompartStyleTemp~=nil then changeCompartStyle = changeCompartStyle + changeCompartStyleTemp end
		end)
		
		--izdzest AA# Dalu
		

		lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
			
			utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
			if changeElemStyle > 0 then 
				lQuery(diagram):find("/element:has(/elemType/elementStyleSetting)"):each(function(obj)
					owl_fields_specific.ElemStyleBySettings(obj, "Change")
				end)
			end
			if changeCompartStyle > 0 then 
				lQuery(diagram):find("/element/compartment:has(/compartType/compartmentStyleSetting)"):each(function(obj)
					owl_fields_specific.CompartStyleBySetting(obj, "Change")
				end)
			end
			local cmd = lQuery.create("OkCmd")
			cmd:link("graphDiagram", diagram)
			utilities.execute_cmd_obj(cmd)

			graph_diagram_style_utils.save_diagram_element_and_compartment_styles(diagram)
		end)
		if changeElemStyle > 0 or changeCompartStyle > 0 then
			--jaatjauno visi elementi
			local elem = lQuery("Element:has(/elemType/elementStyleSetting)"):each(function(obj)
				utilities.refresh_element(obj, obj:find("/graphDiagram"))
			end)
		end
		styleMechanism.deleteIsDeletedStyleSetting()
		profile:find("/view"):each(function(objV)
			local extension = lQuery("Extension[id='" .. objV:attr("name") .. "'][type='aa#View']")
			lQuery(extension):delete()
		end)
		profile:find("/view"):delete()
end

--izdzes skatijumu
function deleteView()
	local selectedItem = lQuery("D#ListBox[id='ListWithViews']/selected")
	if selectedItem:is_not_empty() then
		local profileName = lQuery("D#ListBox[id='ListWithProfiles']/selected"):attr("value")
		if profileName==nil then profileName=lQuery("D#ComboBox[id='ListWithProfilesForViews']/selected"):attr("value") end
		local viewSize = string.find(profileName, " ")
		if viewSize~=nil then profileName = string.sub(profileName, 1, viewSize-1) end
		local profile = lQuery("AA#Profile[name='" .. profileName .. "']")
		viewSize = string.find(selectedItem:attr("value"), " ")
		local viewName = selectedItem:attr("value")
		if viewSize~=nil then viewName = string.sub(viewName, 1, viewSize-1) end
		local view = profile:find("/view[name='" .. viewName .. "']")
		lQuery(view):each(function(obj)
			obj:find("/styleSetting/customStyleSetting"):delete()
			obj:find("/styleSetting"):delete()
		end)
		
		--izdzest AA# Dalu
		local extension = lQuery("Extension[id='" .. viewName .. "'][type='aa#View']")
		local changeCompartStyle = styleMechanism.syncViewStyleSettingCompartment(view, extension)
		local changeElemStyle = styleMechanism.syncViewStyleSettingElement(view, extension)
		lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
			
			utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
			if changeElemStyle > 0 then 
				lQuery(diagram):find("/element:has(/elemType/elementStyleSetting)"):each(function(obj)
					owl_fields_specific.ElemStyleBySettings(obj, "Change")
				end)
			end
			if changeCompartStyle > 0 then
				lQuery(diagram):find("/element/compartment:has(/compartType/compartmentStyleSetting)"):each(function(obj)
					owl_fields_specific.CompartStyleBySetting(obj, "Change")
				end)
			end
			local cmd = lQuery.create("OkCmd")
			cmd:link("graphDiagram", diagram)
			utilities.execute_cmd_obj(cmd)

			graph_diagram_style_utils.save_diagram_element_and_compartment_styles(diagram)
		end)
		if view:attr("showInPalette")=="true" then
			--jaatjauno palleteStyle forma
			lQuery("D#HorizontalBox[id='HorFormStylePalette']/component[id='" .. view:id() .. "']"):delete()	
		end
		if view:attr("showInToolBar")=="true" then
			--jaatjauno palleteStyle forma
			lQuery("ToolbarElementType[id='" .. view:id() .. "']"):delete()
			-- refresh project diagram
			configurator.make_toolbar(lQuery("GraphDiagramType[id=projectDiagram]"))
			configurator.make_toolbar(lQuery("GraphDiagramType[id=OWL]"))
		end
		
		view:delete()
		lQuery(extension):delete()

		
		--atjaunot listBox
		refreshListBox()
		lQuery("D#HorizontalBox[id='HorFormStylePalette']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	
		if changeElemStyle > 0 or changeCompartStyle > 0 then 
			--jaatjauno visi elementi
			local elem = lQuery("Element:has(/elemType/elementStyleSetting)"):each(function(obj)
				utilities.refresh_element(obj, obj:find("/graphDiagram"))
			end)
		end
	end
	styleMechanism.deleteIsDeletedStyleSetting()
	
end

--atver formu jauna skatijuma veidosanai
function newView()
	
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.closeNewViewForm()")
	})
  
	local create_button = lQuery.create("D#Button", {
    caption = "Create"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.createNewView()")
	})
  
  local form = lQuery.create("D#Form", {
    id = "newView"
    ,caption = "Create new view"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = create_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.closeNewViewForm()")
	,component = {
		lQuery.create("D#VerticalBox",{
			component = {
				lQuery.create("D#InputField", {
					id = "InputFieldForNewView"
					,text = ""
				})
			}
		})
		,lQuery.create("D#HorizontalBox", {
		id = "closeButton"
		,horizontalAlignment = 1
		,component = {create_button, close_button}})
    }
  })
  dialog_utilities.show_form(form)
end

--izveido jaunu skatijumu
function createNewView()
	--atrast profilu
	local profileName = lQuery("D#ListBox[id='ListWithProfiles']/selected"):attr("value")
	if profileName==nil then profileName=lQuery("D#ComboBox[id='ListWithProfilesForViews']/selected"):attr("value") end
	local profile = lQuery("AA#Profile[name='" .. profileName .. "']")
	
	local newViewValue = lQuery("D#InputField[id='InputFieldForNewView']"):attr("text")
	
	if newViewValue ~="" then
		if lQuery("Extension[type = 'aa#View'][id = '" .. newViewValue .. "']"):is_empty() then
			local selectedItem = lQuery("D#ListBox[id='ListWithViews']/selected")
			lQuery("D#ListBox[id='ListWithViews']"):remove_link("selected", selectedItem)
			
			
			--izveidot jaunu AA#View instanci
			--piesaistit to profile AA#Profile instancei
			
			lQuery.create("AA#View", {name = newViewValue}):link("profile", profile)
			lQuery.create("Extension", {id = newViewValue, type = "aa#View"}):link("aa#owner", lQuery("Extension[id = '" .. profileName .. "'][type='aa#Profile']"))

			--atjaunot listBox
			refreshListBox()
			View(newViewValue)
			closeNewViewForm()
		else
			--print("The view with this name already exists") --!!!!!!!!!!!!!!!
		end
	end
end

--atjauno skatijumu sarakstu
function refreshListBox()
	local profileName = lQuery("D#ComboBox[id='ListWithProfilesForViews']/selected")
	if profileName:is_empty() then profileName=lQuery("D#ListBox[id='ListWithProfiles']/selected") end
	profileName = profileName:attr("value")
	local viewSize = string.find(profileName, " ")
	if viewSize~=nil then profileName = string.sub(profileName, 1, viewSize-1) end
	lQuery("D#ListBox[id='ListWithViews']"):delete()
		lQuery.create("D#ListBox", {
			id = "ListWithViews"
			,item = collectViews(profileName)
		}):link("container", lQuery("D#VerticalBox[id='VerticalBoxWithListBoxView']"))
		lQuery("D#VerticalBox[id='VerticalBoxWithListBoxView']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	
end

--nolasa pazimi vai skatijums ir noklusets
function getViewDefault(viewName)
	return lQuery("AA#View[name='" ..viewName .. "']"):attr("isDefault")
end

function getShowInPalette(viewName)
	return lQuery("AA#View[name='" ..viewName .. "']"):attr("showInPalette")
end

function getShowInToolBar(viewName)
	return lQuery("AA#View[name='" ..viewName .. "']"):attr("showInToolBar")
end

function setShowInToolBar()
	local focus = lQuery("D#CheckBox[id='setShowInToolBar']"):attr("checked")
	local selectedItem=lQuery("D#ListBox[id='ListWithViews']/selected")
	local viewName
	if selectedItem:attr("value") == nil then viewName = lQuery("D#InputField[id='InputFieldForNewView']"):attr("text")
	else
		local viewSize = string.find(selectedItem:attr("value"), " ")
		viewName = selectedItem:attr("value")
		if viewSize~=nil then viewName = string.sub(viewName, 1, viewSize-1) end
	end
	local profileName = lQuery("D#ListBox[id='ListWithProfiles']/selected"):attr("value")
	if profileName==nil then profileName=lQuery("D#ComboBox[id='ListWithProfilesForViews']/selected"):attr("value") end
	local viewSize = string.find(profileName, " ")
	if viewSize~=nil then profileName = string.sub(profileName, 1, viewSize-1) end
	lQuery("AA#Profile[name='" .. profileName .. "']/view[name='" .. viewName .. "']"):attr("showInToolBar", focus)
	local view = lQuery("AA#Profile[name='" .. profileName .. "']/view[name='" .. viewName .. "']")
	
	--japarveido attiecigas toolbar pogas
	if focus == "true" then 
	--izveidojam jaunu pogu
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
	else
		--dzesam pogu
		lQuery("ToolbarElementType[id='" .. view:id() .. "']"):delete()
	end
	-- refresh project diagram
	configurator.make_toolbar(lQuery("GraphDiagramType[id=projectDiagram]"))
	configurator.make_toolbar(lQuery("GraphDiagramType[id=OWL]"))	
end

function setShowInPalette()
	local focus = lQuery("D#CheckBox[id='setShowInPalette']"):attr("checked")
	local selectedItem=lQuery("D#ListBox[id='ListWithViews']/selected")
	local viewName
	if selectedItem:attr("value") == nil then viewName = lQuery("D#InputField[id='InputFieldForNewView']"):attr("text")
	else
		local viewSize = string.find(selectedItem:attr("value"), " ")
		viewName = selectedItem:attr("value")
		if viewSize~=nil then viewName = string.sub(viewName, 1, viewSize-1) end
	end
	local profileName = lQuery("D#ListBox[id='ListWithProfiles']/selected"):attr("value")
	if profileName==nil then profileName=lQuery("D#ComboBox[id='ListWithProfilesForViews']/selected"):attr("value") end
	local viewSize = string.find(profileName, " ")
	if viewSize~=nil then profileName = string.sub(profileName, 1, viewSize-1) end
	lQuery("AA#Profile[name='" .. profileName .. "']/view[name='" .. viewName .. "']"):attr("showInPalette", focus)
	local view = lQuery("AA#Profile[name='" .. profileName .. "']/view[name='" .. viewName .. "']")
	
	if focus == "true" then 
		local picturePath
		if tda.isWeb then 
			picturePath = tda.GetToolPath().. "/web-root/Pictures/"
		else
			picturePath = tda.GetProjectPath() .. "\\Pictures\\"
		end
		
		--jaatjauno palleteStyle forma
		lQuery.create("D#Row", {id = view:id(),component={
			lQuery.create("D#Label", {caption=view:attr("name")})
			,lQuery.create("D#ImageButton", {fileName = picturePath .. view:attr("inActiveIcon")})
			,lQuery.create("D#Label", {caption="Default"})
			,lQuery.create("D#CheckBox", {
				id=view:id()
				,editable = "true" 
				,checked = view:attr("isDefault")
				,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.stylePalette.setAsDefault()")}})
		}}):link("container", lQuery("D#HorizontalBox[id='HorFormStylePalette']"))
		
	else
		--jaatjauno palleteStyle forma
		lQuery("D#HorizontalBox[id='HorFormStylePalette']/component[id='" .. view:id() .. "']"):delete()
	end
	lQuery("D#HorizontalBox[id='HorFormStylePalette']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	
end

--uzstada/nomem pazimi vai skatijums ir noklusets
function setViewDefault()
	local focus = lQuery("D#CheckBox[id='setViewDefault']"):attr("checked")
	local selectedItem=lQuery("D#ListBox[id='ListWithViews']/selected")
	local viewName
	if selectedItem:attr("value") == nil then viewName = lQuery("D#InputField[id='InputFieldForNewView']"):attr("text")
	else
		local viewSize = string.find(selectedItem:attr("value"), " ")
		viewName = selectedItem:attr("value")
		if viewSize~=nil then viewName = string.sub(viewName, 1, viewSize-1) end
	end
	local profileName = lQuery("D#ListBox[id='ListWithProfiles']/selected"):attr("value")
	if profileName==nil then profileName=lQuery("D#ComboBox[id='ListWithProfilesForViews']/selected"):attr("value") end
	local viewSize = string.find(profileName, " ")
	if viewSize~=nil then profileName = string.sub(profileName, 1, viewSize-1) end
	lQuery("AA#Profile[name='" .. profileName .. "']/view[name='" .. viewName .. "']"):attr("isDefault", focus)
	--nonemt linkus uz diagramam
	local view = lQuery("Extension[type='aa#View'][id='" .. viewName .. "']")
	local dia = view:find("/graphDiagram")
	view:remove_link("graphDiagram", dia)
	--neuzstadit noklusetos skatijumus jau izveidotajam diagrammam
	lQuery("GraphDiagramType[id='OWL']/graphDiagram"):link("aa#notDefault", view)
end

--pacel skatijumu augstak
function upView()
	--profils
	local profileName = lQuery("D#ListBox[id='ListWithProfiles']/selected"):attr("value")
	if profileName==nil then profileName=lQuery("D#ComboBox[id='ListWithProfilesForViews']/selected"):attr("value") end
	if profileName~=nil then
		local viewSize = string.find(profileName, " ")
		if viewSize~=nil then profileName = string.sub(profileName, 1, viewSize-1) end
		local profile = lQuery("Extension[type='aa#Profile'][id='" .. profileName .. "']")
		local profileA = lQuery("AA#Profile[name='" .. profileName .. "']")
		--izveletais skatijums
		local selectedItem = lQuery("D#ListBox[id='ListWithViews']/selected")
		
		if selectedItem:is_not_empty() then
			local viewSize = string.find(selectedItem:attr("value"), " ")
			local viewName = selectedItem:attr("value")
			
			if viewSize~=nil then viewName = string.sub(viewName, 1, viewSize-1) end
			local view = profile:find("/aa#subExtension[type='aa#View'][id='" .. viewName .. "']")
			local viewA = profileA:find("/view[name='" .. viewName .. "']")
			--ja skatijums ir pirmais neko nedarit
			if profile:find("/aa#subExtension[type='aa#View']"):first():id()~=view:id() then
				--atrast visus skatijumus, kas pielikti dotajam profilam, ielikt tabulaa
				local viewTable = profile:find("/aa#subExtension[type='aa#View']"):map(function(obj)
					return obj
				end)
				local viewTableA = profileA:find("/view"):map(function(obj)
					return obj
				end)
				--nonemt saites no profila uz skatijumiem
				profile:remove_link("aa#subExtension", profile:find("/aa#subExtension[type='aa#View']"))
				profileA:remove_link("view", profileA:find("/view"))
				for i,v in pairs(viewTable) do 
					--ja nakosais skatijums ir izveletais, tad mainit vietam
					if i~=1 and v:id() == view:id()	then
						local temp = viewTable[i-1]
						local tempA = viewTableA[i-1]
						viewTable[i-1]=v
						viewTableA[i-1]=viewTableA[i]
						viewTable[i]=temp
						viewTableA[i]=tempA
						break
					end
				end
				--atjaunot saites
				for i,v in pairs(viewTable) do v:link("aa#owner", profile) end
				for i,v in pairs(viewTableA) do v:link("profile", profileA) end
				
				lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
					utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
					local extension = lQuery("Extension[id='" .. viewName .. "'][type='aa#View']")
					local l = 0
					diagram:find("/activeExtension"):each(function(d)
						if d:id() == extension:id() then l = 1 end
					end)
					--ja noklusetais
					if viewA:attr("isDefault") == "true" then l = 1 end
					if l==1 then 
							lQuery(diagram):find("/element:has(/elemType/elementStyleSetting)"):each(function(obj)
								owl_fields_specific.ElemStyleBySettings(obj, "ViewApply")
							end)
			
							local a = lQuery(diagram):find("/element/compartment:has(/compartType/compartmentStyleSetting)"):map(function(obj)
								return obj
							end)
							local b = lQuery(diagram):find("/element/compartment/subCompartment:has(/compartType/compartmentStyleSetting)"):map(function(obj)
								return obj
							end)
							local values = lQuery.merge(a, b)
							for i,v in pairs(values) do
								owl_fields_specific.CompartStyleBySetting(v, "ViewApply")
							end
			
							--atjaunojam tos elementus, kur bija compartmentu stila izmaina
							local elem = lQuery(diagram):find("/element:has(/compartment/compartType/compartmentStyleSetting)")
							elem:add(lQuery(diagram):find("/element:has(/compartment/subCompartment/compartType/compartmentStyleSetting)"))
					
							utilities.refresh_element(elem, diagram) 
						
							local cmd = lQuery.create("OkCmd")
							cmd:link("graphDiagram", diagram)
							utilities.execute_cmd_obj(cmd)
							
							graph_diagram_style_utils.save_diagram_element_and_compartment_styles(diagram)
					end
				end)
			end
		end
		styleMechanism.deleteIsDeletedStyleSetting()
		refreshListBox()
	end
end

--noved skatijumu zemak
function downView()
	--profils
	local profileName = lQuery("D#ListBox[id='ListWithProfiles']/selected"):attr("value")
	if profileName==nil then profileName=lQuery("D#ComboBox[id='ListWithProfilesForViews']/selected"):attr("value") end
	if profileName~=nil then
		local viewSize = string.find(profileName, " ")
		if viewSize~=nil then profileName = string.sub(profileName, 1, viewSize-1) end
		local profile = lQuery("Extension[type='aa#Profile'][id='" .. profileName .. "']")
		local profileA = lQuery("AA#Profile[name='" .. profileName .. "']")
		--izveletais skatijums
		local selectedItem = lQuery("D#ListBox[id='ListWithViews']/selected")
		if selectedItem:is_not_empty() then
			local viewSize = string.find(selectedItem:attr("value"), " ")
			local viewName = selectedItem:attr("value")
			if viewSize~=nil then viewName = string.sub(viewName, 1, viewSize-1) end
			local view = profile:find("/aa#subExtension[type='aa#View'][id='" .. viewName .. "']")
			local viewA = profileA:find("/view[name='" .. viewName .. "']")
			--ja skatijums ir pirmais neko nedarit
			if profile:find("/aa#subExtension[type='aa#View']"):last():id()~=view:id() then
				--atrast visus skatijumus, kas pielikti dotajam profilam, ielikt tabulaa
				local viewTable = profile:find("/aa#subExtension[type='aa#View']"):map(function(obj)
					return obj
				end)
				local viewTableA = profileA:find("/view"):map(function(obj)
					return obj
				end)
				--nonemt saites no profila uz skatijumiem
				profile:remove_link("aa#subExtension", profile:find("/aa#subExtension[type='aa#View']"))
				profileA:remove_link("view", profileA:find("/view"))
				for i,v in pairs(viewTable) do 
					--ja nakosais skatijums ir izveletais, tad mainit vietam
					if i~=#viewTable and v:id() == view:id()	then
						local temp = viewTable[i+1]
						local tempA = viewTableA[i+1]
						viewTable[i+1]=v
						viewTableA[i+1]=viewTableA[i]
						viewTable[i]=temp
						viewTableA[i]=tempA
						break
					end
				end
				--atjaunot saites
				for i,v in pairs(viewTable) do v:link("aa#owner", profile) end
				for i,v in pairs(viewTableA) do v:link("profile", profileA) end
				
				lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
					utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
					local extension = lQuery("Extension[id='" .. viewName .. "'][type='aa#View']")
					local l = 0
					diagram:find("/activeExtension"):each(function(d)
						if d:id() == extension:id() then l = 1 end
					end)
					--ja noklusetais
					if viewA:attr("isDefault") == "true" then l = 1 end
					if l==1 then 
							lQuery(diagram):find("/element:has(/elemType/elementStyleSetting)"):each(function(obj)
								owl_fields_specific.ElemStyleBySettings(obj, "ViewApply")
							end)
			
							local a = lQuery(diagram):find("/element/compartment:has(/compartType/compartmentStyleSetting)"):map(function(obj)
								return obj
							end)
							local b = lQuery(diagram):find("/element/compartment/subCompartment:has(/compartType/compartmentStyleSetting)"):map(function(obj)
								return obj
							end)
							local values = lQuery.merge(a, b)
							for i,v in pairs(values) do
								owl_fields_specific.CompartStyleBySetting(v, "ViewApply")
							end
			
							--atjaunojam tos elementus, kur bija compartmentu stila izmaina
							local elem = lQuery(diagram):find("/element:has(/compartment/compartType/compartmentStyleSetting)")
							elem:add(lQuery(diagram):find("/element:has(/compartment/subCompartment/compartType/compartmentStyleSetting)"))
					
							utilities.refresh_element(elem, diagram) 
						
							local cmd = lQuery.create("OkCmd")
							cmd:link("graphDiagram", diagram)
							utilities.execute_cmd_obj(cmd)

							graph_diagram_style_utils.save_diagram_element_and_compartment_styles(diagram)
					end
				end)
			end
		end
	refreshListBox()
	end
	
end

--atver formu ar skatijuma konfiguraciju
function View(viewName)
	--atrast vajadzigo skatijumu
	local view = lQuery("AA#View[name='" .. viewName .. "']")
	local close_button = lQuery.create("D#Button", {
		caption = "Close"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.closeView()")
	  })
	  
	  local picturePath
		if tda.isWeb then 
			picturePath = tda.GetToolPath().. "/web-root/Pictures/"
		else
			picturePath = tda.GetProjectPath() .. "\\Pictures\\"
		end
	  
	  local form = lQuery.create("D#Form", {
		id = "viewProperty"
		,caption = "View style setting"
		,buttonClickOnClose = false
		,cancelButton = close_button
		,defaultButton = close_button
		,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.closeView()")
		,component = {
			lQuery.create("D#VerticalBox", {
				id = "TableViewStyleVerBox"
				,minimumHeight = 250
				,component = {
					lQuery.create("D#Row", {
						horizontalAlignment = -1
						,component = {
							lQuery.create("D#Label", {caption = 'Apply by default (for new diagrams)'})
							,lQuery.create("D#CheckBox", {
								id = "setViewDefault"
								,checked=getViewDefault(viewName)
								,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.setViewDefault()")
							})
						}
					})
					,lQuery.create("D#Row", {
						id = "RowForPalette"
						,horizontalAlignment = -1
						,component = {
							lQuery.create("D#Label", {caption = 'Show in toolbar'})
							,lQuery.create("D#CheckBox", {
								id = "setShowInToolBar"
								,checked=getShowInToolBar(viewName)
								,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.setShowInToolBar()")
							})
							,lQuery.create("D#Label", {caption = 'Show in palette'})
							,lQuery.create("D#CheckBox", {
								id = "setShowInPalette"
								,checked=getShowInPalette(viewName)
								,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.setShowInPalette()")
							})
							,lQuery.create("D#Label", {caption = 'Active icon'})
							,lQuery.create("D#ImageButton", {
								id = "activeIcon"
								,fileName = picturePath .. view:attr("activeIcon")
								,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.setActiveIcon()")
							})
							,lQuery.create("D#Label", {caption = 'Inactive icon'})
							,lQuery.create("D#ImageButton", {
								id = "inactiveIcon"
								,fileName = picturePath ..  view:attr("inActiveIcon")
								,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.setInactiveIcon()")
							})
						}
					})
					,lQuery.create("D#VTable", {
						id = "TableViewStyle"
						,column = {
							lQuery.create("D#VTableColumnType", {
								caption = "ElementType",editable = true,width = 100
							})
							,lQuery.create("D#VTableColumnType", {
								caption = "Path",editable = true,width = 100
							})
							,lQuery.create("D#VTableColumnType", {
								caption = "CompartType",editable = true,width = 100
							})
							,lQuery.create("D#VTableColumnType", {
								caption = "StyleItem",editable = true,width = 100
							})
							,lQuery.create("D#VTableColumnType", {
								caption = "Value",editable = true,width = 100
							})
							,lQuery.create("D#VTableColumnType", {
								caption = "ConditionCompartType",editable = true,width = 100
							})
							,lQuery.create("D#VTableColumnType", {
								caption = "ConditionChoiceItem",editable = true,width = 100
							})
							,lQuery.create("D#VTableColumnType", {
								caption = "AddMirror",editable = true,width = 100
							})
							,lQuery.create("D#VTableColumnType", {
								caption = "Extra",editable = true,width = 100
							})
						}
						,vTableRow = {
							styleMechanism.getViewStyle(view)
						}
					})
					,lQuery.create("D#HorizontalBox", {
						component={
						lQuery.create("D#Button", {
							caption = "Create New Style"
							,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.createNewStyle()")
						})
						,lQuery.create("D#Button", {
							caption = "Delete View Style"
							,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.deleteOneViewStyle()")
						})
					}})
				}})
			,lQuery.create("D#HorizontalBox", {
			id = "closeButton"
			,horizontalAlignment = 1
			,component = {close_button}})
		}
	  })
	  dialog_utilities.show_form(form)
end

function setActiveIcon()
	local caption = "Select active icon"
	local filter = "Pictures(*.bmp)"
	local start_folder
	if tda.isWeb then 
		start_folder = "$WEBAPPOS_ROOT/apps/OWLGrEd.webapp/web-root/Pictures/"
	else
		start_folder = tda.GetProjectPath() .. "\\Pictures\\"
	end
	start_file = ""
	save = false
	local path = tda.BrowseForFile(caption, filter, start_folder, start_file, save)
	if path ~= "" then
		local startS, endS
		if tda.isWeb then 
			startS, endS = string.find(path, "/Pictures/")
		else
			startS, endS = string.find(path, "\\Pictures\\")
		end
		path = string.sub(path, endS+1)

		local selectedItem=lQuery("D#ListBox[id='ListWithViews']/selected")
		local viewName
		if selectedItem:attr("value") == nil then viewName = lQuery("D#InputField[id='InputFieldForNewView']"):attr("text")
		else
			local viewSize = string.find(selectedItem:attr("value"), " ")
			viewName = selectedItem:attr("value")
			if viewSize~=nil then viewName = string.sub(viewName, 1, viewSize-1) end
		end
		local profileName = lQuery("D#ListBox[id='ListWithProfiles']/selected"):attr("value")
		if profileName==nil then profileName=lQuery("D#ComboBox[id='ListWithProfilesForViews']/selected"):attr("value") end
		local viewSize = string.find(profileName, " ")
		if viewSize~=nil then profileName = string.sub(profileName, 1, viewSize-1) end
		lQuery("AA#Profile[name='" .. profileName .. "']/view[name='" .. viewName .. "']"):attr("activeIcon", path)
		
		local view = lQuery("AA#Profile[name='" .. profileName .. "']/view[name='" .. viewName .. "']")
		
		refreshIconButton(view)
	end
end

function refreshIconButton(view)
    local picturePath
	if tda.isWeb then 
		picturePath = tda.GetToolPath().. "/web-root/Pictures/"
	else
		picturePath = tda.GetProjectPath() .. "\\Pictures\\"
	end
	
	lQuery("D#Row[id='RowForPalette']/component"):delete()
		lQuery.create("D#Label", {caption = 'Show in palette'}):link("container", lQuery("D#Row[id='RowForPalette']"))
		lQuery.create("D#CheckBox", {
			id = "setShowInPalette"
			,checked=getShowInPalette(view:attr("name"))
			,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.setShowInPalette()")
		}):link("container", lQuery("D#Row[id='RowForPalette']"))
		lQuery.create("D#Label", {caption = 'Active icon'}):link("container", lQuery("D#Row[id='RowForPalette']"))
		lQuery.create("D#ImageButton", {
			id = "activeIcon"
			,fileName = picturePath ..  view:attr("activeIcon")
			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.setActiveIcon()")
		}):link("container", lQuery("D#Row[id='RowForPalette']"))
		lQuery.create("D#Label", {caption = 'Inactive icon'}):link("container", lQuery("D#Row[id='RowForPalette']"))
		lQuery.create("D#ImageButton", {
			id = "inactiveIcon"
			,fileName = picturePath .. view:attr("inActiveIcon")
			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.setInactiveIcon()")
		}):link("container", lQuery("D#Row[id='RowForPalette']"))
		
		lQuery("D#Form[id = 'viewProperty']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end


function setInactiveIcon()
	local caption = "Select inactive icon"
	local filter = "Pictures(*.bmp)"
	local start_folder
	if tda.isWeb then 
		start_folder = "$WEBAPPOS_ROOT/apps/OWLGrEd.webapp/web-root/Pictures/"
	else
		start_folder = tda.GetProjectPath() .. "\\Pictures\\"
	end
	start_file = ""
	save = false
	local path = tda.BrowseForFile(caption, filter, start_folder, start_file, save)
	if path ~= "" then
		local startS, endS
		if tda.isWeb then 
			startS, endS = string.find(path, "/Pictures/")
		else
			startS, endS = string.find(path, "\\Pictures\\")
		end
		path = string.sub(path, endS+1)

		local selectedItem=lQuery("D#ListBox[id='ListWithViews']/selected")
		local viewName
		if selectedItem:attr("value") == nil then viewName = lQuery("D#InputField[id='InputFieldForNewView']"):attr("text")
		else
			local viewSize = string.find(selectedItem:attr("value"), " ")
			viewName = selectedItem:attr("value")
			if viewSize~=nil then viewName = string.sub(viewName, 1, viewSize-1) end
		end
		local profileName = lQuery("D#ListBox[id='ListWithProfiles']/selected"):attr("value")
		if profileName==nil then profileName=lQuery("D#ComboBox[id='ListWithProfilesForViews']/selected"):attr("value") end
		local viewSize = string.find(profileName, " ")
		if viewSize~=nil then profileName = string.sub(profileName, 1, viewSize-1) end
		lQuery("AA#Profile[name='" .. profileName .. "']/view[name='" .. viewName .. "']"):attr("inActiveIcon", path)
		
		local view = lQuery("AA#Profile[name='" .. profileName .. "']/view[name='" .. viewName .. "']")
		
		refreshIconButton(view)
	end
end

function createNewStyle()
	--pievieno tukso rindu
		lQuery.create("D#VTableRow", {
			vTableCell = {
				lQuery.create("D#VTableCell", { 
					vTableColumnType = lQuery("D#VTableColumnType[caption = 'ElementType']")
						,component = lQuery.create("D#ComboBox", {
							item = {styleMechanism.getElementType()}
							,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectElementType()")}
						})
					})
				,styleMechanism.createVTableTextBox("", "Path")
				,styleMechanism.createVTableTextBox("", "CompartType")
				,styleMechanism.createVTableTextBox("", "StyleItem")
				,styleMechanism.createVTableTextBox("", "Value")
				,styleMechanism.createVTableTextBox("", "ConditionCompartType")
				,styleMechanism.createVTableTextBox("", "ConditionChoiceItem")
				,styleMechanism.createVTableTextBox("", "AddMirror")
				,styleMechanism.createVTableTextBox("", "Extra")
			}
		}):link("vTable", lQuery("D#VTable[id = 'TableViewStyle']"))
		lQuery("D#VTable[id = 'TableViewStyle']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

function viewsForToolBar()
	if lQuery("AA#Profile[isDefaultForViews='true']"):is_empty() then
		askLoadDefaultProfile()
	else
		viewsInProfiles()
	end
end

function askLoadDefaultProfile()
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.closeAskLoadDefaultProfile()")
  })

  local form = lQuery.create("D#Form", {
    id = "askLoadDefaultProfile"
  --  ,caption = "Views in profiles"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = ok_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.closeAskLoadDefaultProfile()")
	,component = {
		lQuery.create("D#VerticalBox", {
			id = "WouldYouLike"
			,component = { 
				lQuery.create("D#HorizontalBox", {
					component = {
						lQuery.create("D#Label", {caption = "Would you like to import profile with example view definitions?"})
					}
				})
				,lQuery.create("D#HorizontalBox", {
					component = {
						lQuery.create("D#Button", {caption = "Yes"
							,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.yesDefaultProfile()")
						})
						,lQuery.create("D#Button", {caption = "No"
							,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.noDefaultProfile()")
						})
					}
				})
			}
		})
      ,lQuery.create("D#HorizontalBox", {
        horizontalAlignment = 1
		,id = "closeForm"
        ,component = {
		  lQuery.create("D#VerticalBox", {
			id = "closeButton"
			,horizontalAlignment = 1
			,component = {close_button}})
		  }
      })
    }
  })
  dialog_utilities.show_form(form)
end

function anywhere (p)
  return lpeg.P{ p + 1 * lpeg.V(1) }
end

function yesDefaultProfile()
	caption = "Select text file"
	filter = "text file(*.txt)"
	local start_folder
	if tda.isWeb then
		start_folder = tda.FindPath(tda.GetToolPath() .. "/AllPlugins", "OWLGrEd_UserFields")
	else
		start_folder = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields"
	end
	start_file = "viewCollection.txt"
	save = false
	local path = tda.BrowseForFile(caption, filter, start_folder, start_file, save)
	if path ~= "" then
		
		f = assert(io.open(path, "r"))
		local t = f:read("*all")
		f:close()
		
		local Letter = lpeg.R("az") + lpeg.R("AZ") + lpeg.R("09") + lpeg.S("_/:#.<>='(){}?!@$%^&*-+|")
		local String = lpeg.C(Letter * (Letter) ^ 0)
		
			local profileName
			local pat = lpeg.P([["AA#Profile",
    ["properties"] = {
      ["name"] = "]])
		
			local p = pat * String * '"'
			p = anywhere (p)

			profileName = lpeg.match(p, t) or ""
			
			local fieldPattern = lpeg.P("AA#Field")
			fieldPattern = anywhere (fieldPattern)
			if profileName == "" then showError("Selected file does not contains any profile definition. Please select another file")
			elseif lpeg.match(fieldPattern, t) then showError("Selected profile file contains field definition. Please select another file")
			elseif lQuery("Extension[id='" .. profileName .. "'][type='aa#Profile']"):is_empty() then
				serialize.import_from_file(path)
				
				--izveidojam profilu
				
				if profileName == "" then
					lQuery("AA#Profile"):each(function(obj)
						if lQuery("Extension[id='" .. obj:attr("name") .. "'][type='aa#Profile']"):is_empty() then 
							profileName = obj:attr("name")
						end
					end)
				end
				
				local ext = lQuery.create("Extension", {id = profileName, type = "aa#Profile"})--:link("aa#owner", lQuery("Extension[id = 'OWL_Fields']"))
				lQuery("Extension[id = 'OWL_Fields']"):link("aa#subExtension", ext)
				
				--izveidojam profila skatijumus
				lQuery("AA#Profile[name='" .. profileName .. "']/view"):each(function(obj)
					lQuery.create("Extension", {id = obj:attr("name"), type = "aa#View"}):link("aa#owner", ext)
					:link("aa#graphDiagram", lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"))
				end)
				lQuery("AA#Profile[name='" .. profileName .. "']"):attr("isDefaultForViews", true)
				--saglabajam izmainas
				lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
					utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
				end)
				
				--sinhronizejam profilu
				syncProfile.syncProfile(profileName)
				--sinhronizejam skatijumus
				styleMechanism.syncExtensionViews()
				
				closeAskLoadDefaultProfile()
				--atvert formu
				viewsInProfiles(profileName)
			else
				showError("Import was canceled. Profile with this name already exists")
			end
	else --print("Import was canceled")
	end
end

function showError(massage)
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.closeAskLoadDefaultProfile()")
  })
	
	lQuery("D#VerticalBox[id='WouldYouLike']"):delete()
	lQuery.create("D#VerticalBox", {
		id = "WouldYouLike"
		,component = { 
			lQuery.create("D#Label", {caption = massage})
		}
	}):link("container", lQuery("D#Form[id = 'askLoadDefaultProfile']"))
	lQuery("D#HorizontalBox[id='closeForm']"):delete()
	lQuery.create("D#HorizontalBox", {
        horizontalAlignment = 1
		,id = "closeForm"
        ,component = {
		  lQuery.create("D#VerticalBox", {
			id = "closeButton"
			,horizontalAlignment = 1
			,component = {close_button}})
		  }
      }):link("container", lQuery("D#Form[id = 'askLoadDefaultProfile']"))
	lQuery("D#Form[id = 'askLoadDefaultProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	
end

function noDefaultProfile()
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.closeAskLoadDefaultProfile()")
  })
	
	lQuery("D#VerticalBox[id='WouldYouLike']"):delete()
	lQuery.create("D#VerticalBox", {
		id = "WouldYouLike"
		,component = { 
			lQuery.create("D#Label", {caption = "Please go to profile dialogue 'P' to set up a default profile for views"})
		}
	}):link("container", lQuery("D#Form[id = 'askLoadDefaultProfile']"))
	lQuery("D#HorizontalBox[id='closeForm']"):delete()
	lQuery.create("D#HorizontalBox", {
        horizontalAlignment = 1
		,id = "closeForm"
        ,component = {
		  lQuery.create("D#VerticalBox", {
			id = "closeButton"
			,horizontalAlignment = 1
			,component = {close_button}})
		  }
      }):link("container", lQuery("D#Form[id = 'askLoadDefaultProfile']"))
	lQuery("D#Form[id = 'askLoadDefaultProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	
end

--atlasa skatijumus, kas ir pieejami profilos
function viewsInProfiles(profileName)
	local text = ""
	if profileName~=nil then text = profileName .. " (Default for views)" end
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.closeViewsInProfiles()")
  })

  local path
  if tda.isWeb then
		path = tda.FindPath(tda.GetToolPath() .. "/AllPlugins", "OWLGrEd_UserFields") .."/"
  else
		path = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\"
  end
  
  local form = lQuery.create("D#Form", {
    id = "ViewsInProfiles"
    ,caption = "Views in profiles"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = ok_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.closeViewsInProfiles()")
	,component = {
		lQuery.create("D#HorizontalBox", {
			id = "HorForm"
			,minimumWidth = 350
			,minimumHeight = 250
			,component = { 
				lQuery.create("D#HorizontalBox", {
					id = "HorizontalBoxWithViewsInDiagram"
					,component = {
						lQuery.create("D#VerticalBox",{
							id = "VerticalBoxWithListBoxView"
							,component = {
								lQuery.create("D#ComboBox", {
									id = "ListWithProfilesForViews"
									,text = text
									,item = profileMechanism.collectProfiles()
									,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.selectView()")
								})
								,lQuery.create("D#ListBox", {
									id = "ListWithViews"
									,item = collectViews(profileName)
								})
							}
						})
						,lQuery.create("D#VerticalBox",{
							component = {
								lQuery.create("D#ImageButton",{
									fileName = path .. "up.bmp"
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.upView()")
								})
								,lQuery.create("D#ImageButton",{
									fileName = path .. "down.bmp"
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.downView()")
								})
							}
						})
						,lQuery.create("D#VerticalBox",{
							component = {
								lQuery.create("D#Button",{
									caption = "Style setting"
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.openViewProperties()")
								})
								,lQuery.create("D#Button",{
									caption = "Default"
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.setDefault()")
								})
								,lQuery.create("D#Button",{
									caption = "New view"
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.newViewInProfile()")
								})
								,lQuery.create("D#Button",{
									caption = "Delete view"
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.deleteView()")
								})
							}
						})
						}
					})
			}
		})
      ,lQuery.create("D#HorizontalBox", {
        horizontalAlignment = 1
		,id = "closeForm"
        ,component = {
		  lQuery.create("D#VerticalBox", {
			id = "closeButton"
			,horizontalAlignment = 1
			,component = {close_button}})
		  }
      })
    }
  })
  dialog_utilities.show_form(form)
end

--atlasa skatijumus, kas ir piesaistiti izveletajam profilam
function selectView()
	local profileName = lQuery("D#ComboBox[id='ListWithProfilesForViews']/selected"):attr("value")
	local viewSize = string.find(profileName, " ")
	if viewSize~=nil then profileName = string.sub(profileName, 1, viewSize-1) end
	lQuery("D#ListBox[id='ListWithViews']"):delete()
		lQuery.create("D#ListBox", {
			id = "ListWithViews"
			,item = collectViews(profileName)
		}):link("container", lQuery("D#VerticalBox[id='VerticalBoxWithListBoxView']"))
		lQuery("D#VerticalBox[id='VerticalBoxWithListBoxView']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	
end

--veido jauno skatijumu tikai ja ir izvelets profils
function newViewInProfile()
	if lQuery("D#ComboBox[id='ListWithProfilesForViews']/selected"):is_not_empty() then 
		newView()
	end
end

function close()
  lQuery("D#Event"):delete()
  utilities.close_form("viewsInProfile")
end

function closeNewViewForm()
  lQuery("D#Event"):delete()
  utilities.close_form("newView")
end

function closeViewsInProfiles()
	lQuery("D#Event"):delete()
	utilities.close_form("ViewsInProfiles")
end

function closeAskLoadDefaultProfile()
	lQuery("D#Event"):delete()
	utilities.close_form("askLoadDefaultProfile")
end

function closeView()
	--print(os.date("%m_%d_%Y_%H_%M_%S"))
	local selectedItem = lQuery("D#ListBox[id='ListWithViews']/selected")
	local viewName
	if selectedItem:attr("value") == nil then viewName = lQuery("D#InputField[id='InputFieldForNewView']"):attr("text")
	else
		local viewSize = string.find(selectedItem:attr("value"), " ")
		viewName = selectedItem:attr("value")
		if viewSize~=nil then viewName = string.sub(viewName, 1, viewSize-1) end
	end
	
	lQuery("D#Event"):delete()
    utilities.close_form("viewProperty")
	
	local view = lQuery("AA#View[name='" .. viewName .. "']")
	local extension = lQuery("Extension[id='" .. viewName .. "'][type='aa#View']")
	
	local changeElemStyle = styleMechanism.syncViewStyleSettingElement(view, extension)
	local changeCompartStyle = styleMechanism.syncViewStyleSettingCompartment(view, extension)
	
	lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
		utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
		
		local l = 0
		diagram:find("/activeExtension"):each(function(d)
			if d:id() == extension:id() then l = 1 end
		end)
		--ja noklusetais
		if view:attr("isDefault") == "true" then l = 1 end
		if l==1 then 
			if changeElemStyle > 0 then
				lQuery(diagram):find("/element:has(/elemType/elementStyleSetting)"):each(function(obj)
					
					owl_fields_specific.ElemStyleBySettings(obj, "Change")
				end)
			end
			if changeCompartStyle > 0 then
				local a = lQuery(diagram):find("/element/compartment:has(/compartType/compartmentStyleSetting)"):map(function(obj)
					return obj
				end)
				local b = lQuery(diagram):find("/element/compartment/subCompartment:has(/compartType/compartmentStyleSetting)"):map(function(obj)
					return obj
				end)
				local values = lQuery.merge(a, b)
				for i,v in pairs(values) do
					owl_fields_specific.CompartStyleBySetting(v, "Change")
				end
			end
			if changeCompartStyle > 0 or changeElemStyle > 0 then
				--atjaunojam tos elementus, kur bija compartmentu stila izmaina
				local elem = lQuery(diagram):find("/element:has(/compartment/compartType/compartmentStyleSetting)")
				elem:add(lQuery(diagram):find("/element:has(/compartment/subCompartment/compartType/compartmentStyleSetting)"))
		
				utilities.refresh_element(elem, diagram) 
			
				local cmd = lQuery.create("OkCmd")
				cmd:link("graphDiagram", diagram)
				utilities.execute_cmd_obj(cmd)
				
				graph_diagram_style_utils.save_diagram_element_and_compartment_styles(diagram)
			end
		end
	end)
	styleMechanism.deleteIsDeletedStyleSetting()
	refreshListBox()
	--print(os.date("%m_%d_%Y_%H_%M_%S"))
end