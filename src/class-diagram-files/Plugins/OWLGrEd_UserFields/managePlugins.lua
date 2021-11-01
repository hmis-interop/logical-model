module(..., package.seeall)

require("lua_tda")
require "dialog_utilities"
local utils = require "plugin_mechanism.utils"

function managePlugins()
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.managePlugins.close()")
  })
  
  local form = lQuery.create("D#Form", {
    id = "managePlugins"
    ,caption = "Manage extensions"
	,minimumWidth = 300
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.managePlugins.close()")
	,component = {
		lQuery.create("D#VerticalBox",{
			component = {
				lQuery.create("D#VerticalBox"	,{
					component = {
						
						lQuery.create("D#VerticalBox", {
							id = "VerticalBoxWithListBoxM"
							,horizontalAlignment = -1
							,component = {
								lQuery.create("D#Label", {caption = "Installed extensions"})
								,lQuery.create("D#ListBox", {
									id = "ListWithPlugins"
									,item = collectPlugins()
								})
							}
						})
						,lQuery.create("D#HorizontalBox", {
							horizontalAlignment = -1
							,component = {
								lQuery.create("D#Button", {
									caption = "Add new.."
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.managePlugins.addNew()")
								})
								,lQuery.create("D#Button", {
									caption = "Update"
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.managePlugins.updatePlugin()")
								})
								,lQuery.create("D#Button", {
									caption = "Delete"
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.managePlugins.deletePlugin()")
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

function reloadProjectInfo(caption, textMessage)
  local close_button = lQuery.create("D#Button", {
    caption = "OK"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.managePlugins.closeReloadProject()")
  })
  
  local form = lQuery.create("D#Form", {
    id = "reloadProject"
    --,caption = "Reload Project"
    ,caption = caption
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.managePlugins.closeReloadProject()")
	,component = {
		lQuery.create("D#VerticalBox",{
			component = {
				-- lQuery.create("D#Label", {caption = "Re-open the project (Menu: Project -> Re-open) to complete operation"})
				lQuery.create("D#Label", {caption = textMessage})
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


function close()
  lQuery("D#Event"):delete()
  utilities.close_form("managePlugins")
end


function closeReloadProject()
  lQuery("D#Event"):delete()
  utilities.close_form("reloadProject")
end

function collectPlugins()
	local values = lQuery("Plugin"):filter(function(plugin)
		return plugin:attr("status") == "loaded"
	end):map(
	  function(plugin)
		return {plugin:attr("id"), plugin:attr("version")}
	  end)  
	
	return lQuery.map(values, function(plugin) 
		local pluginName = plugin[1]
		
		return lQuery.create("D#Item", {
			value = plugin[1] .. " (version:" .. plugin[2] ..")"
			,id = plugin[1]
		}) 
	end)
end

function addNew()
	local path = select_plugin_path("")
	if path ~= "" then	
		local info, err = get_plugin_info(path)
		local plugin_name = info.name
		if tda.isWeb == nil then 
			local Plugin_dir_path = tda.GetProjectPath() .. "\\" .. "Plugins"
			utils.copy(path, Plugin_dir_path .. "\\" .. plugin_name) 
		end
		reloadProjectInfo("Reload Project", "Re-open the project (Menu: Project -> Re-open) to complete operation")
		addItemListBox(info)
		if lQuery("Plugin[id='"..info.name.."']"):is_empty() then
		  lQuery.create("Plugin", {
			id = info.name,
			version = info.version,
			status = "added",
		  })
		end
	end
end

function updatePlugin()
	local path = select_plugin_path("")
	if path ~= "" then
		local info, err = get_plugin_info(path)
		local plugin_name = info["name"]
		local current_version = tonumber(string.sub(lQuery("Plugin[id='"..info["name"].."']"):attr("version"), 3))
		local plugin_version = tonumber(string.sub(info["version"], 3))

		if lQuery("Plugin[id='"..plugin_name.."']"):is_not_empty() and plugin_version >  current_version then
			if tda.isWeb == nil then 
				local Plugin_dir_path = tda.GetProjectPath() .. "\\" .. "Plugins"
				utils.copy(path, Plugin_dir_path .. "\\" .. plugin_name)
			end
			reloadProjectInfo("Reload Project", "Re-open the project (Menu: Project -> Re-open) to complete operation")
			addItemListBox(info)
			lQuery("Plugin[id='"..plugin_name.."']"):attr("status", "updated")
		end
	end
end

function deletePlugin()
	local plugin = lQuery("D#ListBox[id='ListWithPlugins']/selected")
	if plugin:is_not_empty() then
		local pluginName = plugin:attr("id")
		if(pluginName ~= "OWLGrEd_UserFields") then
			if tda.isWeb == nil then 
				local Plugin_dir_path = tda.GetProjectPath() .. "\\" .. "Plugins"
				utils.delete(Plugin_dir_path .. "\\" .. pluginName)
			end
			reloadProjectInfo("Reload Project", "Re-open the project (Menu: Project -> Re-open) to complete operation")
			removeItemListBox(pluginName)
			lQuery("Plugin[id='"..pluginName.."']"):attr("status", "unloaded")
		else
			reloadProjectInfo("Message", "UserFields extension can not be deleted")
		end
	end
end

function select_plugin_path(start_path)
	local caption = "Select extension folder"
	if tda.isWeb then
		return tda.BrowseForFileAsList(caption, tda.GetToolPath() .. "\\AllPlugins")
	end
	
	local start_folder = tda.GetRuntimePath()--.."\\..\\Plugins"
	return tda.BrowseForFolder(caption, start_folder)
end

function get_plugin_info(path)
  
  local f
  if tda.isWeb then
	f = io.open(path.. "/info.lua", "r")
  else
	f = io.open(path.. "\\info.lua", "r")
  end
  
  local info = loadstring("return" .. f:read("*a"))()
  f:close()
  return info
end

function addItemListBox(info)
	lQuery("D#ListBox[id='ListWithPlugins']/item[id='"..info["id"].."']"):delete()
	lQuery.create("D#Item", {
		value = info["name"] .. " (version:" .. info["version"] ..")"
		,id = info["id"]
	}):link("listBox", lQuery("D#ListBox[id='ListWithPlugins']"))	
	lQuery("D#ListBox[id='ListWithPlugins']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

function removeItemListBox(pluginName)
	lQuery("D#Item[id='"..pluginName.."']"):delete()
	lQuery("D#ListBox[id='ListWithPlugins']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	
end
