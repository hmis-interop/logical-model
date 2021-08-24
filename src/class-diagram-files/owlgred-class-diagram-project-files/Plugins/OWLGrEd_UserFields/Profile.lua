module(..., package.seeall)

require("lua_tda")
require "lpeg"
require "core"
require "dialog_utilities"
specific = require "OWL_specific"
syncProfile = require "OWLGrEd_UserFields.syncProfile"
styleMechanism = require "OWLGrEd_UserFields.styleMechanism"
extensionCreate = require "OWLGrEd_UserFields.extensionCreate"
axiom = require "OWLGrEd_UserFields.axiom"

--atver profila parvaldibas logu (profileName-profila nosaukums)
function Profile(profileName)
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.close()")
  })
  local prof = lQuery("AA#Profile[name = '" .. profileName .. "']")
  local profId = lQuery("AA#Profile[name = '" .. profileName .. "']"):id()
  
  local form = lQuery.create("D#Form", {
    id = "Profile"
    ,caption = "Profile"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.Profile.close()")
	,component = {
		lQuery.create("D#HorizontalBox", {
			id = "HorForm"
			,minimumWidth = 800
			,component = { 
				lQuery.create("D#VerticalBox", {
					id = "VerticalBoxWithTree"
					,component = {
						lQuery.create("D#Tree", {
							id = "treeProfile",maximumWidth = 250,minimumWidth = 250,maximumHeight = 500,minimumHeight = 500
							,treeNode = lQuery.create("D#TreeNode", {
								text = lQuery(prof):attr("name"),id = profId .. " AA#Profile",childNode = create_items(profId),expanded = true
							})
							,eventHandler = {utilities.d_handler("TreeNodeSelect", "lua_engine", "lua.OWLGrEd_UserFields.Profile.treeEvent()")}
						})}
					})
				,lQuery.create("D#VerticalBox", {id = "property"
					,component = {
						lQuery.create("D#TabContainer", {
							minimumWidth = 250
							,component = {
								lQuery.create("D#Tab", {
									caption = "Profile properties"
									,component = {
										lQuery.create("D#HorizontalBox", {
											horizontalAlignment = 1
											,component = {
												lQuery.create("D#Label", {caption = "Prefixes", minimumWidth = 100})
												,lQuery.create("D#MultiLineTextBox", {
													id = "ProfilePrefix"
													,textLine = {colectProfilePrefix(prof)}
													,eventHandler = {utilities.d_handler("MultiLineTextBoxChange", "lua_engine", "lua.OWLGrEd_UserFields.Profile.profilePrefix()")}
												})}
										})
									}
								})
							}
						})
					}
				}) 
			}
		})
      ,lQuery.create("D#HorizontalBox", {
        horizontalAlignment = 1
		,id = "closeFormProfile"
        ,component = {
		  lQuery.create("D#VerticalBox", {id = "buttons", component={lQuery.create("D#Label", {caption="To enter a field, select a context type 'T: ...' in the structure tree"})}}) 
		  ,lQuery.create("D#VerticalBox", {
			id = "closeButton"
			,horizontalAlignment = 1
			,component = {close_button}})
		  }
      })
    }
  })
	--pievieno ne pirma limena koka konteksta tipus
	createTreeChild(profId)
	
	dialog_utilities.show_form(form)
end

--izveido jaunu lauku
function createField()
	--atrast profilu
	local prof = lQuery("D#Tree[id = 'treeProfile']/treeNode"):attr("id")
	local n1 = string.find(prof, " ")
	local types1 = string.sub(prof, n1+1)--tips
	local repNr1 = string.sub(prof, 1, n1-1)
	repNr1 = tonumber(repNr1)

	local profile -- vajadziga AA#Profile instance
	local field1 = lQuery("AA#Profile"):each(function(obj)
		if obj:id() == repNr1 then 
			profile = obj
			return
		end end)

	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")--tree node id
		
	--jaatrod iezimeta klase
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)
	repNr = tonumber(repNr)

	local fielDRepId -- vajadziga AA#ContextType instance
	local field = lQuery("AA#ContextType"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)

	local f = lQuery.create("AA#Field",{name = "Field", pattern = "a-zA-Z0-9-_", fieldType = "InputField"}):link("context", fielDRepId)
	lQuery(f):link("profile", profile)

	--lQuery("AA#RowType[typeName = 'InputField']"):link("field", f)--pievieno nokluseto Field type

	local n = lQuery.create("D#TreeNode", {
		text = "F:Field"
		,id = lQuery(f):id() .. " AA#Field"
		,expanded = true}):link("parentNode", lQuery("D#Tree[id = 'treeProfile']/selected"))
	lQuery("D#Tree[id='treeProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	lQuery("D#Tree[id='treeProfile']"):remove_link("selected", lQuery("D#Tree[id='treeProfile']/selected"))
	lQuery("D#Tree[id='treeProfile']"):link("selected", n)
	lQuery("D#Tree[id='treeProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))

	local tabCont = lQuery("D#VerticalBox[id = 'property']/component")--tabConteiner
	local tabs = lQuery(tabCont):find("/component")--tabi
	lQuery(tabs):each(function(tab)
		lQuery(tab):find("/component"):delete()
	end)
	lQuery(tabs):delete()
	lQuery(tabCont):delete()
	f:attr("propertyEditorTab", firstTab())
	
	--atver pirma limena lauku ipasibu logu
	openSuperFieldProperty(tonumber(lQuery(f):id()))
end

--atrod pirmo cilni
function firstTab()
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#ChoiceItem instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	
	local compartType = lQuery(fielDRepId):find("/context"):attr("type")
	
	local values 
	values = lQuery("PropertyTab:has(/propertyDiagram[id='" .. compartType .. "'])")
	
	if lQuery("PropertyDiagram[id='" .. compartType .. "']"):is_empty() and fielDRepId:find("/context"):attr("mode") == "Group" then 
		values = lQuery("PropertyTab:has(/propertyDiagram[id='" .. lQuery(fielDRepId):find("/context"):attr("elTypeName") .. "'])")
	end

	if (fielDRepId:find("/context"):attr("path") == "Role/" and fielDRepId:find("/context"):attr("type") == "Name") or (fielDRepId:find("/context"):attr("path") == "InvRole/" and fielDRepId:find("/context"):attr("type") == "Name") then
		values = lQuery("PropertyTab:has(/propertyDiagram[id='" .. lQuery(fielDRepId):find("/context"):attr("elTypeName") .. "'])")
	end
	if fielDRepId:find("/context"):attr("elTypeName") == "Link" then
		values = lQuery("PropertyTab:has(/propertyDiagram[id='" .. lQuery(fielDRepId):find("/context"):attr("elTypeName") .. "'])")
	end
	return values:first():attr("caption")
end

--izvaido apaklaukus
function createSubField()
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")--tree node id
	
	--jaatrod iezimeta klase
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#ContextType instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	
	local f = lQuery.create("AA#Field", {name = "Field", pattern = "a-zA-Z0-9-_", fieldType = "InputField"}):link("superField", fielDRepId)
	--lQuery("AA#RowType[typeName = 'InputField']"):link("field", f)--pievieno nokluseto Field type

	local n = lQuery.create("D#TreeNode", {
		text = "F:Field"
		,id = lQuery(f):id() .. " SubAA#Field"
		,expanded = true}):link("parentNode", lQuery("D#Tree[id = 'treeProfile']/selected"))
	lQuery("D#Tree[id='treeProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	lQuery("D#Tree[id='treeProfile']"):remove_link("selected", lQuery("D#Tree[id='treeProfile']/selected"))
	lQuery("D#Tree[id='treeProfile']"):link("selected", n)
	lQuery("D#Tree[id='treeProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	
	local tabCont = lQuery("D#VerticalBox[id = 'property']/component")--tabConteiner
	local tabs = lQuery(tabCont):find("/component")--tabi
	lQuery(tabs):each(function(tab)
		lQuery(tab):find("/component"):delete()
	end)
	lQuery(tabs):delete()
	lQuery(tabCont):delete()
	
	--atver lauka ipasibu logu
	openFieldProperty(tonumber(lQuery(f):id()))
end

--izveido jauno itemu
function createItem()
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")--tree node id
	--jaatrod iezimeta klase
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)

	local f = lQuery.create("AA#ChoiceItem"):link("field", fielDRepId)
	lQuery(f):attr("caption", "Item")

	--atrast Fieldu kuram pievienojam itemu, pievienot tikko izveidoto treeNode
	local n = lQuery.create("D#TreeNode", {text = "I:Item", id = lQuery(f):id() .. " AA#ChoiceItem"}):link("parentNode", lQuery("D#Tree[id = 'treeProfile']/selected"))
	lQuery("D#Tree[id='treeProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	lQuery("D#Tree[id='treeProfile']"):remove_link("selected", lQuery("D#Tree[id='treeProfile']/selected"))
	lQuery("D#Tree[id='treeProfile']"):link("selected", n)
	lQuery("D#Tree[id='treeProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))

	local tabCont = lQuery("D#VerticalBox[id = 'property']/component")--tabConteiner
	local tabs = lQuery(tabCont):find("/component")--tabi
	lQuery(tabs):each(function(tab)
		lQuery(tab):find("/component"):delete()
	end)

	lQuery(tabs):delete()
	lQuery(tabCont):delete()

	openItemProperty(tonumber(lQuery(f):id()))
end

--kad tiek iezimeta koka rinda, noskaidro kadu logu jaatver
function treeEvent()
    local text = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("text")--tree node id

	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")--tree node id
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)
	repNr = tonumber(repNr)
	
	
	
	local tabCont = lQuery("D#VerticalBox[id = 'property']/component")--tabConteiner
	local tabs = lQuery(tabCont):find("/component")--tabi
	lQuery(tabs):each(function(tab)
		lQuery(tab):find("/component"):delete()
	end)
	lQuery(tabs):delete()
	lQuery(tabCont):delete()
	
	
	if types == "SubAA#Field" then 
		openFieldProperty(repNr)
	end
	if types == "AA#Field" then 
		local fielDRepId -- vajadziga AA#Field instance
		local field = lQuery("AA#Field"):each(function(obj)
			if obj:id() == repNr then 
				fielDRepId = obj
				return
			end end)
		local isExistingField = fielDRepId:attr("isExistingField")
		
		if isExistingField == "true" then
		    openExistingFieldProperty(repNr)
		else
		    openSuperFieldProperty(repNr)
		end
	end
	if types == "AA#ChoiceItem" then 
		openItemProperty(repNr)
	end
	if types == "AA#ContextType" then
		openContextProperty(repNr)
	end
	if types == "AA#Profile" then
		openProfileProperty(repNr)
	end
	if types == "AA#Mid" then
		openMidProperty()
	end
end

--atver starp limena logu
function openMidProperty()
	local close_button = lQuery.create("D#Button", {
		caption = "Close"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.close()")
	})

	-- lQuery("D#VerticalBox[id = 'property']"):delete()
	-- lQuery.create("D#VerticalBox", {id = "property"}):link("container", lQuery("D#HorizontalBox[id = 'HorForm']"))
	
	-- lQuery("D#HorizontalBox[id = 'HorForm']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	
	lQuery("D#VerticalBox[id = 'buttons']"):delete()
	lQuery.create("D#VerticalBox", {id = "buttons",component={lQuery.create("D#Label", {caption="To enter a field, select a context type 'T: ...' in the structure tree"})}})
	:link("container", lQuery("D#HorizontalBox[id = 'closeFormProfile']"))
	
	lQuery("D#VerticalBox[id = 'closeButton']"):delete()
	lQuery.create("D#VerticalBox", {
		id = "closeButton"
		,horizontalAlignment = 1
		,component = {close_button}}):link("container", lQuery("D#HorizontalBox[id = 'closeFormProfile']"))

	lQuery("D#HorizontalBox[id = 'closeFormProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

--atver profila ipasibu logu (nr-profila identifikatotrs)
function openProfileProperty(nr)
	local close_button = lQuery.create("D#Button", {
		caption = "Close"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.close()")
	})

	local prof = lQuery("AA#Profile"):filter(function(pr)
		return pr:id()==tonumber(nr)
	end)
	-- lQuery("D#VerticalBox[id = 'property']"):delete()
	-- lQuery.create("D#VerticalBox", {id = "property"}):link("container", lQuery("D#HorizontalBox[id = 'HorForm']"))
	lQuery.create("D#TabContainer", {
		minimumWidth = 250
		,component = {
			lQuery.create("D#Tab", {--anotaciju tabs
				caption = "Profile properties"
				,component = {
					lQuery.create("D#HorizontalBox", {
						horizontalAlignment = 1
						,component = {
							lQuery.create("D#Label", {caption = "Prefixes", minimumWidth = 100})
							,lQuery.create("D#MultiLineTextBox", {
								id = "ProfilePrefix"
								,textLine = {colectProfilePrefix(prof)}
								,eventHandler = {utilities.d_handler("MultiLineTextBoxChange", "lua_engine", "lua.OWLGrEd_UserFields.Profile.profilePrefix()")}
							})}
					})
				}
			})
		}
	}):link("container", lQuery("D#VerticalBox[id = 'property']"))
	
	lQuery("D#VerticalBox[id = 'property']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	-- lQuery("D#HorizontalBox[id = 'HorForm']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	
	lQuery("D#VerticalBox[id = 'buttons']"):delete()
	lQuery.create("D#VerticalBox", {id = "buttons",component={lQuery.create("D#Label", {caption="To enter a field, select a context type 'T: ...' in the structure tree"})}})
	:link("container", lQuery("D#HorizontalBox[id = 'closeFormProfile']"))
	
	lQuery("D#VerticalBox[id = 'closeButton']"):delete()
	lQuery.create("D#VerticalBox", {
		id = "closeButton"
		,horizontalAlignment = 1
		,component = {close_button}}):link("container", lQuery("D#HorizontalBox[id = 'closeFormProfile']"))
	
	lQuery("D#HorizontalBox[id = 'closeFormProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

--atvar konteksta tipa ipasibu logu (AA#ContextType)
function openContextProperty()

	local close_button = lQuery.create("D#Button", {
		caption = "Close"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.close()")
	})

	lQuery("D#VerticalBox[id = 'property']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	
	lQuery("D#VerticalBox[id = 'buttons']"):delete()
	lQuery.create("D#VerticalBox", {id = "buttons"
		,component = {
		  lQuery.create("D#Button", {
			caption = "Add Field"
			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.createField()")
			})}}):link("container", lQuery("D#HorizontalBox[id = 'HorForm']"))
			:link("container", lQuery("D#HorizontalBox[id = 'closeFormProfile']"))
	lQuery("D#VerticalBox[id = 'closeButton']"):delete()
	lQuery.create("D#VerticalBox", {
		id = "closeButton"
		,horizontalAlignment = 1
		,component = {close_button}}):link("container", lQuery("D#HorizontalBox[id = 'closeFormProfile']"))
	lQuery("D#HorizontalBox[id = 'closeFormProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

--atver choiceItema ipasibu logu (nr-itema identifikators)
function openItemProperty(nr)--atvar item ipasibu logu
	local fielDRepId -- vajadziga AA#ChoiceItem instance
	local field = lQuery("AA#ChoiceItem"):each(function(obj)
		if obj:id() == nr then 
			fielDRepId = obj
			return
		end end)
	local getAttributes = lQuery.model.property_list("AA#ChoiceItem")

	--ja nav attribute
	local cap
	if lQuery(fielDRepId):find("/field/context"):attr("type") ~= "Attributes" then
		cap = "Element style setting"
	else cap = "Attributes style setting"
	end
	local styleTab = ""
	if lQuery(fielDRepId):find("/field/context"):is_not_empty() then
	    styleTab = lQuery.create("D#Tab", {--anotaciju tabs
				caption = "Styles"
				,id = "StyleItem"
				,component = {
					lQuery.create("D#VerticalBox",{
						id = "ItemElementStyleVerticalBox"
						,component = {
							lQuery.create("D#Label", {caption = cap})
							,lQuery.create("D#VTable", {
								id = "TableStyleItemElement"
								,minimumHeight = 180
								,maximumHeight = 180
								,column = {
									lQuery.create("D#VTableColumnType", {
										caption = "Feature",editable = true,width = 220
									})
									,lQuery.create("D#VTableColumnType", {
										caption = "Value",editable = true,width = 220
									})
								}
								,vTableRow = {
									getItemElementStyles()
									,lQuery.create("D#VTableRow", {
										vTableCell = {
											lQuery.create("D#VTableCell", { 
												vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
												,component = lQuery.create("D#ComboBox", {
													text = ""
													,item = getNewStyleItemElement()
													,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.collectItemElementStyleValuesMakeNewRow()")}
												})
											})
											,lQuery.create("D#VTableCell", { value = ""
												,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
											})
										}
									}) 
								}
							})
							,lQuery.create("D#Button", {
								caption = "Delete Element Style"
								,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.deleteOneElementsStyle()")
							})
						}
					})
					,lQuery.create("D#VerticalBox",{
						id = "ItemFieldStyleVerticalBox"
						,component = {
							lQuery.create("D#Label", {caption = "Field style setting"})
							,lQuery.create("D#VTable", {
								id = "TableStyleItemField"
								,column = {
									lQuery.create("D#VTableColumnType", {
										caption = "Target",editable = true,width = 110
									})
									,lQuery.create("D#VTableColumnType", {
										caption = "Path",editable = true,width = 110
									})
									,lQuery.create("D#VTableColumnType", {
										caption = "Feature",editable = true,width = 110
									})
									,lQuery.create("D#VTableColumnType", {
										caption = "Value",editable = true,width = 110
									})
								}
								,vTableRow = {
									getItemFieldStyles()
									,lQuery.create("D#VTableRow", {
										vTableCell = {
											lQuery.create("D#VTableCell", { value = ""
												,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Target']")
												,component = lQuery.create("D#ComboBox", {
													text = ""
													,item = getTarget()
													--,id = lQuery(st):id()
													,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectTarget2()")}
												})
											})
											,lQuery.create("D#VTableCell", { value = ""
												,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Path']")
												,component = lQuery.create("D#Button", {
													caption = "select compartment"
													,eventHandler = {utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.generateElemTypeTree()")}
												})
											})
											,lQuery.create("D#VTableCell", { value = ""
												,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
											})
											,lQuery.create("D#VTableCell", { value = ""
												,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
											})
											
										}
									}) 
								}
							})
							,lQuery.create("D#Button", {
								caption = "Delete Field Style"
								,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.deleteOneFieldStyle()")
							})
						}
					})
				}
			})
	end

	local impSem = fielDRepId:find("/tag[tagKey='owl_Fields_ImportSpec']"):attr("tagValue")
	if fielDRepId:find("/tag[tagKey='owl_Fields_ImportSpec']"):size() == 0 then impSem = "" end
	lQuery.create("D#TabContainer", {
		minimumWidth = 250
		,component = {
			lQuery.create("D#Tab", {--anotaciju tabs
				caption = "ChoiceItem Properties"
				,component = {
					lQuery.map(getAttributes, function(name)--ieraksta visus ipasibas nosaukumus
						local str = name
						str = str:gsub("%a", string.upper, 1)--mainam pirmo burtu pret lielo
						return lQuery.create("D#HorizontalBox", {
							horizontalAlignment = 1
							,component = {
								lQuery.create("D#Label", {caption = str, minimumWidth = 100})
								,lQuery.create("D#InputField", {
									text = fielDRepId:attr(name)
									,id = name
									,eventHandler = {
										utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEventItem()")
									}
								})}
						})
					end)
					,generateTagTypeItem(nr)
					,lQuery.create("D#HorizontalBox", {
						id = "HorizontalBoxItemDelete"
						,horizontalAlignment = 1
						,verticalAlignment = -1
						,component = {
							lQuery.create("D#Button", {
								caption = "Delete Item"
								,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.aksDeleteOneItem()")
							})
						}
					})
				}
			})
			,styleTab
		}
	}):link("container", lQuery("D#VerticalBox[id = 'property']"))

	lQuery("D#VerticalBox[id = 'property']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	local close_button = lQuery.create("D#Button", {
		caption = "Close"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.close()")
	})
	lQuery("D#VerticalBox[id = 'buttons']"):delete()
	lQuery.create("D#VerticalBox", {id = "buttons"})
	:link("container", lQuery("D#HorizontalBox[id = 'closeFormProfile']"))
	lQuery("D#VerticalBox[id = 'closeButton']"):delete()
	lQuery.create("D#VerticalBox", {
		id = "closeButton"
		,horizontalAlignment = 1
		,component = {close_button}}):link("container", lQuery("D#HorizontalBox[id = 'closeFormProfile']"))
	lQuery("D#HorizontalBox[id = 'closeFormProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	
end

--atver formu ar ElemType piesaistitiem CompartType
function generateElemTypeTree()
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")--tree node id
	--jaatrod iezimeta klase
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	lQuery("AA#ChoiceItem"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
    local contextType = fielDRepId:find("/field/context")
	local elementType -- vajadziga ElemType
	if contextType:attr("elTypeName")~="" then elementType = lQuery("ElemType[id='" .. contextType:attr("elTypeName") .. "']") else
	elementType = lQuery("ElemType[id='" .. contextType:attr("type") .. "']") end
	
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profile.closeGenerateElemTypeTree()")
	})
  
	local ok_button = lQuery.create("D#Button", {
		caption = "Ok"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.profile.OkTree()")
	})

	local form = lQuery.create("D#Form", {
		id = "generateElemTypeTree"
		,caption = "Select compartment"
		,buttonClickOnClose = false
		,cancelButton = close_button
		,defaultButton = ok_button
		,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.profile.closeGenerateElemTypeTree()")
		,component = {
			lQuery.create("D#HorizontalBox", {
				id = "HorForm"
				,minimumWidth = 250
				,component = { 
					lQuery.create("D#VerticalBox", {
						id = "VerticalBoxWithTree"
						,component = {
							lQuery.create("D#Tree", {
								id = "treeCompartment",maximumWidth = 250,minimumWidth = 250,maximumHeight = 600,minimumHeight = 600
								,treeNode = lQuery.create("D#TreeNode", {
									text = elementType:attr("caption")
									,id = elementType:id()
									,childNode = styleMechanism.createChildNode(elementType)
									,expanded = true
								})
							})
						}
					})
				}
			})
		  ,lQuery.create("D#HorizontalBox", {
			horizontalAlignment = 1
			,id = "closeFormGenerateElemTypeTree"
			,component = {
			  lQuery.create("D#VerticalBox", {id = "buttons"}) 
			  ,lQuery.create("D#VerticalBox", {
				id = "closeButton"
				,horizontalAlignment = 1
				,component = {ok_button,close_button}})
			  }
		  })
		}
	  })
	  dialog_utilities.show_form(form)
end

function OkTree()
		--atrast compartmetType
	local compartTypeId = lQuery("D#Tree[id='treeCompartment']/selected"):attr("id")
	local compartType = lQuery("CompartType"):filter(
		function(obj)
			return lQuery(obj):id() == tonumber(compartTypeId)
		end)
	if compartType:is_not_empty() then
	
	

	local node = lQuery("D#Tree[id='treeCompartment']/selected"):attr("text")--target
	
	--atrast celu lidz elementam
	local path = ""--path
	local l = 0
	local compartTypeT = compartType
	
		while l==0 do
			if compartTypeT:find("/elemType"):is_empty() then 
				local pat = lpeg.P("ASFictitious")
				if  not lpeg.match(pat, compartTypeT:find("/parentCompartType"):attr("id")) then path = compartTypeT:find("/parentCompartType"):attr("caption")  .. "/" .. path end
				compartTypeT = compartTypeT:find("/parentCompartType")
			else l=1 end
		end

		local row = lQuery("D#VTable[id = 'TableStyleItemField']/selectedRow")
		
		local nodeType = lQuery("NodeType"):filter(
			function(obj)
				return lQuery(obj):id() == compartTypeT:find("/elemType"):id()
			end)
		local elemType
		if nodeType:is_not_empty() then elemType = "NodeType" else elemType = "EdgeType" end
		
		if compartType:find("/elemType"):is_not_empty() or compartType:find("/parentCompartType"):attr("isGroup") == 'true' then 
			elemType = elemType
		else elemType = "NotStyleable" end
		--pielasam jaunas vertibas
		lQuery(row):find("/vTableCell"):delete()
		lQuery.create("D#VTableCell", { value = node
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Target']")
						,component = lQuery.create("D#TextBox", {
							text = node
						})
				}):link("vTableRow", row)
				lQuery.create("D#VTableCell", { value = path
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Path']")
					,component = lQuery.create("D#TextBox", {
						text = path
					})
				}):link("vTableRow", row)
				lQuery.create("D#VTableCell", { value = ""
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
					,component = lQuery.create("D#ComboBox", {
						text = ""
						,item = styleMechanism.getCompartmentStyleItem(elemType)
						,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.collectItemFieldStyleValuesMakeNewRow()")}
					})
				}):link("vTableRow", row)
				lQuery.create("D#VTableCell", { value = ""
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
				}):link("vTableRow", row)
		
		lQuery("D#VTable[id = 'TableStyleItemField']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	end
	closeGenerateElemTypeTree()
	--pievienot tukso rindu
		lQuery.create("D#VTableRow", {
			vTableCell = {
				lQuery.create("D#VTableCell", { value = ""
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Target']")
					,component = lQuery.create("D#ComboBox", {
						text = ""
						,item = getTarget()
						,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectTarget2()")}
					})
				})
				,lQuery.create("D#VTableCell", { value = ""
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Path']")
					,component = lQuery.create("D#Button", {
						caption = "select compartment"
						,eventHandler = {utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.generateElemTypeTree()")}
					})
				})
				,lQuery.create("D#VTableCell", { value = ""
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
				})
				,lQuery.create("D#VTableCell", { value = ""
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
				})
			}
		}):link("vTable", lQuery("D#VTable[id = 'TableStyleItemField']"))	
		lQuery("D#VTable[id = 'TableStyleItemField']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

function collectElemTypeStructure()--?????????????
	--jaatrod AA#ContextType inctance
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local field = lQuery("AA#ChoiceItem"):filter(function(obj)
		return obj:id() == repNr end)
	local context = lQuery(field):find("/field/context")
	
	--jaatrod elemType
	  --vai nu no elTypeName
	  --vai no type, elTypeName nav noradits
	local elemType = lQuery("ElemType[id = '" .. context:attr('elTypeName') .. "']")
	if elemType:is_empty() then elemType = lQuery("ElemType[id = '" .. context:attr("type") .. "']") end
	
	--jauzbuve koks
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.closeTree()")
  })
  
  local ok_button = lQuery.create("D#Button", {
    caption = "Ok"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.closeTree()")
  })

  local form = lQuery.create("D#Form", {
    id = "CompartmentTree"
    ,caption = "Select compartType"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = ok_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.closeTree()")
	,component = {
		lQuery.create("D#HorizontalBox", {
			id = "HorForm"
			,minimumWidth = 250
			,component = { 
				lQuery.create("D#VerticalBox", {
					id = "VerticalBoxWithTree"
					,component = {
						lQuery.create("D#Tree", {
							id = "treeCompartment"
							,maximumWidth = 250
							,minimumWidth = 250
							,maximumHeight = 600
							,minimumHeight = 600
							,treeNode = lQuery.create("D#TreeNode", {
								text = elemType:attr("caption")
								,id = elemType:id()
								,childNode = styleMechanism.createChildNode(elemType)
								,expanded = true
							})
						})}
					})
			}
		})
      ,lQuery.create("D#HorizontalBox", {
        horizontalAlignment = 1
		,id = "closeFormCompartmentTree"
        ,component = {
		  lQuery.create("D#VerticalBox", {id = "buttons"}) 
		  ,lQuery.create("D#VerticalBox", {
			id = "closeButton"
			,horizontalAlignment = 1
			,component = {ok_button,close_button}})
		  }
      })
    }
  })
  dialog_utilities.show_form(form)
end

--atlasa targetus
function getTarget()
	--atkariba no ta kads ir CompartType
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#ChoiceItem instance
	local field = lQuery("AA#ChoiceItem"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	local context = lQuery(fielDRepId):find("/field/context")
	local mode = context:attr("mode")
	local values
	if mode == "Element" then 
		local elemType = context:attr("type")
		values = lQuery("CompartType:has(/elemType[id='" .. elemType .. "'])")

		values = values:map(
		  function(obj, i)
			return {lQuery(obj):attr("caption"), lQuery(obj):id()}
		  end)
	else
		local path = context:attr("path")
		local pathTable = styleMechanism.split(path, "/")
		local elemType = lQuery("ElemType[caption='" .. context:attr("elTypeName") .. "']")
		local comparType

		if #pathTable ~= 1 then
			compartType = elemType:find("/compartType[caption='" .. pathTable[1] .. "']")
			local pat = lpeg.P("ASFictitious")
			if lpeg.match(pat, compartType:attr("id")) then 
				compartType = compartType:find("/subCompartType[caption='" .. pathTable[1] .. "']")
			end
			for i=2,#pathTable,1 do 
				if pathTable[i] ~= "" then 
					compartType = compartType:find("/subCompartType[caption='" .. pathTable[i] .. "']")
					if lpeg.match(pat, compartType:attr("id")) then 
						compartType = compartType:find("/subCompartType[caption='" .. pathTable[i] .. "']")
						end
				end
			end
			compartType2 = compartType:find("/subCompartType[caption='" .. context:attr("type") .. "']")
			if compartType2:is_empty() then compartType = compartType:find("/subCompartType[caption='CheckBoxFictitious" .. context:attr("type") .. "']") 
			else compartType = compartType2
			end
			local pat = lpeg.P("ASFictitious")
			if lpeg.match(pat, compartType:attr("id")) then 
				compartType = compartType:find("/subCompartType[caption='" .. context:attr("type") .. "']")
				if compartType:is_empty() then compartType = compartType:find("/subCompartType[caption='CheckBoxFictitious" .. context:attr("type") .. "']") end
			end
			values1 = lQuery(compartType):find("/subCompartType"):map(
			  function(obj, i)
				return {lQuery(obj):attr("caption")}
			  end)
			values2 = fielDRepId:find("/field"):map(
			  function(obj, i)
				return {lQuery(obj):attr("name")}
			  end)
			values = lQuery.merge(values1, values2)
		else--ja ir pirma limenja lauks
			compartType = elemType:find("/compartType[caption='" .. context:attr("type") .. "']")
			
			if compartType:is_empty() then compartType = elemType:find("/compartType[caption='CheckBoxFictitious" .. context:attr("type") .. "']") end
			
			local pat = lpeg.P("ASFictitious")
			if lpeg.match(pat, compartType:attr("id")) then 
				compartType = compartType:find("/subCompartType[caption='" .. context:attr("type") .. "']")
			end
			
			values1 = lQuery(compartType):find("/subCompartType"):map(
			  function(obj, i)
				return {lQuery(obj):attr("caption")}
			  end)
			values2 = fielDRepId:find("/field"):map(
			  function(obj, i)
				return {lQuery(obj):attr("name")}
			  end)
			values = lQuery.merge(values1, values2)
		end
	end

	return lQuery.map(values, function(mode_value) 
		return lQuery.create("D#Item", {
			value = mode_value[1]
			,id = mode_value[2]
		}) 
	end)
end

--noskaidro, vai izveles vienumu tiesam ir jadzess
function aksDeleteOneItem()

	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#ChoiceItem instance
	local field = lQuery("AA#ChoiceItem"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)

	local valuesD = lQuery(fielDRepId):find("/dependency/dependsOn"):map(
	  function(obj, i)
		return {lQuery(obj):attr("caption"), lQuery(obj):find("/field"):attr("name")}
	  end)
	
	local valuesS = lQuery(fielDRepId):find("/tag"):map(
	  function(obj, i)
		return {lQuery(obj):attr("tagValue"), lQuery(obj):id()}
	  end)
	  
	local valuesSt = lQuery(fielDRepId):find("/styleSetting"):map(
	  function(obj, i)
		return {lQuery(obj):attr("value"), lQuery(obj):id()}
	  end)
	
	local close_button = lQuery.create("D#Button", {
    caption = "No"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.closeAksDeleteOneItem()")
  })
	
	local yesItem = lQuery.create("D#Button", {
    caption = "Yes"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.deleteAksDeleteOneItem()")
  })
	
  local form = lQuery.create("D#Form", {
    id = "aksDeleteOneItem"
    ,caption = "Are you sure you want to delete..."
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.Profile.closeAksDeleteOneItem()")
	,component = {
		lQuery.create("D#HorizontalBox", {
			id = "HorFormItem"
			,component = { 
				lQuery.create("D#VerticalBox", {
					id = "VerticalBoxItem"
					,component = {
						lQuery.create("D#Label", {caption = "Are you sure you want to delete:"})
						,lQuery.create("D#Label", {caption = "--Dependencies:"})
						,lQuery.map(valuesD, function(mode_value) 
						return lQuery.create("D#Label", {
							caption = mode_value[1] .. " " .. mode_value[2]
							,id = mode_value[2]
							}) 
						end)
						,lQuery.create("D#Label", {caption = "--Tags:"})
						,lQuery.map(valuesS, function(mode_value) 
						return lQuery.create("D#Label", {
							caption = mode_value[1]
							,id = mode_value[2]
							}) 
						end)
						,lQuery.create("D#Label", {caption = "--StyleSetting:"})
						,lQuery.map(valuesSt, function(mode_value) 
						return lQuery.create("D#Label", {
							caption = mode_value[1]
							,id = mode_value[2]
							}) 
						end)
					}
				})
			}
		})
      ,lQuery.create("D#HorizontalBox", {
		id = "closeFormItem"
        ,component = {
		  lQuery.create("D#HorizontalBox", {
			id = "closeButtonItem"
			,component = {
				yesItem
				,close_button}})
		  }
      })
    }
  })
  dialog_utilities.show_form(form)
end

--izdzes izveles vienumu
function deleteAksDeleteOneItem()

	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#ChoiceItem instance
	local field = lQuery("AA#ChoiceItem"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
		
--------------------------------------	
	lQuery(fielDRepId):find("/dependency"):delete()
	lQuery(fielDRepId):find("/tag"):delete()
	lQuery(fielDRepId):find("/styleSetting"):delete()
	lQuery(fielDRepId):delete()
	

	local p = lQuery("D#Tree[id = 'treeProfile']/selected/parentNode")
	local n = lQuery("D#Tree[id = 'treeProfile']/selected")
	
	lQuery("D#Tree[id='treeProfile']"):remove_link("selected", lQuery("D#Tree[id='treeProfile']/selected"))
	lQuery("D#Tree[id='treeProfile']"):link("selected", p)
	lQuery("D#Tree[id='treeProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	lQuery(n):delete()
	lQuery("D#Tree[id='treeProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	
	local tabCont = lQuery("D#VerticalBox[id = 'property']/component")--tabConteiner
	local tabs = lQuery(tabCont):find("/component")--tabi
	lQuery(tabs):each(function(tab)
		lQuery(tab):find("/component"):delete()
	end)
	lQuery(tabs):delete()
	lQuery(tabCont):delete()
	
	
	if types == "AA#Field" then 
		openSuperFieldProperty(tonumber(repNr))
	else
		openFieldProperty(tonumber(repNr))
	end
	
	closeAksDeleteOneItem()
end

--atver apakslauka ipasibu logu (nr-lauka identifikators)
function openFieldProperty(nr)

	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == nr then 
			fielDRepId = obj
			return
		end end)
		
	--local defaultItem = fielDRepId:find("/fieldType"):attr("typeName")
	local defaultItem = fielDRepId:attr("fieldType")
	
	local getAttributes = lQuery.model.property_list("AA#Field")
	local impSem = fielDRepId:find("/tag[tagKey='owl_Fields_ImportSpec']"):attr("tagValue")
	if fielDRepId:find("/tag[tagKey='owl_Fields_ImportSpec']"):size() == 0 then impSem = "" end
    -- lQuery("D#VerticalBox[id = 'property']"):delete()
	-- lQuery.create("D#VerticalBox", {
		-- id = "property"
		-- ,component = { 
			lQuery.create("D#TabContainer", {
				minimumWidth = 250
				,component = {
					lQuery.create("D#Tab", {--anotaciju tabs
						caption = "Field Properties"
						,component = {
							lQuery.map(getAttributes, function(name)--ieraksta visus ipasibas nosaukumus
								local str = name
								str = str:gsub("%a", string.upper, 1)--mainam pirmo burtu pret lielo
								if name == "isStereotypeField" then 
									return lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,component = {
										    lQuery.create("D#Label", {caption = str, minimumWidth = 160})
											,lQuery.create("D#CheckBox", {
												checked = fielDRepId:attr(name)
												,id = name
												,eventHandler = {
													utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEvent()")
												}
											})}
									})
								end
								if name == "prefix" or name == "suffix" or name == "delimiter" then 
									return lQuery.create("D#HorizontalBox", {
										horizontalAlignment = 1
										,component = {
											lQuery.create("D#Label", {caption = str, minimumWidth = 160})
											,lQuery.create("D#TextArea", {
												text = fielDRepId:attr(name)
												,id = name
												,eventHandler = {utilities.d_handler("FocusLost", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEvent()")}
											})}
									})
									
								end
								if name == "fieldType" then
									return lQuery.create("D#HorizontalBox", {
										horizontalAlignment = 1
										,component = {
											lQuery.create("D#Label", {caption = "FieldType", minimumWidth = 160})
											,lQuery.create("D#ComboBox", {
												id = "fieldType"
												--,text = defaultItem
												,text = fielDRepId:attr(name)
												,item = createItemsForFieldType()
												,eventHandler = {
													utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEventFieldType()")
												}
											})}
									})
								end
									return lQuery.create("D#HorizontalBox", {
										horizontalAlignment = 1
										,component = {
											lQuery.create("D#Label", {caption = str, minimumWidth = 160})
											,lQuery.create("D#InputField", {
												text = fielDRepId:attr(name)
												,id = name
												,eventHandler = {
													utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEvent()")
												}
											})}
									})
							end)
							-- ,lQuery.create("D#HorizontalBox", {
								-- horizontalAlignment = 1
								-- ,component = {
									-- lQuery.create("D#Label", {caption = "FieldType", minimumWidth = 160})
									-- ,lQuery.create("D#ComboBox", {
										-- id = "fieldType"
										-- ,text = defaultItem
										-- ,item = createItemsForFieldType()
										-- ,eventHandler = {
											-- utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEventFieldType()")
										-- }
									-- })}
							-- })
							,lQuery.create("D#HorizontalBox", {
								horizontalAlignment = 1
								,component = {
									lQuery.create("D#Button", {
										caption = "Delete Field"
										,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.aksDeleteOneField()")
									})}
							})
						}
					})
					,lQuery.create("D#Tab", {
						caption = "Tags"
						,id = "Semantics"
						,component = {
							generateTagType(nr)
						}
					})
					,lQuery.create("D#Tab", {
						caption = "Translets"
						,id = "Translets"
						,component = {
							lQuery.create("D#VerticalBox", {
							  component = {
								lQuery.create("D#VTable", {
									id = "TableTransletes"
									,column = {
										lQuery.create("D#VTableColumnType", {
											caption = "Translet_task",editable = true,width = 150
										})
										,lQuery.create("D#VTableColumnType", {
											caption = "Procedure",editable = true,width = 320
										})
									}
									,vTableRow = {
										getTranslete()
										,lQuery.create("D#VTableRow", {
											vTableCell = {
												lQuery.create("D#VTableCell", { 
													vTableColumnType = lQuery("D#VTableColumnType[caption = 'Translet_task']")
													,component = lQuery.create("D#ComboBox", {
														item = {getTransletTasks()}
														,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectTransletTask()")}
													})
												})
												,lQuery.create("D#VTableCell", { value = ""
													,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Procedure']")
													,component = lQuery.create("D#TextBox", {text = ""})
												})
											}
										})
									}
								})
								,lQuery.create("D#Button", {
									caption = "Delete Translet"
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.deleteOneTranslete()")
								})
							}})
						}
					})
					-- ,lQuery.create("D#Tab", {
						-- caption = "Dependencies"
						-- ,id = "Dependencies"
						-- ,component = {
							-- lQuery.create("D#VerticalBox",{
							  -- id = "VerBoxDependencies"
							  -- ,component = {
								-- lQuery.create("D#VerticalBox",{
									-- id = "VerBoxDependenciesLine"
									-- ,component = {
										-- getDependencies()
									-- }
								-- })
								-- ,lQuery.create("D#Button", {
									-- caption = "Add Dependency"
									-- ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.getNewDependencies()")
								-- })
								-- ,lQuery.create("D#Button", {
									-- caption = "Delete Dependency"
									-- ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.deleteOneDependency()")
								-- })
							-- }})
						-- }
					-- })
				}
			}):link("container", lQuery("D#VerticalBox[id = 'property']"))
		-- }
	-- }):link("container", lQuery("D#HorizontalBox[id = 'HorForm']"))
		
	changeButtons(defaultItem)
		
    lQuery("D#VerticalBox[id = 'property']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
    -- lQuery("D#Form[id='Profile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

--noskaidro vai luks tiesam irjadzes
function aksDeleteOneField() 
	
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#ChoiceItem instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	
	local valuesI = lQuery(fielDRepId):find("/choiceItem"):map(
	  function(obj, i)
		return {lQuery(obj):attr("caption")}
	  end)
	
	local valuesF = lQuery(fielDRepId):find("/subField"):map(
	  function(obj, i)
		return {lQuery(obj):attr("name"), lQuery(obj):id()}
	  end)

	local close_button = lQuery.create("D#Button", {
    caption = "No"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.closeAksDeleteOneField()")
  })
	
	local yesItem = lQuery.create("D#Button", {
    caption = "Yes"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.deleteAksDeleteOneField()")
  })
	
  local form = lQuery.create("D#Form", {
    id = "aksDeleteOneField"
    ,caption = "Are you sure you want to delete..."
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.Profile.closeAksDeleteOneField()")
	,component = {
		lQuery.create("D#HorizontalBox", {
			id = "HorFormField"
			,component = { 
				lQuery.create("D#VerticalBox", {
					id = "VerticalBoxField"
					,component = {
						lQuery.create("D#Label", {caption = "Are you sure you want to delete all dependent elements?"})
						,lQuery.create("D#Label", {caption = "--Items:"})
						,lQuery.map(valuesI, function(mode_value) 
						return lQuery.create("D#Label", {
							caption = mode_value[1]
							}) 
						end)
						,lQuery.create("D#Label", {caption = "--Fields:"})
						,lQuery.map(valuesF, function(mode_value) 
						return lQuery.create("D#Label", {
							caption = mode_value[1]
							}) 
						end)
					}
				})
			}
		})
      ,lQuery.create("D#HorizontalBox", {
		id = "closeFormField"
        ,component = {
		  lQuery.create("D#HorizontalBox", {
			id = "closeButtonField"
			,component = {
				yesItem
				,close_button}})
		  }
      })
    }
  })
  dialog_utilities.show_form(form)
	
end

--izdzes lauku
function deleteAksDeleteOneField()
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)

	local profileName = fielDRepId:find("/profile"):attr("name")
	local extension = lQuery("Extension[id = '" .. profileName .. "'][type='aa#Profile']")
	local compartType = lQuery(extension):find("/type[id='" .. fielDRepId:attr("name") .. "']")
	if fielDRepId:attr("isExistingField") == "true" then
		extension:remove_link("type", compartType)
		compartType:remove_link("extension", extension)
	end
	
	allSubFields(fielDRepId)--izdzest instances
	--izdzest kokaa
	local p = lQuery("D#Tree[id = 'treeProfile']/selected/parentNode")
	local n = lQuery("D#Tree[id = 'treeProfile']/selected")
	
	lQuery("D#Tree[id='treeProfile']"):remove_link("selected", lQuery("D#Tree[id='treeProfile']/selected"))
	lQuery("D#Tree[id='treeProfile']"):link("selected", p)
	lQuery("D#Tree[id='treeProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	lQuery(n):delete()
	lQuery("D#Tree[id='treeProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	
	local tabCont = lQuery("D#VerticalBox[id = 'property']/component")--tabConteiner
	local tabs = lQuery(tabCont):find("/component")--tabi
	lQuery(tabs):each(function(tab)
		lQuery(tab):find("/component"):delete()
	end)
	lQuery(tabs):delete()
	lQuery(tabCont):delete()
	
	if types == "AA#Field" then 
		openSuperFieldProperty(tonumber(repNr))
	elseif types == "SubAA#Field" then
		openFieldProperty(tonumber(repNr))
	else openContextProperty(tonumber(repNr))
	end
	
	closeAksDeleteOneField()
end

--izdzes visus Filda atkarigos elementus
function allSubFields(field)
	local subFields = lQuery(field):find("/subField")
	
	--izdzest itemus, semantiku, transletus, atkaribas, stilus, apakslaukus
	lQuery(field):find("/tag"):delete()
	lQuery(field):find("/translet"):delete()
	lQuery(field):find("/dependency"):delete()
	lQuery(field):find("/selfStyleSetting"):delete()
	lQuery(field):find("/choiceItem"):each(function(objI)
		--izdzest atkaribas, semantiku, stilus
		lQuery(objI):find("/dependency"):delete()
		lQuery(objI):find("/tag"):delete()
		lQuery(objI):find("/styleSetting"):delete()
		
		lQuery(objI):delete()
	end)
	lQuery(field):delete()
	if lQuery(subFields):size() == 0 then 
		return
	else
		lQuery(subFields):each(function(obj)
			return allSubFields(obj)
		end)
	end
end

--atver lauka ipasibu logu (nr-lauka identifikators)
function openSuperFieldProperty(nr)
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == nr then 
			fielDRepId = obj
			return
		end end)
	--local defaultItem = fielDRepId:find("/fieldType"):attr("typeName")
	local defaultItem = fielDRepId:attr("fieldType")
	local fieldStyleComponent
	local context = fielDRepId:find("/context"):attr("type")
	
	fieldStyleComponent = lQuery.create("D#VerticalBox",{
		id = "FieldStyleVerticalBox"
		,component = {
			lQuery.create("D#VTable", {
				id = "TableStyleField"
				,column = {
					lQuery.create("D#VTableColumnType", {
						caption = "Feature",editable = true,width = 220
					})
					,lQuery.create("D#VTableColumnType", {
						caption = "Value",editable = true,width = 220
					})
				}
				,vTableRow = {
					getFieldStyles()
					,lQuery.create("D#VTableRow", {
						vTableCell = {
							lQuery.create("D#VTableCell", { 
								vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
									,component = lQuery.create("D#ComboBox", {
										text = ""
										,item = getNewStyleField()
										,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.collectFieldStyleValuesMakeNewRow()")}
									})
							})
							,lQuery.create("D#VTableCell", { value = ""
								,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
							})
						}
					}) 
				}
			})
			,lQuery.create("D#Button", {
				caption = "Delete Style"
				,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.deleteOneStyle()")
			})
		}
	})
	local impSem = fielDRepId:find("/tag[tagKey='owl_Fields_ImportSpec']"):attr("tagValue")
	if fielDRepId:find("/tag[tagKey='owl_Fields_ImportSpec']"):size() == 0 then impSem = "" end
	local getAttributes = lQuery.model.property_list("AA#Field")
    -- lQuery("D#VerticalBox[id = 'property']"):delete()
	-- lQuery.create("D#VerticalBox", {
		-- id = "property"
		-- ,component = { 
			lQuery.create("D#TabContainer", {
				minimumWidth = 250
				,component = {
					lQuery.create("D#Tab", {--anotaciju tabs
						caption = "Field Properties"
						,component = {
							lQuery.map(getAttributes, function(name)--ieraksta visus ipasibas nosaukumus
								local str = name
								str = str:gsub("%a", string.upper, 1)--mainam pirmo burtu pret lielo
								if name == "isStereotypeField" or name == "isExistingField" then 
									return lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,component = {
										    lQuery.create("D#Label", {caption = str, minimumWidth = 160})
											,lQuery.create("D#CheckBox", {
												checked = fielDRepId:attr(name)
												,id = name
												,eventHandler = {
													utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEvent()")
												}
											})}
									})
								end
								if name == "displayPlaceBefore" then 
									return lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,component = {
										    lQuery.create("D#Label", {caption = str, minimumWidth = 160})
											,lQuery.create("D#ComboBox", {
												text = fielDRepId:attr(name)
												,item = getDisplayPlaceBefore()
												,id = name
												,eventHandler = {
													utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEvent()")
												}
											})
											}
									})
								end
								if name == "propertyEditorTab" then 
									local tab = fielDRepId:attr(name)
									return lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,component = {
										    lQuery.create("D#Label", {caption = str, minimumWidth = 160})
											,lQuery.create("D#ComboBox", {
												text = tab
												,item = getPropertyEditorTab()
												,id = name
												,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.refreshPropertyEditorPlaceBefore()")}
											})
											}
									})
								end
								if name == "propertyEditorPlaceBefore" then 
									return lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,id = "propertyEditorPlaceBefore"
										,component = {
										    lQuery.create("D#Label", {caption = str, minimumWidth = 160})
											,lQuery.create("D#ComboBox", {
												text = fielDRepId:attr(name)
												,item = getPropertyEditorPlaceBefore()
												,id = name
												,eventHandler = {
													utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEvent()")
												}
											})
											}
									})
								end
								if name == "prefix" or name == "suffix" or name == "delimiter" then 
									return lQuery.create("D#HorizontalBox", {
										horizontalAlignment = 1
										,component = {
											lQuery.create("D#Label", {caption = str, minimumWidth = 160})
											,lQuery.create("D#TextArea", {
												text = fielDRepId:attr(name)
												,id = name
												,eventHandler = {utilities.d_handler("FocusLost", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEvent()")}
											})}
									})
								end
								if name == "fieldType" then
									return lQuery.create("D#HorizontalBox", {
										horizontalAlignment = 1
										,component = {
											lQuery.create("D#Label", {caption = "FieldType", minimumWidth = 160})
											,lQuery.create("D#ComboBox", {
												id = "fieldType"
												--,text = defaultItem
												,text = fielDRepId:attr(name)
												,item = createItemsForFieldType()
												,eventHandler = {
													utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEventFieldType()")
												}
											})}
									})
								end
									return lQuery.create("D#HorizontalBox", {
										horizontalAlignment = 1
										,component = {
											lQuery.create("D#Label", {caption = str, minimumWidth = 160})
											,lQuery.create("D#InputField", {
												text = fielDRepId:attr(name)
												,id = name
												,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEvent()")}
											})}
									})
							end)
							-- ,lQuery.create("D#HorizontalBox", {
								-- horizontalAlignment = 1
								-- ,component = {
									-- lQuery.create("D#Label", {caption = "FieldType", minimumWidth = 160})
									-- ,lQuery.create("D#ComboBox", {
										-- id = "fieldType"
										-- ,text = defaultItem
										-- ,item = createItemsForFieldType()
										-- ,eventHandler = {
											-- utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEventFieldType()")
										-- }
									-- })}
							-- })
							,lQuery.create("D#HorizontalBox", {
								horizontalAlignment = 1
								,component = {
									lQuery.create("D#Button", {
										caption = "Delete Field"
										,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.aksDeleteOneField()")
									})}
							})
						}
					})
					
					,lQuery.create("D#Tab", {--anotaciju tabs
						caption = "Tags"
						,id = "Semantics"
						,component = {
							generateTagType(nr)
						}
					})
					,lQuery.create("D#Tab", {
						caption = "Translets"
						,id = "Translets"
						,component = {
							lQuery.create("D#VerticalBox", {
							  component = {
								lQuery.create("D#VTable", {
									id = "TableTransletes"
									,column = {
										lQuery.create("D#VTableColumnType", {
											caption = "Translet_task",editable = true,width = 150
										})
										,lQuery.create("D#VTableColumnType", {
											caption = "Procedure",editable = true,width = 320
										})
									}
									,vTableRow = {
										getTranslete()
										,lQuery.create("D#VTableRow", {
											vTableCell = {
												lQuery.create("D#VTableCell", { 
													vTableColumnType = lQuery("D#VTableColumnType[caption = 'Translet_task']")
													,component = lQuery.create("D#ComboBox", {
														item = {getTransletTasks()}
													,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectTransletTask()")}
													})
												})
												,lQuery.create("D#VTableCell", { value = ""
													,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Procedure']")
													,component = lQuery.create("D#TextBox", {text = ""})
												})
											}
										})
									}
								})
								,lQuery.create("D#Button", {
									caption = "Delete Translet"
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.deleteOneTranslete()")
								})
							}})
						}
					})
					-- ,lQuery.create("D#Tab", {
						-- caption = "Dependencies"
						-- ,id = "Dependencies"
						-- ,component = {
							-- lQuery.create("D#VerticalBox",{
							  -- id = "VerBoxDependencies"
							  -- ,component = {
								-- lQuery.create("D#VerticalBox",{
									-- id = "VerBoxDependenciesLine"
									-- ,component = {
										-- getDependencies()
									-- }
								-- })
								-- ,lQuery.create("D#Button", {
									-- caption = "Add Dependency"
									-- ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.getNewDependencies()")
								-- })
								-- ,lQuery.create("D#Button", {
									-- caption = "Delete Dependency"
									-- ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.deleteOneDependency()")
								-- })
							-- }})
						-- }
					-- })
					,lQuery.create("D#Tab", {
						caption = "FieldStyle"
						,id = "StyleField"
						,component = {
							fieldStyleComponent
						}
					})
				}
			}):link("container", lQuery("D#VerticalBox[id = 'property']"))
		-- }
	-- }):link("container", lQuery("D#HorizontalBox[id = 'HorForm']"))
	changeButtons(defaultItem)
    lQuery("D#VerticalBox[id = 'property']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

--atver lauka ipasibu logu (nr-lauka identifikators)
function openExistingFieldProperty(nr)
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == nr then 
			fielDRepId = obj
			return
		end end)
		
	--local defaultItem = fielDRepId:find("/fieldType"):attr("typeName")
	local defaultItem = fielDRepId:attr("fieldType")
	local fieldStyleComponent
	local context = fielDRepId:find("/context"):attr("type")
	
	
	local impSem = fielDRepId:find("/tag[tagKey='owl_Fields_ImportSpec']"):attr("tagValue")
	if fielDRepId:find("/tag[tagKey='owl_Fields_ImportSpec']"):size() == 0 then impSem = "" end
	local getAttributes = lQuery.model.property_list("AA#Field")
    -- lQuery("D#VerticalBox[id = 'property']"):delete()
	-- lQuery.create("D#VerticalBox", {
		-- id = "property"
		-- ,component = { 
			lQuery.create("D#TabContainer", {
				minimumWidth = 250
				,component = {
					lQuery.create("D#Tab", {--anotaciju tabs
						caption = "Field Properties"
						,component = {
							lQuery.map(getAttributes, function(name)--ieraksta visus ipasibas nosaukumus
								local str = name
								str = str:gsub("%a", string.upper, 1)--mainam pirmo burtu pret lielo
								if name == "isExistingField" then 
									return lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,component = {
										    lQuery.create("D#Label", {caption = str, minimumWidth = 160})
											,lQuery.create("D#CheckBox", {
												checked = fielDRepId:attr(name)
												,id = name
												,eventHandler = {
													utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEvent()")
												}
											})}
									})
								end
								if name == "isStereotypeField" or name == "isExistingField" then 
									return lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,component = {
										    lQuery.create("D#Label", {caption = str, minimumWidth = 160})
											,lQuery.create("D#CheckBox", {
												checked = fielDRepId:attr(name)
												,enabled = false
												,id = name
												,eventHandler = {
													utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEvent()")
												}
											})}
									})
								end
								if name == "displayPlaceBefore" then 
									return lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,component = {
										    lQuery.create("D#Label", {caption = str, minimumWidth = 160})
											,lQuery.create("D#ComboBox", {
												text = fielDRepId:attr(name)
												,enabled = false
												,item = getDisplayPlaceBefore()
												,id = name
												,eventHandler = {
													utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEvent()")
												}
											})
											}
									})
								end
								if name == "propertyEditorTab" then 
									local tab = fielDRepId:attr(name)
									return lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,component = {
										    lQuery.create("D#Label", {caption = str, minimumWidth = 160})
											,lQuery.create("D#ComboBox", {
												text = tab
												,enabled = false
												,item = getPropertyEditorTab()
												,id = name
												,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.refreshPropertyEditorPlaceBefore()")}
											})
											}
									})
								end
								if name == "propertyEditorPlaceBefore" then 
									return lQuery.create("D#HorizontalBox", {
										horizontalAlignment = -1
										,id = "propertyEditorPlaceBefore"
										,component = {
										    lQuery.create("D#Label", {caption = str, minimumWidth = 160})
											,lQuery.create("D#ComboBox", {
												text = fielDRepId:attr(name)
												,enabled = false
												,item = getPropertyEditorPlaceBefore()
												,id = name
												,eventHandler = {
													utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEvent()")
												}
											})
											}
									})
								end
								if name == "prefix" or name == "suffix" or name == "delimiter" then 
									return lQuery.create("D#HorizontalBox", {
										horizontalAlignment = 1
										,component = {
											lQuery.create("D#Label", {caption = str, minimumWidth = 160})
											,lQuery.create("D#TextArea", {
												text = fielDRepId:attr(name)
												,enabled = false
												,id = name
												,eventHandler = {utilities.d_handler("FocusLost", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEvent()")}
											})}
									})
								end
								if name == "fieldType" then
									return lQuery.create("D#HorizontalBox", {
										horizontalAlignment = 1
										,component = {
											lQuery.create("D#Label", {caption = "FieldType", minimumWidth = 160})
											,lQuery.create("D#ComboBox", {
												id = "fieldType"
												--,text = defaultItem
												,text = fielDRepId:attr(name)
												,enabled = false
												,item = createItemsForFieldType()
												,eventHandler = {
													utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEventFieldType()")
												}
											})}
									})
								end
									return lQuery.create("D#HorizontalBox", {
										horizontalAlignment = 1
										,component = {
											lQuery.create("D#Label", {caption = str, minimumWidth = 160})
											,lQuery.create("D#InputField", {
												text = fielDRepId:attr(name)
												,enabled = false
												,id = name
												,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEvent()")}
											})}
									})
							end)
							,lQuery.create("D#HorizontalBox", {
								horizontalAlignment = 1
								,component = {
									lQuery.create("D#Button", {
										caption = "Delete Field"
										,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.aksDeleteOneField()")
									})}
							})
						}
					})
					
					,lQuery.create("D#Tab", {--anotaciju tabs
						caption = "Tags"
						,id = "Semantics"
						,component = {
							generateTagType(nr)
						}
					})
					
				}
			}):link("container", lQuery("D#VerticalBox[id = 'property']"))
		-- }
	-- }):link("container", lQuery("D#HorizontalBox[id = 'HorForm']"))
	changeButtons(defaultItem)
    -- lQuery("D#Form[id='Profile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
    lQuery("D#VerticalBox[id = 'property']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

--iaveido laukus semantikas ierakstisanai pie izveles vienuma
function generateTagTypeItem(nr)
	local tagType = lQuery("AA#TagType"):map(function(obj)
		return {obj:attr("key"), obj:attr("notation"), obj:attr("rowType"), obj:id()}
	end)
	return lQuery.map(tagType, function(obj) 
		if obj[3] == "TextArea+Button" then 
			return  lQuery.create("D#HorizontalBox", {
								horizontalAlignment = 1
								,verticalAlignment = -1
								,component = {
									lQuery.create("D#Label", {caption = obj[2], minimumWidth = 100})
									,lQuery.create("D#MultiLineTextBox", {
										id = obj[4]
										,textLine = {colectSemanticsItem(nr, obj[1])}
										,eventHandler = {
											utilities.d_handler("MultiLineTextBoxChange", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEventSemanticsItem()")
										}
									})
								}
							})
		elseif obj[3] == "TextArea" then 
			return lQuery.create("D#HorizontalBox", {
								horizontalAlignment = 1
								,verticalAlignment = -1
								,component = {
									lQuery.create("D#Label", {caption = obj[2], minimumWidth = 100})
									,lQuery.create("D#TextArea", {
										id = obj[4]
										,text = colectSemanticsImportItem(obj[1])
										,eventHandler = {
											utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEventImportSemanticsItem()")
										}
									})
								}
							})
		end
	end)
end

--iaveido laukus semantikas ierakstisanai pie lauka
function generateTagType(nr)

	local tagType = lQuery("AA#TagType"):map(function(obj)
		return {obj:attr("key"), obj:attr("notation"), obj:attr("rowType"), obj:id()}
	end)
	return lQuery.map(tagType, function(obj) 
		if obj[3] == "TextArea+Button" then 
			return  lQuery.create("D#HorizontalBox", {
								horizontalAlignment = 1
								,verticalAlignment = -1
								,component = {
									lQuery.create("D#Label", {caption = obj[2], minimumWidth = 100})
									,lQuery.create("D#MultiLineTextBox", {
										id = obj[4]
										,textLine = {colectSemantics(nr, obj[1])}
										,eventHandler = {
											utilities.d_handler("MultiLineTextBoxChange", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEventSemantics()")
										}
									})
								}
							})
		elseif obj[3] == "TextArea" then 
			return lQuery.create("D#HorizontalBox", {
								horizontalAlignment = 1
								,verticalAlignment = -1
								,component = {
									lQuery.create("D#Label", {caption = obj[2], minimumWidth = 100})
									,lQuery.create("D#TextArea", {
										id = obj[4]
										,text = colectSemanticsImport(obj[1])
										,eventHandler = {
											utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEventImportSemantics()")
										}
									})
								}
							})
		end
	end)
end

--atjauno propertyEditorPlaceBefore lauku, pielasa jaunos izveles vienumus
function refreshPropertyEditorPlaceBefore()
	local tab = lQuery("D#Event/source"):attr("text")
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	fielDRepId:attr("propertyEditorPlaceBefore", "")
	fielDRepId:attr("propertyEditorTab", tab)
	--atjaunot PropertyEditorPlaceBefore
	lQuery("D#HorizontalBox[id='propertyEditorPlaceBefore']/component"):delete()
			lQuery.create("D#Label", {caption = "PropertyEditorPlaceBefore", minimumWidth = 160}):link("container", lQuery("D#HorizontalBox[id='propertyEditorPlaceBefore']"))
			lQuery.create("D#ComboBox", {
				text = ""
				,item = getPropertyEditorPlaceBefore()
				,id = "propertyEditorPlaceBefore"
				,eventHandler = {
					utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeEvent()")
				}
			}):link("container", lQuery("D#HorizontalBox[id='propertyEditorPlaceBefore']"))
	lQuery("D#HorizontalBox[id='propertyEditorPlaceBefore']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))

	changeEvent()
end

function anywhere (p)
  return lpeg.P{ p + 1 * lpeg.V(1) }
end

--atlasa iespejamas propertyEditorPlaceBefore lauka izveles vienumus
function getPropertyEditorPlaceBefore()
--atkariba no ta kads ir CompartType
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	
	local tab = fielDRepId:attr("propertyEditorTab")
	local compartType = lQuery(fielDRepId):find("/context"):attr("type")
	local values 
	local compType
	if fielDRepId:find("/context"):attr("mode") ~= "Element" then 
		compType = extensionCreate.findCompartType(fielDRepId)
	end
	if tab ~= "" then 
		values = lQuery("PropertyRow:has(/propertyTab[caption='" .. tab .. "']/propertyDiagram[id='" .. compartType .. "'])")
		if lQuery("PropertyDiagram[id='" .. compartType .. "']"):is_empty() then 
			values = lQuery("PropertyRow:has(/propertyTab[caption='" .. tab .. "']/propertyDiagram[id='" .. lQuery(fielDRepId):find("/context"):attr("elTypeName") .. "'])")
		end
	else
		local pat = lpeg.P("(")
		pat = anywhere(pat)
		if lpeg.match(pat, compartType)~= nil then 
			compartType = string.sub(compartType, 1, lpeg.match(pat, compartType)-2)
		end
		--atrast tuksumu (ja tads ir) aizvakt to, nakoso burtu pec ta uzlikt lielu
		local n = string.find(compartType, " ")
		if n ~= nil then 
			compartType = string.sub(compartType, 1, n-1) .. string.sub(compartType, n+1, n+1):gsub("%a", string.upper, 1) .. string.sub(compartType, n+2)
		end
		
		local propertyDiagram = lQuery("PropertyDiagram[id = '" .. compartType .. "']")
		if compType~=nil and compType:find("/subCompartType"):size() == 0 then 
			if compType:find("/propertyRow"):is_not_empty() then values = compType 
			else values = compType:find("/subCompartType")  end
		else
			if propertyDiagram:size() > 1 then
				if fielDRepId:find("/context"):attr("mode") == "Element" then 
					propertyDiagram = lQuery("ElemType[id = '" .. fielDRepId:find("/context"):attr("type") .. "']/propertyDiagram")
				else
					propertyDiagram = compType:find("/propertyDiagram")
					if propertyDiagram:size() == 0 then propertyDiagram = compType:find("/parentCompartType/propertyDiagram") end
				end
			elseif propertyDiagram:size() < 1 then
				if compType~=nil then
					propertyDiagram = lQuery("PropertyDiagram[id = '" .. compType:find("/parentCompartType"):attr("id") .. "']")
				end
			end
			if propertyDiagram:size() == 0 and compType~=nil then propertyDiagram = lQuery("PropertyDiagram[id = '" .. compType:attr("id") .. "']")  end
			values = propertyDiagram:find("/propertyRow")
		end
	end
	values = values:filter(
		function(obj)
			return lQuery(obj):find("/compartType/extension[type = 'aa#Profile']"):is_empty()
		end)
		
	values = values:map(
		function(obj, i)
			if compType~=nil and values:id() == compType:id() then return {lQuery(obj):attr("caption"), lQuery(obj):id()} end
			return {lQuery(obj):attr("id"), lQuery(obj):id()}
		end)

	return lQuery.map(values, function(mode_value) 
		return lQuery.create("D#Item", {
			value = mode_value[1]
			,id = mode_value[2]
		}) 
	end)
end

--atlasa iespejamas propertyEditorTab lauka izveles vienumus
function getPropertyEditorTab()
--atkariba no ta kads ir CompartType
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#ChoiceItem instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	
	local compartType = lQuery(fielDRepId):find("/context"):attr("type")
	
	local values 
	values = lQuery("PropertyTab:has(/propertyDiagram[id='" .. compartType .. "'])")
	
	if lQuery("PropertyDiagram[id='" .. compartType .. "']"):is_empty() and fielDRepId:find("/context"):attr("mode") == "Group" then 
		values = lQuery("PropertyTab:has(/propertyDiagram[id='" .. lQuery(fielDRepId):find("/context"):attr("elTypeName") .. "'])")
	end
	
	if (fielDRepId:find("/context"):attr("path") == "Role/" and fielDRepId:find("/context"):attr("type") == "Name") or (fielDRepId:find("/context"):attr("path") == "InvRole/" and fielDRepId:find("/context"):attr("type") == "Name") then
		values = lQuery("PropertyTab:has(/propertyDiagram[id='" .. lQuery(fielDRepId):find("/context"):attr("elTypeName") .. "'])")
	end
	
	if fielDRepId:find("/context"):attr("elTypeName") == "Link" then
		values = lQuery("PropertyTab:has(/propertyDiagram[id='" .. lQuery(fielDRepId):find("/context"):attr("elTypeName") .. "'])")
	end
	
	values = values:map(
		function(obj)
			return {lQuery(obj):attr("caption"), lQuery(obj):id()}
		end)

	return lQuery.map(values, function(mode_value) 
		return lQuery.create("D#Item", {
			value = mode_value[1]
			,id = mode_value[2]
		}) 
	end)
end

--atlasa iespejamas displayPlaceBefore lauka izveles vienumus
function getDisplayPlaceBefore()
--atkariba no ta kads ir CompartType
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	
	
	local context = lQuery(fielDRepId):find("/context")
	local mode = context:attr("mode")
	local values
	if mode == "Element" then 
		
		local elemType = context:attr("type")
		values = lQuery("CompartType:has(/elemType[id='" .. elemType .. "'])")
		values = values:filter(
		function(obj)
			return lQuery(obj):find("/extension[type = 'aa#Profile']"):is_empty()
		end)
		values = values:map(
		  function(obj, i)
			return {lQuery(obj):attr("caption"), lQuery(obj):id()}
		  end)
	else 
		local path = context:attr("path")
		local pathTable = styleMechanism.split(path, "/")
		local elemType = lQuery("ElemType[id='" .. context:attr("elTypeName") .. "']")
		local comparType
		
		if #pathTable ~= 1 then
			compartType = elemType:find("/compartType[caption='" .. pathTable[1] .. "']")
			
			local pat = lpeg.P("ASFictitious")
			if lpeg.match(pat, compartType:attr("id")) then 
				compartType = compartType:find("/subCompartType[caption='" .. pathTable[1] .. "']")
			end
			for i=2,#pathTable,1 do 
				if pathTable[i] ~= "" then 

					local compartType2 = compartType:find("/subCompartType[caption='" .. context:attr("type") .. "']")
					if compartType2:is_empty() then  
						compartType2 = compartType:find("/subCompartType[caption='CheckBoxFictitious" .. context:attr("type") .. "']")
						if compartType2:is_empty() then compartType2 = compartType:find("/subCompartType[id='ASFictitious" .. context:attr("type") .. "']") end
					end	
					compartType=compartType2
					if lpeg.match(pat, compartType:attr("id")) then 
						compartType = compartType:find("/subCompartType[caption='" .. pathTable[i] .. "']")
					end
				end
			end
		
			local compartType2 = compartType:find("/subCompartType[caption='" .. context:attr("type") .. "']")
			if compartType2:is_empty() then  
				
				compartType2 = compartType:find("/subCompartType[caption='CheckBoxFictitious" .. context:attr("type") .. "']")
				if compartType2:is_empty() then 
					local pat2 = lpeg.P("(")
					pat2 = anywhere(pat2)
					local contextType
					contextType = context:attr("type")
					if lpeg.match(pat2, context:attr("type"))~= nil then 
						contextType = string.sub(context:attr("type"), 1, lpeg.match(pat2, context:attr("type"))-2)
					end
					compartType2 = compartType:find("/subCompartType[id='ASFictitious" .. contextType .. "']") 
				end
			end	
			compartType=compartType2
			
			if lpeg.match(pat, compartType:attr("id")) then 
				compartType = compartType:find("/subCompartType[caption='" .. context:attr("type") .. "']")
				
			end
	
			values = lQuery(compartType):find("/subCompartType")
			
			--atrast vajadzigo compartType un ja tam propertyRow ir tuks vai id ir label, tad radit so compartType
			--ja vecakElements ir ar id AutoGenerete
			if compartType:find("/subCompartType"):size() == 0 then values = compartType end
			values = values:filter(
			function(obj)
				return lQuery(obj):find("/extension[type = 'aa#Profile']"):is_empty()
			end)
			values = values:map(
			  function(obj, i)
				return {lQuery(obj):attr("caption"), lQuery(obj):id()}
			  end)
		else--ja ir pirma limenja lauks
			--compartType = elemType:find("/compartType[caption='" .. context:attr("type") .. "']")
			local pat = lpeg.P("ASFictitious")
			
			local pat2 = lpeg.P("(")
			pat2 = anywhere(pat2)
			local contextType
			
			local compartType2 = elemType:find("/compartType[caption='" .. context:attr("type") .. "']")
			
			if compartType2:is_empty() then  
				compartType = elemType:find("/compartType[caption='CheckBoxFictitious" .. context:attr("type") .. "']")
				if compartType:is_empty() then 
					contextType = context:attr("type")
					if lpeg.match(pat2, context:attr("type"))~= nil then 
						contextType = string.sub(context:attr("type"), 1, lpeg.match(pat2, context:attr("type"))-2)
					end
					compartType = elemType:find("/compartType[id='ASFictitious" .. contextType .. "']")
				end
			else compartType=compartType2 end

			if lpeg.match(pat, compartType:attr("id")) and lpeg.match(pat2, context:attr("type"))~= nil then 
				contextType = string.sub(context:attr("type"), 1, lpeg.match(pat2, context:attr("type"))-2)
				compartType2 = compartType:find("/subCompartType[id='ASFictitious" .. contextType .. "']")
				if compartType2:is_empty() then compartType2 = compartType:find("/subCompartType[id='" .. contextType .. "']") end
			elseif lpeg.match(pat, compartType:attr("id")) and lpeg.match(pat2, context:attr("type"))~= nil then 
				contextType = string.sub(context:attr("type"), 1, lpeg.match(pat2, context:attr("type"))-2)
				compartType2 = compartType:find("/subCompartType[id='ASFictitious" .. compartType:attr("id") .. "']")
			elseif lpeg.match(pat, compartType:attr("id")) then 
				compartType2 = compartType:find("/subCompartType[id='" .. context:attr("type") .. "']")
			end
			if compartType2:is_not_empty() then compartType=compartType2 end

			values = lQuery(compartType):find("/subCompartType")
			values = values:filter(
			function(obj)
				return lQuery(obj):find("/extension[type = 'aa#Profile']"):is_empty()
			end)
			
			--atrast vajadzigo compartType un ja tam propertyRow ir tuks vai id ir label, tad radit so compartType
			if compartType:find("/subCompartType"):size() == 0 then values = compartType end
			
			values = values:map(
			  function(obj, i)
				return {lQuery(obj):attr("caption"), lQuery(obj):id()}
			  end)
		end
	end

	return lQuery.map(values, function(mode_value) 
		return lQuery.create("D#Item", {
			value = mode_value[1]
			,id = mode_value[2]
		}) 
	end)
end

--atlasa jau piesaistitos stilus (itemElement)
function getItemElementStyles()
	t = styleMechanism.valuesTable()
	f = styleMechanism.functionTable()
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#ChoiceItem"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)

	local values1 = lQuery(fielDRepId):find("/styleSetting:has(/elemStyleFeature)"):map(
	  function(obj, i)
		return {lQuery(obj):find("/elemStyleFeature"):attr("itemName"), lQuery(obj):attr("value"), lQuery(obj):id()}
	  end)
	  
	local values = lQuery(fielDRepId):find("/styleSetting[isElementStyleSetting = true]"):map(
	  function(obj, i)
		local itemName = lQuery(obj):find("/elemStyleFeature"):attr("itemName")
		if lQuery(obj):find("/elemStyleFeature"):is_empty() then
			itemName = lQuery(obj):find("/fieldStyleFeature"):attr("itemName")
		end
		local a = t[itemName]
		local af = f[itemName]
		if itemName == "picPos" or itemName == "picStyle" then a = t[itemName .. "Node"]  end
		  local contextType = lQuery(fielDRepId):find("/field/context"):attr("type")
		  
		  if itemName == "shapeCode" then
			local elemStyle = lQuery("ElemType[id='" .. contextType .. "']/elemStyle"):first()
			local mode = lQuery(fielDRepId):find("/field/context"):attr("mode")
			if mode == "Group" then elemStyle = lQuery("ElemType[id='" .. lQuery(fielDRepId):find("/field/context"):attr("elTypeName") .. "']/elemStyle"):first() end
			lQuery("NodeStyle"):each(function(obj)
				if lQuery(obj):id() == lQuery(elemStyle):id() then a = t[itemName .. "Box"]  end
			end)
			lQuery("EdgeStyle"):each(function(obj)
				if lQuery(obj):id() == lQuery(elemStyle):id() then a = t[itemName .. "Line"] end
			end)
		  end
		local val = lQuery(obj):attr("value")
		if a ~= nil or af ~= nil then
			if a ~=nil then
				for i,v in pairs(a) do
					if tostring(v)==lQuery(obj):attr("value") then 
						val = i
					end
				end
			end
			if af~=nil then
				for i,v in pairs(af) do
					if tostring(v)==lQuery(obj):attr("procSetValue") then 
						val = i
					end
				end
			end
		else val = lQuery(obj):attr("value")
		end
		
		return {itemName, val, lQuery(obj):id(), lQuery(obj):attr("value")}
	  end)  
	  
	return lQuery.map(values, function(mode_value) 
	  local tt = t[mode_value[1]]
	  local ft = f[mode_value[1]]
	  if mode_value[1] == "picPos" or mode_value[1] == "picStyle" then tt = t[mode_value[1] .. "Node"] end
	  local contextType = lQuery(fielDRepId):find("/field/context"):attr("type")
	  
	  if mode_value[1] == "shapeCode" then
		local elemStyle = lQuery("ElemType[id='" .. contextType .. "']/elemStyle"):first()
		local mode = lQuery(fielDRepId):find("/field/context"):attr("mode")
		if mode == "Group" then elemStyle = lQuery("ElemType[id='" .. lQuery(fielDRepId):find("/field/context"):attr("elTypeName") .. "']/elemStyle"):first() end
		lQuery("NodeStyle"):each(function(obj)
			if lQuery(obj):id() == lQuery(elemStyle):id() then tt = t[mode_value[1] .. "Box"]  end
		end)
		lQuery("EdgeStyle"):each(function(obj)
			if lQuery(obj):id() == lQuery(elemStyle):id() then tt = t[mode_value[1] .. "Line"] end
		end)
	  end
	  
	  if string.find(mode_value[1], "Color")~=nil then
		return lQuery.create("D#VTableRow", {
			vTableCell = {
				lQuery.create("D#VTableCell", { value = mode_value[1]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
					,component = lQuery.create("D#TextBox", {
						text = mode_value[1]
					})
				})
				,lQuery.create("D#VTableCell", { value = mode_value[4]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
					,component = {lQuery.create("D#Button", {
						caption = mode_value[4]
						,id = mode_value[3]
						,eventHandler = {
							utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectItemElementColor()")
						}
					})}
				})
			}
		})
	  elseif tt ~= nil or ft ~= nil then 
		--izveidot comboBox
		local valuesI = {}
		if tt ~= nil then
			for i,v in pairs(tt) do
				local g = {i, v}
				table.insert(valuesI, g)
			end
		end
		if ft ~= nil then
			for i,v in pairs(ft) do
				local g = {i, v}
				table.insert(valuesI, g)
			end
		end
		table.sort(valuesI, function(x,y) return x[1] < y[1] end)
		return lQuery.create("D#VTableRow", {
			vTableCell = {
				lQuery.create("D#VTableCell", { value = mode_value[1]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
					,component = lQuery.create("D#TextBox", {
						text = mode_value[1]
					})
				})
				,lQuery.create("D#VTableCell", { value = mode_value[2]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
					,component = {lQuery.create("D#ComboBox", {
						text = mode_value[2]
						,item = {
							lQuery.map(valuesI, function(item_value) 
								return lQuery.create("D#Item", {
									value = item_value[1]
									,id = item_value[2]
								}) 
							end)
						}
						,id = mode_value[3]
						,eventHandler = {
							utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectItemElementValues()")
						}
					})}
				})
			}
		})
	  else
		return lQuery.create("D#VTableRow", {
			vTableCell = {
				lQuery.create("D#VTableCell", { value = mode_value[1]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
					,component = lQuery.create("D#TextBox", {
						text = mode_value[1]
					})
				})
				,lQuery.create("D#VTableCell", { value = mode_value[2]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
					,component = {lQuery.create("D#TextBox", {
						text = mode_value[2]
						,id = mode_value[3]
						,eventHandler = {
							utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectItemElementValues()")
						}
					})}
				})
			}
		})
	  end
	end)
end

--atlasa jau piesaistitos stilus (itemField)
function getItemFieldStyles()
	t = styleMechanism.valuesTable()
	f = styleMechanism.functionTable()
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#ChoiceItem"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	  
	local values = lQuery(fielDRepId):find("/styleSetting[isElementStyleSetting != true]"):map(
	  function(obj, i)
		local itemName = lQuery(obj):find("/fieldStyleFeature"):attr("itemName")
		local a = t[itemName]
		local af = f[itemName]
		if itemName == "picPos" or itemName == "picStyle" then a = t[itemName .. "Com"]  end
		local contextType = lQuery(fielDRepId):find("/field/context"):attr("type")
		
		if itemName == "adornment" or itemName == "adjustment" then
			local mode = lQuery(fielDRepId):find("/field/context"):attr("mode")
			local elemStyle = lQuery("ElemType[id='" .. contextType .. "']/elemStyle"):first()
			if mode == "Group" then elemStyle = lQuery("ElemType[id='" .. lQuery(fielDRepId):find("/field/context"):attr("elTypeName") .. "']/elemStyle"):first() end
			lQuery("NodeStyle"):each(function(obj)
				if lQuery(obj):id() == lQuery(elemStyle):id() then a = t[itemName .. "Box"]  end
			end)
			lQuery("EdgeStyle"):each(function(obj)
				if lQuery(obj):id() == lQuery(elemStyle):id() then a = t[itemName .. "Line"] end
			end)
			
			if contextType == "Class" or contextType == "Object" then a = t[itemName .. "Box"] 
			else a = t[itemName .. "Line"] end
		end
		local val
		if a ~= nil or af ~= nil then
			if a ~=nil then
				for i,v in pairs(a) do
					if tostring(v)==lQuery(obj):attr("value") then 
						val = i
					end
				end
			end
			if af~=nil then
				for i,v in pairs(af) do
					if tostring(v)==lQuery(obj):attr("procSetValue") then 
						val = i
					end
				end
			end
		else val = lQuery(obj):attr("value")
		end
		
		return {itemName, val, lQuery(obj):id(), lQuery(obj):attr("target"), lQuery(obj):attr("value"), lQuery(obj):attr("path")}
	  end)  
	 
	return lQuery.map(values, function(mode_value) 
	  local tt = t[mode_value[1]]
	  local ft = f[mode_value[1]]
	  if mode_value[1] == "picPos" or mode_value[1] == "picStyle" then tt = t[mode_value[1] .. "Com"] end
	  local contextType = lQuery(fielDRepId):find("/field/context"):attr("type")
	  if mode_value[1] == "adornment" or mode_value[1] == "adjustment" then
		local elemStyle = lQuery("ElemType[id='" .. contextType .. "']/elemStyle"):first()
		local mode = lQuery(fielDRepId):find("/field/context"):attr("mode")
		if mode == "Group" then elemStyle = lQuery("ElemType[id='" .. lQuery(fielDRepId):find("/field/context"):attr("elTypeName") .. "']/elemStyle"):first() end
		lQuery("NodeStyle"):each(function(obj)
			if lQuery(obj):id() == lQuery(elemStyle):id() then tt = t[mode_value[1] .. "Box"]  end
		end)
		lQuery("EdgeStyle"):each(function(obj)
			if lQuery(obj):id() == lQuery(elemStyle):id() then tt = t[mode_value[1] .. "Line"] end
		end)
	  end
	  if string.find(mode_value[1], "Color")~=nil then
		return lQuery.create("D#VTableRow", {
			vTableCell = {
				lQuery.create("D#VTableCell", { value = mode_value[4]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Target']")
						,component = lQuery.create("D#TextBox", {
							text = mode_value[4]
							--,item = getTarget()
							,id = mode_value[3]
						})
				})
				,lQuery.create("D#VTableCell", { value = mode_value[6]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Path']")
					,component = lQuery.create("D#TextBox", {
						text = mode_value[6]
					})
				})
				,lQuery.create("D#VTableCell", { value = mode_value[1]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
					,component = lQuery.create("D#TextBox", {
						text = mode_value[1]
					})
				})
				,lQuery.create("D#VTableCell", { value = mode_value[5]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
					,component = {lQuery.create("D#Button", {
						caption = mode_value[5]
						,id = mode_value[3]
						,eventHandler = {
							utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectItemFieldColor()")
						}
					})}
				})
				
			}
		})
	  elseif tt ~= nil or ft ~= nil then 
		--izveidot comboBox
		local valuesI = {}
		if tt ~= nil then
			for i,v in pairs(tt) do
				local g = {i, v}
				table.insert(valuesI, g)
			end
		end
		if ft ~= nil then
			for i,v in pairs(ft) do
				local g = {i, v}
				table.insert(valuesI, g)
			end
		end
		table.sort(valuesI, function(x,y) return x[1] < y[1] end)
		return lQuery.create("D#VTableRow", {
			vTableCell = {
				lQuery.create("D#VTableCell", { value = mode_value[4]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Target']")
						,component = lQuery.create("D#TextBox", {
							text = mode_value[4]
							--,item = getTarget()
							,id = mode_value[3]
						})
				})
				,lQuery.create("D#VTableCell", { value = mode_value[6]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Path']")
					,component = lQuery.create("D#TextBox", {
						text = mode_value[6]
					})
				})
				,lQuery.create("D#VTableCell", { value = mode_value[1]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
					,component = lQuery.create("D#TextBox", {
						text = mode_value[1]
					})
				})
				,lQuery.create("D#VTableCell", { value = mode_value[2]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
					,component = {lQuery.create("D#ComboBox", {
						text = mode_value[2]
						,item = {
							lQuery.map(valuesI, function(item_value) 
								return lQuery.create("D#Item", {
									value = item_value[1]
									,id = item_value[2]
								}) 
							end)
						}
						,id = mode_value[3]
						,eventHandler = {
							utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectItemFieldValues()")
						}
					})}
				})
				
			}
		})
	  else
		return lQuery.create("D#VTableRow", {
			vTableCell = {
				lQuery.create("D#VTableCell", { value = mode_value[4]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Target']")
						,component = lQuery.create("D#TextBox", {
							text = mode_value[4]
							--,item = getTarget()
							,id = mode_value[3]
						})
				})
				,lQuery.create("D#VTableCell", { value = mode_value[6]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Path']")
					,component = lQuery.create("D#TextBox", {
						text = mode_value[6]
					})
				})
				,lQuery.create("D#VTableCell", { value = mode_value[1]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
					,component = lQuery.create("D#TextBox", {
						text = mode_value[1]
					})
				})
				,lQuery.create("D#VTableCell", { value = mode_value[2]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
					,component = {lQuery.create("D#TextBox", {
						text = mode_value[2]
						,id = mode_value[3]
						,eventHandler = {
							utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectItemFieldValues()")
						}
					})}
				})
			}
		})
	  end
	end)
end

--atlasa jau piesaistitos stilus (fildi)
function getFieldStyles()
	
	t = styleMechanism.valuesTable()
	f = styleMechanism.functionTable()
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)

	local values = lQuery(fielDRepId):find("/selfStyleSetting"):map(
	  function(obj, i)
		local itemName = lQuery(obj):find("/fieldStyleFeature"):attr("itemName")
		local a = t[itemName]
		local af = f[itemName]
		if itemName == "picPos" or itemName == "picStyle" then a = t[itemName .. "Com"]  end
		local contextType = lQuery(fielDRepId):find("/context"):attr("type")
		if itemName == "adornment" or itemName == "adjustment" then
			local elemStyle = lQuery("ElemType[id='" .. contextType .. "']/elemStyle"):first()
			local mode = lQuery(fielDRepId):find("/context"):attr("mode")
			if mode == "Group" then elemStyle = lQuery("ElemType[id='" .. lQuery(fielDRepId):find("/context"):attr("elTypeName") .. "']/elemStyle"):first() end
			lQuery("NodeStyle"):each(function(obj)
				if lQuery(obj):id() == lQuery(elemStyle):id() then a = t[itemName .. "Box"]  end
			end)
			lQuery("EdgeStyle"):each(function(obj)
				if lQuery(obj):id() == lQuery(elemStyle):id() then a = t[itemName .. "Line"] end
			end)
		end
		local val = lQuery(obj):attr("value")
		if a ~= nil or af ~= nil then
			if a ~=nil then
				for i,v in pairs(a) do
					if tostring(v)==lQuery(obj):attr("value") then 
						val = i
					end
				end
			end
			if af~=nil then
				for i,v in pairs(af) do
					if tostring(v)==lQuery(obj):attr("procSetValue") then 
						val = i
					end
				end
			end
		else val = lQuery(obj):attr("value")
		end
		return {itemName, val, lQuery(obj):id(), lQuery(obj):attr("value")}
	  end)
	  
	return lQuery.map(values, function(mode_value) 
	  local tt = t[mode_value[1]]
	  local ft = f[mode_value[1]]
	  if mode_value[1] == "picPos" or mode_value[1] == "picStyle" then tt = t[mode_value[1] .. "Com"]  end
	  local contextType = lQuery(fielDRepId):find("/context"):attr("type")
	  if mode_value[1] == "adornment" or mode_value[1] == "adjustment" then
		local elemStyle = lQuery("ElemType[id='" .. contextType .. "']/elemStyle"):first()
		local mode = lQuery(fielDRepId):find("/context"):attr("mode")
		if mode == "Group" then elemStyle = lQuery("ElemType[id='" .. lQuery(fielDRepId):find("/context"):attr("elTypeName") .. "']/elemStyle"):first() end
		lQuery("NodeStyle"):each(function(obj)
			if lQuery(obj):id() == lQuery(elemStyle):id() then tt = t[mode_value[1] .. "Box"]  end
		end)
		lQuery("EdgeStyle"):each(function(obj)
			if lQuery(obj):id() == lQuery(elemStyle):id() then tt = t[mode_value[1] .. "Line"] end
		end)
	  end
	  
	  if string.find(mode_value[1], "Color")~=nil then
		return lQuery.create("D#VTableRow", {
			vTableCell = {
				lQuery.create("D#VTableCell", { value = mode_value[1]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
					,component = lQuery.create("D#TextBox", {
						text = mode_value[1]
					})
				})
				,lQuery.create("D#VTableCell", { value = mode_value[4]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
					,component = {lQuery.create("D#Button", {
						caption = mode_value[4]
						,id = mode_value[3]
						,eventHandler = {
							utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectFieldColor()")
						}
					})}
				})
			}
		})
	  elseif tt ~= nil or ft ~= nil then 
		--izveidot comboBox
		local valuesI = {}
		if tt ~= nil then
			for i,v in pairs(tt) do
				local g = {i, v}
				table.insert(valuesI, g)
			end
		end
		if ft ~= nil then
			for i,v in pairs(ft) do
				local g = {i, v}
				table.insert(valuesI, g)
			end
		end
		table.sort(valuesI, function(x,y) return x[1] < y[1] end)
		return lQuery.create("D#VTableRow", {
			vTableCell = {
				lQuery.create("D#VTableCell", { value = mode_value[1]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
					,component = lQuery.create("D#TextBox", {
						text = mode_value[1]
					})
				})
				,lQuery.create("D#VTableCell", { value = mode_value[2]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
					,component = {lQuery.create("D#ComboBox", {
						text = mode_value[2]
						,item = {
							lQuery.map(valuesI, function(item_value) 
								return lQuery.create("D#Item", {
									value = item_value[1]
									,id = item_value[2]
								}) 
							end)
						}
						,id = mode_value[3]
						,eventHandler = {
							utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectFieldValues()")
						}
					})}
				})
			}
		})
	  else
		return lQuery.create("D#VTableRow", {
			vTableCell = {
				lQuery.create("D#VTableCell", { value = mode_value[1]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
					,component = lQuery.create("D#TextBox", {
						text = mode_value[1]
					})
				})
				,lQuery.create("D#VTableCell", { value = mode_value[2]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
					,component = {lQuery.create("D#TextBox", {
						text = mode_value[2]
						,id = mode_value[3]
						,eventHandler = {
							utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectFieldValues()")
						}
					})}
				})
			}
		})
	  end
	end)
end

--atlasa iespejamas stila vertibas, izveido jauno tukso rindu(ItemElement)
function collectItemElementStyleValuesMakeNewRow()
	--atrast itemu
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#ChoiceItem"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	
	t = styleMechanism.valuesTable()
	f = styleMechanism.functionTable()
	--atrast kas tika izvelets
	local activeCell = lQuery("D#VTable[id = 'TableStyleItemElement']/selectedRow/activeCell"):attr("value")
	if lQuery("AA#ElemStyleItem[itemName='" .. activeCell .. "']"):is_not_empty() then
		local tt = t[activeCell]
		local ft = f[activeCell]
		if activeCell == "picPos" or activeCell == "picStyle" then tt = t[activeCell .. "Node"]  end
		local contextType = lQuery(fielDRepId):find("/field/context"):attr("type")
		if activeCell == "shapeCode" then
			if contextType == "Class" or contextType == "Object" then tt = t[activeCell .. "Box"] 
			else tt = t[activeCell .. "Line"] end
		end
		--log(dumptable(tt))
		--ja tika atrastas vertibas ierakstam tas ComboBox
		--ja netika izvadas input fieldu
		
		--atrast vajadzigo sunu
		local cell = lQuery("D#VTable[id = 'TableStyleItemElement']/selectedRow/vTableCell:has(/vTableColumnType[caption='Value'])")

		--atrast AA#CompartStyleItem
		local csi = lQuery("AA#ElemStyleItem[itemName='" .. activeCell .. "']")
		if activeCell == "isVisible" then csi = lQuery("AA#CompartStyleItem[itemName='" .. activeCell .. "']") end
		--izveidot AA#FieldStyleSetting
		--piesaistit AA#CompartStyleItem un AA#Field
		--target tukhs
		--isElementStyleSetting = false
		local st = lQuery.create("AA#FieldStyleSetting", {isElementStyleSetting = true})
		lQuery(fielDRepId):link("styleSetting", st)
		lQuery(csi):link("styleSetting", st)
		
		if string.find(activeCell, "Color")~=nil then
			local row = lQuery("D#VTable[id = 'TableStyleItemElement']/selectedRow")

			lQuery(row):find("/vTableCell"):delete()
			
					lQuery.create("D#VTableCell", { value = activeCell
						,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
						,component = lQuery.create("D#TextBox", {
							text = activeCell
						})
					}):link("vTableRow", row)
					lQuery.create("D#VTableCell", { value = ""
						,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
						,component = {lQuery.create("D#Button", {
							caption = ""
							,id = lQuery(st):id()
							,eventHandler = {
								utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectItemElementColor()")
							}
						})}
					}):link("vTableRow", row)
		elseif tt ~= nil or ft ~= nil then 
			--izveidot comboBox
			local values = {}
			if tt ~= nil then
				for i,v in pairs(tt) do
					local g = {i, v}
					table.insert(values, g)
				end
			end
			if ft ~= nil then
				for i,v in pairs(ft) do
					local g = {i, v}
					table.insert(values, g)
				end
			end
			table.sort(values, function(x,y) return x[1] < y[1] end)
			local row = lQuery("D#VTable[id = 'TableStyleItemElement']/selectedRow")

			lQuery(row):find("/vTableCell"):delete()
			
					lQuery.create("D#VTableCell", { value = activeCell
						,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
						,component = lQuery.create("D#TextBox", {
							text = activeCell
						})
					}):link("vTableRow", row)
					lQuery.create("D#VTableCell", { value = ""
						,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
						,component = {lQuery.create("D#ComboBox", {
							text = ""
							,item = {
								lQuery.map(values, function(item_value) 
									return lQuery.create("D#Item", {
										value = item_value[1]
										,id = item_value[2]
									}) 
								end)
							}
							,id = lQuery(st):id()
							,eventHandler = {
								utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectItemElementValues()")
							}
						})}
					}):link("vTableRow", row)
		else
			local row = lQuery("D#VTable[id = 'TableStyleItemElement']/selectedRow")
		
			lQuery(row):find("/vTableCell"):delete()
			
					lQuery.create("D#VTableCell", { value = activeCell
						,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
						,component = lQuery.create("D#TextBox", {
							text = activeCell
						})
					}):link("vTableRow", row)
					lQuery.create("D#VTableCell", { value = ""
						,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
						,component = {lQuery.create("D#TextBox", {
							text = ""
							,id = lQuery(st):id()
							,eventHandler = {
								utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectItemElementValues()")
							}
						})}
					}):link("vTableRow", row)	
		end
		lQuery("D#VTable[id = 'TableStyleItemElement']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	

		--pievienot tukso rindu
		lQuery.create("D#VTableRow", {
			vTableCell = {
				lQuery.create("D#VTableCell", { 
					vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
					,component = lQuery.create("D#ComboBox", {
						text = ""
						,item = getNewStyleItemElement()
						,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.collectItemElementStyleValuesMakeNewRow()")}
					})
				})
				,lQuery.create("D#VTableCell", { value = ""
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
				})
			}
		}):link("vTable", lQuery("D#VTable[id = 'TableStyleItemElement']"))	
	end
end

--atlasa iespejamas stila vertibas, izveido jauno tukso rindu(ItemField)
function collectItemFieldStyleValuesMakeNewRow()
	--atrast fildu
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#ChoiceItem"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	
	local rows = lQuery("D#VTable[id = 'TableStyleItemField']/vTableRow"):map(function(obj)
		return obj
	  end)
	local neededRow = rows[#rows-1]
	
	t = styleMechanism.valuesTable()
	f= styleMechanism.functionTable()
	--atrast kas tika izvelets
	local activeCell = neededRow:find("/vTableCell:has(/vTableColumnType[caption='Feature'])"):attr("value")

	
	--row:find("/vTableCell:has(/vTableColumnType[caption = 'Target'])"):attr("value")
	local tt = t[activeCell]
	local ft = f[activeCell]
	if activeCell == "picPos" or activeCell == "picStyle" then tt = t[activeCell .. "Com"] end
	local contextType = lQuery(fielDRepId):find("/field/context"):attr("type")
	  if activeCell == "adornment" or activeCell == "adjustment" then
		if contextType == "Class" or contextType == "Object" then tt = t[activeCell .. "Box"] 
		else tt = t[activeCell .. "Line"] end
	  end
	
	local targer = neededRow:find("/vTableCell:has(/vTableColumnType[caption = 'Target'])"):attr("value")
	local path = neededRow:find("/vTableCell:has(/vTableColumnType[caption = 'Path'])"):attr("value")

	if activeCell=="isVisible" and (lQuery(fielDRepId):find("/field/context"):attr("mode")=="Group Item" or lQuery(fielDRepId):find("/field/context"):attr("mode") == "Text") then
		tt = t["isVisibleHidden"]
	end
	--ja tika atrastas vertibas ierakstam tas ComboBox
	--ja netika izvadas imput fieldu
	
	--atrast AA#CompartStyleItem
	
	
	local csi = lQuery("AA#CompartStyleItem[itemName='" .. activeCell .. "']")
	if csi:is_not_empty() then
		
		--izveidot AA#FieldStyleSetting
		--piesaistit AA#CompartStyleItem un AA#Field
		--target tukhs
		--isElementStyleSetting = false
		local st = lQuery.create("AA#FieldStyleSetting", {isElementStyleSetting = false})
		lQuery(fielDRepId):link("styleSetting", st)
		lQuery(csi):link("styleSetting", st)
		
	--	local row = lQuery("D#VTable[id = 'TableStyleItemField']/selectedRow")
		local row = neededRow
		local targer = row:find("/vTableCell:has(/vTableColumnType[caption = 'Target'])"):attr("value")
		local path = row:find("/vTableCell:has(/vTableColumnType[caption = 'Path'])"):attr("value")
		st:attr("target", targer)
		st:attr("path", path)
		if string.find(activeCell, "Color")~=nil then
			local row = neededRow
			local targer = row:find("/vTableCell:has(/vTableColumnType[caption = 'Target'])"):attr("value")
			lQuery(row):find("/vTableCell"):delete()
			
			lQuery.create("D#VTableCell", { value = targer
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Target']")
				,component = lQuery.create("D#TextBox", {
					text = targer
				})
			}):link("vTableRow", row)
			
			lQuery.create("D#VTableCell", { value = path
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Path']")
				,component = lQuery.create("D#TextBox", {
					text = path
				})
			}):link("vTableRow", row)
			
			lQuery.create("D#VTableCell", { value = activeCell
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
				,component = lQuery.create("D#TextBox", {
					text = activeCell
				})
			}):link("vTableRow", row)
					
			lQuery.create("D#VTableCell", { value = ""
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
				,component = {lQuery.create("D#Button", {
					caption = ""
					,id = lQuery(st):id()
					,eventHandler = {
						utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectItemFieldColor()")
					}
				})}
			}):link("vTableRow", row)
					
		elseif tt ~= nil or ft ~= nil then 
			--izveidot comboBox
			local values = {}
			if tt ~= nil then
				for i,v in pairs(tt) do
					local g = {i,v}
					table.insert(values, g)
				end
			end
			if ft ~= nil then
				for i,v in pairs(ft) do
					local g = {i,v}
					table.insert(values, g)
				end
			end
			table.sort(values, function(x,y) return x[1] < y[1] end)
			
			--local row = lQuery("D#VTable[id = 'TableStyleItemField']/selectedRow")
			local row = neededRow
			local targer = row:find("/vTableCell:has(/vTableColumnType[caption = 'Target'])"):attr("value")
			lQuery(row):find("/vTableCell"):delete()
			
			lQuery.create("D#VTableCell", { value = targer
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Target']")
				,component = lQuery.create("D#TextBox", {
					text = targer
				})
			}):link("vTableRow", row)
			
			lQuery.create("D#VTableCell", { value = path
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Path']")
				,component = lQuery.create("D#TextBox", {
					text = path
				})
			}):link("vTableRow", row)
			
			lQuery.create("D#VTableCell", { value = activeCell
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
				,component = lQuery.create("D#TextBox", {
					text = activeCell
				})
			}):link("vTableRow", row)
					
			lQuery.create("D#VTableCell", { value = ""
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
				,component = {lQuery.create("D#ComboBox", {
					text = ""
					,item = {
						lQuery.map(values, function(item_value) 
							return lQuery.create("D#Item", {
								value = item_value[1]
								,id = item_value[2]
							}) 
						end)
					}
					,id = lQuery(st):id()
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectItemFieldValues()")}
				})}
			}):link("vTableRow", row)

		else
			-- local row = lQuery("D#VTable[id = 'TableStyleItemField']/selectedRow")
		    local row = neededRow
			local targer = row:find("/vTableCell:has(/vTableColumnType[caption = 'Target'])"):attr("value")
			lQuery(row):find("/vTableCell"):delete()
			
			lQuery.create("D#VTableCell", { value = targer
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Target']")
				,component = lQuery.create("D#TextBox", {
					text = targer
				})
			}):link("vTableRow", row)
			
			lQuery.create("D#VTableCell", { value = path
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Path']")
				,component = lQuery.create("D#TextBox", {
					text = path
				})
			}):link("vTableRow", row)
			
			lQuery.create("D#VTableCell", { value = activeCell
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
				,component = lQuery.create("D#TextBox", {
					text = activeCell
				})
			}):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ""
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
				,component = {lQuery.create("D#TextBox", {
					text = ""
					,id = lQuery(st):id()
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectItemFieldValues()")}
				})}
			}):link("vTableRow", row)
		end

		lQuery("D#VTable[id = 'TableStyleItemField']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	end
end

--atlasa iespejamas stila vertibas, izveido jauno tukso rindu(Field)
function collectFieldStyleValuesMakeNewRow()

	--atrast fildu
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	
	t = styleMechanism.valuesTable()
	f = styleMechanism.functionTable()
	--atrast kas tika izvelets
	local activeCell = lQuery("D#VTable[id = 'TableStyleField']/selectedRow/activeCell"):attr("value")
	if lQuery("AA#CompartStyleItem[itemName='" .. activeCell .. "']"):is_not_empty() then
		local tt = t[activeCell]
		local ft = f[activeCell]
		if activeCell == "picPos" or activeCell == "picStyle" then tt = t[activeCell .. "Com"] end
		local contextType = lQuery(fielDRepId):find("/context"):attr("type")
		  if activeCell == "adornment" or activeCell == "adjustment" then
			if contextType == "Class" or contextType == "Object" then tt = t[activeCell .. "Box"] 
			else tt = t[activeCell .. "Line"] end
		  end
		if activeCell=="isVisible" and (lQuery(fielDRepId):find("/context"):attr("mode")=="Group Item" or lQuery(fielDRepId):find("/context"):attr("mode") == "Text") then
			tt = t["isVisibleHidden"]
		end
		--ja tika atrastas vertibas ierakstam tas ComboBox
		--ja netika izvadas imput fieldu
		
		--atrast vajadzigo sunu
		local cell = lQuery("D#VTable[id = 'TableStyleField']/selectedRow/vTableCell:has(/vTableColumnType[caption='Value'])")
		
		--atrast AA#CompartStyleItem
		local csi = lQuery("AA#CompartStyleItem[itemName='" .. activeCell .. "']")
		--izveidot AA#FieldStyleSetting
		--piesaistit AA#CompartStyleItem un AA#Field
		--target tukhs
		--isElementStyleSetting = false
		local st = lQuery.create("AA#FieldStyleSetting", {isElementStyleSetting = false})
		lQuery(fielDRepId):link("selfStyleSetting", st)
		lQuery(csi):link("styleSetting", st)
		if string.find(activeCell, "Color")~=nil then
			local row = lQuery("D#VTable[id = 'TableStyleField']/selectedRow")
		
			lQuery(row):find("/vTableCell"):delete()
			
			lQuery.create("D#VTableCell", { value = activeCell
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
				,component = lQuery.create("D#TextBox", {
					text = activeCell
				})
			}):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ""
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
				,component = {lQuery.create("D#Button", {
					caption = ""
					,id = lQuery(st):id()
					,eventHandler = {utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectFieldColor()")}
				})}
			}):link("vTableRow", row)
		elseif tt ~= nil or ft ~= nil then 
			--izveidot comboBox
			local values = {}
			if tt ~= nil then
				for i,v in pairs(tt) do
					local g = {i,v}
					table.insert(values, g)
				end
			end
			if ft ~= nil then
				for i,v in pairs(ft) do
					local g = {i,v}
					table.insert(values, g)
				end
			end
			table.sort(values, function(x,y) return x[1] < y[1] end)
			
			local row = lQuery("D#VTable[id = 'TableStyleField']/selectedRow")
			
			lQuery(row):find("/vTableCell"):delete()
			
			lQuery.create("D#VTableCell", { value = activeCell
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
				,component = lQuery.create("D#TextBox", {
					text = activeCell
				})
			}):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ""
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
				,component = {lQuery.create("D#ComboBox", {
					text = ""
					,item = {
						lQuery.map(values, function(item_value) 
							return lQuery.create("D#Item", {
								value = item_value[1]
								,id = item_value[2]
							}) 
						end)
					}
					,id = lQuery(st):id()
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectFieldValues()")}
				})}
			}):link("vTableRow", row)
		else
			local row = lQuery("D#VTable[id = 'TableStyleField']/selectedRow")

			lQuery(row):find("/vTableCell"):delete()
			
			lQuery.create("D#VTableCell", { value = activeCell
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
				,component = lQuery.create("D#TextBox", {
					text = activeCell
				})
			}):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ""
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
				,component = {lQuery.create("D#TextBox", {
					text = ""
					,id = lQuery(st):id()
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectFieldValues()")}
				})}
			}):link("vTableRow", row)	
		end

		--pievienot tukso rindu
		lQuery.create("D#VTableRow", {
			vTableCell = {
				lQuery.create("D#VTableCell", { 
					vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
					,component = lQuery.create("D#ComboBox", {
						text = ""
						,item = getNewStyleField()
						,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.collectFieldStyleValuesMakeNewRow()")}
					})
				})
				,lQuery.create("D#VTableCell", { value = ""
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
				})
			}
		}):link("vTable", lQuery("D#VTable[id = 'TableStyleField']"))	
		lQuery("D#VTable[id = 'TableStyleField']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	end
end

--ja maina atkarigu no choiceItem lauka stila vertibu
function selectItemFieldValues()
--atrast aktivo shunu
--atrast tas componentes id
--atrrast AA#FieldStyleSetting instsnci
--ierakstit value = aktivas sunas vertiba
	local activeCell = lQuery("D#VTable[id = 'TableStyleItemField']/selectedRow/activeCell")--aktiva suna
	local comID = lQuery(activeCell):find("/component"):attr("id")--componentes id
	local styleSetting -- vajadziga AA#FieldStyleSetting instance
	local field = lQuery("AA#FieldStyleSetting"):each(function(obj)
		if obj:id() == tonumber(comID) then 
			styleSetting = obj
			return
		end end)

	local value = lQuery(activeCell):attr("value")	
	if lQuery(activeCell):find("/component/item"):is_not_empty() then 
		lQuery(activeCell):find("/component/item"):each(function(obj)
			if obj:attr("value") == value then 
				value = obj:attr("id")
				return
			end end)
	end
	
	local f = styleMechanism.functionTable()
	local styleFeature = styleSetting:find("/elemStyleFeature")
	if styleFeature:is_empty() then styleFeature = styleSetting:find("/fieldStyleFeature") end
	local ft = f[styleFeature:attr("itemName")]
	if ft~=nil then
		local procSetValue = ft[lQuery(activeCell):attr("value")]
		if procSetValue~=nil then 
			lQuery(styleSetting):attr("procSetValue", ft[lQuery(activeCell):attr("value")])
			lQuery(styleSetting):attr("value", "")
		else
			lQuery(styleSetting):attr("value", value)
			lQuery(styleSetting):attr("procSetValue", "")
		end
	else
		lQuery(styleSetting):attr("value", value)
	end
	--lQuery(styleSetting):attr("value", value)
end

--ja maina atkarigu no choiceItem elementa stila vertibu
function selectItemElementValues()
--atrast aktivo shunu
--atrast tas componentes id
--atrrast AA#FieldStyleSetting instsnci
--ierakstit value = aktivas sunas vertiba
	local activeCell = lQuery("D#VTable[id = 'TableStyleItemElement']/selectedRow/activeCell")--aktiva suna
	local comID = lQuery(activeCell):find("/component"):attr("id")--componentes id
	local styleSetting -- vajadziga AA#FieldStyleSetting instance
	local field = lQuery("AA#FieldStyleSetting"):each(function(obj)
		if obj:id() == tonumber(comID) then 
			styleSetting = obj
			return
		end end)

	local value = lQuery(activeCell):attr("value")	
	if lQuery(activeCell):find("/component/item"):is_not_empty() then 
		lQuery(activeCell):find("/component/item"):each(function(obj)
			if obj:attr("value") == value then 
				value = obj:attr("id")
				return
			end end)
	end
	
	local f = styleMechanism.functionTable()
	local styleFeature = styleSetting:find("/elemStyleFeature")
	if styleFeature:is_empty() then styleFeature = styleSetting:find("/fieldStyleFeature") end
	local ft = f[styleFeature:attr("itemName")]
	if ft~=nil then
		local procSetValue = ft[lQuery(activeCell):attr("value")]
		if procSetValue~=nil then 
			lQuery(styleSetting):attr("procSetValue", ft[lQuery(activeCell):attr("value")])
			lQuery(styleSetting):attr("value", "")
		else
			lQuery(styleSetting):attr("value", value)
			lQuery(styleSetting):attr("procSetValue", "")
		end
	else
		lQuery(styleSetting):attr("value", value)
	end
end

function selectTarget2()
	--atrast fildu
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#ChoiceItem"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	
	-- t = styleMechanism.valuesTable()
	-- f = styleMechanism.functionTable()
	--atrast kas tika izvelets
	local activeCell = lQuery("D#VTable[id = 'TableStyleItemField']/selectedRow/activeCell"):attr("value")
		--ja tika atrastas vertibas ierakstam tas ComboBox
		--ja netika izvadas imput fieldu
		
		--atrast vajadzigo sunu
		local cell = lQuery("D#VTable[id = 'TableStyleItemField']/selectedRow/vTableCell:has(/vTableColumnType[caption='Value'])")
		
		local path = fielDRepId:find("/field/context"):attr("path")
		local types = fielDRepId:find("/field/context"):attr("type")

		if fielDRepId:find("/field/context"):attr("elTypeName")~="" then path = types .. "/" .. path end
		

		--atrast AA#CompartStyleItem
		-- local csi = lQuery("AA#CompartStyleItem[itemName='" .. activeCell .. "']")
		--izveidot AA#FieldStyleSetting
		--piesaistit AA#CompartStyleItem un AA#Field
		--target tukhs
		--isElementStyleSetting = false
		-- local st = lQuery.create("AA#FieldStyleSetting", {isElementStyleSetting = false})
		-- lQuery(fielDRepId):link("selfStyleSetting", st)
		-- lQuery(csi):link("styleSetting", st)
			local row = lQuery("D#VTable[id = 'TableStyleItemField']/selectedRow")
			lQuery(row):find("/vTableCell"):delete()
			
			lQuery.create("D#VTableCell", { value = activeCell
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Target']")
				,component = lQuery.create("D#TextBox", {
					text = activeCell
				})
			}):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = path
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Path']")
				,component = lQuery.create("D#TextBox", {
					text = path
				})
			}):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ""
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
				,component = lQuery.create("D#ComboBox", {
					text = ""
					,item = getNewStyleField("Item")
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.collectItemFieldStyleValuesMakeNewRow()")}
				})
			}):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ""
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
				,component = lQuery.create("D#TextBox", {
					text = ""
				})
			}):link("vTableRow", row)
	
	lQuery.create("D#VTableRow", {
			vTableCell = {
				lQuery.create("D#VTableCell", { value = ""
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Target']")
					,component = lQuery.create("D#ComboBox", {
						text = ""
						,item = getTarget()
						,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectTarget2()")}
					})
				})
				,lQuery.create("D#VTableCell", { value = ""
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Path']")
					,component = lQuery.create("D#Button", {
						caption = "select compartment"
						,eventHandler = {utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.generateElemTypeTree()")}
					})
				})
				,lQuery.create("D#VTableCell", { value = ""
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Feature']")
				})
				,lQuery.create("D#VTableCell", { value = ""
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
				})
			}
		}):link("vTable", lQuery("D#VTable[id = 'TableStyleItemField']"))	
	
	lQuery("D#VTable[id = 'TableStyleItemField']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

--ja maina target vertibu
function selectTarget()
--atrast aktivo shunu
--atrast tas componentes id
--atrrast AA#FieldStyleSetting instsnci
--ierakstit value = aktivas sunas vertiba
	local activeCell = lQuery("D#VTable[id = 'TableStyleItemField']/selectedRow/activeCell")--aktiva suna
	local comID = lQuery(activeCell):find("/component"):attr("id")--componentes id
	local styleSetting -- vajadziga AA#FieldStyleSetting instance
	local field = lQuery("AA#FieldStyleSetting"):each(function(obj)
		if obj:id() == tonumber(comID) then 
			styleSetting = obj
			return
		end end)
	local value = lQuery(activeCell):attr("value")
	lQuery(styleSetting):attr("target", value)
end

--ja maina atkarigu no choiceItem lauka stila krasu
function selectItemFieldColor()
	--atrast aktivo shunu
--atrast tas componentes id
--atrrast AA#FieldStyleSetting instsnci
--ierakstit value = aktivas sunas vertiba
	local activeCell = lQuery("D#VTable[id = 'TableStyleItemField']/selectedRow/activeCell")--aktiva suna
	local comID = lQuery(activeCell):find("/component"):attr("id")--componentes id
	local styleSetting -- vajadziga AA#FieldStyleSetting instance
	local field = lQuery("AA#FieldStyleSetting"):each(function(obj)
		if obj:id() == tonumber(comID) then 
			styleSetting = obj
			return
		end end)
	local value = lQuery(styleSetting):attr("value")
	if value == "" then value = 0 end
	local color = tda.BrowseForColor(value)
	if color ~= -1 then 
		lQuery(styleSetting):attr("value", color)
		local button = activeCell:find("/component")
		button:attr("caption", color)
		activeCell:attr("value", color)
	end
end

--ja maina atkarigu no choiceItem elementa stila krasu
function selectItemElementColor()
	--atrast aktivo shunu
--atrast tas componentes id
--atrrast AA#FieldStyleSetting instsnci
--ierakstit value = aktivas sunas vertiba
	local activeCell = lQuery("D#VTable[id = 'TableStyleItemElement']/selectedRow/activeCell")--aktiva suna
	local comID = lQuery(activeCell):find("/component"):attr("id")--componentes id
	local styleSetting -- vajadziga AA#FieldStyleSetting instance
	local field = lQuery("AA#FieldStyleSetting"):each(function(obj)
		if obj:id() == tonumber(comID) then 
			styleSetting = obj
			return
		end end)
	local value = lQuery(styleSetting):attr("value")
	if value == "" then value = 0 end
	local color = tda.BrowseForColor(value)
	if color ~= -1 then 
		lQuery(styleSetting):attr("value", color)
		local button = activeCell:find("/component")
		button:attr("caption", color)
		activeCell:attr("value", color)
	end
end

--ja maina lauka stila krasu
function selectFieldColor()
--atrast aktivo shunu
--atrast tas componentes id
--atrrast AA#FieldStyleSetting instsnci
--ierakstit value = aktivas sunas vertiba
	local activeCell = lQuery("D#VTable[id = 'TableStyleField']/selectedRow/activeCell")--aktiva suna
	local comID = lQuery(activeCell):find("/component"):attr("id")--componentes id
	local styleSetting -- vajadziga AA#FieldStyleSetting instance
	local field = lQuery("AA#FieldStyleSetting"):each(function(obj)
		if obj:id() == tonumber(comID) then 
			styleSetting = obj
			return
		end end)
		
	local value = lQuery(styleSetting):attr("value")
	if value == "" then value = 0 end
	local color = tda.BrowseForColor(value)
	if color ~= -1 then 
		lQuery(styleSetting):attr("value", color)
		--atjaunot pogu
		local button = activeCell:find("/component")
		button:attr("caption", color)
		activeCell:attr("value", color)
	end
end

--ja maina lauka stila vertibu
function selectFieldValues()
--atrast aktivo shunu
--atrast tas componentes id
--atrrast AA#FieldStyleSetting instsnci
--ierakstit value = aktivas sunas vertiba
	local activeCell = lQuery("D#VTable[id = 'TableStyleField']/selectedRow/activeCell")--aktiva suna
	local comID = lQuery(activeCell):find("/component"):attr("id")--componentes id
	local styleSetting -- vajadziga AA#FieldStyleSetting instance
	local field = lQuery("AA#FieldStyleSetting"):each(function(obj)
		if obj:id() == tonumber(comID) then 
			styleSetting = obj
			return
		end end)
			
	local value = lQuery(activeCell):attr("value")
	if lQuery(activeCell):find("/component/item"):is_not_empty() then 
		lQuery(activeCell):find("/component/item"):each(function(obj)
			if obj:attr("value") == value then 
				value = obj:attr("id")
				return
			end end)
	end
	--lQuery(styleSetting):attr("value", value)

	local f = styleMechanism.functionTable()
	local styleFeature = styleSetting:find("/elemStyleFeature")
	if styleFeature:is_empty() then styleFeature = styleSetting:find("/fieldStyleFeature") end
	local ft = f[styleFeature:attr("itemName")]
	if ft~=nil then
		local procSetValue = ft[lQuery(activeCell):attr("value")]
		if procSetValue~=nil then 
			lQuery(styleSetting):attr("procSetValue", ft[lQuery(activeCell):attr("value")])
			lQuery(styleSetting):attr("value", "")
		else
			lQuery(styleSetting):attr("value", value)
			lQuery(styleSetting):attr("procSetValue", "")
		end
	else
		lQuery(styleSetting):attr("value", value)
	end
end

--izdzes atkaribu
function deleteOneDependency()
	local close_button = lQuery.create("D#Button", {
	caption = "Close"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.closeDeleteOneDependency()")
  })
  
 -- local mode = lQuery("D#ComboBox[id = 'tableMode']/selected"):attr("value")--ja kads rezims jau ir izvelets
  
  local form = lQuery.create("D#Form", {	
	id = "deleteOneDependency"
    ,caption = "Delete Dependency"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.Profile.closeDeleteOneDependency()")
	,component = {
	   lQuery.create("D#HorizontalBox", {
		  component = {lQuery.create("D#ComboBox", {
		    id = "dependencyComboBox"
			,text = ""
			,editable = is_editable
			,item = createItemsDependency()--atlasa visus rezimus un katram izveido itemu elementu un pievieno to comboBox elementam
		  })}
	  })
	  ,lQuery.create("D#HorizontalBox", {
		  minimumWidth = 200
		  ,horizontalAlignment = 1
          ,component = {lQuery.create("D#Button", {
			caption = "Delete"--poga izdzesh rezimu
			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.delete_dependency()")
		  })}
	  })
	  ,lQuery.create("D#HorizontalBox", {
        horizontalAlignment = 1
        ,component = close_button--formas aizvershanas poga
	  })
    }	
  })
  dialog_utilities.show_form(form)
end

--izveido sarakstu ar atkaribam
function createItemsDependency()
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	  
	local values = lQuery(fielDRepId):find("/dependency"):map(
	  function(obj, i)
		return {lQuery(obj):find("/dependsOn"):attr("caption"), lQuery(obj):find("/dependsOn"):id(), lQuery(obj):find("/dependsOn"), lQuery(obj):id()}
	  end)  
	
	return lQuery.map(values, function(mode_value) 
		local fieldF = lQuery(mode_value[3]):find("/field")
		return lQuery.create("D#Item", {
			id = mode_value[4]
			,value = "Field: " .. fieldF:attr("name") .. " Item: " .. mode_value[1]
		}) 
	end)
end

--izdzes atkaribu
function delete_dependency()
	local selected = lQuery("D#ComboBox[id='dependencyComboBox']/selected"):attr("id")
	local dependency -- vajadziga AA#dependency instance
	local field = lQuery("AA#Dependency"):each(function(obj)
		if obj:id() == tonumber(selected) then 
			dependency = obj
			return
		end end)
	lQuery(dependency):delete()
	closeDeleteOneDependency()
	lQuery("D#VerticalBox[id = 'VerBoxDependenciesLine']/component[id = '" .. selected .. "']"):delete()
	lQuery("D#VerticalBox[id = 'VerBoxDependenciesLine']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

--izdzes transletu
function deleteOneTranslete()
	--atrast aktivo rindu transletu tabulaa
	local activeRow = lQuery("D#VTable[id = 'TableTransletes']/selectedRow")
	local id = lQuery("D#VTable[id = 'TableTransletes']/selectedRow/vTableCell:has(/vTableColumnType[caption='Procedure'])/component"):attr("id")
	
	--citadi ja ir aktiva tuksa rinda
	if id ~= "" then
	--atrast AA#Translet, kas ir piesaistits Procedure cunai, izdzest to
		local fielDRepId -- vajadziga AA#ChoiceItem instance
		local field = lQuery("AA#Translet"):each(function(obj)
			if obj:id() == tonumber(id) then 
				fielDRepId = obj
				return
			end end)
		lQuery(fielDRepId):delete()
		lQuery(activeRow):delete()
		lQuery("D#Tab[id='Translets']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	--izdzest aktivo rindu no tabulas
	end
end

--izdzes stila vienumu
function deleteOneStyle()
	--atrast aktivo rindu transletu tabulaa
	local activeRow = lQuery("D#VTable[id = 'TableStyleField']/selectedRow")
	local id = lQuery("D#VTable[id = 'TableStyleField']/selectedRow/vTableCell:has(/vTableColumnType[caption='Value'])/component"):attr("id")
		
	--citadi ja ir aktiva tuksa rinda
	if id ~= nil then
	--atrast AA#Translet, kas ir piesaistits Procedure shunai, izdzest to
		local fielDRepId -- vajadziga AA#ChoiceItem instance
		local field = lQuery("AA#FieldStyleSetting"):each(function(obj)
			if obj:id() == tonumber(id) then 
				fielDRepId = obj
				return
			end end)
		lQuery(fielDRepId):delete()
		lQuery(activeRow):delete()
		lQuery("D#Tab[id='StyleField']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	--izdzest aktivo rindu no tabulas
	end
end

--izdzes elementa stila vienumu
function deleteOneElementsStyle()
	--atrast aktivo rindu transletu tabulaa
	local activeRow = lQuery("D#VTable[id = 'TableStyleItemElement']/selectedRow")
	local id = lQuery("D#VTable[id = 'TableStyleItemElement']/selectedRow/vTableCell:has(/vTableColumnType[caption='Value'])/component"):attr("id")

	--citadi ja ir aktiva tuksa rinda
	if id ~= nil then
	--atrast AA#Translet, kas ir piesaistits Procedure shunai, izdzest to
		local fielDRepId -- vajadziga AA#ChoiceItem instance
		local field = lQuery("AA#FieldStyleSetting"):each(function(obj)
			if obj:id() == tonumber(id) then 
				fielDRepId = obj
				return
			end end)
		lQuery(fielDRepId):delete()
		lQuery(activeRow):delete()

		lQuery("D#Tab[id='StyleItem']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	--izdzest aktivo rindu no tabulas
	end
end

--izdzes lauka stila vienumu
function deleteOneFieldStyle()
	--atrast aktivo rindu transletu tabulaa
	local activeRow = lQuery("D#VTable[id = 'TableStyleItemField']/selectedRow")
	local id = lQuery("D#VTable[id = 'TableStyleItemField']/selectedRow/vTableCell:has(/vTableColumnType[caption='Value'])/component"):attr("id")

	--citadi ja ir aktiva tuksa rinda
	if id ~= nil then
	--atrast AA#Translet, kas ir piesaistits Procedure shunai, izdzest to
		local fielDRepId -- vajadziga AA#ChoiceItem instance
		local field = lQuery("AA#FieldStyleSetting"):each(function(obj)
			if obj:id() == tonumber(id) then 
				fielDRepId = obj
				return
			end end)
		lQuery(fielDRepId):delete()
		lQuery(activeRow):delete()
		lQuery("D#Tab[id='StyleItem']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	--izdzest aktivo rindu no tabulas
	end
end

--atlasa iespejamos stilus (ItemElement)
function getNewStyleItemElement()
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")

	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#ChoiceItem"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)

	local contextType = lQuery(fielDRepId):find("/field/context"):attr("type")
	local values
	
	local mode = lQuery(fielDRepId):find("/field/context"):attr("mode")
	local forCompart
	if mode~=nil then
		if mode == "Element" then
			local elemStyle = lQuery("ElemType[caption='" .. contextType .. "']/elemStyle"):first()
			lQuery("NodeStyle"):each(function(obj)
				if lQuery(obj):id() == lQuery(elemStyle):id() then 
					local values1 = lQuery("AA#NodeStyleItem"):map(
					  function(obj, i)
						return {lQuery(obj):attr("itemName"), lQuery(obj):id()}
					  end)
					local values2 = lQuery("AA#AnyElemStyleItem"):map(
					  function(obj, i)
						return {lQuery(obj):attr("itemName"), lQuery(obj):id()}
					  end)
					values = lQuery.merge(values2, values1)
				end
			end)
			lQuery("EdgeStyle"):each(function(obj)
				if lQuery(obj):id() == lQuery(elemStyle):id() then 
					local values1 = lQuery("AA#EdgeStyleItem"):map(
					  function(obj, i)
						return {lQuery(obj):attr("itemName"), lQuery(obj):id()}
					  end)
					local values2 = lQuery("AA#AnyElemStyleItem"):map(
					  function(obj, i)
						return {lQuery(obj):attr("itemName"), lQuery(obj):id()}
					  end)
					values = lQuery.merge(values2, values1)
				end
			end)
		elseif mode == "Group" then
			local elemStyle = lQuery("ElemType[caption='" .. lQuery(fielDRepId):find("/field/context"):attr("elTypeName") .. "']/elemStyle"):first()
			lQuery("NodeStyle"):each(function(obj)
				if lQuery(obj):id() == lQuery(elemStyle):id() then 
					local values1 = lQuery("AA#NodeStyleItem"):map(
					  function(obj, i)
						return {lQuery(obj):attr("itemName"), lQuery(obj):id()}
					  end)
					local values2 = lQuery("AA#AnyElemStyleItem"):map(
					  function(obj, i)
						return {lQuery(obj):attr("itemName"), lQuery(obj):id()}
					  end)
					values = lQuery.merge(values2, values1)
				end
			end)
			lQuery("EdgeStyle"):each(function(obj)
				if lQuery(obj):id() == lQuery(elemStyle):id() then 
					local values1 = lQuery("AA#EdgeStyleItem"):map(
					  function(obj, i)
						return {lQuery(obj):attr("itemName"), lQuery(obj):id()}
					  end)
					local values2 = lQuery("AA#AnyElemStyleItem"):map(
					  function(obj, i)
						return {lQuery(obj):attr("itemName"), lQuery(obj):id()}
					  end)
					values = lQuery.merge(values2, values1)
				end
			end)
		elseif mode == "Group Item" or mode == "Text" then 
			values = lQuery("AA#CompartStyleItem[forAttribCompart = 1]"):map(
			  function(obj, i)
				return {lQuery(obj):attr("itemName"), lQuery(obj):id()}
			  end)
		end
    else
		values = lQuery("AA#CompartStyleItem[forAttribCompart = 1]"):map(
			  function(obj, i)
				return {lQuery(obj):attr("itemName"), lQuery(obj):id()}
			  end)
	end
	return lQuery.map(values, function(mode_value) 
		return lQuery.create("D#Item", {
			value = mode_value[1]
			,id = mode_value[2]
		}) 
	end)
end

--atlasa iespejamos stilus vienumus laukam
function getNewStyleField(val)
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId
	local contextType
	local context
	if val == "Item" then 
		 -- vajadziga AA#Field instance
		local field = lQuery("AA#ChoiceItem"):each(function(obj)
			if obj:id() == repNr then 
				fielDRepId = obj
				return
			end end)
		
		context = lQuery(fielDRepId):find("/field/context")
		contextType = lQuery(fielDRepId):find("/field/context"):attr("type")
	elseif val == "Context" then
		-- vajadziga AA#Context instance
		local field = lQuery("AA#ContextType"):each(function(obj)
			if obj:id() == repNr then 
				fielDRepId = obj
				return
			end end)
		
		context =fielDRepId
		contextType = lQuery(fielDRepId):attr("type")
	else
		 -- vajadziga AA#Field instance
		local field = lQuery("AA#Field"):each(function(obj)
			if obj:id() == repNr then 
				fielDRepId = obj
				return
			end end)
		context = lQuery(fielDRepId):find("/context")
		contextType = lQuery(fielDRepId):find("/context"):attr("type")
	end
	local values
	local mode = context:attr("mode")
	local forCompart
	if mode == "Element" then
		local elemStyle = lQuery("ElemType[id='" .. contextType .. "']/elemStyle"):first()
		lQuery("NodeStyle"):each(function(obj)
			if lQuery(obj):id() == lQuery(elemStyle):id() then forCompart = "forNodeCompart" end
		end)
		lQuery("EdgeStyle"):each(function(obj)
			if lQuery(obj):id() == lQuery(elemStyle):id() then forCompart = "forEdgeCompart" end
		end)
	elseif mode == "Group" then
		local elemStyle = lQuery("ElemType[id='" .. context:attr("elTypeName") .. "']/elemStyle"):first()
		lQuery("NodeStyle"):each(function(obj)
			if lQuery(obj):id() == lQuery(elemStyle):id() then forCompart = "forNodeCompart" end
		end)
		lQuery("EdgeStyle"):each(function(obj)
			if lQuery(obj):id() == lQuery(elemStyle):id() then forCompart = "forEdgeCompart" end
		end)
	elseif mode == "Group Item" or mode == "Text"  then forCompart = "forAttribCompart"
	end
	values = lQuery("AA#CompartStyleItem[" .. forCompart .. " = 1]"):map(
		  function(obj, i)
			return {lQuery(obj):attr("itemName"), lQuery(obj):id()}
		  end)

	return lQuery.map(values, function(mode_value) 
		return lQuery.create("D#Item", {
			value = mode_value[1]
			,id = mode_value[2]
		}) 
	end)
end

--pievieno tukso rindu atkaribai
function getNewDependencies()

	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
		
		lQuery.create("D#Row", {
			id = "EmptyTableRows"
			,component = {
				lQuery.create("D#Label", {caption = "Show this field when field "})
				,lQuery.create("D#ComboBox", {
					text = ""
					,item = getFieldsDependencies()
					,eventHandler = {
						utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectNewFieldsDependencies2()")
					}
				})
				,lQuery.create("D#Label", {caption = " has value"})
				,lQuery.create("D#ComboBox", {
					text = ""
				})
			}
		}):link("container", lQuery("D#VerticalBox[id = 'VerBoxDependenciesLine']"))
		lQuery("D#VerticalBox[id = 'VerBoxDependenciesLine']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

--savac jau piesaistitas atkaribas
function getDependencies()

	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
  
	local values = lQuery(fielDRepId):find("/dependency"):map(
	  function(obj, i)
		return {lQuery(obj):find("/dependsOn"):attr("caption"), lQuery(obj):find("/dependsOn"):id(), lQuery(obj):find("/dependsOn"), lQuery(obj):id()}
	  end)  
	
	return lQuery.map(values, function(mode_value) 

		local fieldF = lQuery(mode_value[3]):find("/field")
		return lQuery.create("D#Row", {
			id = mode_value[4]
			,component = {
				lQuery.create("D#Label", {caption = "Show this field when field "})
				,lQuery.create("D#InputField", {
					text = fieldF:attr("name")
				})
				,lQuery.create("D#Label", {caption = " has value"})
				,lQuery.create("D#ComboBox", {
					text = mode_value[1]
					,id = mode_value[2]
					,item = getItemsDependencies(fieldF)
					,eventHandler = {
						utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectItemDependencies2()")
					}
				})
			}
		}) 
	end)
end

--savac atkaribas Laukus
function getFieldsDependencies()
	--atrast visus fieldus ar isStereotypeField = true
	--atradam aktivo lauku	
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	
	--atrast ContextType(kamer /context ir tuks iet pa superField)
	local l = 0
	local contextType
	while l  == 0 do
        if lQuery(fielDRepId):find("/context"):is_not_empty() then
			l = 1
			contextType = lQuery(fielDRepId):find("/context"):attr("type")
		else
			fielDRepId = lQuery(fielDRepId):find("/superField")
		end
    end

	--atrast visus pirma limena fildus, kam ir isStereotypeField = true un ir ar tadu pasu ContextType, bet nav tas pats lauks
	local values = lQuery("AA#ContextType[type = '" .. contextType .. "']/fieldInContext[isStereotypeField = true]"):map(--tikai pirma limenja fieldi
	  function(obj, i)
		if lQuery(obj):find("/choiceItem"):size() ~= 0 and lQuery(fielDRepId):id() ~= lQuery(obj):id() then
			return {lQuery(obj):attr("name"), lQuery(obj):id()}
		end
	  end)
	return lQuery.map(values, function(mode_value) 
		return lQuery.create("D#Item", {
			id = mode_value[2]
			,value = mode_value[1]
		}) 
	end)
end

--savac atkaribas Itemus(field-lauks kura vienumus jasavac)
function getItemsDependencies(field)
	local values = lQuery(field):find("/choiceItem"):map(
	  function(obj, i)
		return {lQuery(obj):attr("caption"), lQuery(obj):id()}
	  end)
	return lQuery.map(values, function(mode_value) 
		return lQuery.create("D#Item", {
			id = mode_value[2]
			,value = mode_value[1]
		}) 
	end)
end

--savac jau piesaistitos transletus
function getTranslete()
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	--atrast AA#TransletTask ar vajadzigo tekstu
	local fielDRepId -- vajadziga AA#ChoiceItem instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)

	local values = lQuery(fielDRepId):find("/translet"):map(
	  function(obj, i)
		return {lQuery(obj):find("/task"):attr("taskName"), lQuery(obj):find("/task"):id(), lQuery(obj):attr("procedure"), lQuery(obj):id()}
	  end)

	return lQuery.map(values, function(mode_value) 
		return lQuery.create("D#VTableRow", {
			vTableCell = {
				lQuery.create("D#VTableCell", { 
					vTableColumnType = lQuery("D#VTableColumnType[caption = 'Translet_task']")
					,component = lQuery.create("D#ComboBox", {
						text = mode_value[1]
						,item = getTransletTasks()
						,eventHandler = {
							utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeTransletTask()")
						}
					})
				})
				,lQuery.create("D#VTableCell", { value = mode_value[3]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Procedure']")
					,component = lQuery.create("D#TextBox", {
						text = mode_value[3]
						,id = mode_value[4]--AA#Translet instances id
						,eventHandler = {
							utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeTransletProcedure()")
						}
					})
				})
			}
		}) 
	end)								
end

--maina transleta procedures vardu
function changeTransletProcedure()
	local cellValue = lQuery("D#VTable[id = 'TableTransletes']/selectedRow/activeCell"):attr("value")--jauna vartiba
	local cellId = lQuery("D#VTable[id = 'TableTransletes']/selectedRow/activeCell/component"):attr("id")--AA#Translet repId
	
	local tran2--AA#Translet instance
	local tran = lQuery("AA#Translet"):each(function(obj)
		if obj:id() == tonumber(cellId) then 
			tran2 = obj
			return
		end end)
	lQuery(tran2):attr("procedure", cellValue)
end

--ja tiek mainits jau eksistejash Translet task
function changeTransletTask()
	local cellId = lQuery("D#VTable[id = 'TableTransletes']/selectedRow/vTableCell:has(/vTableColumnType[caption='Procedure'])/component"):attr("id")--jauna vartiba

	local tran2--AA#Translet instance
	local tran = lQuery("AA#Translet"):each(function(obj)
		if obj:id() == tonumber(cellId) then 
			tran2 = obj
			return
		end end)
	local tt = lQuery(tran):find("/task")--AA#TransletTask instance veca
	
	local cellValue = lQuery("D#VTable[id = 'TableTransletes']/selectedRow/activeCell"):attr("value")--jauna vartiba
	local newTT = lQuery("AA#TransletTask[taskName = '" .. cellValue .. "']")--jauna AA#TransletTask instance

	lQuery(tran2):remove_link("task", tt)
	lQuery(tran2):link("task", newTT)
	
	local cell = lQuery("D#VTable[id = 'TableTransletes']/selectedRow/activeCell")--shuna
	lQuery("D#VTable[id = 'TableTransletes']/selectedRow/activeCell/component"):delete()
	
	--atrast ChoiseItemus
	local values = lQuery("AA#TransletTask"):map(
	  function(obj, i)
		return {lQuery(obj):attr("taskName"), lQuery(obj):id()}
	  end)
	local cb = lQuery.create("D#ComboBox", {
		text = newTT:attr("taskName")
		,item = {
			lQuery.map(values, function(mode_value) 
				return lQuery.create("D#Item", {
					id = mode_value[2]
					,value = mode_value[1]
				}) 
			end)}
		,eventHandler = {
			utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeTransletTask()")
		}
	})
	lQuery(cell):link("component", cb)	
	lQuery(cell):attr("value", newTT:attr("taskName"))
	lQuery("D#Tab[id='Translets']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

--atlasa AA#TranstetTask instances
function getTransletTasks()
	local values = lQuery("AA#TransletTask"):map(
	  function(obj, i)
		return {lQuery(obj):attr("taskName"), lQuery(obj):id()}
	  end)
	return lQuery.map(values, function(mode_value) 
		return lQuery.create("D#Item", {
			value = mode_value[1]
			,id = mode_value[2] .. " AA#Field"
		}) 
	end)
end

--ja tiek mainits TransletTasks tuksaja rindaa
function selectTransletTask()
	--ja tiek pievienots jauns
	--jatiek maimits jau eksistejass
	
	local cellValue = lQuery("D#VTable[id = 'TableTransletes']/selectedRow/activeCell"):attr("value")
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	--atrast AA#TransletTask ar vajadzigo tekstu
	local fielDRepId -- vajadziga AA#ChoiceItem instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	local t = lQuery("AA#TransletTask[taskName='".. cellValue .. "']")
		
	--piesaistit transletu 		
	local TT = lQuery.create("AA#Translet"):link("task", t)
	lQuery(TT):link("field", fielDRepId)
	
	cellTransletTask = lQuery("D#VTable[id = 'TableTransletes']/selectedRow/activeCell")--suna translet task

	transletTask = lQuery("D#VTable[id = 'TableTransletes']/selectedRow/activeCell/component"):delete()--komponente

	local cb = lQuery.create("D#ComboBox", {
		text = cellValue
		,item = getTransletTasks()
		,eventHandler = {
			utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeTransletTask()")
		}
	})
	lQuery(cellTransletTask):link("component", cb)	
	lQuery(cellTransletTask):attr("value", cellValue)
	lQuery("D#Tab[id='Translets']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	
	cellTransletProcedure = lQuery("D#VTable[id = 'TableTransletes']/selectedRow/activeCell/vTableRow/vTableCell:has(/vTableColumnType[caption='Procedure'])")--suna procedure
	transletProcedure = lQuery("D#VTable[id = 'TableTransletes']/selectedRow/activeCell/vTableRow/vTableCell:has(/vTableColumnType[caption='Procedure'])/component"):delete()--komponente
	
	local cc = lQuery.create("D#TextBox", {
						text = ""
						,id = TT:id()--AA#Translet instances id
						,eventHandler = {
							utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.changeTransletProcedure()")
						}
					})
	lQuery(cellTransletProcedure):link("component", cc)	
	lQuery(cellTransletProcedure):attr("value", "")

	lQuery.create("D#VTableRow", {
		vTableCell = {
			lQuery.create("D#VTableCell", { 
				vTableColumnType = lQuery("D#VTableColumnType[caption = 'Translet_task']")
					,component = lQuery.create("D#ComboBox", {
						item = {
							getTransletTasks()
						}
						,eventHandler = {
							utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectTransletTask()")
						}
					})
			})
			,lQuery.create("D#VTableCell", { value = ""
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Procedure']")
				,component = lQuery.create("D#TextBox", {text = ""})
			})
		}
	}):link("vTable", lQuery("D#VTable[id= 'TableTransletes']"))
	lQuery("D#VTable[id= 'TableTransletes']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

--ja izvelas atkaribas lauku
function selectNewFieldsDependencies()

	local cellValue = lQuery("D#VTable[id = 'TableDependencies']/selectedRow/activeCell"):attr("value")
	
	--nolasit kads fields tika izvelets
	local id = lQuery("D#VTable[id = 'TableDependencies']/selectedRow/activeCell/component/selected"):attr("id")
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == tonumber(id) then 
			fielDRepId = obj
			return
		end end)
	--izdzest AA#Dependencies
		--atrast atkarigo Fieldu
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepIdD -- atkariga AA#Field instance
	local fieldD = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepIdD = obj
			return
		end end)
	
	--aizvacam linku uz ChoiceItem
	local defaultItem = lQuery(fielDRepId):find("/choiceItem")
	defaultItem = defaultItem:first()

	--fielDRepIdD - filds no koka
	--defaultItem - noklusets items
	lQuery.create("AA#Dependency"):link("dependent", fielDRepIdD)
									:link("dependsOn", defaultItem)
	
	--atrast aktiva sunu - field
	cellField = lQuery("D#VTable[id = 'TableDependencies']/selectedRow/activeCell")--suna field

	lQuery("D#VTable[id = 'TableDependencies']/selectedRow/activeCell/component"):delete()--komponente

	local cb = lQuery.create("D#ComboBox", {
		text = lQuery(defaultItem):find("/field"):attr("name")
		,item = getFieldsDependencies()
		,eventHandler = {
			utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectFieldsDependencies()")
		}
	})
	lQuery(cellField):link("component", cb)	
	lQuery(cellField):attr("value", cellValue)
	lQuery("D#Tab[id='Dependencies']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	
	cellItem = lQuery("D#VTable[id = 'TableDependencies']/selectedRow/activeCell/vTableRow/vTableCell:has(/vTableColumnType[caption='Item'])")--suna procedure
	lQuery("D#VTable[id = 'TableDependencies']/selectedRow/activeCell/vTableRow/vTableCell:has(/vTableColumnType[caption='Item'])/component"):delete()--komponente
	
	local cc = lQuery.create("D#ComboBox", {
		text = defaultItem:attr("caption")
		,id = defaultItem:id()
		,item = getItemsDependencies(lQuery(defaultItem):find("/field"))
		,eventHandler = {
			utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectItemDependencies()")
		}
	})
	lQuery(cellItem):link("component", cc)	
	lQuery(cellItem):attr("value", "")
	lQuery("D#Tab[id='Dependencies']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	
	--tuksa rinda
	lQuery.create("D#VTableRow", {
			id = "EmptyTableRows"
			,vTableCell = {
				lQuery.create("D#VTableCell", { value = ""
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Field']")
					,component = lQuery.create("D#ComboBox", {
						text = ""
						,item = getFieldsDependencies()
						,eventHandler = {
							utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectNewFieldsDependencies()")
						}
					})
				})
				,lQuery.create("D#VTableCell", { 
					vTableColumnType = lQuery("D#VTableColumnType[caption = 'Item']")
					,component = lQuery.create("D#ComboBox", {
						text = ""
					})
				})
			}
		}):link("vTable", lQuery("D#VTable[id= 'TableDependencies']"))
	lQuery("D#Tab[id='Dependencies']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

--ja izvelas atkaribas lauku
function selectNewFieldsDependencies2()
	local cellValue = lQuery("D#Event/source"):attr("text")

		--nolasit kads fields tika izvelets
	local idItem = lQuery("D#Event/source/selected"):attr("id")

	local fielDRepId -- vajadziga AA#Field instance ko izvelas combo boksii
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == tonumber(idItem) then 
			fielDRepId = obj
			return
		end end)
	--izdzest AA#Dependencies
	--atrast atkarigo Fieldu
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepIdD -- atkariga AA#Field instance no koka (iezimeta)
	local fieldD = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepIdD = obj
			return
		end end)
	
	--aizvacam linku uz ChoiceItem

	local defaultItem = lQuery(fielDRepId):find("/choiceItem")
	defaultItem = defaultItem:first()

	--fielDRepIdD - filds no koka
	--defaultItem - noklusets items
	local dep = lQuery.create("AA#Dependency"):link("dependent", fielDRepIdD)
									:link("dependsOn", defaultItem)
	--atrast Row ar id "EmptyTableRows"
	--izdzest to
	--izveidot jauno

	lQuery("D#Row[id ='EmptyTableRows']"):delete()
	lQuery.create("D#Row", {
			id = lQuery(dep):id()
			,component = {
				lQuery.create("D#Label", {caption = "Show this field when field "})
				,lQuery.create("D#InputField", {
					text = lQuery(defaultItem):find("/field"):attr("name")
				})
				,lQuery.create("D#Label", {caption = " has value"})
				,lQuery.create("D#ComboBox", {
					text = defaultItem:attr("caption")
					,id = defaultItem:id()
					,item = getItemsDependencies(lQuery(defaultItem):find("/field"))
					,eventHandler = {
						utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectItemDependencies2()")
					}
				})
			}
		}):link("container", lQuery("D#VerticalBox[id = 'VerBoxDependenciesLine']"))
		lQuery("D#VerticalBox[id = 'VerBoxDependenciesLine']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

--ja maina jau eksitejiso atkarigo Lauku
function selectFieldsDependencies()
	
	--nolasit kads fields tika izvelets
	local id = lQuery("D#VTable[id = 'TableDependencies']/selectedRow/activeCell/component/selected"):attr("id")

	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == tonumber(id) then 
			fielDRepId = obj
			return
		end end)
	--izdzest AA#Dependencies
		--atrast atkarigo Fieldu
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")

	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepIdD -- atkariga AA#Field instance
	local fieldD = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepIdD = obj
			return
		end end)

	--aizvacam linku uz ChoiceItem
	
	--atrast Itemu, kas atrodal tabula, to repId
	local cell = lQuery("D#VTable[id = 'TableDependencies']/selectedRow/vTableCell:has(/vTableColumnType[caption='Item'])")--shuna
	local cellId = lQuery(cell):find("/component"):attr("id")--vajadziga iteme id (ta no kura ir jaaizvac links)

	local dep2--vajadziga dependency
	local dep = lQuery(fielDRepIdD):find("/dependency"):each(function(obj)
		if obj:find("/dependsOn"):id() == tonumber(cellId) then 
			dep2 = obj
			return
		end end)

	local oldItem2--vajadzigais items (no kura jaaizvac links)
	local oldItem = lQuery(dep2):find("/dependsOn"):each(function(obj)
		if obj:id() == tonumber(cellId) then 
			oldItem2 = obj
			return
		end end)
	
	local d = lQuery(fielDRepIdD):find("/dependency/dependsOn")
	local defaultItem = lQuery(fielDRepId):find("/choiceItem")
	defaultItem = defaultItem:first()

	lQuery(dep2):remove_link("dependsOn", oldItem2)
	lQuery(dep2):link("dependsOn", defaultItem)
	
	--atrast shunu ar itemiem
	--izdzest to
	
	--izdzest comboBox
	--piesaistit jauno shunai
	
	local cell = lQuery("D#VTable[id = 'TableDependencies']/selectedRow/vTableCell:has(/vTableColumnType[caption='Item'])")--shuna
	lQuery("D#VTable[id = 'TableDependencies']/selectedRow/vTableCell:has(/vTableColumnType[caption='Item'])/component"):delete()
	
	--atrast ChoiseItemus
	local values = lQuery(fielDRepId):find("/choiceItem"):map(
	  function(obj, i)
		return {lQuery(obj):attr("caption"), lQuery(obj):id()}
	  end)
	local cb = lQuery.create("D#ComboBox", {
		text = defaultItem:attr("caption")
		,id = defaultItem:id()
		,item = {
			lQuery.map(values, function(mode_value) 
				return lQuery.create("D#Item", {
					id = mode_value[2]
					,value = mode_value[1]
				}) 
			end)}
		,eventHandler = {
			utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.Profile.selectItemDependencies()")
		}
	})
	lQuery(cell):link("component", cb)	
	lQuery(cell):attr("value", "")
	lQuery("D#Tab[id='Dependencies']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

--ja maina jau eksitejiso atkarigo izveles vienumu
function selectItemDependencies()

--	atrast fieldu, kas ir "Field" laukaa,
--	atrast itemu, kas piesaistits fieldam
--	novilkt saiti no atkarigsLauks/dependency uz atrasto Itemu

	--nolasit kads fields tika izvelets
	local id = lQuery("D#VTable[id = 'TableDependencies']/selectedRow/activeCell/component/selected"):attr("id")

	local fielDRepId -- vajadziga AA#ChoiceItem instance
	local field = lQuery("AA#ChoiceItem"):each(function(obj)
		if obj:id() == tonumber(id) then
			fielDRepId = obj
			return
		end end)
	
	local subField = lQuery(fielDRepId):find("/field"):id()
	
	--izdzest AA#Dependencies
		--atrast atkarigo Fieldu
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepIdD -- atkariga AA#Field instance
	local fieldD = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepIdD = obj
			return
		end end)

	local old2
	local oldItem = lQuery(fielDRepIdD):find("/dependency/dependsOn"):each(function(obj)
		if obj:find("/field"):id() == subField then 
			old2 = obj
			return
		end end)

	local dep2
	local dep = lQuery(fielDRepIdD):find("/dependency"):each(function(obj)
		if obj:find("/dependsOn/field"):id() == subField then 
			dep2 = obj
			return
		end end)
	
	lQuery(dep2):remove_link("dependsOn", old2)
	lQuery(dep2):link("dependsOn", fielDRepId)
	lQuery("D#Tab[id='Dependencies']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

--ja maina jau eksitejiso atkarigo izveles vienumu
function selectItemDependencies2()

--	atrast fieldu, kas ir "Field" laukaa,
--	atrast itemu, kas piesaistits fieldam
--	novilkt saiti no atkarigsLauks/dependency uz atrasto Itemu

	--nolasit kads items tika izvelets
	local idItem = lQuery("D#Event/source/selected"):attr("id")
	
	local fielDRepId -- vajadziga AA#ChoiceItem instance
	local field = lQuery("AA#ChoiceItem"):each(function(obj)
		if obj:id() == tonumber(idItem) then
			fielDRepId = obj
			return
		end end)	
	
	local subField = lQuery(fielDRepId):find("/field"):id()
	
	--izdzest AA#Dependencies
		--atrast atkarigo Fieldu
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepIdD -- atkariga AA#Field instance
	local fieldD = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepIdD = obj
			return
		end end)

	local old2
	local oldItem = lQuery(fielDRepIdD):find("/dependency/dependsOn"):each(function(obj)
		if obj:find("/field"):id() == subField then 
			old2 = obj
			return
		end end)

	local dep2
	local dep = lQuery(fielDRepIdD):find("/dependency"):each(function(obj)
		if obj:find("/dependsOn/field"):id() == subField then 
			dep2 = obj
			return
		end end)
	
	lQuery(dep2):remove_link("dependsOn", old2)
	lQuery(dep2):link("dependsOn", fielDRepId)
	lQuery("D#Tab[id='Dependencies']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

--nomaina pogas, kad tiek izvelets cits koka elements (defaultItem-lauka tips)
function changeButtons(defaultItem)
	local close_button = lQuery.create("D#Button", {
		caption = "Close"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.close()")
	})

	if defaultItem == "InputField+Button" or defaultItem == "TextArea+Button" or defaultItem == "" then
		lQuery("D#VerticalBox[id = 'buttons']"):delete()
		lQuery.create("D#VerticalBox", {id = "buttons"
			,component = {
				lQuery.create("D#Button", {
					caption = "Add SubField"
					,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.createSubField()")
				})
			}
		}):link("container", lQuery("D#HorizontalBox[id = 'closeFormProfile']"))
	elseif defaultItem == "ListBox" or defaultItem == "ComboBox" then
		lQuery("D#VerticalBox[id = 'buttons']"):delete()
		lQuery.create("D#VerticalBox", {id = "buttons"
			,component = {
				lQuery.create("D#Button", {
					caption = "Add Item"
					,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.createItem()")
				})
			}
		}):link("container", lQuery("D#HorizontalBox[id = 'closeFormProfile']"))
	else 
		lQuery("D#VerticalBox[id = 'buttons']"):delete()
		lQuery.create("D#VerticalBox", {id = "buttons"}):link("container", lQuery("D#HorizontalBox[id = 'closeFormProfile']"))
	end
	lQuery("D#VerticalBox[id = 'closeButton']"):delete()
	lQuery.create("D#VerticalBox", {
		id = "closeButton"
		,horizontalAlignment = 1
		,component = {close_button}
	}):link("container", lQuery("D#HorizontalBox[id = 'closeFormProfile']")) 
	lQuery("D#HorizontalBox[id = 'closeFormProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

--atlasa profila namespace deklaracijas(profile-atvertais profils)
function colectProfilePrefix(profile)	
	local values = profile:find("/tag[tagKey='owl_Import_Prefixes']"):map(
	  function(obj)
			return {lQuery(obj):attr("tagValue"), lQuery(obj):id()}
	  end)

	local r = lQuery.map(values, function(mode_value) 
								return lQuery.create("D#TextLine", {
									text = mode_value[1]
									,id = mode_value[2]
								}) 
							  end)
	return r
end

--savac semantiku no Itemiem(nr-choiceItem identifikators, key-semantikas veids)
function colectSemanticsItem(nr, key)
	  local values = lQuery("AA#Tag[tagKey='" .. key .."']"):map(
	  function(obj, i)
		if lQuery(obj):find("/choiceItem"):id() == nr then
			return {lQuery(obj):attr("tagValue"), lQuery(obj):id()}
		end
	  end)

	local r = lQuery.map(values, function(mode_value) 
								return lQuery.create("D#TextLine", {
									text = mode_value[1]
									,id = mode_value[2]
								}) 
							  end)
	return r
end

--savac semantiku no Itemiem, kur vienumam var but tikai viena sada tipa semantikas deklaracija(key-semantikas veids)
function colectSemanticsImportItem(key)
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")

	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
		
	local fielDRepId -- vajadziga AA#ChoiceItem instance
	local field = lQuery("AA#ChoiceItem"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	return fielDRepId:find("/tag[tagKey='" .. key .. "']"):attr("tagValue")
end

--atlasa semantikas vertibu (key-semantikas veids)
function colectSemanticsImport(key)
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")

	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
		
	local fielDRepId -- vajadziga AA#ChoiceItem instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	return fielDRepId:find("/tag[tagKey='" .. key .. "']"):attr("tagValue")
end

function split (s, sep)
  sep = lpeg.P(sep)
  local elem = lpeg.C((1 - sep)^0)
  local p = lpeg.Ct(elem * (sep * elem)^0)
  return lpeg.match(p, s)
end

--savac semantiku no laukiem
function colectSemantics(value, tagType)
	local values = lQuery("AA#Tag[tagKey='" .. tagType .. "']"):map(
	  function(obj, i)
		if lQuery(obj):find("/field"):id() == value then
			return {lQuery(obj):attr("tagValue"), lQuery(obj):id()}
		end
	  end)

	local r = lQuery.map(values, function(mode_value) 
								return lQuery.create("D#TextLine", {
									text = mode_value[1]
									,id = mode_value[2]
								}) 
							  end)
	return r
end

--item lauku izmainas
function changeEventItem()
	local focus = lQuery("D#Event/source"):attr("text")
	local focusID = lQuery("D#Event/source"):attr("id")
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#ChoiceItem instance
	local field = lQuery("AA#ChoiceItem"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	
	fielDRepId:attr(focusID, focus)--ierakstam jauno vertibu
	if focusID == "caption" then--atjaunojam koku
		lQuery("D#Tree[id = 'treeProfile']/selected"):attr("text", "I:" .. focus)
		lQuery("D#Tree[id='treeProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	end
end

--maina semantiku, kur laukam var but tikai viena sada tipa semantikas deklaracija
function changeEventImportSemantics()
	if lQuery("D#Event/source"):size() == 1 then
		local focus = lQuery("D#Event/source"):attr("text")
		local idTextArea = lQuery("D#Event/source"):attr("id")
		local tagType = lQuery("AA#TagType"):filter(function(obj)
			return obj:id() == tonumber(idTextArea)
		end):attr("key")
		--if focus~=nil then
			local len = string.len(focus)
			local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")

			local n = string.find(id, " ")
			local types = string.sub(id, n+1)--tips
			local repNr = string.sub(id, 1, n-1)--id
			repNr = tonumber(repNr)
			
			local fielDRepId -- vajadziga AA#ChoiceItem instance
			local field = lQuery("AA#Field"):each(function(obj)
				if obj:id() == repNr then 
					fielDRepId = obj
					return
				end end)
			if focus == "" then fielDRepId:find("/tag[tagKey='" .. tagType .. "']"):delete()
			elseif fielDRepId:find("/tag[tagKey='" .. tagType .. "']"):is_empty() then 
				lQuery.create("AA#Tag", {tagKey=tagType, tagValue = focus}):link("field", fielDRepId)
			else
				fielDRepId:find("/tag[tagKey='" .. tagType .. "']"):attr("tagValue", focus)
			end
	end	
end

--maina semantiku, kur vienumam var but tikai viena sada tipa semantikas deklaracija
function changeEventImportSemanticsItem()
	local focus = lQuery("D#Event/source"):attr("text")
	if focus~=nil then
		local idTextArea = lQuery("D#Event/source"):attr("id")
		local tagType = lQuery("AA#TagType"):filter(function(obj)
			return obj:id() == tonumber(idTextArea)
		end):attr("key")
		local len = string.len(focus)
		local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")

		local n = string.find(id, " ")
		local types = string.sub(id, n+1)--tips
		local repNr = string.sub(id, 1, n-1)--id
		repNr = tonumber(repNr)
		
		local fielDRepId -- vajadziga AA#ChoiceItem instance
		local field = lQuery("AA#ChoiceItem"):each(function(obj)
			if obj:id() == repNr then 
				fielDRepId = obj
				return
			end end)
		if focus == "" then fielDRepId:find("/tag[tagKey='" .. tagType .. "']"):delete()
		elseif fielDRepId:find("/tag[tagKey='" .. tagType .. "']"):is_empty() then 
		    lQuery.create("AA#Tag", {tagKey=tagType, tagValue = focus}):link("choiceItem", fielDRepId)
		else
		    fielDRepId:find("/tag[tagKey='" .. tagType .. "']"):attr("tagValue", focus)
		end
	end
end

--izveidot/maina/dzes namespace deklaraciju
function profilePrefix()
	local id = lQuery("D#Tree[id = 'treeProfile']/treeNode"):attr("id")
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	id = string.sub(id, 1, n-1)--id
	
	local prof = lQuery("AA#Profile"):filter(function(pr)
		return pr:id()==tonumber(id)
	end)
	local Sem
	local focus = lQuery("D#Event/edited")
	lQuery("AA#Tag"):each(function(objS)
		if objS:id() == tonumber(focus:attr("id")) then 
			Sem = objS
			Sem:attr("tagValue", focus:attr("text"))
			return
		end end)
	local focusID = lQuery("D#Event/source"):attr("id")
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	if lQuery("D#Event/inserted"):size() ~= 0 then
		local multiLineId = lQuery("D#Event/inserted"):find("/multiLineTextBox"):attr("id")
		local s = lQuery.create("AA#Tag", {tagKey = "owl_Import_Prefixes", tagValue = lQuery("D#Event/inserted"):attr("text")}):link("profile", prof)
		lQuery("D#Event/inserted"):attr("id", s:id())
	end
	if lQuery("D#Event/deleted"):size() ~= 0 then
		local focusD = lQuery("D#Event/deleted")
		local SS
		lQuery("AA#Tag"):each(function(objS)
			if objS:id() == tonumber(focusD:attr("id")) then 
				SS = objS
				return
		end end)
	end
		lQuery("AA#Tag"):filter(
		function(obj)
			return lQuery(obj):attr("tagValue") == ""
		end):delete()
end

--maina vienuma semantiku
function changeEventSemanticsItem()
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#ChoiceItem"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)

	local Sem
	local focus = lQuery("D#Event/edited")
	lQuery("AA#Tag"):each(function(objS)
		if objS:id() == tonumber(focus:attr("id")) then 
			Sem = objS
			Sem:attr("tagValue", focus:attr("text"))
			return
		end end)
	local focusID = lQuery("D#Event/source"):attr("id")
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	if lQuery("D#Event/inserted"):size() ~= 0 then
		local multiLineId = lQuery("D#Event/inserted"):find("/multiLineTextBox"):attr("id")
		local key = lQuery("AA#TagType"):filter(function(obj)
			return obj:id() == tonumber(multiLineId)
		end):attr("key")
		local s = lQuery.create("AA#Tag", {tagKey = key, tagValue = lQuery("D#Event/inserted"):attr("text")}):link("choiceItem", fielDRepId)
		lQuery("D#Event/inserted"):attr("id", s:id())
	end
	if lQuery("D#Event/deleted"):size() ~= 0 then
		local focusD = lQuery("D#Event/deleted")
		local SS
		lQuery("AA#Tag"):each(function(objS)
			if objS:id() == tonumber(focusD:attr("id")) then 
				SS = objS
				return
		end end)
		lQuery(SS):delete()
	end
		lQuery("AA#Tag"):filter(
		function(obj)
			return lQuery(obj):attr("tagValue") == ""
		end):delete()
end

--maina lauka semantiku
function changeEventSemantics()
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	
	local Sem
	local focus = lQuery("D#Event/edited")
		lQuery("AA#Tag"):each(function(objS)
			if objS:id() == tonumber(focus:attr("id")) then 
				Sem = objS
				Sem:attr("tagValue", focus:attr("text"))
				return
			end end)
	local focusID = lQuery("D#Event/source"):attr("id")
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	if lQuery("D#Event/inserted"):size() ~= 0 then
		--atrast MultyLineTextBox id
		local multiLineId = lQuery("D#Event/inserted"):find("/multiLineTextBox"):attr("id")
		local key = lQuery("AA#TagType"):filter(function(obj)
		    return obj:id() == tonumber(multiLineId)
		end):attr("key")
		local s = lQuery.create("AA#Tag", {tagKey = key, tagValue = lQuery("D#Event/inserted"):attr("text")}):link("field", fielDRepId)
		local f = lQuery("D#Event/inserted"):attr("id", s:id())
	end
	if lQuery("D#Event/deleted"):size() ~= 0 then
		local focusD = lQuery("D#Event/deleted")
		local SS
		lQuery("AA#Tag"):each(function(objS)
			if objS:id() == tonumber(focusD:attr("id")) then 
				SS = objS
				return
		end end)
		lQuery(SS):delete()
	end
	lQuery("AA#Tag"):filter(
		function(obj)
			return lQuery(obj):attr("tagValue") == ""
		end):delete()
end

--Row Type izmainas
function changeEventFieldType()	
--atrast pasreizeja tipu
--kads RowType ir piesaistits laukam

	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	--local oldRowType = lQuery(fielDRepId):find("/fieldType")
	local oldRowType = lQuery(fielDRepId)
--atrast jauno tipu
--fokusa lements
	--local text = lQuery("D#Event/source/selected"):attr("value")
	local text = lQuery("D#Event/source"):attr("text")
	local typeName = lQuery(oldRowType):attr("fieldType")

	-- if typeName ~= "ComboBox" and typeName ~= "ListBox"  and typeName ~= "CheckBox"  and typeName ~= "" and typeName ~= "InputField" and typeName ~= "TextArea"
	if (typeName == "InputField+Button" or typeName == "TextArea+Button")
		and text ~= "InputField+Button" and text ~= "TextArea+Button" then
			--forma: Vai izdzest apaks laukus
			if lQuery(fielDRepId):find("/subField"):is_not_empty() then
				--forma vai izdzest itemus
				--askDeleteAllItems(fielDRepId)
				askDleteAllSubFields(fielDRepId)
			else
				deleteAskDleteAllSubFields("noForm")
			end

	-- elseif typeName ~= "InputField" and typeName ~= "TextArea" and typeName ~= "InputField+Button" and typeName ~= "TextArea+Button" and  typeName ~= "" 
	elseif (typeName == "ComboBox" or typeName == "ListBox" or typeName == "CheckBox")
		and text ~= "ComboBox" and text ~= "ListBox" and  text ~= "CheckBox" then
			--ja ir apakslauki
			if lQuery(fielDRepId):find("/choiceItem"):is_not_empty() then
				--forma vai izdzest itemus
				askDeleteAllItems(fielDRepId)
			else
				deleteItem()
			end
			
	elseif (typeName == "ComboBox" and text == "CheckBox") or (typeName == "ListBox" and text == "CheckBox") then
			--ja ir apakslauki
			if lQuery(fielDRepId):find("/choiceItem"):is_not_empty() then
				--forma vai izdzest itemus
				askDeleteAllItems(fielDRepId)
			else
				deleteItem()
			end
			--izveidot true un false
			
	elseif typeName == text then 

	else
		--forma nav vjadziga
		--parlikt saiti
		-- lQuery("AA#RowType[typeName = '" .. typeName .. "']"):remove_link("field", fielDRepId)--aizvacam linku
		-- lQuery("AA#RowType[typeName = '" .. text .. "']"):link("field", fielDRepId)--izveidojam linku
		fielDRepId:attr("fieldType", text)
		if text == "CheckBox" then
				local t = lQuery.create("AA#ChoiceItem", {caption = "true"}):link("field", fielDRepId)
				--lQuery.create("AA#Tag", {tagKey = 'owl_Fields_ImportSpec', tagValue = ''}):link("choiceItem", t)--veidojam tag prieks importa 
				local ff = lQuery.create("AA#ChoiceItem", {caption = "false"}):link("field", fielDRepId)
				--lQuery.create("AA#Tag", {tagKey = 'owl_Fields_ImportSpec', tagValue = ''}):link("choiceItem", ff)--veidojam tag prieks importa 
			
				local n = lQuery.create("D#TreeNode", {text = "I:true", id = lQuery(t):id() .. " AA#ChoiceItem"}):link("parentNode", lQuery("D#Tree[id = 'treeProfile']/selected"))
				local nn = lQuery.create("D#TreeNode", {text = "I:false", id = lQuery(ff):id() .. " AA#ChoiceItem"}):link("parentNode", lQuery("D#Tree[id = 'treeProfile']/selected"))
				lQuery("D#Tree[id='treeProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
		end
		
		local values = {"InputField", "InputField+Button", "TextArea", "TextArea+Button", "CheckBox", "ComboBox", "ListBox", ""}
		
		local fieldTypeTable = {
			["InputField"]=1,
			["InputField+Button"]=1,
			["TextArea"]=1,
			["TextArea+Button"]=1,
			["CheckBox"]=1,
			["ComboBox"]=1,
			["ListBox"]=1,
			[""]=1,
		}
		local FieldTypeValue = lQuery("D#Event/source"):attr("text")
		if fieldTypeTable[FieldTypeValue]~=nil then
			changeButtons(FieldTypeValue)
			-- lQuery("D#Form[id='Profile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
		end
	end
end

--noskaidro vai jadzes visi lo lauka atkarigi elementi(field-dzesamais lauks)
function askDleteAllSubFields(field)

	local valuesF = lQuery(field):find("/subField"):map(
	  function(obj, i)
		return {lQuery(obj):attr("name"), lQuery(obj):id()}
	  end)

	local close_button = lQuery.create("D#Button", {
    caption = "No"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.closeAskDleteAllSubFields()")
  })
	
	local yesItem = lQuery.create("D#Button", {
    caption = "Yes"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.deleteAskDleteAllSubFields()")
  })
	
  local form = lQuery.create("D#Form", {
    id = "aksDeleteAllSubField"
    ,caption = "Are you sure you want to delete..."
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.Profile.closeAskDleteAllSubFields()")
	,component = {
		lQuery.create("D#HorizontalBox", {
			id = "HorFormField"
			,component = { 
				lQuery.create("D#VerticalBox", {
					id = "VerticalBoxField"
					,component = {
						lQuery.create("D#Label", {caption = "Are you sure you want to delete all dependent elements?"})
						,lQuery.map(valuesF, function(mode_value) 
						return lQuery.create("D#Label", {
							caption = mode_value[1]
							}) 
						end)
					}
				})
			}
		})
      ,lQuery.create("D#HorizontalBox", {
		id = "closeFormField"
        ,component = {
		  lQuery.create("D#HorizontalBox", {
			id = "closeButtonField"
			,component = {
				yesItem
				,close_button}})
		  }
      })
    }
  })
  dialog_utilities.show_form(form)
end

--noskaidro vai dzest lauka itemus (field-dzesamais lauks)
function askDeleteAllItems(field)
--atrast lauku
--atrast lauka itemus
	local values = lQuery(field):find("/choiceItem"):map(
	  function(obj, i)
		return {lQuery(obj):attr("caption"), lQuery(obj):id()}
	end)
	
	local close_button = lQuery.create("D#Button", {
    caption = "No"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.closeAskDeleteAllItems()")
  })
	
	local yesItem = lQuery.create("D#Button", {
    caption = "Yes"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.Profile.deleteItem()")
  })
	
  local form = lQuery.create("D#Form", {
    id = "askDeleteAllItems"
    ,caption = "Delete Items?"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.Profile.closeAskDeleteAllItems()")
	,component = {
		lQuery.create("D#HorizontalBox", {
			id = "HorFormAskDeleteAllItems"
			,component = { 
				lQuery.create("D#VerticalBox", {
					id = "VerticalBoxAskDeleteAllItems"
					,component = {
						lQuery.create("D#Label", {caption = "Delete items:"})
						,lQuery.map(values, function(mode_value) 
						return lQuery.create("D#Label", {
							caption = mode_value[1]
							,id = mode_value[2]
							}) 
						end)
					}
				})
			}
		})
	  ,lQuery.create("D#HorizontalBox", {
		component = {
		  lQuery.create("D#HorizontalBox", {
			component = {
				yesItem
				,close_button}})
		  }
      })
	  
    }
  })
  dialog_utilities.show_form(form)
end

--noskaidro vai dzest lauka apakslaukus
function deleteAskDleteAllSubFields(mark)
--atrast lauku
	local text = lQuery("D#ComboBox[id = 'fieldType']"):attr("text")
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	--izdzest no koka
	lQuery("D#Tree[id = 'treeProfile']/selected"):find("/childNode"):delete()
	lQuery("D#Tree[id='treeProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	

	--local oldRowType = lQuery(fielDRepId):find("/fieldType")
	local oldRowType = lQuery(fielDRepId)
	local typeName = lQuery(oldRowType):attr("fieldType")
	fielDRepId:attr("fieldType", text)
	-- lQuery("AA#RowType[typeName = '" .. typeName .. "']"):remove_link("field", fielDRepId)--aizvacam linku
	-- lQuery("AA#RowType[typeName = '" .. text .. "']"):link("field", fielDRepId)--izveidojam linku
	--atrast visus arakslaukus
	local a = lQuery(fielDRepId):find("/subField"):each(function(obj)
		--katram rekursivi izdezest visus atkarigos elementus
		allSubFields(obj)
	end)

	if text == "CheckBox" then
		local t = lQuery.create("AA#ChoiceItem", {caption = "true"}):link("field", fielDRepId)
		local ff = lQuery.create("AA#ChoiceItem", {caption = "false"}):link("field", fielDRepId)
		
		local n = lQuery.create("D#TreeNode", {text = "I:true", id = lQuery(t):id() .. " AA#ChoiceItem"}):link("parentNode", lQuery("D#Tree[id = 'treeProfile']/selected"))
		local nn = lQuery.create("D#TreeNode", {text = "I:false", id = lQuery(ff):id() .. " AA#ChoiceItem"}):link("parentNode", lQuery("D#Tree[id = 'treeProfile']/selected"))
		lQuery("D#Tree[id='treeProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	end
	if mark==nil then
		lQuery("D#Event"):delete()
		utilities.close_form("aksDeleteAllSubField")
	end
	changeButtons(text)
	-- lQuery("D#Form[id='Profile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

--izdzes itemu
function deleteItem()
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	-- local oldRowType = lQuery(fielDRepId):find("/fieldType")
	-- local typeName = lQuery(oldRowType):attr("typeName")
	-- lQuery("AA#RowType[typeName = '" .. typeName .. "']"):remove_link("field", fielDRepId)--aizvacam linku
	
	
	lQuery(fielDRepId):find("/choiceItem"):each(function(objI)
		--izdzest atkaribas, semantiku, stilus
		lQuery(objI):find("/dependency"):delete()
		lQuery(objI):find("/tag"):delete()
		lQuery(objI):find("/styleSetting"):delete()
		
		lQuery(objI):delete()
	end)
	lQuery("D#Tree[id = 'treeProfile']/selected"):find("/childNode"):delete()
	lQuery("D#Tree[id='treeProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	
	local text = lQuery("D#ComboBox[id = 'fieldType']"):attr("text")
	
	if text == "CheckBox" then
			local t = lQuery.create("AA#ChoiceItem", {caption = "true"}):link("field", fielDRepId)
			local ff = lQuery.create("AA#ChoiceItem", {caption = "false"}):link("field", fielDRepId)

			local n = lQuery.create("D#TreeNode", {text = "I:true", id = lQuery(t):id() .. " AA#ChoiceItem"}):link("parentNode", lQuery("D#Tree[id = 'treeProfile']/selected"))
			local nn = lQuery.create("D#TreeNode", {text = "I:false", id = lQuery(ff):id() .. " AA#ChoiceItem"}):link("parentNode", lQuery("D#Tree[id = 'treeProfile']/selected"))
			lQuery("D#Tree[id='treeProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	end
	lQuery("D#Event"):delete()
    utilities.close_form("askDeleteAllItems")
	
--atrast jauno tipu
--fokusa lements
	fielDRepId:attr("fieldType", text)
	--lQuery("AA#RowType[typeName = '" .. text .. "']"):link("field", fielDRepId)--izveidojam linku
	
	changeButtons(text)
	-- lQuery("D#Form[id='Profile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

--Field izmainas
function changeEvent()
	local focus = lQuery("D#Event/source"):attr("text")

	local focusID = lQuery("D#Event/source"):attr("id")

	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	
	fielDRepId:attr(focusID, focus)--ierakstam jauno vertibu
	if focusID == "name" then
		lQuery("D#Tree[id = 'treeProfile']/selected"):attr("text", "F:" .. focus)
		lQuery("D#Tree[id='treeProfile']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	end
	if focusID == "isStereotypeField" or focusID == "isExistingField" then fielDRepId:attr(focusID, lQuery("D#Event/source"):attr("checked")) end
	if focusID == "isExistingField" then
	    local checked = lQuery("D#Event/source"):attr("checked")
		local tabCont = lQuery("D#VerticalBox[id = 'property']/component")--tabConteiner
		local tabs = lQuery(tabCont):find("/component")--tabi
		lQuery(tabs):each(function(tab)
			lQuery(tab):find("/component"):delete()
		end)
		lQuery(tabs):delete()
		lQuery(tabCont):delete()
	    if checked == "true" then
			openExistingFieldProperty(repNr)
		else
			openSuperFieldProperty(repNr)
		end
	end
end

--atlasa "AA#RowType" intances
function createItemsForFieldType()
	local values = {"InputField", "InputField+Button", "TextArea", "TextArea+Button", "CheckBox", "ComboBox", "ListBox", ""}
	-- local values = lQuery("AA#RowType"):map(
	  -- function(obj)
		-- return lQuery(obj):attr("typeName")
	  -- end)
	return lQuery.map(values, function(mode_value) return lQuery.create("D#Item", {value = mode_value}) end)
end

--izveido pofila koka elementus(profId-profila identifikators)
function createTreeChild(profId)
	local values = lQuery("AA#ContextType"):map(
	  function(obj, i)
		if lQuery(obj):attr("mode") ~="Element" then
			return {lQuery(obj):attr("type"), lQuery(obj):attr("nr"), lQuery(obj):id(), lQuery(obj):attr("elTypeName"), lQuery(obj):attr("mode"), lQuery(obj):attr("path")}
		end
	  end)
	
	table.sort(values, function(x,y) return tonumber(x[2]) < tonumber(y[2]) end)
	
	for i,mode_value in pairs(values) do
		if mode_value[6] == "" then
			if lQuery("D#Tree[id = 'treeProfile']/treeNode/childNode[text='T: " .. mode_value[4] .. "']"):is_empty()
			and lQuery("D#Tree[id = 'treeProfile']/treeNode/childNode[text='" .. mode_value[4] .. "']"):is_empty() then
				lQuery.create("D#TreeNode", {
					text = mode_value[4]
					,id = " AA#Mid"
					,childNode = lQuery.create("D#TreeNode", {
						text = "T: " ..  mode_value[1]
						,id = mode_value[3] .. " AA#ContextType"
						,childNode = getField(mode_value[1], mode_value[3], profId, mode_value[4])
						,expanded = true
					})
					,expanded = true
				}):link("parentNode", lQuery("D#Tree[id = 'treeProfile']/treeNode"))
			elseif lQuery("D#Tree[id = 'treeProfile']/treeNode/childNode[text='T: " .. mode_value[4] .. "']"):is_not_empty() then
				if lQuery("D#Tree[id = 'treeProfile']/treeNode/childNode[text='T: " .. mode_value[4] .. "']/childNode[text='" .. mode_value[1] .. "']"):is_empty() then
					lQuery.create("D#TreeNode", {
						text = "T: " ..  mode_value[1]
						,id = mode_value[3] .. " AA#ContextType"
						,childNode = getField(mode_value[1], mode_value[3], profId, mode_value[4])
						,expanded = true
					}):link("parentNode", lQuery("D#Tree[id = 'treeProfile']/treeNode/childNode[text='T: " .. mode_value[4] .. "']"))
				else
					local node = lQuery("D#Tree[id = 'treeProfile']/treeNode/childNode[text='T: " .. mode_value[4] .. "']/childNode[text='" .. mode_value[1] .. "']")
					node:attr("text", "T: " .. mode_value[1])
					node:attr("id", mode_value[3] .. " AA#ContextType")
					node:attr("expanded",true)
					node:attr("childNode", getField(mode_value[1], mode_value[3], profId, mode_value[4]))
				end
			elseif lQuery("D#Tree[id = 'treeProfile']/treeNode/childNode[text='" .. mode_value[4] .. "']"):is_not_empty() then
				if lQuery("D#Tree[id = 'treeProfile']/treeNode/childNode[text='" .. mode_value[4] .. "']/childNode[text='" .. mode_value[1] .. "']"):is_empty() then
					lQuery.create("D#TreeNode", {
						text = "T: " ..  mode_value[1]
						,id = mode_value[3] .. " AA#ContextType"
						,childNode = getField(mode_value[1], mode_value[3], profId, mode_value[4])
						,expanded = true
					}):link("parentNode", lQuery("D#Tree[id = 'treeProfile']/treeNode/childNode[text='" .. mode_value[4] .. "']"))
				else
					local node = lQuery("D#Tree[id = 'treeProfile']/treeNode/childNode[text='" .. mode_value[4] .. "']/childNode[text='" .. mode_value[1] .. "']")
					node:attr("text", "T: " .. mode_value[1])
					node:attr("id", mode_value[3] .. " AA#ContextType")
					node:attr("expanded",true)
					node:attr("childNode", getField(mode_value[1], mode_value[3], profId, mode_value[4]))
				end
			end
		else
			--ja nav elementa
			if lQuery("D#Tree[id = 'treeProfile']/treeNode/childNode[text='T: " .. mode_value[4] .. "']"):is_empty()
			and lQuery("D#Tree[id = 'treeProfile']/treeNode/childNode[text='" .. mode_value[4] .. "']"):is_empty() then
				lQuery.create("D#TreeNode", {
					text = mode_value[4]
					,id = " AA#Mid"
					,expanded = true
				}):link("parentNode", lQuery("D#Tree[id = 'treeProfile']/treeNode"))
			end
			--atrast elementu
			local elemTypeTreeNode = lQuery("D#Tree[id = 'treeProfile']/treeNode/childNode[text='T: " .. mode_value[4] .. "']")
			if elemTypeTreeNode:is_empty() then 
				elemTypeTreeNode = lQuery("D#Tree[id = 'treeProfile']/treeNode/childNode[text='" .. mode_value[4] .. "']")
			end
			--vajadziga celu tabula
			local path = mode_value[6]
			local pathTable = styleMechanism.split(path, "/")
			
			for i=1,#pathTable,1 do 
				if pathTable[i] ~= "" then 
					local childNode = elemTypeTreeNode:find("/childNode[text='T: " .. pathTable[i] .. "']")
					if childNode:is_empty() then childNode = elemTypeTreeNode:find("/childNode[text='" .. pathTable[i] .. "']") end
					if childNode:is_empty() then
						childNode = lQuery.create("D#TreeNode", {
							text = pathTable[i]
							,id = " AA#Mid"
							,expanded = true
						}):link("parentNode", elemTypeTreeNode)
					end
					elemTypeTreeNode = childNode
				end
			end
			if elemTypeTreeNode:find("/childNode[text='" .. mode_value[1] .. "']"):is_empty() then
				lQuery.create("D#TreeNode", {
					text = "T: " .. mode_value[1]
					,id = mode_value[3] .. " AA#ContextType"
					,expanded = true
					,childNode = getField(mode_value[1], mode_value[3], profId, mode_value[4])
				}):link("parentNode", elemTypeTreeNode)
			else
				local node = elemTypeTreeNode:find("/childNode[text='" .. mode_value[1] .. "']")
				node:attr("text", "T: " .. mode_value[1])
				node:attr("id", mode_value[3] .. " AA#ContextType")
				node:attr("expanded",true)
			end
		end
	end	
end

--atlasam pirmalimena elementus (ContextType) (profId-profila identifikators)
function create_items(profId)
	--atlacam visus AA#ContextType instances
	local values = lQuery("AA#ContextType"):map(
	  function(obj, i)
		return {lQuery(obj):attr("type"), lQuery(obj):attr("nr"), lQuery(obj):id(), lQuery(obj):attr("elTypeName"), lQuery(obj):attr("mode")}
	  end)
	
	--sakartojam tabulu pec Number
	table.sort(values, function(x,y) return tonumber(x[2]) < tonumber(y[2]) end)
	
	return lQuery.map(values, function(mode_value) 
		if mode_value[5] == "Element" then
			return lQuery.create("D#TreeNode", {
				text = "T: " ..  mode_value[1]
				,id = mode_value[3] .. " AA#ContextType"
				,childNode = getField(mode_value[1], mode_value[3], profId, mode_value[4])
				,expanded = true
			}) 
		end
	end)
end

--atlasam pirma limena fieldus
function getField(value, fieldId, profId, elTypeName)
	profId = tonumber(profId)
	local fielDRepId -- vajadziga AA#Profile instance
	local field = lQuery("AA#Profile"):each(function(obj)
		if obj:id() == profId then 
			fielDRepId = obj
			return
		end end)

	local values = lQuery(fielDRepId):find("/field:has(/context[type = '" .. value .. "'])")
	values = values:filter(
		function(obj)
			return lQuery(obj):find("/context"):attr("elTypeName") == elTypeName
		end)
	values = values:map(
	  function(obj, i)
		return {lQuery(obj):attr("name"), lQuery(obj):id()}
	  end)
	return lQuery.map(values, function(mode_value) 
		return lQuery.create("D#TreeNode", {
			text = "F:" .. mode_value[1]
			,id = mode_value[2] .. " AA#Field"
			,childNode = getSubElement(mode_value[1], mode_value[2])
			,expanded = true
		}) 
	end)
end

--atlasa apaks elementus
function getSubElement(value, valueID)
	local r1 = getItem(valueID)
	local r2 = getSubField(value, valueID)
	return lQuery.merge(r1, r2)
end

--atlasa itemus
function getItem(value)
	local values = lQuery("AA#ChoiceItem"):map(
	  function(obj, i)
		if lQuery(obj):find("/field"):id() == value then
			return {lQuery(obj):attr("caption"), lQuery(obj):id()}
		end
	  end)
	  
	local r = lQuery.map(values, function(mode_value) 
		return lQuery.create("D#TreeNode", {
			text = "I:" .. mode_value[1]
			,id = mode_value[2] .. " AA#ChoiceItem"
			,expanded = true
		}) 
	end)
	return r
end

--atlasa apaks laukus
function getSubField(value, valueID)
	local valuesID = lQuery("AA#Field"):map(
	  function(obj, i)
		if lQuery(obj):find("/superField"):id() == valueID then
			return {lQuery(obj):attr("name"), lQuery(obj):id()}
		end
	  end)
	
	local r2 = lQuery.map(valuesID, function(mode_value) 
		return lQuery.create("D#TreeNode", {
			text = "F:" .. mode_value[1]
			,childNode = getSubElement(mode_value[1], mode_value[2])
			,id = mode_value[2] .. " SubAA#Field"
			,expanded = true
		}) 
	end)
	return r2
end

function close()
  local profileName = lQuery("D#Tree[id = 'treeProfile']/treeNode"):attr("text")
  lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
	utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
  end)
  syncProfile.syncProfile(profileName)
  styleMechanism.syncExtensionViews()
  lQuery("D#Event"):delete()
  utilities.close_form("Profile")
end

function closeDeleteItem()
  lQuery("D#Event"):delete()
  utilities.close_form("deleteItem")
end

function closeAskDeleteAllItems()
    lQuery("D#Event"):delete()
    utilities.close_form("askDeleteAllItems")
 
    local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)

	--local oldRowType = lQuery(fielDRepId):find("/fieldType")
	local oldRowType = lQuery(fielDRepId)
	local typeName = lQuery(oldRowType):attr("fieldType")
  
	lQuery("D#ComboBox[id = 'fieldType']"):attr("text", typeName)
    local selItem = lQuery("D#ComboBox[id = 'fieldType']/item[value='" .. typeName .. "']")
    lQuery("D#ComboBox[id = 'fieldType']"):link("selected", selItem)

    lQuery("D#ComboBox[id = 'fieldType']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

function closeDeletedField()
  lQuery("D#Event"):delete()
  utilities.close_form("deletedField")
end

function closeAksDeleteOneItem()
  lQuery("D#Event"):delete()
  utilities.close_form("aksDeleteOneItem")
end

function closeAksDeleteOneField()
  lQuery("D#Event"):delete()
  utilities.close_form("aksDeleteOneField")
end

function closeAskDleteAllSubFields()
	lQuery("D#Event"):delete()
    utilities.close_form("aksDeleteAllSubField")
  
	local id = lQuery("D#Tree[id = 'treeProfile']/selected"):attr("id")
	local n = string.find(id, " ")
	local types = string.sub(id, n+1)--tips
	local repNr = string.sub(id, 1, n-1)--id
	repNr = tonumber(repNr)
	
	local fielDRepId -- vajadziga AA#Field instance
	local field = lQuery("AA#Field"):each(function(obj)
		if obj:id() == repNr then 
			fielDRepId = obj
			return
		end end)
	--local oldRowType = lQuery(fielDRepId):find("/fieldType")
	local oldRowType = lQuery(fielDRepId)
	local typeName = lQuery(oldRowType):attr("fieldType")

    lQuery("D#ComboBox[id = 'fieldType']"):attr("text", typeName)
    local selItem = lQuery("D#ComboBox[id = 'fieldType']/item[value='" .. typeName .. "']")
    lQuery("D#ComboBox[id = 'fieldType']"):link("selected", selItem)

    lQuery("D#ComboBox[id = 'fieldType']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

function closeGenerateElemTypeTree()
  lQuery("D#Event"):delete()
  utilities.close_form("generateElemTypeTree")
end

function closeDeleteOneDependency()
  lQuery("D#Event"):delete()
  utilities.close_form("deleteOneDependency")
end

function closeTree()
 lQuery("D#Event"):delete()
  utilities.close_form("CompartmentTree")
end