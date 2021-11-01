module(..., package.seeall)

require("lua_tda")
require "lpeg"
require "core"
require "dialog_utilities"
styleMechanism = require "OWLGrEd_UserFields.styleMechanism"
extensionCreate = require "OWLGrEd_UserFields.extensionCreate"

--atver konfiguraciju konfiguracijas formu
function configurationProperty()

  local close_button = lQuery.create("D#Button", {
    caption = "Close"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.configuration.close()")
  })

  local form = lQuery.create("D#Form", {
    id = "Configuration"
    ,caption = "Configuration"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.configuration.close()")
	,component = {
		lQuery.create("D#VerticalBox", {
			component = { 
				lQuery.create("D#Label", {caption="The configuration determines the editor structure"})
				,lQuery.create("D#Label", {caption="points, where new user fields can be added"})
				,lQuery.create("D#Label", {caption="(the context types for user fields)."})
			}
		})
		,lQuery.create("D#HorizontalBox", {
			component = { 
				lQuery.create("D#VerticalBox", {
					id = "VerFormConTree"
					,component = { 
						lQuery.create("D#Tree", {
							id = "treeConfiguration",maximumWidth = 200,minimumWidth = 200,maximumHeight = 300,minimumHeight = 300
							,treeNode = lQuery.create("D#TreeNode", {
								text = "ContextTypes"
								,childNode = createNode()
								,expanded = true
							})
						})
					}
				})
		
				,lQuery.create("D#VerticalBox", {
					id = "VerFormCon"
					,component = { 
						lQuery.create("D#Button", {
							caption = "Import (extend) Configuration"
							,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.configuration.loadConfiguration()")
						})
						,lQuery.create("D#Button", {
							caption = "Export full Configuration"
							,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.configuration.loadSaveConfiguration()")
						})
						,lQuery.create("D#Button", {
							caption = "Add ContextType"
							,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.configuration.addContextType()")
						})
						,lQuery.create("D#Button", {
							caption = "Remove ContextType"
							,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.configuration.deleteContextType()")
						})
						,lQuery.create("D#Button", {
							caption = "Manage TagType"
							,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.configuration.manageTagType()")
						})
					}
				})
		}})
		
      ,lQuery.create("D#HorizontalBox", {
        horizontalAlignment = 1
		,id = "closeForm"
        ,component = {
		  lQuery.create("D#VerticalBox", {id = "buttonsConf"}) 
		  ,lQuery.create("D#VerticalBox", {
			id = "closeButton"
			,horizontalAlignment = 1
			,component = {close_button}})
		  }
      })
    }
  })
	createChildNode("treeConfiguration")--papildina koku ar AA#ContextType instancem
	dialog_utilities.show_form(form)
end

--atver lodu, kas jauta vai configuaciju ir jaielasa automatiski
function loadSaveConfiguration()
	local close_button = lQuery.create("D#Button", {
    caption = "No"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.configuration.noLoadForm()")
  })
  
	local create_button = lQuery.create("D#Button", {
    caption = "Yes"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.configuration.yesLoadForm(()")
  })
  
  local form = lQuery.create("D#Form", {
    id = "loadConfigurationAuto"
    ,caption = "Load configuration"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = create_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.configuration.noLoadForm()")
	,component = {
		lQuery.create("D#VerticalBox",{
			component = {
				lQuery.create("D#Label", {caption="Do you want to load this configuration automatically?"})
			}
		})
		,lQuery.create("D#HorizontalBox", {
		id = "closeButton"
		,component = {create_button, close_button}})
    }
  })
  dialog_utilities.show_form(form)
end

function noLoadForm()
	lQuery("D#Event"):delete()
	utilities.close_form("loadConfigurationAuto")
	saveConfiguration()
end

function yesLoadForm()
	lQuery("D#Event"):delete()
	utilities.close_form("loadConfigurationAuto")
	local objects_to_export = lQuery("AA#Configuration")
	local export_spec = {
			include = {
			   ["AA#Configuration"] = {
					context = serialize.export_as_table
					,tagType = serialize.export_as_table
			   }
			   ,["AA#ContextType"] = {}
			   ,["AA#TagType"] = {}
			 },
			border = {}
		}
	local deteTime = os.date("%m_%d_%Y_%H_%M_%S")
	caption = "select folder"
	
	local path
	if tda.isWeb then
		path = tda.GetProjectPath() .. "/Plugins/OWLGrEd_UserFields/user/AutoLoadConfiguration/configuration"-- ???
	else
		path = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\user\\AutoLoadConfiguration\\configuration"
	end
	
	local file_path = path  .. deteTime .. ".txt"

	serialize.save_to_file(objects_to_export, export_spec, file_path)
end

--ielade konfiguraciju no teksta faila
function loadConfiguration()
	local caption = "Select text file"
	local filter = "text file(*.txt)"
	
	local start_folder
	if tda.isWeb then
		start_folder = "" -- relative to the user's home directory (currently, ignored)
	else
		start_folder = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\examples\\"
	end
	
	local start_file = ""
	local save = false
	local file_path = tda.BrowseForFile(caption, filter, start_folder, start_file, save)
	if file_path ~= "" then

		serialize.import_from_file(file_path)
		
		--izmetam dublikatus, ja tadi ir
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
		
		--izmest dublikatus
		  --atrast visus AA#ContextType
		  --iziet cauri visiem. Ja ir vairki ar viendu id, tad izdzest to, kam nav AA#Field
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
		
		--ievietojam ieladetos AA#ContextType kokaa
		lQuery("D#Tree[id = treeConfiguration]"):find("/treeNode"):delete()
		lQuery.create("D#TreeNode", {
			text = "ContextTypes"
			,childNode = createNode()
			,expanded = true
		}):link("tree", lQuery("D#Tree[id = treeConfiguration]"))
		createChildNode("treeConfiguration")
		lQuery("D#Tree[id = treeConfiguration]"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	
		
	else --print("Import was canceled")
	end
end

--saglaba konfiguraciju taksta faila
function saveConfiguration()
		local objects_to_export = lQuery("AA#Configuration")
		local export_spec = {
			include = {
			   ["AA#Configuration"] = {
					context = serialize.export_as_table
					,tagType = serialize.export_as_table
			   }
			   ,["AA#ContextType"] = {}
			   ,["AA#TagType"] = {}
			 },
			border = {}
		}
		local deteTime = os.date("%m_%d_%Y_%H_%M_%S")
		caption = "select folder"
		
		local start_folder
		if tda.isWeb then
			start_folder = "" -- relative to the user's home directory (currently, ignored)
		else
			start_folder = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\user\\"
		end
				
		local folder = tda.BrowseForFolder(caption, start_folder)
		if folder ~= "" then
			local file_path
			if tda.isWeb then
				file_path = folder .. "/configuration"  .. deteTime .. ".txt"
			else
				file_path = folder .. "\\configuration"  .. deteTime .. ".txt"
			end
			serialize.save_to_file(objects_to_export, export_spec, file_path)
		else --print("Export was canceled") 
		end
end

--atver formua AA#TagType konfiguracijai
function manageTagType()
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.configuration.closeTagType()")
  })

  local form = lQuery.create("D#Form", {
    id = "TagType"
    ,caption = "TagType"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.configuration.closeTagType()")
	,component = {
		lQuery.create("D#HorizontalBox", {
			component = { 
				lQuery.create("D#VerticalBox", {
					id = "VerFormtreeTagType"
					,component = { 
						lQuery.create("D#ListBox", {
							id = "treeTagType",maximumWidth = 300,minimumWidth = 300,maximumHeight = 300,minimumHeight = 300
							,item = collectTagType()
						})
					}
				})
				,lQuery.create("D#VerticalBox", {
					id = "VerFormCon"
					,component = { 
						lQuery.create("D#Button", {
							caption = "Add TagType"
							,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.configuration.addTagType()")
						})
						,lQuery.create("D#Button", {
							caption = "Remove TagType"
							,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.configuration.removeTagType()")
						})
					}
				})
		}})
      ,lQuery.create("D#HorizontalBox", {
        horizontalAlignment = 1
		,id = "closeForm"
        ,component = {
		  lQuery.create("D#VerticalBox", {id = "buttonsTag"}) 
		  ,lQuery.create("D#VerticalBox", {
			id = "closeButton"
			,horizontalAlignment = 1
			,component = {close_button}})
		  }
      })
    }
  })
  dialog_utilities.show_form(form)
end

--izdzes TagType
function removeTagType()
	local TagType = lQuery("D#ListBox[id='treeTagType']/selected")
	if TagType:is_not_empty() then
		local id = TagType:attr("id")
		lQuery("AA#TagType"):filter(function(obj)
			return obj:id() == tonumber(id)
		end):delete()
		--atjaunot listBox
		refreshListBox()
	end
end

--savac visus AA#TagType
function collectTagType()
	local values = lQuery("AA#TagType:has(/configuration)"):map(
	  function(obj)
		return {"Key-" .. lQuery(obj):attr("key") .. ", Notation-" .. lQuery(obj):attr("notation"), obj:id()}
	  end)  
	
	return lQuery.map(values, function(profile) 
		return lQuery.create("D#Item", {
			value = profile[1]
			,id = profile[2]
		}) 
	end)
end

--atver formu AA#TagType instancies pievienosanai
function addTagType()
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.configuration.closeAddTagType()")
  })
	local add_button = lQuery.create("D#Button", {
    caption = "Add"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.configuration.createAddTagType()")
  })
  local form = lQuery.create("D#Form", {
    id = "AddTagType"
    ,caption = "AddTagType"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = add_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.configuration.closeAddTagType()")
	,component = {
		lQuery.create("D#HorizontalBox", {
			component = { 
				lQuery.create("D#Row", {
					component = {
						lQuery.create("D#Label", {caption = "Key"})
						,lQuery.create("D#TextBox", {id = "key"})
					}
				})
				,lQuery.create("D#Row", {
					component = {
						lQuery.create("D#Label", {caption = "Notation"})
						,lQuery.create("D#TextBox", {id = "notation"})
					}
				})
				,lQuery.create("D#Row", {
					component = {
						lQuery.create("D#Label", {caption = "RowType"})
						,lQuery.create("D#ComboBox", {
							id = "rowType", 
							item = {
								lQuery.create("D#Item", {value = "TextArea"})
								,lQuery.create("D#Item", {value = "TextArea+Button"})
							}})
					}
				})
			
		}})
      ,lQuery.create("D#HorizontalBox", {
        horizontalAlignment = 1
		,id = "closeForm"
        ,component = {
		  lQuery.create("D#VerticalBox", {id = "buttonsAddTag"}) 
		  ,lQuery.create("D#HorizontalBox", {
			id = "closeButton"
			,horizontalAlignment = 1
			,component = {add_button, close_button}})
		  }
      })
    }
  })
  dialog_utilities.show_form(form)
	--createChildNode("treeConfiguration")
end

--izveido AA#TagType instanci
function createAddTagType()
	local keyT = lQuery("D#TextBox[id='key']"):attr("text")
	local notationT = lQuery("D#TextBox[id='notation']"):attr("text")
	local rowTypeT = lQuery("D#ComboBox[id='rowType']"):attr("text")

	lQuery.create("AA#TagType", {key = keyT, notation = notationT, rowType = rowTypeT}):link("configuration", lQuery("AA#Configuration"))
	
	--atjaunot list box
	refreshListBox()
	closeAddTagType()
end

--atjauno sarakstu ar AA#TagType instancem
function refreshListBox()
	lQuery("D#ListBox[id='treeTagType']"):delete()
	lQuery.create("D#ListBox", {
			id = "treeTagType",maximumWidth = 300,minimumWidth = 300,maximumHeight = 300,minimumHeight = 300
			,item = collectTagType()
	}):link("container", lQuery("D#VerticalBox[id='VerFormtreeTagType']"))
	lQuery("D#VerticalBox[id='VerFormtreeTagType']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	
end

--atver formu AA#ContextType dzesanai
function removeContextType()
	local close_button = lQuery.create("D#Button", {
		caption = "Close"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.configuration.closeRemoveContextType()")
	})
	local delete_button = lQuery.create("D#Button", {
		caption = "Delete"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.configuration.deleteContextType()")
	})

	local form = lQuery.create("D#Form", {
		id = "RemoveContextType"
		,caption = "Remove ContextType"
		,buttonClickOnClose = false
		,cancelButton = close_button
		,defaultButton = close_button
		,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.configuration.closeRemoveContextType()")
		,component = {
			lQuery.create("D#VerticalBox", {
				component = {
					lQuery.create("D#Tree", {
						id = "treeDeleteContextType"
						,minimumWidth = 200,maximumHeight = 300,minimumHeight = 300
						,treeNode = lQuery.create("D#TreeNode", {
							text = "ContextTypes"
							,childNode = createNode()
							,expanded = true
						})
					})
				}
			})
		  ,lQuery.create("D#HorizontalBox", {
			horizontalAlignment = 1
			,id = "closeForm"
			,component = {delete_button, close_button}
		  })
		}
	  })
	  dialog_utilities.show_form(form)
	
	createChildNode("treeDeleteContextType")
	
end

--izdzes AA#ContextType instanci
function deleteContextType()
	local selectedNode = lQuery("D#Tree[id = 'treeConfiguration']/selected"):attr("id")
	local contextType = lQuery("AA#ContextType"):filter(function(obj)
		return lQuery(obj):id() == tonumber(selectedNode)
	end)
	
	--dzest AA#ContextType instanci drikst tikai ja tai nav lietotaju defineto lauku
	if contextType:find("/fieldInContext"):is_empty() then contextType:delete()
	else --print("contextType is used in profiles") --!!!!!!!!!!!!
	end

	--atjaunot ContextType koku
	lQuery("D#Tree[id = treeConfiguration]"):find("/treeNode"):delete()
	lQuery.create("D#TreeNode", {
		text = "ContextTypes"
		,childNode = createNode()
		,expanded = true
	}):link("tree", lQuery("D#Tree[id = treeConfiguration]"))
	createChildNode("treeConfiguration")
	lQuery("D#Tree[id = treeConfiguration]"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	
end

--atver formu AA#ContextType instancu izveidosanai
function addContextType()
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.configuration.closeAddContextType()")
  })
	local ok_button = lQuery.create("D#Button", {
    caption = "Ok"
	,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.configuration.closeAddContextType()")
  })

  local form = lQuery.create("D#Form", {
    id = "addContextType"
    ,caption = "Add ContextType"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.configuration.closeAddContextType()")
	,component = {
		lQuery.create("D#VerticalBox", {
			id = "VerFormCon"
			,component = { 
				lQuery.create("D#VTable", {
						id = "TableContextType"
						,column = {
							lQuery.create("D#VTableColumnType", {
								caption = "ElementType",editable = true,width = 150
							})
							,lQuery.create("D#VTableColumnType", {
								caption = "Path",editable = true,width = 150
							})
							,lQuery.create("D#VTableColumnType", {
								caption = "CompartType",editable = true,width = 150
							})
							,lQuery.create("D#VTableColumnType", {
								caption = "AddMirror",editable = true,width = 150
							})
						}
						,vTableRow = {
							lQuery.create("D#VTableRow", {
								vTableCell = {
									lQuery.create("D#VTableCell", { 
										vTableColumnType = lQuery("D#VTableColumnType[caption = 'ElementType']")
										,component = lQuery.create("D#ComboBox", {
											item = getElementType()
											,eventHandler = {
												utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.configuration.collectContextTypeMakeNewRow()")
											}
										})
									})
									,lQuery.create("D#VTableCell", { value = ""
										,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Path']")
									})
									,lQuery.create("D#VTableCell", { value = ""
										,vTableColumnType = lQuery("D#VTableColumnType[caption = 'CompartType']")
									})
									,lQuery.create("D#VTableCell", { value = ""
										,vTableColumnType = lQuery("D#VTableColumnType[caption = 'AddMirror']")
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
        ,component = {ok_button, close_button}
      })
    }
  })
  dialog_utilities.show_form(form)
end

--atlasa ContextType AddMirror vertibu
function selectAddMirror()
	
	local row = lQuery("D#VTable[id = 'TableContextType']/selectedRow"):attr("id")
	local activeCell = lQuery("D#VTable[id = 'TableContextType']/selectedRow/activeCell")--aktiva suna
	local comID = lQuery(activeCell):find("/component"):attr("checked")--componentes id
	if row=="" then 
	    local id = lQuery("D#VTable[id = 'TableContextType']/vTableRow"):map(function(obj)
		    return obj
	    end)
		row = id[#id-1]:attr("id")
		comID = id[#id-1]:find("/vTableCell:has(/vTableColumnType[caption='AddMirror'])"):attr("value")
	end

	local contexType = lQuery("AA#ContextType"):filter(
		function(obj)
			return lQuery(obj):id() == tonumber(row)
		end)
	if comID == "true" then comID = 1 else comID = 0 end
	contexType:attr("hasMirror", comID)
end

--atlasa visus elementa tipus
function getElementType()
	local values = lQuery("ElemType"):map(
	  function(obj, i)
		return {lQuery(obj):attr("caption"), lQuery(obj):id()}
	  end)
	return lQuery.map(values, function(mode_value) 
		return lQuery.create("D#Item", {
			value = mode_value[1]
			,id = mode_value[2]
		}) 
	end)
end

--atlasa AA#ContextType instances, izveido jaunu rindu tabula
function collectContextTypeMakeNewRow()
	
	local row = lQuery("D#VTable[id = 'TableContextType']/selectedRow")
	local elemType = row:find("/vTableCell:has(/vTableColumnType[caption='ElementType'])"):attr("value")
	local elemTypeId = lQuery("D#VTable[id = 'TableContextType']/selectedRow/activeCell/component/selected"):attr("id")
	local addMir = row:find("/vTableCell:has(/vTableColumnType[caption='AddMirror'])"):attr("value")

	local context = lQuery("AA#ContextType:has(/configuration)"):map(function(obj)
		return {obj:attr("type"), obj:attr("nr"), obj}
	end)
	
	table.sort(context, function(x,y) return tonumber(x[2]) < tonumber(y[2]) end)
	local nr1 = context[#context]
	local num
	if #context == 0 then num = 1 else
	    num = nr1[2]+1
	end

	local contextType = lQuery.create("AA#ContextType", {type=elemType, nr=num, mode="Element", id=elemType}):link("configuration", lQuery("AA#Configuration"))
	row:attr("id", contextType:id())
	
	lQuery(row):find("/vTableCell"):delete()
	lQuery.create("D#VTableCell", { value = elemType
		,id = elemTypeId
		,vTableColumnType = lQuery("D#VTableColumnType[caption = 'ElementType']")
		,component = lQuery.create("D#TextBox", {text = elemType, id = elemTypeId})
	}):link("vTableRow", row)
	lQuery.create("D#VTableCell", { value = ""
		,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Path']")
	}):link("vTableRow", row)
	lQuery.create("D#VTableCell", { value = ""
		,vTableColumnType = lQuery("D#VTableColumnType[caption = 'CompartType']")
		,component = lQuery.create("D#Button", {
			caption = "set CompartType"
			,id = elemTypeId
			,eventHandler = {utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.configuration.generateElemTypeTree()")}
		})
	}):link("vTableRow", row)
	lQuery.create("D#VTableCell", { value = ""
		,vTableColumnType = lQuery("D#VTableColumnType[caption = 'AddMirror']")
	}):link("vTableRow", row)
	
	--izveidot jaunu rindu
	lQuery.create("D#VTableRow", {
		vTableCell = {
			lQuery.create("D#VTableCell", { 
				vTableColumnType = lQuery("D#VTableColumnType[caption = 'ElementType']")
				,component = lQuery.create("D#ComboBox", {
					text = ""
					,item = getElementType()
					,eventHandler = {
						utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.configuration.collectContextTypeMakeNewRow()")
					}
				})
			})
			,lQuery.create("D#VTableCell", { value = ""
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Path']")
			})
			,lQuery.create("D#VTableCell", { value = ""
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'CompartType']")
			})
			,lQuery.create("D#VTableCell", { value = ""
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'AddMirror']")
			})
		}
	}):link("vTable", lQuery("D#VTable[id = 'TableContextType']"))	
	lQuery("D#VTable[id = 'TableContextType']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	
end

--atver formu ar ElemType piesaistitiem CompartType
function generateElemTypeTree()
	
	local activeCell = lQuery("D#VTable[id = 'TableContextType']/selectedRow/activeCell")--aktiva suna
	local comID = lQuery(activeCell):find("/component"):attr("id")--componentes id

	local elementType -- vajadziga ElemType
	local field = lQuery("ElemType"):each(function(obj)
		if obj:id() == tonumber(comID) then 
			elementType = obj
			return
		end end)
	
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.configuration.closeTree()")
	})
  
	local ok_button = lQuery.create("D#Button", {
		caption = "Ok"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.configuration.OkTree()")
	})

	local form = lQuery.create("D#Form", {
		id = "CompartmentTree"
		,caption = "Select compartment"
		,buttonClickOnClose = false
		,cancelButton = close_button
		,defaultButton = ok_button
		,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.configuration.closeTree()")
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
			,id = "closeForm"
			,component = {
			  lQuery.create("D#VerticalBox", {id = "buttonsElemType"}) 
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

--ieraksta AA#ContextType tabulaa
function OkTree()
	--atrast compartType
	local compartTypeId = lQuery("D#Tree[id='treeCompartment']/selected"):attr("id")
	local compartType = lQuery("CompartType"):filter(
		function(obj)
			return lQuery(obj):id() == tonumber(compartTypeId)
		end)
	if compartType:is_not_empty() then
	
		local activeCell = lQuery("D#VTable[id = 'TableContextType']/selectedRow/activeCell")--aktiva suna
		local comID = lQuery(activeCell):find("/component"):attr("id")--componentes id

		local node = lQuery("D#Tree[id='treeCompartment']/selected"):attr("text")

		--atrast celu
		
		--atrast celu lidz elementam
		local elemType = lQuery("D#VTable[id = 'TableContextType']/selectedRow/vTableCell:has(/vTableColumnType[caption='ElementType'])"):attr("value")
		local id = ""
		local path = ""
		local l = 0
		local compartTypeT = compartType
		while l==0 do
			if compartTypeT:find("/elemType"):is_empty() then 
				local pat = lpeg.P("ASFictitious")
				if  not lpeg.match(pat, compartTypeT:find("/parentCompartType"):attr("id")) then 
					path = compartTypeT:find("/parentCompartType"):attr("caption")  .. "/" .. path
					id = compartTypeT:find("/parentCompartType"):attr("id")  .. "/" .. id
				end
				compartTypeT = compartTypeT:find("/parentCompartType")
			else
				l=1
			end
		end
		id = elemType .. "/" .. id
		id = id .. compartType:attr("id")
		--atjaunot sunas
		--atrast kas tika izvelets
		
		local cotextTypeId = lQuery("D#VTable[id = 'TableContextType']/selectedRow"):attr("id")
		
		--atrast contextType
		local contextType = lQuery("AA#ContextType"):filter(function(obj)
			return lQuery(obj):id() == tonumber(cotextTypeId)
		end)
		local pat = lpeg.P("ASFictitious")
		local mode
		contextType:attr("elTypeName", elemType)
		contextType:attr("path", path)
		contextType:attr("type", node)
		contextType:attr("id", id)
		--atrast compartType
		local compartType = extensionCreate.findCompartType("", contextType)
		
		--atrast ContextType rezimu
		if compartType:attr("isGroup") == "true" then mode = "Group"
		elseif compartType:find("/elemType"):is_not_empty() or compartType:find("/parentCompartType"):attr("isGroup") == "true" then
			mode = "Group Item"
		elseif lpeg.match(pat, compartType:find("/parentCompartType"):attr("id")) and compartType:find("/parentCompartType/elemType"):is_not_empty() then
			mode = "Group Item"
		else
			mode = "Text"
		end
		
		--atjaunot tabulu
		contextType:attr("mode", mode)
		local row = lQuery("D#VTable[id = 'TableContextType']/selectedRow")
		local addMir = row:find("/vTableCell:has(/vTableColumnType[caption='AddMirror'])"):attr("value")
		row:attr("id", contextType:id())
		lQuery(row):find("/vTableCell"):delete()
		lQuery.create("D#VTableCell", { value = elemType
			,vTableColumnType = lQuery("D#VTableColumnType[caption = 'ElementType']")
			,component = lQuery.create("D#TextBox", {
				text = elemType
			})
		}):link("vTableRow", row)
		lQuery.create("D#VTableCell", { value = path
			,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Path']")
			,component = lQuery.create("D#TextBox", {
				text = path
			})
		}):link("vTableRow", row)
		lQuery.create("D#VTableCell", { value = node
			,vTableColumnType = lQuery("D#VTableColumnType[caption = 'CompartType']")
			,component = lQuery.create("D#TextBox", {
				text = node
			})
		}):link("vTableRow", row)
		lQuery.create("D#VTableCell", {
			vTableColumnType = lQuery("D#VTableColumnType[caption = 'AddMirror']")
			,component = lQuery.create("D#CheckBox", {editable = "true"
				,checked = addMir
				,eventHandler = {
					utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.configuration.selectAddMirror()")
				}}
			)
		}):link("vTableRow", row)
		
		lQuery("D#VTable[id = 'TableContextType']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	
	end
	lQuery("D#Event"):delete()
	utilities.close_form("CompartmentTree")
end

--Atlasa AA#ContextType insdtances, kas ir elemType
function createNode()

	local values = lQuery("AA#ContextType"):map(
	  function(obj, i)
		if obj:find("/configuration"):is_not_empty() then
			return {lQuery(obj):attr("type"), lQuery(obj):attr("nr"), lQuery(obj):id(), lQuery(obj):attr("elTypeName"), lQuery(obj):attr("mode")}
		end
	  end)
	
	--sakartojam tabulu pec Number
	table.sort(values, function(x,y) return tonumber(x[2]) < tonumber(y[2]) end)
	
	return lQuery.map(values, function(mode_value) 
		if mode_value[5] == "Element" then
			return lQuery.create("D#TreeNode", {
				text = "T: " ..  mode_value[1]
				,id = mode_value[3]
				,expanded = true
			}) 
		end
	end)
end

--parildina koku ar zemaka limena AA#ContextType instancem
function createChildNode(treeId)
	local values = lQuery("AA#ContextType"):map(
	  function(obj, i)
		if lQuery(obj):attr("mode") ~="Element" and obj:find("/configuration"):is_not_empty() then
			return {lQuery(obj):attr("type"), lQuery(obj):attr("nr"), lQuery(obj):id(), lQuery(obj):attr("elTypeName"), lQuery(obj):attr("mode"), lQuery(obj):attr("path")}
		end
	  end)
	--sakartojam tabulu pec Number
	table.sort(values, function(x,y) return tonumber(x[2]) < tonumber(y[2]) end)
	
	for i,mode_value in pairs(values) do
		--ja cels nav noradits
		if mode_value[6] == "" then
			--ja tada ContextType(ElemType) vel nav, tad veidojam to un vajadzigo apaksContextType
			if lQuery("D#Tree[id = '" .. treeId .. "']/treeNode/childNode[text='T: " .. mode_value[4] .. "']"):is_empty()
			and lQuery("D#Tree[id = '" .. treeId .. "']/treeNode/childNode[text='" .. mode_value[4] .. "']"):is_empty() then
				lQuery.create("D#TreeNode", {
					text = mode_value[4]
					,childNode = lQuery.create("D#TreeNode", {
						text = "T: " ..  mode_value[1]
						,id = mode_value[3]
						,expanded = true
					})
					,expanded = true
				}):link("parentNode", lQuery("D#Tree[id = '" .. treeId .. "']/treeNode"))
			--ja tads ContextType jau ir un tas ir pamat limenis
			elseif lQuery("D#Tree[id = '" .. treeId .. "']/treeNode/childNode[text='T: " .. mode_value[4] .. "']"):is_not_empty() then
				--ja tada apaksCompartType vel nav, tad veidojam to
				if lQuery("D#Tree[id = '" .. treeId .. "']/treeNode/childNode[text='T: " .. mode_value[4] .. "']/childNode[text='" .. mode_value[1] .. "']"):is_empty() then
					lQuery.create("D#TreeNode", {
						text = "T: " ..  mode_value[1]
						,id = mode_value[3]
						,expanded = true
					}):link("parentNode", lQuery("D#Tree[id = '" .. treeId .. "']/treeNode/childNode[text='T: " .. mode_value[4] .. "']"))
				--ja apaksCompartType ir,tad ja tas ir apakslimenis, padaram to par ContextType
				else
					local node = lQuery("D#Tree[id = '" .. treeId .. "']/treeNode/childNode[text='T: " .. mode_value[4] .. "']/childNode[text='" .. mode_value[1] .. "']")
					node:attr("text", "T: " .. mode_value[1])
					node:attr("id", mode_value[3])
					node:attr("expanded",true)
				end
			--ja tads ContextType jau ir un tas ir starp limenis
			elseif lQuery("D#Tree[id = '" .. treeId .. "']/treeNode/childNode[text='" .. mode_value[4] .. "']"):is_not_empty() then
				--ja tada apaksCompartType vel nav, tad veidojam to
				if lQuery("D#Tree[id = '" .. treeId .. "']/treeNode/childNode[text='" .. mode_value[4] .. "']/childNode[text='" .. mode_value[1] .. "']"):is_empty() then
					lQuery.create("D#TreeNode", {
						text = "T: " ..  mode_value[1]
						,id = mode_value[3]
						,expanded = true
					}):link("parentNode", lQuery("D#Tree[id = '" .. treeId .. "']/treeNode/childNode[text='" .. mode_value[4] .. "']"))
				else
					local node = lQuery("D#Tree[id = '" .. treeId .. "']/treeNode/childNode[text='" .. mode_value[4] .. "']/childNode[text='" .. mode_value[1] .. "']")
					node:attr("text", "T: " .. mode_value[1])
					node:attr("id", mode_value[3])
					node:attr("expanded",true)
				end
			end
		--ja cels ir noradits
		else
			--ja tada ContextType(ElemType) vel nav, tad veidojam to
			if lQuery("D#Tree[id = '" .. treeId .. "']/treeNode/childNode[text='T: " .. mode_value[4] .. "']"):is_empty()
			and lQuery("D#Tree[id = '" .. treeId .. "']/treeNode/childNode[text='" .. mode_value[4] .. "']"):is_empty() then
				lQuery.create("D#TreeNode", {
					text = mode_value[4]
					,expanded = true
				}):link("parentNode", lQuery("D#Tree[id = '" .. treeId .. "']/treeNode"))
			end
			--atrast elementu
			local elemTypeTreeNode = lQuery("D#Tree[id = '" .. treeId .. "']/treeNode/childNode[text='T: " .. mode_value[4] .. "']")
			if elemTypeTreeNode:is_empty() then 
				elemTypeTreeNode = lQuery("D#Tree[id = '" .. treeId .. "']/treeNode/childNode[text='" .. mode_value[4] .. "']")
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
					,id = mode_value[3]
					,expanded = true
				}):link("parentNode", elemTypeTreeNode)
			else
				local node = elemTypeTreeNode:find("/childNode[text='" .. mode_value[1] .. "']")
				node:attr("text", "T: " .. mode_value[1])
				node:attr("id", mode_value[3])
				node:attr("expanded",true)
			end
		end
	end	
end

function closeRemoveContextType()
	lQuery("D#Event"):delete()
    utilities.close_form("RemoveContextType")
end

function closeTree()
	lQuery("D#Event"):delete()
    utilities.close_form("CompartmentTree")
end

function closeAddContextType()
	--atlasit visas tabulas rindas
	lQuery("D#VTable[id = 'TableContextType']/vTableRow"):each(function(obj)
	    local contextType = lQuery("AA#ContextType:has(/configuration)"):filter(function(conT)
			return lQuery(conT):id() == tonumber(obj:attr("id"))
		end)
		if contextType:is_not_empty() then
			local ctype = contextType:attr("type")
			local cmode = contextType:attr("mode")
			local cpath = contextType:attr("path")
			local celTypeName = contextType:attr("elTypeName")
			local chasMirror = contextType:attr("hasMirror")
			local ct=lQuery("AA#ContextType[type='" .. ctype .. "'][mode='" .. cmode .. "'][path='" .. cpath .. "'][elTypeName='" .. celTypeName .. "'][hasMirror='" .. chasMirror .. "']:has(/configuration)")
			if ct:size()>1 then contextType:delete() end
		end
	end)
	
	lQuery("D#Event"):delete()
    utilities.close_form("addContextType")
	
	--parrekinat koku
	lQuery("D#Tree[id = treeConfiguration]"):find("/treeNode"):delete()
	lQuery.create("D#TreeNode", {
		text = "ContextTypes"
		,childNode = createNode()
		,expanded = true
	}):link("tree", lQuery("D#Tree[id = treeConfiguration]"))
	createChildNode("treeConfiguration")
	lQuery("D#Tree[id = treeConfiguration]"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	
end

function closeTagType()
	lQuery("D#Event"):delete()
    utilities.close_form("TagType")
end

function closeAddTagType()
	lQuery("D#Event"):delete()
    utilities.close_form("AddTagType")
end

function close()
	lQuery("D#Event"):delete()
    utilities.close_form("Configuration")
end