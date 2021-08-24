module(..., package.seeall)

require("lua_tda")
require "lpeg"
require "dialog_utilities"
require "core"
require "dialog_utilities"
joProfile = require "OWLGrEd_UserFields.Profile"
syncProfile = require "OWLGrEd_UserFields.syncProfile"
styleMechanism = require "OWLGrEd_UserFields.styleMechanism"
viewMechanism = require "OWLGrEd_UserFields.viewMechanism"
serialize = require "serialize"
local report = require("reporter.report")

--atver formu ar visiem profiliem projektaa
function profileMechanism()
	report.event("StylePaletteWindow_ManageViewsAndExtensions", {
		GraphDiagramType = "projectDiagram"
	})
	
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.close()")
  })
  
  local form = lQuery.create("D#Form", {
    id = "allProfiles"
    ,caption = "Profiles in project"
	,minimumWidth = 300
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.close()")
	,component = {
		lQuery.create("D#VerticalBox",{
			component = {
				lQuery.create("D#HorizontalBox"	,{
					component = {
						lQuery.create("D#VerticalBox", {
							id = "VerticalBoxWithListBox"
							,component = {
								lQuery.create("D#ListBox", {
									id = "ListWithProfiles"
									,item = collectProfiles()
								})
							}
						})
						,lQuery.create("D#VerticalBox", {
							component = {
								lQuery.create("D#Button", {
									caption = "Custom Fields"
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.openProfileProperties()")
								})
								,lQuery.create("D#Button", {
									caption = "Views in profile"
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.viewMechanism.viewMechanism()")
								})
								,lQuery.create("D#Button", {
									caption = "New profile"
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.newProfile()")
									,topMargin = 15
								})
								,lQuery.create("D#Button", {
									caption = "Import (load) profile"
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.import()")
								})
								,lQuery.create("D#Button", {
									caption = "Save profile"
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.noLoadForm()")
								})
								-- ,lQuery.create("D#Button", {
									-- caption = "Default for views"
									-- ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.defaultForViews()")
								-- })

								,lQuery.create("D#Button", {
									caption = "Delete profile"
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.deleteProfile()")
									,topMargin = 15
								})
								,lQuery.create("D#Button", {
									caption = "Advanced.."
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.advenced()")
								})
							}
						})
				}})
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

function advenced()
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.closeAdvanced()")
  })
  
  local form = lQuery.create("D#Form", {
    id = "AdvencedManegement"
    ,caption = "Advanced profile management"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.closeAdvanced()")
	,component = {
		lQuery.create("D#VerticalBox",{
			component = {
				lQuery.create("D#HorizontalBox"	,{
					component = {
						lQuery.create("D#VerticalBox", {
							component = {
								lQuery.create("D#Row", {
									component = {
										lQuery.create("D#Button", {
											caption = "Save profile snapshot"
											,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.saveProfileSnapshot()")
										})
										,lQuery.create("D#Label", {caption="Export all profile definitions to OWLGrEd_UserFields/snapshot folder"})
									}
								})
								,lQuery.create("D#Row", {
									component = {
										lQuery.create("D#Button", {
											caption = "Restore from snapshot"
											,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.restoreFromSnapshot()")
										})
										,lQuery.create("D#Label", {caption="Import all profile definitions from OWLGrEd_UserFields/snapshot folder"})
									}
								})
								,lQuery.create("D#Row", {
									component = {
										lQuery.create("D#Button", {
											caption = "Manage configuration"
											,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.configuration.configurationProperty()")
										})
										,lQuery.create("D#Label", {caption="Open form for field context and profile tag management"})
									}
								})
							}
						})
				}})
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

function MakeDir(path) 
	lfs = require("lfs")
	lfs.mkdir(path)
end

function restoreFromSnapshot()
	local start_folder
	if tda.isWeb then 
		start_folder = tda.FindPath(tda.GetToolPath() .. "/AllPlugins", "OWLGrEd_UserFields") .. "/snapshot/"
	else
		start_folder = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\snapshot\\"
	end
	local path = start_folder .. "snapshot.txt"
	serialize.import_from_file(path)
	
		local configuration = lQuery("AA#Configuration"):first()
		lQuery("AA#ContextType"):each(function(obj)
			obj:remove_link("configuration", obj:find("/configuration"))
		end)
		lQuery("AA#ContextType"):link("configuration", configuration)
		
		lQuery("AA#TagType"):each(function(obj)
			obj:remove_link("configuration", obj:find("/configuration"))
		end)
		lQuery("AA#TagType"):link("configuration", configuration)
		
		lQuery("AA#Configuration"):filter(function(obj)
			return obj:id() ~= configuration:id()
		end):delete()
		
		lQuery("AA#Profile"):remove_link("configuration", lQuery("AA#Profile/configuration"))
		lQuery("AA#Profile"):link("configuration", lQuery("AA#Configuration"))
		
		-- izmest dublikatus
		 -- atrast visus AA#ContextType
		 -- iziet cauri visiem. Ja ir vairki ar viendu id, tad izdzest to, kam nav AA#Field
		lQuery("AA#ContextType"):each(function(obj)
			local id = obj:attr("id")
			local eq = lQuery("AA#ContextType[id = '" .. id .."']")
			if eq:size()>1 then
				if obj:find("/fieldInContext"):is_empty() then 
					obj:delete()
				else
					eq:filter(function(ct)
						return ct:attr("id") ~= obj:attr("id")
					end):delete()
				end
			end
		end)
		
		lQuery("AA#TagType"):each(function(obj)
			local tt = lQuery("AA#TagType[key='" .. obj:attr("key") .. "'][notation='" .. obj:attr("notation") .. "'][rowType='" .. obj:attr("rowType") .. "']")
			if tt:size()>1 then obj:delete() end
		end)

		--jaatrod profila vards
		--jaatrod tas profils, kam nav saderibas
		local profileName
		lQuery("AA#Profile"):each(function(obj)
			if lQuery("Extension[id='" .. obj:attr("name") .. "'][type='aa#Profile']"):is_empty() then 
				profileName = obj:attr("name")
				local ext = lQuery.create("Extension", {id = profileName, type = "aa#Profile"})--:link("aa#owner", lQuery("Extension[id = 'OWL_Fields']"))
				lQuery("Extension[id = 'OWL_Fields']"):link("aa#subExtension", ext)
				lQuery("AA#Profile[name='" .. profileName .. "']/view"):each(function(prof)
					if ext:find("/aa#subExtension[id='" .. prof:attr("name") .. "'][type='aa#View']"):is_empty() then
						lQuery.create("Extension", {id=prof:attr("name"), type="aa#View"}):link("aa#owner", ext)
						:link("aa#graphDiagram", lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"))
					end
				end)
				syncProfile.syncProfile(profileName)
			end
		end)
		styleMechanism.syncExtensionViews()
		--atjaunot listBox
		refreshListBox()
end

function saveProfileSnapshot()
	
	local objects_to_export = lQuery("AA#Configuration")

		local export_spec = {
			include = {
			   ["AA#Configuration"] = {
					context = serialize.export_as_table
					,profile = serialize.export_as_table
					,tagType = serialize.export_as_table
			   }
			   ,["AA#Profile"] = {
					field = serialize.export_as_table
					,view = serialize.export_as_table
					,tag = serialize.export_as_table
			   }
			   ,["AA#TagType"] = {}
			   ,["AA#ContextType"] = {
					fieldInContext = serialize.export_as_table
			   }
			   ,["AA#View"] = {
					styleSetting = serialize.export_as_table
			   }
			   ,["AA#Field"] = {
					tag = serialize.export_as_table
					,translet = serialize.export_as_table
					,selfStyleSetting = serialize.export_as_table
					,dependency = serialize.export_as_table
					,choiceItem = serialize.export_as_table
					,subField = serialize.export_as_table
			   }
			   ,["AA#ChoiceItem"] = {
					tag = serialize.export_as_table
					,styleSetting = serialize.export_as_table
					,dependency = serialize.export_as_table
			   }
			   ,["AA#Tag"] = {}
			   ,["AA#Translet"] = {}
			   ,["AA#Dependency"] = {}
			   ,["AA#FieldStyleSetting"] = {}
			   ,["AA#ViewStyleSetting"] = {}
			 },
			border = {
				["AA#Field"] = {
					-- fieldType = serialize.make_exporter(function(object)
						-- return "AA#RowType[typeName=" .. lQuery(object):attr("typeName") .. "]"
					-- end)
				}
				,["AA#Translet"] = {
					task = serialize.make_exporter(function(object)
						return "AA#TransletTask[taskName=" .. lQuery(object):attr("taskName") .. "]"
					end)
				}
				,["AA#FieldStyleSetting"] = {
					fieldStyleFeature = serialize.make_exporter(function(object)
						return "AA#CompartStyleItem[itemName=" .. lQuery(object):attr("itemName") .. "]"
					end)
					,elemStyleFeature = serialize.make_exporter(function(object)
						return "AA#ElemStyleItem[itemName=" .. lQuery(object):attr("itemName") .. "]"
					end)
				}
				,["AA#ViewStyleSetting"] = {
					fieldStyleFeature = serialize.make_exporter(function(object)
						return "AA#CompartStyleItem[itemName=" .. lQuery(object):attr("itemName") .. "]"
					end)
					,elemStyleFeature = serialize.make_exporter(function(object)
						return "AA#ElemStyleItem[itemName=" .. lQuery(object):attr("itemName") .. "]"
					end)
				}
			}
		}
		
		local start_folder
		if tda.isWeb then 
			start_folder = tda.FindPath(tda.GetToolPath() .. "/AllPlugins", "OWLGrEd_UserFields") .. "/snapshot/"
			MakeDir(tda.FindPath(tda.GetToolPath() .. "/AllPlugins", "OWLGrEd_UserFields") .. "/snapshot")
		else
			start_folder = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\snapshot\\"
			MakeDir(tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\snapshot")
		end
		
		local path = start_folder .. "snapshot.txt"
		serialize.save_to_file(objects_to_export, export_spec, path)
end

--padara profilu nokluseto prieks skatijumiem
function defaultForViews()
	--izveletais profils
	local selectedItem = lQuery("D#ListBox[id='ListWithProfiles']/selected")
	if selectedItem:is_not_empty() then
		local profileName = selectedItem:attr("value")
		local viewSize = string.find(profileName, " ")
		if viewSize~=nil then profileName = string.sub(profileName, 1, viewSize-1) end
		--nedrikst padarit profilu nokluseto, ja zem ta ir izveidoti lauki
		if selectedItem:is_not_empty() and lQuery("AA#Profile[name='" .. profileName .. "']/field"):is_empty() then
			if lQuery("AA#Profile[name='" .. profileName .. "']"):attr("isDefaultForViews")=="true" then
				lQuery("AA#Profile[name='" .. profileName .. "']"):attr("isDefaultForViews", false)
				refreshListBox()
			else
				if lQuery("AA#Profile[isDefaultForViews='true']"):is_empty() then
					lQuery("AA#Profile[name='" .. profileName .. "']"):attr("isDefaultForViews", true)
					refreshListBox()
				else
					showNotificationForm()
				end
			end
			--atjaunot listBox
			--refreshListBox()
		end
	end
end

function showNotificationForm()
	local profileName = lQuery("D#ListBox[id='ListWithProfiles']/selected")
		local close_button = lQuery.create("D#Button", {
		caption = "No"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.noChangeDefaultForViews()")
	  })
	  
		local create_button = lQuery.create("D#Button", {
		caption = "Yes"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.yesChangeDefaultForViews()")
	  })
	  
	  local form = lQuery.create("D#Form", {
		id = "changeDefaultForViews"
		,caption = "Confirmation"
		,buttonClickOnClose = false
		,cancelButton = close_button
		,defaultButton = create_button
		,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.noChangeDefaultForViews()")
		,component = {
			lQuery.create("D#VerticalBox",{
				component = {
					lQuery.create("D#Label", {caption="Do you want to save the profile for auto loading?"})
				}
			})
			,lQuery.create("D#HorizontalBox", {
			id = "closeButton"
			,component = {create_button, close_button}})
		}
	  })
	  dialog_utilities.show_form(form)
end

function noChangeDefaultForViews()
  lQuery("D#Event"):delete()
  utilities.close_form("changeDefaultForViews")
end

function yesChangeDefaultForViews()
	local selectedItem = lQuery("D#ListBox[id='ListWithProfiles']/selected")
	local profileName = selectedItem:attr("value")
	local viewSize = string.find(profileName, " ")
	if viewSize~=nil then profileName = string.sub(profileName, 1, viewSize-1) end
	lQuery("AA#Profile"):attr("isDefaultForViews", false)
	lQuery("AA#Profile[name='" .. profileName .. "']"):attr("isDefaultForViews", true)
	noChangeDefaultForViews()
	refreshListBox()
end
--atver profila konfiguracijas formu
function openProfileProperties()
	local selectedItem = lQuery("D#ListBox[id='ListWithProfiles']/selected")
	if selectedItem:is_not_empty() then
		local profileName = selectedItem:attr("value")
		local viewSize = string.find(profileName, " ")
		if viewSize~=nil then profileName = string.sub(profileName, 1, viewSize-1) end
		if selectedItem:is_not_empty() and lQuery("AA#Profile[name='" .. profileName.. "']"):attr("isDefaultForViews")~="true" then
			joProfile.Profile(profileName)
		else
			pleaseSelectNotDefaultProfile("Please use a profile that is not default for views to enter and manage user field definitions")
		end
	else
		pleseSelectProfile()
	end
end


function pleseSelectProfile()
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
				lQuery.create("D#Label", {caption = "Please select a profile"})
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

--izdzes profilu no projekta
function deleteProfile()
	--atrast profilu
	local profileName = lQuery("D#ListBox[id='ListWithProfiles']/selected")
	if profileName:is_not_empty() then
		local profileName = profileName:attr("value")
		local viewSize = string.find(profileName, " ")
		if viewSize~=nil then profileName = string.sub(profileName, 1, viewSize-1) end
		local profile = lQuery("AA#Profile[name = '" .. profileName .. "']")
		--izdzest AA# Dalu
		lQuery(profile):find("/field"):each(function(obj)
			deleteField(obj)
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
		
		--atjaunot listBox
		refreshListBox()
	end
end

--izdzes lietotaja defineto lauku un visu, kas ir saistits ar to (field-dzesamais lauks)
function deleteField(field)
	lQuery(field):find("/tag"):delete()
	lQuery(field):find("/translet"):delete()
	lQuery(field):find("/dependency"):delete()
	lQuery(field):find("/selfStyleSetting"):delete()
	lQuery(field):find("/choiceItem/tag"):delete()
	lQuery(field):find("/choiceItem/styleSetting"):delete()
	lQuery(field):find("/choiceItem"):delete()
	--lQuery(field):find("/fieldType"):remove_link("field", field)
	
	lQuery(field):find("/subField"):each(function(obj)
		deleteField(obj)
	end)
	
	lQuery(field):delete()
end

--atver formu jauno profilu veidosanai
function newProfile()
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.closeNewProfileForm()")
  })
  
	local create_button = lQuery.create("D#Button", {
    caption = "Create"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.createNewProfile()")
  })
  
  local form = lQuery.create("D#Form", {
    id = "newProfile"
    ,caption = "Create new profile"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = create_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.closeNewProfileForm()")
	,component = {
		lQuery.create("D#VerticalBox",{
			component = {
				lQuery.create("D#InputField", {
					id = "InputFieldForNewProfile"
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

--izveido jaunu profilu
function createNewProfile()
	local newProfileValue = lQuery("D#InputField[id='InputFieldForNewProfile']"):attr("text")
	if newProfileValue ~="" then
		
		closeNewProfileForm()
		
		--izveidojam profilu
		local profile = lQuery.create("AA#Profile", {name = newProfileValue}):link("configuration", lQuery("AA#Configuration"))
		local profileExtension = lQuery.create("Extension", {id = newProfileValue, type = "aa#Profile"}):link("aa#owner", lQuery("Extension[id = 'OWL_Fields']"))
		--izveidojam nokluseto skatijumu
		-- lQuery.create("AA#View", {name = "Default", isDefault = 1}):link("profile", profile)
		-- lQuery.create("Extension", {id = "Default", type = "aa#View"}):link("aa#owner", profileExtension)

		--atverm profila configuracijas formu
	--	joProfile.Profile(newProfileValue)
		
		--atjaunot listBox
		refreshListBox()
	end
end

--atjauno sarakstu ar profiliem
function refreshListBox()
	lQuery("D#ListBox[id='ListWithProfiles']"):delete()
		lQuery.create("D#ListBox", {
			id = "ListWithProfiles"
			,item = collectProfiles()
		}):link("container", lQuery("D#VerticalBox[id='VerticalBoxWithListBox']"))
		lQuery("D#VerticalBox[id='VerticalBoxWithListBox']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	
end

--savac visus profilus no projekta
function collectProfiles()
	local values = lQuery("AA#Profile"):map(
	  function(obj)
		return {lQuery(obj):attr("name"), lQuery(obj):attr("isDefaultForViews")}
	  end)  
	
	return lQuery.map(values, function(profile) 
		local profileName = profile[1]
		if profile[2]=="true" then profileName = profileName .. " (Default for views)" end
		return lQuery.create("D#Item", {
			value = profileName
		}) 
	end)
end

function anywhere (p)
  return lpeg.P{ p + 1 * lpeg.V(1) }
end

--ielade profilu no teksta faila
function import()
	caption = "Select text file"
	filter = "text file(*.txt)"
	
	local start_folder
	if tda.isWeb then 
		start_folder = tda.FindPath(tda.GetToolPath() .. "/AllPlugins", "OWLGrEd_UserFields") .. "/examples/"
	else
		start_folder = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\examples\\"
	end
	start_file = ""
	save = false
	local path = tda.BrowseForFile(caption, filter, start_folder, start_file, save)
	if path ~= "" then
		
		f = assert(io.open(path, "r"))
		local t = f:read("*all")
		f:close()
		
		local contextTypeTable = {}
		
		local Letter = lpeg.R("az") + lpeg.R("AZ") + lpeg.R("09") + lpeg.S("_/:#.<>='(){}?!@$%^&*-+|")
		local String = lpeg.C(Letter * (Letter) ^ 0)
		
		local ct = lpeg.P("AA#ContextType[id=")
		local compartTypeTable = {}
		local ctP = (ct * String * "]")

		ctP = lpeg.P(ctP)
		ctP = lpeg.Cs((ctP/(function(a) table.insert(compartTypeTable, a) end) + 1)^0)
		lpeg.match(ctP, t)
		
		local l = 0
		for i,v in pairs(compartTypeTable) do 
			if lQuery("AA#ContextType[id='" .. v .. "']"):is_empty() then l = 1 end
		end
		if l ~= 1 then 
			local profileName
			local pat = lpeg.P([["AA#Profile",
    ["properties"] = {
      ["name"] = "]])
		
			local p = pat * String * '"'
			p = anywhere (p)

			profileName = lpeg.match(p, t) or ""
			if lQuery("Extension[id='" .. profileName .. "'][type='aa#Profile']"):is_empty() then
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
				
				--ja ir saite uz AA#RowType, nonemam tas
				lQuery("AA#Field"):each(function(obj)
					local fieldType = obj:find("/fieldType")
					if fieldType:is_not_empty() then
						obj:attr("fieldType", fieldType:attr("typeName"))
						fieldType:remove_link("field", obj)
					end
				end)
				
				--izveidojam profila skatijumus
				lQuery("AA#Profile[name='" .. profileName .. "']/view"):each(function(obj)
					lQuery.create("Extension", {id = obj:attr("name"), type = "aa#View"}):link("aa#owner", ext)
					:link("aa#graphDiagram", lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"))
				end)
				
				--saglabajam izmainas
				lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
					utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
				end)
				
				lQuery("AA#Profile"):remove_link("configuration", lQuery("AA#Profile/configuration"))
				lQuery("AA#Profile"):link("configuration", lQuery("AA#Configuration"))
				
				--sinhronizejam profilu
				syncProfile.syncProfile(profileName)
				--sinhronizejam skatijumus
				styleMechanism.syncExtensionViews()
				--atjaunot listBox
				refreshListBox()
			else
				-- print("Import was canceled")--!!!!!!!!!!!!
				-- print("Profile with this name already exists")--!!!!!!!!!!
			end
		else 
			contextTypesMissing()
			
			-- print("Import was canceled")
			-- print("Some ContextTypes are missing")
			-- print("Please create or load corresponding configuration.")
		end
	else --print("Import was canceled")
	end
end

function pleaseSelectNotDefaultProfile()
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
				lQuery.create("D#Label", {caption = "Please use a profile that is not default for views"})
				,lQuery.create("D#Label", {caption = "to enter and manage user field definitions"})
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

function contextTypesMissing()
	local close_button = lQuery.create("D#Button", {
    caption = "Ok"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.closeContextTypesMissing()")
  })
  
  local form = lQuery.create("D#Form", {
    id = "contextTypesMissing"
    ,caption = "Create new profile"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = create_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.closeContextTypesMissing()")
	,component = {
		lQuery.create("D#VerticalBox",{
			component = {
				lQuery.create("D#Label", {caption = "The profile to be imported requires extend profile configuration"})
				,lQuery.create("D#Label", {caption = "Please import the profiles configuration from"})
				,lQuery.create("D#Label", {caption = "'Advanced..'->'Manage configuration' form"})
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

--parada dialoga logu ar jautajumu vai ir jaielade profils automatiski
function load()
	local profileName = lQuery("D#ListBox[id='ListWithProfiles']/selected")
	if profileName:is_not_empty() then 
		local close_button = lQuery.create("D#Button", {
		caption = "No"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.noLoadForm()")
	  })
	  
		local create_button = lQuery.create("D#Button", {
		caption = "Yes"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.yesLoadForm(()")
	  })
	  
	  local form = lQuery.create("D#Form", {
		id = "loadProfile"
		,caption = "Load profile"
		,buttonClickOnClose = false
		,cancelButton = close_button
		,defaultButton = create_button
		,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.noLoadFormClose()")
		,component = {
			lQuery.create("D#VerticalBox",{
				component = {
					lQuery.create("D#Label", {caption="Do you want to save the profile for auto loading?"})
				}
			})
			,lQuery.create("D#HorizontalBox", {
			id = "closeButton"
			,component = {create_button, close_button}})
		}
	  })
	  dialog_utilities.show_form(form)
	end
end

function noLoadForm()
	  local close_button = lQuery.create("D#Button", {
		caption = "Close"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.loadProfileNameClose()")
	  })
	  
	  local create_button = lQuery.create("D#Button", {
		caption = "Ok"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.noLoadFormExport()")
	  })
	  
	  local form = lQuery.create("D#Form", {
		id = "exportFileNameForm"
		,caption = "Export file name"
		,buttonClickOnClose = false
		,cancelButton = close_button
		,defaultButton = create_button
		,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.profileMechanism.loadProfileNameClose()")
		,component = {
			lQuery.create("D#VerticalBox",{
				component = {
					lQuery.create("D#Label", {caption="Enter export file name"})
					,lQuery.create("D#InputField", {
						id = "exportFileName", text = lQuery("D#ListBox[id='ListWithProfiles']/selected"):attr("value") .. "_" .. os.date("%m_%d_%Y_%H_%M_%S")
					})
				}
			})
			,lQuery.create("D#HorizontalBox", {
				id = "closeButton"
				,component = {create_button, close_button}}
			)
		}
	  })
	  dialog_utilities.show_form(form)
end

function loadProfileNameClose()
	lQuery("D#Event"):delete()
	utilities.close_form("exportFileNameForm")
end

function noLoadFormClose()
	lQuery("D#Event"):delete()
	utilities.close_form("loadProfile")
end

function noLoadFormExport()
	if export() then -- modified by SK
		lQuery("D#Event"):delete()
		--utilities.close_form("loadProfile")
		--print("by SK: deleting form loadProfile")
		utilities.close_form("loadProfile") -- by SK!!!
	else
		--print("by SK: do not deleting the form")
	end
end

function yesLoadForm()
	lQuery("D#Event"):delete()
	utilities.close_form("loadProfile")
	
	local profileName = lQuery("D#ListBox[id='ListWithProfiles']/selected")
	if profileName:is_not_empty() then 
		local objects_to_export = lQuery("AA#Profile[name = '" .. profileName:attr("value") .. "']")

		local export_spec = {
			include = {
			   ["AA#Profile"] = {
					field = serialize.export_as_table
					,view = serialize.export_as_table
					,tag = serialize.export_as_table
			   }
			   ,["AA#View"] = {
					styleSetting = serialize.export_as_table
			   }
			   ,["AA#Field"] = {
					tag = serialize.export_as_table
					,translet = serialize.export_as_table
					,selfStyleSetting = serialize.export_as_table
					,dependency = serialize.export_as_table
					,choiceItem = serialize.export_as_table
					,subField = serialize.export_as_table
			   }
			   ,["AA#ChoiceItem"] = {
					tag = serialize.export_as_table
					,styleSetting = serialize.export_as_table
					,dependency = serialize.export_as_table
			   }
			   ,["AA#Tag"] = {}
			   ,["AA#Translet"] = {}
			   ,["AA#Dependency"] = {}
			   ,["AA#FieldStyleSetting"] = {}
			   ,["AA#ViewStyleSetting"] = {}
			 },
			border = {
				["AA#Field"] = {
					context = serialize.make_exporter(function(object)
						return "AA#ContextType[id=" .. lQuery(object):attr("id") .. "]"
					end)
					-- ,fieldType = serialize.make_exporter(function(object)
						-- return "AA#RowType[typeName=" .. lQuery(object):attr("typeName") .. "]"
					-- end)
				}
				,["AA#Translet"] = {
					task = serialize.make_exporter(function(object)
						return "AA#TransletTask[taskName=" .. lQuery(object):attr("taskName") .. "]"
					end)
				}
				,["AA#FieldStyleSetting"] = {
					fieldStyleFeature = serialize.make_exporter(function(object)
						return "AA#CompartStyleItem[itemName=" .. lQuery(object):attr("itemName") .. "]"
					end)
					,elemStyleFeature = serialize.make_exporter(function(object)
						return "AA#ElemStyleItem[itemName=" .. lQuery(object):attr("itemName") .. "]"
					end)
				}
				,["AA#ViewStyleSetting"] = {
					fieldStyleFeature = serialize.make_exporter(function(object)
						return "AA#CompartStyleItem[itemName=" .. lQuery(object):attr("itemName") .. "]"
					end)
					,elemStyleFeature = serialize.make_exporter(function(object)
						return "AA#ElemStyleItem[itemName=" .. lQuery(object):attr("itemName") .. "]"
					end)
				}
			}
		}

		local start_folder
		if tda.isWeb then 
			start_folder = tda.FindPath(tda.GetToolPath() .. "/AllPlugins", "OWLGrEd_UserFields") .. "/user/AutoLoad/"	
		else
			start_folder = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\user\\AutoLoad\\"
		end
		local path = start_folder .. profileName:attr("value") .. ".txt"
		serialize.save_to_file(objects_to_export, export_spec, path)
	end
	
end

--saglaba profilu teksta failaa
function export()
	local profileName = lQuery("D#ListBox[id='ListWithProfiles']/selected")
	if profileName:is_not_empty() then 
		local objects_to_export = lQuery("AA#Profile[name = '" .. profileName:attr("value") .. "']")

		local export_spec = {
			include = {
			   ["AA#Profile"] = {
					field = serialize.export_as_table
					,view = serialize.export_as_table
					,tag = serialize.export_as_table
			   }
			   ,["AA#View"] = {
					styleSetting = serialize.export_as_table
			   }
			   ,["AA#Field"] = {
					tag = serialize.export_as_table
					,translet = serialize.export_as_table
					,selfStyleSetting = serialize.export_as_table
					,dependency = serialize.export_as_table
					,choiceItem = serialize.export_as_table
					,subField = serialize.export_as_table
			   }
			   ,["AA#ChoiceItem"] = {
					tag = serialize.export_as_table
					,styleSetting = serialize.export_as_table
					,dependency = serialize.export_as_table
			   }
			   ,["AA#Tag"] = {}
			   ,["AA#Translet"] = {}
			   ,["AA#Dependency"] = {}
			   ,["AA#FieldStyleSetting"] = {}
			   ,["AA#ViewStyleSetting"] = {
					customStyleSetting = serialize.export_as_table
				}
			   ,["AA#CustomStyleSetting"] = {}
			 },
			border = {
				["AA#Field"] = {
					context = serialize.make_exporter(function(object)
						return "AA#ContextType[id=" .. lQuery(object):attr("id") .. "]"
					end)
					-- ,fieldType = serialize.make_exporter(function(object)
						-- return "AA#RowType[typeName=" .. lQuery(object):attr("typeName") .. "]"
					-- end)
				}
				,["AA#Translet"] = {
					task = serialize.make_exporter(function(object)
						return "AA#TransletTask[taskName=" .. lQuery(object):attr("taskName") .. "]"
					end)
				}
				,["AA#FieldStyleSetting"] = {
					fieldStyleFeature = serialize.make_exporter(function(object)
						return "AA#CompartStyleItem[itemName=" .. lQuery(object):attr("itemName") .. "]"
					end)
					,elemStyleFeature = serialize.make_exporter(function(object)
						return "AA#ElemStyleItem[itemName=" .. lQuery(object):attr("itemName") .. "]"
					end)
				}
				,["AA#ViewStyleSetting"] = {
					fieldStyleFeature = serialize.make_exporter(function(object)
						return "AA#CompartStyleItem[itemName=" .. lQuery(object):attr("itemName") .. "]"
					end)
					,elemStyleFeature = serialize.make_exporter(function(object)
						return "AA#ElemStyleItem[itemName=" .. lQuery(object):attr("itemName") .. "]"
					end)
				}
			}
		}
		local deteTime = os.date("%m_%d_%Y_%H_%M_%S")
		local caption = "select folder"
		
		if tda.isWeb then
			start_folder = "" -- relative to the user's home directory (currently, ignored)
		else
			start_folder = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\user\\"
		end
		local folder = tda.BrowseForFolder(caption, start_folder)
		if folder == nil then -- by SK
		   return false -- do not delete the form
		end
		if folder ~= "" then
			local path
			if tda.isWeb then 
				path = folder .. "/" .. lQuery("D#InputField[id='exportFileName']"):attr("text") .. ".txt"
			else
				path = folder .. "\\" .. lQuery("D#InputField[id='exportFileName']"):attr("text") .. ".txt"
			end
			
			serialize.save_to_file(objects_to_export, export_spec, path)
			loadProfileNameClose()
		else --print("Export was canceled") 
		end
	end
	return true -- by SK
end

function closeContextTypesMissing()
  lQuery("D#Event"):delete()
  utilities.close_form("contextTypesMissing")
end

function closeAdvanced()
  lQuery("D#Event"):delete()
  utilities.close_form("AdvencedManegement")
end

function close()
  lQuery("D#Event"):delete()
  utilities.close_form("allProfiles")
end

function closeNewProfileForm()
  lQuery("D#Event"):delete()
  utilities.close_form("newProfile")
end