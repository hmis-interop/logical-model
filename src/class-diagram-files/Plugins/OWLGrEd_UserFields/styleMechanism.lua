module(..., package.seeall)

require("lua_tda")
require "lpeg"
require "core"
require "dialog_utilities"
-- require "progress_reporter"
serialize = require "serialize"
owl_fields_specific = require "OWLGrEd_UserFields.owl_fields_specific"
local configurator = require"configurator.configurator"
local report = require("reporter.report")
require("graph_diagram_style_utils")

--izdzes izdzesto stilu instances
function deleteIsDeletedStyleSetting()
	lQuery("ElementStyleSetting[isDeleted=1]"):delete()
	lQuery("CompartmentStyleSetting[isDeleted=1]"):delete()
end

--sinhronize projekta skatijumus
function syncExtensionViews()
	lQuery("AA#View"):each(function(view)
		local extension = lQuery("Extension[id='" .. view:attr("name") .. "'][type='aa#View']")
		local changeElemStyle = syncViewStyleSettingElement(view, extension)
		local changeCompartStyle = syncViewStyleSettingCompartment(view, extension)
	end)
end

--sinhronize skatijumu kompartmentu stilus (view-skatijuma AA#View instance, extension-skatijuma instance)
function syncViewStyleSettingCompartment(view, extension)
	local changeCompartStyle = 0
	local link = {}--tabula ar stiliem, kam ir saderibas abas puses
	view:find("/styleSetting[isElementStyleSetting != true]"):each(function(styleView)
		extension:find("/compartmentStyleSetting"):each(function(styleExt)
			local path = styleView:attr("path")
			local pathTable = split(path, "/")
			local lastPath = pathTable[#pathTable]
			if lastPath == "" and #pathTable>1 then lastPath=pathTable[#pathTable-1] end

			if styleView:find("/fieldStyleFeature"):attr("itemName")==styleExt:attr("setting") and 
				styleView:attr("value")==styleExt:attr("value") and
				styleView:attr("target")==styleExt:find("/compartType"):attr("caption") and
				lastPath==styleExt:find("/compartType/parentCompartType"):attr("caption")
			then
				local linkPair = {}
				table.insert(linkPair, styleView)
				table.insert(linkPair, styleExt)
				table.insert(link, linkPair)
			end
		end)
	end)
	--visi stili, kas tika dzesti no AA#View dalas
	local extensionNotMapped = {}
	extension:find("/compartmentStyleSetting"):each(function(styleExt)
		local l = 0
		for i,v in pairs(link) do
			if v[2]:id()==styleExt:id() then 
				l = 1
				break
			end
		end
		if l==0 then
			table.insert(extensionNotMapped, styleExt)
			changeCompartStyle = 1
		end
	end)
	for i,v in pairs(extensionNotMapped) do 
		v:attr("isDeleted", 1)
		v:find("/settingTag"):delete()
	end	
	--visi stili, kam nav atbilstibas Extension dalaa
	local ViewNotMapped = {}
	view:find("/styleSetting[isElementStyleSetting != true]"):each(function(styleView)
		local l = 0
		for i,v in pairs(link) do
			if v[1]:id()==styleView:id() then 
				l = 1
				break
			end
		end
		if l==0 then 
			table.insert(ViewNotMapped, styleView)
			changeCompartStyle = 1
		end
	end)
	--vaidojam visus iztrukstosos Extension dalas skatijumus
	for i,v in pairs(ViewNotMapped) do 
		local elemType = lQuery("ElemType[id='".. v:attr("elementTypeName") .. "']")
		local l = 0
		local target = v:attr("target")
		local path = v:attr("path")
		local pathTable = split(path, "/")
		local addMirror = v:attr("addMirror")
		local compartType
		
		local pat2 = lpeg.P("(")
		pat2 = anywhere(pat2)
		--caur celu atrodam vajadzigo CompartType instanci
		--ja lauks nav zem pirma limena lauka
		if #pathTable ~= 1 then
			compartType = elemType:find("/compartType[caption='" .. pathTable[1] .. "']")
			if compartType:is_empty() then 
			    compartType = elemType:find("/compartType[caption='ASFictitious" .. pathTable[1] .. "']")
			end
			local pat = lpeg.P("ASFictitious")
			if lpeg.match(pat, compartType:attr("id")) then 
				compartType = compartType:find("/subCompartType[caption='" .. pathTable[1] .. "']")
			end
			for i=2,#pathTable,1 do 
				if pathTable[i] ~= "" then 
					local compartType2 = compartType:find("/subCompartType[caption='" .. pathTable[i] .. "']")
					if compartType2:is_empty() then compartType = compartType:find("/subCompartType[caption='ASFictitious" .. pathTable[i] .. "']")
					else compartType = compartType2 end
					if lpeg.match(pat, compartType:attr("id")) then 
						compartType = compartType:find("/subCompartType[caption='" .. pathTable[i] .. "']")
					end
				end
			end
			local compartType2 = compartType:find("/subCompartType[caption='" .. target .. "']")
			if compartType2:is_empty() then compartType = compartType:find("/subCompartType[caption='ASFictitious" .. target .. "']")
			else compartType = compartType2 end
		--ja ir pirma limenja lauks
		else
			compartType = elemType:find("/compartType[caption='" .. target .. "']")
			if compartType:is_empty() then 
				compartType = elemType:find("/compartType[caption='ASFictitious" .. target .. "']")
			end
			if compartType:attr("isGroup") == "true" then compartType = compartType:find("/subCompartType[caption='" .. target .. "']") end
		end
		--ja CompartType tika atrasts veidojam skatijuma stilu instances
		if compartType:size() ~= 0 then
			if v:attr("addMirror") == "true" and (compartType:find("/aa#mirror"):is_not_empty() or compartType:find("/aa#mirrorInv"):is_not_empty()) then
				local compartTypeInv = compartType:find("/aa#mirror")
				if compartTypeInv:is_empty() then compartTypeInv = compartType:find("/aa#mirrorInv") end
				if v:attr("conditionCompartType") ~= "" and v:attr("conditionChoiceItem") ~= "" then
					createViewAndChoiceItemCompartStyleSetting(extension, compartType, v)
					createViewAndChoiceItemCompartStyleSetting(extension, compartTypeInv, v)
				else
					createViewCompartStyleSetting(extension, compartType, v)
					createViewCompartStyleSetting(extension, compartTypeInv, v)
				end
			else	
				if v:attr("conditionCompartType") ~= "" and v:attr("conditionChoiceItem") ~= "" then
					createViewAndChoiceItemCompartStyleSetting(extension, compartType, v)
				else
					createViewCompartStyleSetting(extension, compartType, v)
				end
			end
		else
			--ja netika atrasts targeta compartType, tad izdezest AA#ViewStyleSetting instanci
			--!!!!!!!!!!!!!!!!!!
			--print("View style instance " .. v:find("/fieldStyleFeature"):attr("itemName") .. v:attr("value") .. " was deleted, because CompartType instance " .. target .. " could not be found")
			v:delete()
		end
	end
	
	--jasingronize extra stili
	for i,v in pairs(link) do
		v[2]:find("/settingTag"):delete()
		v[2]:remove_link("dependsOnCompartType", v[2]:find("/dependsOnCompartType"))
		setExtraStyles(extension, v[1], v[2], "compartment")
	end
	
	return changeCompartStyle
end

function split(s, sep)
	sep=lpeg.P(sep)
	local elem = lpeg.C((1-sep)^0)
	local p = lpeg.Ct(elem * (sep * elem)^0)
	return lpeg.match(p,s)
end

--izveido skatijumu stila instanci, kas ir atkariga kada ChoiceItem (extension-skatijums, compartType-kompart tips kuram ir japiekarto stils, viewStyleSetting-stila instance no AA# dalas)
function createViewAndChoiceItemCompartStyleSetting(extension, compartType, viewStyleSetting)
	--jaatrod compatType/choiceItem
	local choiceItem
	local parent = compartType:find("/parentCompartType")
	if string.find(viewStyleSetting:attr("conditionCompartType"), "/") == nil then 
		if parent:is_empty() then 
			parent = compartType:find("/elemType") 
			choiceItem = parent:find("/compartType[caption='" .. viewStyleSetting:attr("conditionCompartType") .. "']/choiceItem[value='" .. viewStyleSetting:attr("conditionChoiceItem") .."']")
		else
			choiceItem = parent:find("/subCompartType[caption='" .. viewStyleSetting:attr("conditionCompartType") .. "']/choiceItem[value='" .. viewStyleSetting:attr("conditionChoiceItem") .."']")
		end
	else
		local elemType = lQuery("ElemType[id='" .. viewStyleSetting:attr("elementTypeName") .. "']")
		local path = viewStyleSetting:attr("conditionCompartType")
		local pathTable = split(path, "/")
		--ja compartType id dzili
		local compartType2
		if #pathTable ~= 1 then
			compartType2 = elemType:find("/compartType[caption='" .. pathTable[1] .. "']")
			local pat = lpeg.P("ASFictitious")
			if lpeg.match(pat, compartType2:attr("id")) then 
				compartType2 = compartType2:find("/subCompartType[caption='" .. pathTable[1] .. "']")
			end
			for i=2,#pathTable,1 do 
				if pathTable[i] ~= "" then 
					compartType2 = compartType2:find("/subCompartType[caption='" .. pathTable[i] .. "']")
					if lpeg.match(pat, compartType2:attr("id")) then 
						compartType2 = compartType2:find("/subCompartType[caption='" .. pathTable[i] .. "']")
					end
				end
			end
			--compartType = compartType:find("/subCompartType[caption='" .. value .. "']")
		else--ja ir pirma limenja lauks
			compartType2 = elemType:find("/compartType[caption='" .. pathTable[1] .. "']")
			if compartType2:attr("isGroup") == "true" then compartType2 = compartType2:find("/subCompartType[caption='" .. pathTable[1] .. "']") end
		end
		choiceItem = compartType2:find("/choiceItem[value='" .. viewStyleSetting:attr("conditionChoiceItem") .."']")
	end
	
	local itemName = lQuery(viewStyleSetting):find("/fieldStyleFeature"):attr("itemName")
	
	if string.find(itemName, "prefix-")~= nil and string.find(compartType:attr("id"), "ASFictitious") then compartType = compartType:find("/subCompartType[caption='" .. compartType:attr("caption") .."']") end
	if string.find(itemName, "suffix-")~= nil and string.find(compartType:attr("id"), "ASFictitious") then compartType = compartType:find("/subCompartType[caption='" .. compartType:attr("caption") .."']") end
	
	--izveidojam stila instanci
	local elStSet = lQuery.create("CompartmentStyleSetting", {
		setting = itemName
		,value = lQuery(viewStyleSetting):attr("value")
		,procCondition = "setCompartStyleByExtensionAndChoiceItem"
		,procSetValue = lQuery(viewStyleSetting):attr("procSetValue")
		,strength = 10
	})
	:link("compartType", compartType)
	:link("extension", extension)
	:link("choiceItem", choiceItem)
	
	setExtraStyles(extension, viewStyleSetting, elStSet, "compartment")
	
	local elemType = compartType
	local l = 0
	while l ~=1 do
		local temp = elemType:find("/subCompartType")
		if temp:is_empty() then temp = elemType:find("/elemType") l = 1 end
		elemType = temp
	end
	if lQuery(elemType):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDefaultStyle']"):is_empty() then
		lQuery.create("Translet", {extensionPoint = 'procNewElement', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDefaultStyle'})
		:link("type", elemType)
	end
	if lQuery(elemType):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.styleCode']"):is_empty() then
		lQuery.create("Translet", {extensionPoint = 'procCopied', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.styleCode'})
		:link("type", elemType)
	end
	local ct = lQuery(choiceItem):find("/compartType")
	--ja vel nav targeta, kas atbildigs par stiliem, tad to izveidojam
	if lQuery(ct):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDependentStyle']"):is_empty() then
		lQuery.create("Translet", {extensionPoint = 'procFieldEntered', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDependentStyle'})
		:link("type", ct)
	end
	
	--isVisible
	if itemName == "isVisible" and (compartType:find("/elemType"):is_empty() and compartType:find("/parentCompartType"):attr("isGroup") ~= 'true') then 
		elStSet:attr("procCondition", "setTextStyle")
		if lQuery(compartType):find("/translet[extensionPoint = 'procIsHidden']"):is_empty() then
			lQuery.create("Translet", {extensionPoint = 'procIsHidden', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setIsHiddenViewAndChoiceItem'})
			:link("type", compartType)
		end
	end
	--prefix
	if string.find(itemName, "prefix-")~= nil then 
		elStSet:attr("setting", "prefix")
		elStSet:attr("settingMode", string.sub(itemName, 8))
		if string.find(compartType:attr("id"), "ASFictitious") then compartType = compartType:find("/subCompartType[caption='" .. compartType:attr("caption") .."']") end
		if lQuery(compartType):find("/translet[extensionPoint = 'procGetPrefix']"):is_empty()  then
			lQuery.create("Translet", {extensionPoint = 'procGetPrefix', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setAllPrefixesView'})
			:link("type", compartType)
		else
			lQuery(compartType):find("/translet[extensionPoint = 'procGetPrefix']"):attr("procedureName", 'OWLGrEd_UserFields.owl_fields_specific.setAllPrefixesView')
		end
		elStSet:attr("procCondition", "setTextStyle") 
	--suffix
	elseif
		string.find(itemName, "suffix-")~= nil then 
		elStSet:attr("setting", "suffix")
		elStSet:attr("settingMode", string.sub(itemName, 8))
		if string.find(compartType:attr("id"), "ASFictitious") then compartType = compartType:find("/subCompartType[caption='" .. compartType:attr("caption") .."']") end
		if lQuery(compartType):find("/translet[extensionPoint = 'procGetSuffix']"):is_empty() then
			lQuery.create("Translet", {extensionPoint = 'procGetSuffix', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setAllSuffixesView'})
			:link("type", compartType)
		else
			lQuery(compartType):find("/translet[extensionPoint = 'procGetSuffix']"):attr("procedureName", 'OWLGrEd_UserFields.owl_fields_specific.setAllSuffixesView')
		end
		elStSet:attr("procCondition", "setTextStyle")
	end
end

--izveido skatijumu compartmentType stila instanci(extension-skatijums, compartType-kompart tips kuram ir japiekarto stils, viewStyleSetting-stila instance no AA# dalas)
function createViewCompartStyleSetting(extension, compartType, viewStyleSetting)
	local itemName = lQuery(viewStyleSetting):find("/fieldStyleFeature"):attr("itemName")
	local itemNameInstance = lQuery(viewStyleSetting):find("/fieldStyleFeature")
	if itemNameInstance:is_not_empty() then 
		--izveidojam instanci
		if string.find(itemName, "prefix-")~= nil and string.find(compartType:attr("id"), "ASFictitious") then compartType = compartType:find("/subCompartType[caption='" .. compartType:attr("caption") .."']") end
		if string.find(itemName, "suffix-")~= nil and string.find(compartType:attr("id"), "ASFictitious") then compartType = compartType:find("/subCompartType[caption='" .. compartType:attr("caption") .."']") end
		local elStSet = lQuery.create("CompartmentStyleSetting", {
			setting = itemName
			,value = lQuery(viewStyleSetting):attr("value")
			,procCondition = "setCompartStyleByExtension"
			,procSetValue = lQuery(viewStyleSetting):attr("procSetValue")
			,strength = 3
		})
		:link("compartType", compartType)
		:link("extension", extension)
		
		setExtraStyles(extension, viewStyleSetting, elStSet, "compartment")
		
		local elemType = compartType
		local l = 0
		while l ~=1 do
			local temp = elemType:find("/parentCompartType")
			if temp:is_empty() then temp = elemType:find("/elemType") l = 1 end
			elemType = temp
		end
		if lQuery(elemType):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDefaultStyle']"):is_empty() then
			lQuery.create("Translet", {extensionPoint = 'procNewElement', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDefaultStyle'})
			:link("type", elemType)
		end
		if lQuery(elemType):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.styleCode']"):is_empty() then
			lQuery.create("Translet", {extensionPoint = 'procCopied', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.styleCode'})
			:link("type", elemType)
		end
		
		--isVisible
		if itemName == "isVisible" and (compartType:find("/elemType"):is_empty() and compartType:find("/parentCompartType"):attr("isGroup") ~= 'true') then 
			elStSet:attr("procCondition", "setTextStyle")
			if lQuery(compartType):find("/translet[extensionPoint = 'procIsHidden']"):is_empty() then
				lQuery.create("Translet", {extensionPoint = 'procIsHidden', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setIsHiddenView'})
				:link("type", compartType)
			end
		end
		--prefix
		if string.find(itemName, "prefix-")~= nil then 
			elStSet:attr("setting", "prefix")
			elStSet:attr("settingMode", string.sub(itemName, 8))
			if string.find(compartType:attr("id"), "ASFictitious") then compartType = compartType:find("/subCompartType[caption='" .. compartType:attr("caption") .."']") end
			if lQuery(compartType):find("/translet[extensionPoint = 'procGetPrefix']"):is_empty() then
				lQuery.create("Translet", {extensionPoint = 'procGetPrefix', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setAllPrefixesView'})
				:link("type", compartType)
			else
				lQuery(compartType):find("/translet[extensionPoint = 'procGetPrefix']"):attr("procedureName", 'OWLGrEd_UserFields.owl_fields_specific.setAllPrefixesView')
			end
			elStSet:attr("procCondition", "setTextStyle")
		--suffix
		elseif
			string.find(itemName, "suffix-")~= nil then 
			elStSet:attr("setting", "suffix")
			elStSet:attr("settingMode", string.sub(itemName, 8))
			if string.find(compartType:attr("id"), "ASFictitious") then compartType = compartType:find("/subCompartType[caption='" .. compartType:attr("caption") .."']") end
			if lQuery(compartType):find("/translet[extensionPoint = 'procGetSuffix']"):is_empty() then
				lQuery.create("Translet", {extensionPoint = 'procGetSuffix', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setAllSuffixesView'})
				:link("type", compartType)
			else
				lQuery(compartType):find("/translet[extensionPoint = 'procGetSuffix']"):attr("procedureName", 'OWLGrEd_UserFields.owl_fields_specific.setAllSuffixesView')
			end
			elStSet:attr("procCondition", "setTextStyle")
		end
	else
		viewStyleSetting:delete()
	end
end

--izveido skatijumu ElemType stila instanci(extension-skatijums, viewStyleSetting-stila instance no AA# dalas)
function syncViewStyleSettingElement(view, extension)
	local changeElemStyle = 0
	local link = {}--stilu tabula, kuri sakrita abas puses
	view:find("/styleSetting[isElementStyleSetting = true]"):each(function(styleView)
		extension:find("/elementStyleSetting"):each(function(styleExt)
			local itemName = styleView:find("/elemStyleFeature"):attr("itemName")
			if itemName==styleExt:attr("setting") and 
				styleView:attr("value")==styleExt:attr("value") and
				styleView:attr("elementTypeName")==styleExt:find("/elemType"):attr("id")
			then
				local linkPair = {}
				table.insert(linkPair, styleView)
				table.insert(linkPair, styleExt)
				table.insert(link, linkPair)
			elseif styleView:attr("addMirror") == "true" and string.find(itemName, "start") ~= nil and string.sub(itemName, 6) == string.sub(styleExt:attr("setting"),4) then
				local linkPair = {}
				table.insert(linkPair, styleView)
				table.insert(linkPair, styleExt)
				table.insert(link, linkPair)
			elseif styleView:attr("addMirror") == "true" and string.find(itemName, "end") ~= nil and string.sub(itemName, 4) == string.sub(styleExt:attr("setting"),6) then
				local linkPair = {}
				table.insert(linkPair, styleView)
				table.insert(linkPair, styleExt)
				table.insert(link, linkPair)
			elseif styleExt:attr("setting") == "width" and itemName == "widthProc" then
				local linkPair = {}
				table.insert(linkPair, styleView)
				table.insert(linkPair, styleExt)
				table.insert(link, linkPair)
			end
		end)
	end)
	--stili, kam nav saderibas AA#View dalaa
	local extensionNotMapped = {}
	extension:find("/elementStyleSetting"):each(function(styleExt)
		local l = 0
		for i,v in pairs(link) do
			if v[2]:id()==styleExt:id() then 
				l = 1
				break
			end
		end
		if l==0 then 
			table.insert(extensionNotMapped, styleExt)
			changeElemStyle = 1
		end
	end)
	for i,v in pairs(extensionNotMapped) do 
		v:attr("isDeleted",1)
		v:find("/settingTag"):delete()
	end	
	--stili, kas nav izveidoti Extention dalaa
	local ViewNotMapped = {}
	view:find("/styleSetting[isElementStyleSetting = true]"):each(function(styleView)
		local l = 0
		for i,v in pairs(link) do
			if v[1]:id()==styleView:id() then 
				l = 1
				break
			end
		end
		if l==0 then 
			table.insert(ViewNotMapped, styleView) 
			changeElemStyle = 1
		end
	end)
	--izveido iztrukstosos stilu
	-- print("-------------------")
	-- print(dumptable(ViewNotMapped))
	for i,v in pairs(ViewNotMapped) do 
		-- local elemType = lQuery("ElemType[id='".. v:attr("elementTypeName") .. "']")
		local elemType = lQuery("ElemType"):filter(function(et) return et:id() == tonumber(v:attr("elementTypeId")) end)
		if elemType:is_empty() then elemType = lQuery("ElemType[id='".. v:attr("elementTypeName") .. "']") end
		if v:attr("conditionCompartType") ~= "" and v:attr("conditionChoiceItem") ~= "" then
			createViewElemStyleSetting(extension, elemType, v, true)
		else
			createViewElemStyleSetting(extension, elemType, v, false)
		end
	end
	--jasingronize extra stili
	for i,v in pairs(link) do
		v[2]:find("/settingTag"):delete()
		v[2]:remove_link("dependsOnCompartType", v[2]:find("/dependsOnCompartType"))
		setExtraStyles(extension, v[1], v[2], "element")
	end
	return changeElemStyle
end

--izveido skatijumu ElamType stila instanci(extension-skatijums, elemType-elementa tips kuram ir japiekarto stils, viewStyleSetting-stila instance no AA# dalas)
function createViewElemStyleSetting(extension, elemType, viewStyleSetting, isDependentFromChoiceItem)
	local itemName = lQuery(viewStyleSetting):find("/elemStyleFeature"):attr("itemName")
	local itemNameInstance = lQuery(viewStyleSetting):find("/elemStyleFeature")
	if itemNameInstance:is_not_empty() then 
		local procCondition = "setElemStyleByExtension"
		local strength = 3
		local choiceItem
		if isDependentFromChoiceItem == true then
			procCondition = "setElemStyleByExtensionAndChoiceItem"
			strength = 10
			
			local path = viewStyleSetting:attr("conditionCompartType")
			local pathTable = split(path, "/")
			--ja compartType id dzili
			local compartType2
			if #pathTable ~= 1 then
				compartType2 = elemType:find("/compartType[caption='" .. pathTable[1] .. "']")
				local pat = lpeg.P("ASFictitious")
				if lpeg.match(pat, compartType2:attr("id")) then 
					compartType2 = compartType2:find("/subCompartType[caption='" .. pathTable[1] .. "']")
				end
				for i=2,#pathTable,1 do 
					if pathTable[i] ~= "" then 
						compartType2 = compartType2:find("/subCompartType[caption='" .. pathTable[i] .. "']")
						if lpeg.match(pat, compartType2:attr("id")) then 
							compartType2 = compartType2:find("/subCompartType[caption='" .. pathTable[i] .. "']")
						end
					end
				end
				--compartType = compartType:find("/subCompartType[caption='" .. value .. "']")
			else--ja ir pirma limenja lauks
				compartType2 = elemType:find("/compartType[caption='" .. pathTable[1] .. "']")
			end
			choiceItem = compartType2:find("/choiceItem[value='" .. viewStyleSetting:attr("conditionChoiceItem") .."']")

			local ct = lQuery(choiceItem):find("/compartType")
			--ja vel nav targeta, kas atbildigs par stiliem, tad to izveidojam
			if lQuery(ct):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDependentStyle']"):is_empty() then
				lQuery.create("Translet", {extensionPoint = 'procFieldEntered', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDependentStyle'})
				:link("type", ct)
			end
		end
		local addMirror = lQuery(viewStyleSetting):find("/elemStyleFeature"):attr("addMirror")
		if string.find(itemName, "start") ~= nil and addMirror == "true" then
			local elStSet = lQuery.create("ElementStyleSetting", {
				setting = itemName
				,value = lQuery(viewStyleSetting):attr("value")
				,procCondition = procCondition
				,procSetValue = lQuery(viewStyleSetting):attr("procSetValue")
				,strength = strength
			})
			:link("elemType", elemType)
			:link("extension", extension)
			if isDependentFromChoiceItem == true then elStSet:link("choiceItem", choiceItem) end
			
			setExtraStyles(extension, viewStyleSetting, elStSet, "element")
			
			local startStyle = string.sub(itemName, 6)
			itemName = "end" .. startStyle
					
			local elStSet = lQuery.create("ElementStyleSetting", {
				setting = itemName
				,value = lQuery(viewStyleSetting):attr("value")
				,procSetValue = lQuery(viewStyleSetting):attr("procSetValue")
				,procCondition = procCondition
				,strength = strength
			})
			:link("elemType", elemType)
			:link("extension", extension)
			if isDependentFromChoiceItem == true then elStSet:link("choiceItem", choiceItem) end
			
			setExtraStyles(extension, viewStyleSetting, elStSet, "element")
			
			if lQuery(elemType):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDefaultStyle']"):is_empty() then
				lQuery.create("Translet", {extensionPoint = 'procNewElement', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDefaultStyle'})
				:link("type", elemType)
			end
			if lQuery(elemType):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.styleCode']"):is_empty() then
				lQuery.create("Translet", {extensionPoint = 'procCopied', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.styleCode'})
				:link("type", elemType)
			end
		elseif string.find(itemName, "end") ~= nil and addMirror == "true" then
				local elStSet = lQuery.create("ElementStyleSetting", {
					setting = itemName
					,value = lQuery(viewStyleSetting):attr("value")
					,procCondition = procCondition
					,procSetValue = lQuery(viewStyleSetting):attr("procSetValue")
					,strength = strength
				})
				:link("elemType", elemType)
				:link("extension", extension)
				if isDependentFromChoiceItem == true then elStSet:link("choiceItem", choiceItem) end
				
				setExtraStyles(extension, viewStyleSetting, elStSet, "element")
				
				local startStyle = string.sub(itemName, 4)
				itemName = "start" .. startStyle
				local elStSet = lQuery.create("ElementStyleSetting", {
					setting = itemName
					,value = lQuery(viewStyleSetting):attr("value")
					,procCondition = procCondition
					,procSetValue = lQuery(viewStyleSetting):attr("procSetValue")
					,strength = strength
				})
				:link("elemType", elemType)
				:link("extension", extension)
				if isDependentFromChoiceItem == true then elStSet:link("choiceItem", choiceItem) end
				
				setExtraStyles(extension, viewStyleSetting, elStSet, "element")
				
				if lQuery(elemType):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDefaultStyle']"):is_empty() then
					lQuery.create("Translet", {extensionPoint = 'procNewElement', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDefaultStyle'})
					:link("type", elemType)
				end
				if lQuery(elemType):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.styleCode']"):is_empty() then
					lQuery.create("Translet", {extensionPoint = 'procCopied', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.styleCode'})
					:link("type", elemType)
				end
		else
			local elStSet = lQuery.create("ElementStyleSetting", {
				setting = itemName
				,value = lQuery(viewStyleSetting):attr("value")
				,procCondition = procCondition
				,procSetValue = lQuery(viewStyleSetting):attr("procSetValue")
				,strength = strength
			})
			:link("elemType", elemType)
			:link("extension", extension)
			if isDependentFromChoiceItem == true then elStSet:link("choiceItem", choiceItem) end
			
			setExtraStyles(extension, viewStyleSetting, elStSet, "element")
			
			-- if itemName == "widthProc" then 
				-- elStSet:attr("procSetValue", "setAutoWidth") 
				-- elStSet:attr("setting", "width") 
			-- end
			
			if lQuery(elemType):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDefaultStyle']"):is_empty() then
				lQuery.create("Translet", {extensionPoint = 'procNewElement', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDefaultStyle'})
				:link("type", elemType)
			end
			if lQuery(elemType):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.styleCode']"):is_empty() then
				lQuery.create("Translet", {extensionPoint = 'procCopied', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.styleCode'})
				:link("type", elemType)
			end
		end
	else
		viewStyleSetting:delete()
	end
end

--atlasa skatijumus, kas ir piesaistiti diagramai un pieejamos stilus
function viewsInDiagram()
	report.event("StylePaletteWindow_AllViews", {
		GraphDiagramType = "OWL"
	})
	
	
	--atrast aktivo giagrammu
	local diagram = utilities.current_diagram()

	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.closeViewsInDiagram()")
  })
  
  local path
  if tda.isWeb then
		path = tda.FindPath(tda.GetToolPath() .. "/AllPlugins", "OWLGrEd_UserFields").. "/"
  else
		path = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_UserFields\\"
  end

  local form = lQuery.create("D#Form", {
    id = "ViewsInDiagram"
    ,caption = "Views in diagram"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = ok_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.closeViewsInDiagram()")
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
							component = {
								lQuery.create("D#Label",{caption = "Applied views"})
								,lQuery.create("D#ListBox",{
									id = "appliedViews"
									,item = getAppliedViews(diagram)
								})
							}
						})
						,lQuery.create("D#VerticalBox",{
							component = {
								lQuery.create("D#ImageButton",{
									fileName = path .. "up.bmp"
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.upView()")
								})
								,lQuery.create("D#ImageButton",{
									fileName = path .. "down.bmp"
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.downView()")
								})
							}
						})
						,lQuery.create("D#VerticalBox",{
							component = {
								lQuery.create("D#Button",{
									caption = "<-"
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.applyView()")
								})
								,lQuery.create("D#Button",{
									caption = "->"
									,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.deplyView()")
								})
							}
						})
						,lQuery.create("D#VerticalBox",{
							component = {
								lQuery.create("D#Label",{caption = "Available views"})
								,lQuery.create("D#ListBox",{
									id = "avaibleViews"
									,item = getAvaibleViews(diagram)
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

--atjauno vkatijumu sarakstus
function refreshListBox()
	local diagram = utilities.current_diagram()
	lQuery("D#ListBox[id = 'avaibleViews']/item"):delete()
	local itemsAvaible = getAvaibleViews(diagram)
	lQuery("D#ListBox[id = 'avaibleViews']"):link("item", itemsAvaible)
	lQuery("D#ListBox[id = 'avaibleViews']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	
	
	lQuery("D#ListBox[id = 'appliedViews']/item"):delete()
	local itemsApplied = getAppliedViews(diagram)
	lQuery("D#ListBox[id = 'appliedViews']"):link("item", itemsApplied)
	lQuery("D#ListBox[id = 'appliedViews']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	
end

--pacel skatijumu augstak
function upView()
	local diagram = utilities.current_diagram()
	
	utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})

	local viewId = lQuery("D#ListBox[id = 'appliedViews']/selected"):attr("id")
	local view 
	if lQuery("D#ListBox[id = 'appliedViews']/selected"):is_not_empty() then
		--atrast view exteision
		view = lQuery("Extension"):filter(
			function(obj)
				return lQuery(obj):id() == tonumber(viewId)
			end)
		
		--izveidot tabulu ar visiem viewiem
		local t = {}
		if lQuery(diagram):find("/activeExtension[type='aa#View']:has(/aa#owner[type='aa#Profile'])"):size() > 1 then
			lQuery(diagram):find("/activeExtension[type='aa#View']:has(/aa#owner[type='aa#Profile'])"):each(function(obj)
				table.insert(t, obj)
				obj:remove_link("graphDiagram", diagram)
			end)
		
			local up1
			local up2
			for i,v in pairs(t) do
				if i~=1 and v:id() == view:id() then
					local temp = t[i-1]
					up1=t[i-1]
					up2=v
					t[i-1]=v
					t[i]=temp
				end
			end
			for i,v in pairs(t) do
				v:link("graphDiagram", diagram)
			end
			--atjaunot skatijumu sarakstus
			refreshListBox(diagram)
			local l = 0
			local st1 = up1:find("/elementStyleSetting"):each(function(u1)
				up2:find("/elementStyleSetting"):each(function(u2)
					if u1:attr("setting")==u2:attr("setting") and u1:attr("value")~=u2:attr("value") then l = 1 end
				end)
			end)
			
			if l == 1 then 
			--pielietot skatijumu elemType stilus
				local el = lQuery(diagram):find("/element:has(/elemType/elementStyleSetting)"):filter(function(obj)
					local l = 0
					local ex = obj:find("/elemType/elementStyleSetting/extension"):each(function(ext)
						if ext:id() == view:id() then l =1 end
					end)
					return l == 1
				end)
				el:each(function(obj)
					owl_fields_specific.ElemStyleBySettings(obj, "ViewApply")
				end)
			end
			
			l = 0
			st1 = up1:find("/compartmentStyleSetting"):each(function(u1)
				up2:find("/compartmentStyleSetting"):each(function(u2)
					if u1:attr("setting")==u2:attr("setting") and u1:attr("value")~=u2:attr("value") then l = 1 end
				end)
			end)
			
			if l == 1 then 
			--pielietot skatijumu compartType stilus
				local values = lQuery(diagram):find("/element/compartment:has(/compartType/compartmentStyleSetting)")
				values:add(lQuery(diagram):find("/element/compartment/subCompartment:has(/compartType/compartmentStyleSetting)"))
				values:filter(function(obj)
					local l = 0
					local ex = obj:find("/compartType/compartmentStyleSetting/extension"):each(function(ext)
						if ext:id() == view:id() then l =1 end
					end)
					return l == 1
				end)
				values:each(function(obj)
					owl_fields_specific.CompartStyleBySetting(obj, "ViewApply")
				end)
			end
			if view:find("/compartmentStyleSetting[procCondition='setTextStyle']"):is_not_empty() then
				lQuery("Compartment:has(/compartType/compartmentStyleSetting[procCondition='setTextStyle'])"):each(function(obj)
					local element = findElement(obj)
					if element~= nil and diagram:id() == element:find("/graphDiagram"):id() then 
						core.make_compart_value_from_sub_comparts(obj)
						core.set_parent_value(obj)
					end
				end)
			end
			
			--atjaunojam tos elementus, kur bija compartmentu stila izmaina
			local elem = lQuery(diagram):find("/element:has(/compartment/compartType/compartmentStyleSetting)")
			elem:add(lQuery(diagram):find("/element:has(/compartment/subCompartment/compartType/compartmentStyleSetting)"))

			utilities.refresh_element(elem, diagram) 
			
			graph_diagram_style_utils.save_diagram_element_and_compartment_styles(diagram)
			
			deleteIsDeletedStyleSetting()
		end
	end
end

--nolaiz skatijumu zemak
function downView()
	local diagram = utilities.current_diagram()
	
	utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
	
	local viewId = lQuery("D#ListBox[id = 'appliedViews']/selected"):attr("id")
	local view
	if lQuery("D#ListBox[id = 'appliedViews']/selected"):is_not_empty() then
		--atrast view exteision
		view = lQuery("Extension"):filter(
			function(obj)
				return lQuery(obj):id() == tonumber(viewId)
			end)
		--izveidot tabulu ar visiem viewiem
		local t = {}
		if lQuery(diagram):find("/activeExtension[type='aa#View']:has(/aa#owner[type='aa#Profile'])"):size() > 1 then
			lQuery(diagram):find("/activeExtension[type='aa#View']:has(/aa#owner[type='aa#Profile'])"):each(function(obj)
				table.insert(t, obj)
				obj:remove_link("graphDiagram", diagram)
			end)
		
			local up1
			local up2
			for i,v in pairs(t) do
				if i~=#t and v:id() == view:id() then
					local temp = t[i+1]
					up1=t[i+1]
					up2=v
					t[i+1]=v
					t[i]=temp
					break
				end
			end
			for i,v in pairs(t) do
				v:link("graphDiagram", diagram)
			end
			--atjauno skatijumu sarakstus
			refreshListBox(diagram)
			local l = 0
			local st1 = up1:find("/elementStyleSetting"):each(function(u1)
				up2:find("/elementStyleSetting"):each(function(u2)
					if u1:attr("setting")==u2:attr("setting") and u1:attr("value")~=u2:attr("value") then l = 1 end
				end)
			end)

			if l == 1 then 
			--pielieto skatijuma ElemType stilus
				local el = lQuery(diagram):find("/element:has(/elemType/elementStyleSetting)"):filter(function(obj)
					local l = 0
					local ex = obj:find("/elemType/elementStyleSetting/extension"):each(function(ext)
						if ext:id() == view:id() then l =1 end
					end)
					return l == 1
				end)
				el:each(function(obj)
					owl_fields_specific.ElemStyleBySettings(obj, "ViewApply")
				end)
			end
					
			l = 0
			st1 = up1:find("/compartmentStyleSetting"):each(function(u1)
				up2:find("/compartmentStyleSetting"):each(function(u2)
					if u1:attr("setting")==u2:attr("setting") and u1:attr("value")~=u2:attr("value") then l = 1 end
				end)
			end)
				
			if l == 1 then 
			--pielieto skatijuma CompartType stilus
				local values = lQuery(diagram):find("/element/compartment:has(/compartType/compartmentStyleSetting)")
				values:add(lQuery(diagram):find("/element/compartment/subCompartment:has(/compartType/compartmentStyleSetting)"))
				values:filter(function(obj)
					local l = 0
					local ex = obj:find("/compartType/compartmentStyleSetting/extension"):each(function(ext)
						if ext:id() == view:id() then l =1 end
					end)
					return l == 1
				end)
				values:each(function(obj)
					owl_fields_specific.CompartStyleBySetting(obj, "ViewApply")
				end)
			end
			if view:find("/compartmentStyleSetting[procCondition='setTextStyle']"):is_not_empty() then
				lQuery("Compartment:has(/compartType/compartmentStyleSetting[procCondition='setTextStyle'])"):each(function(obj)
					local element = findElement(obj)
					if element~= nil and diagram:id() == element:find("/graphDiagram"):id() then 
						core.make_compart_value_from_sub_comparts(obj)
						core.set_parent_value(obj)
					end
				end)
			end
			--atjaunojam tos elementus, kur bija compartmentu stila izmaina
			local elem = lQuery(diagram):find("/element:has(/compartment/compartType/compartmentStyleSetting)")
			elem:add(lQuery(diagram):find("/element:has(/compartment/subCompartment/compartType/compartmentStyleSetting)"))
				
			utilities.refresh_element(elem, diagram) 
			
			graph_diagram_style_utils.save_diagram_element_and_compartment_styles(diagram)
			
			deleteIsDeletedStyleSetting()
		end
	end
end

function applyViewFromToolBar()
	-- tda.CallFunctionWithPleaseWaitWindow("OWLGrEd_UserFields.styleMechanism.applyViewFromToolBarProgressBar")
	applyViewFromToolBarProgressBar()
	local diagram = utilities.current_diagram()
	--configurator.make_toolbar(lQuery("GraphDiagramType[id=OWL]"))
	utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
end

function applyViewFromToolBarProgressBar()
	-- print("--------- START applyViewFromToolBarProgressBar")
	local viewName = lQuery("ToolbarElementSelectEvent/toolbarElement"):attr("caption")
	--local view = lQuery("Extension[id='PaletteViews']/aa#subExtension[id='CompactHorizontalView']")
	local viewV = lQuery("AA#View[name=" .. viewName .. "]")
	local view = lQuery("Extension[id='" .. viewName .. "'][type='aa#View']")
	
	local diagram = utilities.current_diagram()
	
	if diagram:find("/toolbar/toolbarElement:has(/type[id='" .. viewV:id() .. "'])"):attr("picture") == viewV:attr("inActiveIcon") then
		diagram:find("/toolbar/toolbarElement:has(/type[id='" .. viewV:id() .. "'])"):attr("picture", viewV:attr("activeIcon"))
	else
		diagram:find("/toolbar/toolbarElement:has(/type[id='" .. viewV:id() .. "'])"):attr("picture", viewV:attr("inActiveIcon"))
	end

	local dia = view:find("/graphDiagram"):filter(function(obj)
		return obj:id()==diagram:id()
	end)
	
	--[[local el = lQuery(diagram):find("/element:has(/elemType/elementStyleSetting)"):filter(function(obj)
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
	
	local numberOfSteps = el:size()
	numberOfSteps = numberOfSteps + values:size()--]]

	-- local progress_reporter = progress_reporter.create_progress_logger(numberOfSteps, "Recalculating styles...")
	
	if dia:is_empty() then 
		-- print("--------- APPLY VIEW")
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
	else
		-- print("--------- REMOVE VIEW")
		view:remove_link("graphDiagram", diagram)
		--ja nonemts noklusetais stils
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
	end
	
	if view:find("/compartmentStyleSetting[procCondition='setTextStyle']"):is_not_empty() then
		lQuery("Compartment:has(/compartType/compartmentStyleSetting[procCondition='setTextStyle'])"):each(function(obj)
			local element = findElement(obj)
			if element~= nil and diagram:id() == element:find("/graphDiagram"):id() then 
				core.make_compart_value_from_sub_comparts(obj)
				core.set_parent_value(obj)
			end
		end)
	end
	
	--atjaunojam tos elementus, kur bija stila izmaina
	local elem = lQuery(diagram):find("/element:has(/compartment/compartType/compartmentStyleSetting)")
	elem:add(lQuery(diagram):find("/element:has(/compartment/subCompartment/compartType/compartmentStyleSetting)"))
		
	utilities.refresh_element(elem, diagram) 
		
	local cmd = lQuery.create("OkCmd")
	cmd:link("graphDiagram", diagram)
	utilities.execute_cmd_obj(cmd)
	deleteIsDeletedStyleSetting()
	-- print("--------- deleteIsDeletedStyleSetting")

	graph_diagram_style_utils.save_diagram_element_and_compartment_styles(diagram)
	
	if view:find("/elementStyleSetting[setting='lineDirection']"):is_not_empty() then 
		require("lua_graphDiagram")
		lua_graphDiagram.SetDiagramAlignmentStyle(utilities.current_diagram():id(), 3)
	end
	-- print("--------- END applyViewFromToolBarProgressBar")
end

function applyView()
	-- tda.CallFunctionWithPleaseWaitWindow("OWLGrEd_UserFields.styleMechanism.applyViewProgressBar")
	applyViewProgressBar()
end

--pielieto skatijumu diagramai
function applyViewProgressBar()
	-- print(os.date("%m_%d_%Y_%H_%M_%S"))
	local diagram = utilities.current_diagram()
	utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})

	local viewId = lQuery("D#ListBox[id = 'avaibleViews']/selected"):attr("id")
	local view
	if lQuery("D#ListBox[id = 'avaibleViews']/selected"):is_not_empty() then

		--atrast view exteision
		view = lQuery("Extension"):filter(
			function(obj)
				return lQuery(obj):id() == tonumber(viewId)
			end)
		--izveidot saiti uz diagramu
		local diagram = utilities.current_diagram()
		--[[
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
		
		local numberOfSteps = el:size()
		numberOfSteps = numberOfSteps + values:size()
		--]]
		-- local progress_reporter = progress_reporter.create_progress_logger(numberOfSteps, "Recalculating styles...")
	

		if lQuery("AA#View[name='" .. view:attr("id") .. "']"):attr("isDefault") == "true" then view:remove_link("aa#graphDiagram", diagram) 
		else
			view:link("graphDiagram", diagram)
		end
	--end
		refreshListBox(diagram)
		--pielieto view
		if view~=nil and view:find("/elementStyleSetting"):is_not_empty() then
			local el = lQuery(diagram):find("/element:has(/elemType/elementStyleSetting)"):filter(function(obj)
				local l = 0
				local ex = obj:find("/elemType/elementStyleSetting/extension"):each(function(ext)
					if ext:id() == view:id() then l =1 end
				end)
				return l == 1
			end)

			el:each(function(obj)
				-- progress_reporter()
				-- print(obj:find("/elemType"):attr("id"), obj:find("/elemType"):id())
				owl_fields_specific.ElemStyleBySettings(obj, "ViewApply")
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
				-- progress_reporter()
				owl_fields_specific.CompartStyleBySetting(obj, "ViewApply")
			end)
		end
		
		if view:find("/compartmentStyleSetting[procCondition='setTextStyle']"):is_not_empty() then
			lQuery("Compartment:has(/compartType/compartmentStyleSetting[procCondition='setTextStyle'])"):each(function(obj)
				local element = findElement(obj)
				if element~= nil and diagram:id() == element:find("/graphDiagram"):id() then 
					core.make_compart_value_from_sub_comparts(obj)
					core.set_parent_value(obj)
				end
			end)
		end
		--atjaunojam tos elementus, kur bija stila izmaina
		local elem = lQuery(diagram):find("/element:has(/compartment/compartType/compartmentStyleSetting)")
		elem:add(lQuery(diagram):find("/element:has(/compartment/subCompartment/compartType/compartmentStyleSetting)"))
			
		utilities.refresh_element(elem, diagram) 
			
		local cmd = lQuery.create("OkCmd")
		cmd:link("graphDiagram", diagram)
		utilities.execute_cmd_obj(cmd)
		deleteIsDeletedStyleSetting()
		-- print(os.date("%m_%d_%Y_%H_%M_%S"))

		graph_diagram_style_utils.save_diagram_element_and_compartment_styles(diagram)
		
		local viewV = lQuery("AA#View[name='" .. view:attr("id") .. "']")
		if viewV:attr("showInToolBar")=="true" then
			--nomainit pogu uz pielietotu ikonu
			--lQuery("ToolbarElementType[id='" .. viewV:id() .. "']"):attr("picture", viewV:attr("activeIcon"))
			--configurator.make_toolbar(lQuery("GraphDiagramType[id=OWL]"))
			
			local diagram = utilities.current_diagram()
			diagram:find("/toolbar/toolbarElement:has(/type[id='" .. viewV:id() .. "'])"):attr("picture", viewV:attr("activeIcon"))
			
			if view:find("/elementStyleSetting[setting='lineDirection']"):is_not_empty() then 
				require("lua_graphDiagram")
				lua_graphDiagram.SetDiagramAlignmentStyle(utilities.current_diagram():id(), 3)
			end
			
			--utilities.execute_cmd("AfterConfigCmd", {graphDiagram = diagram})
		end
	end
end

function findElement(compartment)
	local element
	local l = 0
	while l == 0 do
		if compartment:find("/element"):is_not_empty() then
			element = compartment:find("/element")
			l=1
		else
			compartment = compartment:find("/parentCompartment")
			if compartment == nil then return nil end
		end
	end
	return element
end

function deplyView()
	-- tda.CallFunctionWithPleaseWaitWindow("OWLGrEd_UserFields.styleMechanism.deplyViewProgressBar")
	deplyViewProgressBar()
end

--nonem skatijumu no diagramas
function deplyViewProgressBar()
	-- print(os.date("%m_%d_%Y_%H_%M_%S"))
	local diagram = utilities.current_diagram()
	
	utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
	
	local viewId = lQuery("D#ListBox[id = 'appliedViews']/selected"):attr("id")
	local view
	if lQuery("D#ListBox[id = 'appliedViews']/selected"):is_not_empty() then
		--atrast view exteision
		view = lQuery("Extension"):filter(
			function(obj)
				return lQuery(obj):id() == tonumber(viewId)
			end)
		
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
		
		local numberOfSteps = el:size()
		numberOfSteps = numberOfSteps + values:size()
		
		-- local progress_reporter = progress_reporter.create_progress_logger(numberOfSteps, "Recalculating styles...")
		
		
		--izveidot saiti uz diagramu
		local diagram = utilities.current_diagram()
		view:remove_link("graphDiagram", diagram)
		
		--ja nonemts noklusetais stils
		if lQuery("AA#View[name='" .. view:attr("id") .. "']"):attr("isDefault") == "true" then view:link("aa#graphDiagram", diagram) end
	--end
		refreshListBox(diagram)

		--pielieto view
		if view~=nil and view:find("/elementStyleSetting"):is_not_empty() then
			local el = lQuery(diagram):find("/element:has(/elemType/elementStyleSetting)"):filter(function(obj)
				local l = 0
				local ex = obj:find("/elemType/elementStyleSetting/extension"):each(function(ext)
					if ext:id() == view:id() then l =1 end
				end)
				return l == 1
			end)
			el:each(function(obj)
				-- progress_reporter()
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
				-- progress_reporter()
				owl_fields_specific.CompartStyleBySetting(obj,"ViewRemove", view)
			end)
		end
		
		--atjaunojam tos elementus, kur bija stila izmaina
		local elem = lQuery(diagram):find("/element:has(/compartment/compartType/compartmentStyleSetting)")
		elem:add(lQuery(diagram):find("/element:has(/compartment/subCompartment/compartType/compartmentStyleSetting)"))
		
		if view:find("/compartmentStyleSetting[procCondition='setTextStyle']"):is_not_empty() then
			lQuery("Compartment:has(/compartType/compartmentStyleSetting[procCondition='setTextStyle'])"):each(function(obj)
				local element = findElement(obj)
				if element~= nil and diagram:id() == element:find("/graphDiagram"):id() then 
					core.make_compart_value_from_sub_comparts(obj)
					core.set_parent_value(obj)
				end
			end)
		end
		utilities.refresh_element(elem, diagram) 
		
		local cmd = lQuery.create("OkCmd")
		cmd:link("graphDiagram", diagram)
		utilities.execute_cmd_obj(cmd)
		deleteIsDeletedStyleSetting()

		graph_diagram_style_utils.save_diagram_element_and_compartment_styles(diagram)
		
		local viewV = lQuery("AA#View[name='" .. view:attr("id") .. "']")
		if viewV:attr("showInToolBar")=="true" then
			--nomainit pogu uz pielietotu ikonu
			--lQuery("ToolbarElementType[id='" .. viewV:id() .. "']"):attr("picture", viewV:attr("inActiveIcon"))
			--configurator.make_toolbar(lQuery("GraphDiagramType[id=OWL]"))
			
			local diagram = utilities.current_diagram()
			diagram:find("/toolbar/toolbarElement:has(/type[id='" .. viewV:id() .. "'])"):attr("picture", viewV:attr("inActiveIcon"))
			--utilities.execute_cmd("AfterConfigCmd", {graphDiagram = diagram})
			if view:find("/elementStyleSetting[setting='lineDirection']"):is_not_empty() then 
				require("lua_graphDiagram")
				lua_graphDiagram.SetDiagramAlignmentStyle(utilities.current_diagram():id(), 3)
			end
		end
	
	-- print(os.date("%m_%d_%Y_%H_%M_%S"))
	end
end

--atlasa piesaistitus diagramas skatijumus
function getAppliedViews(diagram)
	
	local values = lQuery("Extension[type='aa#View']:has(/aa#owner[type='aa#Profile'])"):map(
	  function(obj)
			local l = 0
			obj:find("/graphDiagram"):each(function(gd)
				if gd:id() ==diagram:id() then
					l=1
				end
			end)
			if l == 1 then
				return {obj:attr("id"), obj:find("/aa#owner"):attr("id"), obj:id()}
			end
		--	if lQuery("AA#View[name='" .. obj:attr("id") .. "']"):attr("isDefault")=="true" and diagram:find("/aa#notDefault"):is_empty() then 
			if lQuery("AA#View[name='" .. obj:attr("id") .. "']"):attr("isDefault")=="true" then 
				local l=0
				local diaWithView = obj:find("/aa#graphDiagram"):each(function(dia)
					if dia:id()==diagram:id() then l=1 end
				end)
				if l==0 then return {obj:attr("id"), obj:find("/aa#owner"):attr("id"), obj:id()} end
			end
	end)
	-- local defaultViews = lQuery("Extension"):map(function(obj)
		
	-- end)
	-- values = lQuery.merge(values, defaultViews)
	return lQuery.map(values, function(mode_value) 
		return lQuery.create("D#Item", {id = mode_value[3] ,value = mode_value[1] .. "(" .. mode_value[2] .. ")"})
	end)
end

--atlasa pieejamus skatijumus
function getAvaibleViews(diagram)
	local values = lQuery("Extension[type='aa#View']:has(/aa#owner[type='aa#Profile'])"):map(
	  function(obj)
			local l = 0
			obj:find("/graphDiagram"):each(function(gd)
				if gd:id() ==diagram:id() then
					l=1
				end
			end)
			
			--if l == 0 and lQuery("AA#View[name='" .. obj:attr("id") .. "']"):attr("isDefault")~="true" then
			if l == 0 and lQuery("AA#View[name='" .. obj:attr("id") .. "']"):attr("isDefault")~="true" then
				return {obj:attr("id"), obj:find("/aa#owner"):attr("id"), obj:id()}
			end
			--if lQuery("AA#View[name='" .. obj:attr("id") .. "']"):attr("isDefault")=="true" and diagram:find("/aa#notDefault"):is_not_empty() then 
			if lQuery("AA#View[name='" .. obj:attr("id") .. "']"):attr("isDefault")=="true" then 
				local l=0
				local diaWithView = obj:find("/aa#graphDiagram"):each(function(dia)
					if dia:id()==diagram:id() then l=1 end
				end)
				if l==1 then return {obj:attr("id"), obj:find("/aa#owner"):attr("id"), obj:id()} end
				--return {obj:attr("id"), obj:find("/aa#owner"):attr("id"), obj:id()}
			end
	end)

	return lQuery.map(values, function(mode_value) 
		return lQuery.create("D#Item", {id = mode_value[3] ,value = mode_value[1] .. "(" .. mode_value[2] .. ")"})
	end)
end

--izdzes vienu skatijuma stila instanci
function deleteOneViewStyle()
	local activeRow = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow")
	local id = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow/vTableCell:has(/vTableColumnType[caption='ElementType'])"):attr("id")
	local viewStyleSetting = lQuery("AA#ViewStyleSetting"):filter(
		function(obj)
			return lQuery(obj):id() == tonumber(id)
		end)
	if id ~= "" then
		viewStyleSetting:find("/customStyleSetting"):delete()
		viewStyleSetting:delete()
		--izdzest rindu, atjaunot tabulu
		lQuery(activeRow):delete()
		lQuery("D#VTable[id = 'TableViewStyle']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	end
end

--atlasa jau piesaistitus stilus (view-skatijums)
function getViewStyle(view)
	t = valuesTable()
	f = functionTable()
	local values = lQuery(view):find("/styleSetting"):map(
	  function(obj)
		local itemName
		local val = lQuery(obj):attr("value")
		--elemType stili
		if obj:attr("isElementStyleSetting") == 'true' then 
			itemName = obj:find("/elemStyleFeature"):attr("itemName")
			elemTypeId = lQuery("ElemType[caption='" .. obj:attr("elementTypeName") .. "']"):id()
			local nodeType = lQuery("NodeType"):filter(
				function(obj)
					return lQuery(obj):id() == elemTypeId
				end)
			local tt = t[itemName]
			local ft = f[itemName]
			if itemName == "picPos" or itemName == "picStyle" then tt = t[itemName .. "Node"]  end
			
			if itemName == "shapeCode" then
				if nodeType:is_not_empty() then tt = t[itemName .. "Box"] 
				else tt = t[itemName .. "Line"] end
			end
			
			if tt ~=nil or ft ~= nil then
				if tt ~= nil then
					for i,v in pairs(tt) do
						if tostring(v)==lQuery(obj):attr("value") then val = i end
					end
				end
				if ft ~= nil then
					for i,v in pairs(ft) do
						if tostring(v)==lQuery(obj):attr("procSetValue") then val = i end
					end
				end
			else val = lQuery(obj):attr("value")
			end
		--compartType stili
		else 
			itemName = obj:find("/fieldStyleFeature"):attr("itemName") 
			
			elemTypeId = lQuery("ElemType[caption='" .. obj:attr("elementTypeName") .. "']"):id()
			local nodeType = lQuery("NodeType"):filter(
				function(obj)
					return lQuery(obj):id() == elemTypeId
				end)
			local tt = t[itemName]
			local ft = f[itemName]
			if itemName == "picPos" or itemName == "picStyle" then tt = t[itemName .. "Com"] end
			  if itemName == "adornment" or itemName == "adjustment" then
				if nodeType:is_not_empty() then tt = t[itemName .. "Box"] 
				else tt = t[itemName .. "Line"] end
			end
			if tt ~=nil or ft ~= nil then
				if tt ~= nil then
					for i,v in pairs(tt) do
						if tostring(v)==lQuery(obj):attr("value") then val = i end
					end
				end
				if ft ~= nil then
					for i,v in pairs(ft) do
						if tostring(v)==lQuery(obj):attr("procSetValue") then val = i end
					end
				end
			else val = lQuery(obj):attr("value")
			end
		end
		return {obj:attr("elementTypeName"), obj:attr("path"), obj:attr("target"), itemName, val, obj:attr("addMirror"), lQuery(obj):id(), obj:attr("conditionCompartType"), obj:attr("conditionChoiceItem"), lQuery(obj):attr("value")}
	end)
	
	return lQuery.map(values, function(mode_value) 
		local value = mode_value[5]
		if string.find(mode_value[4],"Color")~=nil then value = mode_value[10] end
		return lQuery.create("D#VTableRow", {
			id = mode_value[7]
			,vTableCell = {
				 createVTableTextBox(mode_value[1], "ElementType", mode_value[7])
				,createVTableTextBox(mode_value[2], "Path")
				,createVTableTextBox(mode_value[3], "Compartment")
				,createVTableTextBox(mode_value[4], "ItemName")
				,createVTableTextBox(value, "Value")
				,createVTableTextBox(mode_value[8], "ConditionCompartType")
				,createVTableTextBox(mode_value[9], "ConditionChoiceItem")
				,createVTableTextBox(mode_value[6], "AddMirror")
				--,createVTableTextBox("", "Extra")
				,lQuery.create("D#VTableCell", { value = ""
					,id = mode_value[7]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Extra']")
					,component = {lQuery.create("D#Button", {
						caption = "..."
						,id = mode_value[7]
						,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.extraStyle()")
					})}
				})
			}
		})
	end)
end

--izveido tabulas rindas sunu ar teksta lauku
function createVTableTextBox(value, caption, id)
	return lQuery.create("D#VTableCell", { value = value
			,id = id
			,vTableColumnType = lQuery("D#VTableColumnType[caption = '" .. caption .. "']")
			,component = lQuery.create("D#TextBox", {
				text = value
			})
		   })
end

--ieraksta stila elementa tipu un atlasa iespejamos stilus
function selectElementType()
	local selectedItem = lQuery("D#ListBox[id='ListWithViews']/selected")
	local viewName
	if selectedItem:attr("value") == nil then viewName = lQuery("D#InputField[id='InputFieldForNewView']"):attr("text")
	else
		local viewSize = string.find(selectedItem:attr("value"), " ")
		viewName = selectedItem:attr("value")
		if viewSize~=nil then viewName = string.sub(viewName, 1, viewSize-1) end
	end
	local elemTypeValue = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow/activeCell"):attr("value")
	-- local eType = lQuery("ElemType[id='" .. elemTypeValue .. "']")
	local eType = lQuery("ElemType"):filter(function(et) return et:id() == tonumber(lQuery("D#VTable[id = 'TableViewStyle']/selectedRow/activeCell/selectedItem"):attr("id")) end)
	-- print("TTTTTTTTTTTT", lQuery("D#VTable[id = 'TableViewStyle']/selectedRow/activeCell"):attr("value"), lQuery("D#VTable[id = 'TableViewStyle']/selectedRow/activeCell/selectedItem"):attr("id"))
	-- print(eType:size(), eType:id())
	if eType:is_not_empty() then
		local elemTypeId = eType:id()
		--izveido stila instanci
		local viewStyleSetting = lQuery.create("AA#ViewStyleSetting", {elementTypeName=elemTypeValue, elementTypeId = elemTypeId, isElementStyleSetting=true}):link("view", lQuery("AA#View[name='" .. viewName .. "']"))
		
		--noskaidro vai elemType ir Node vai Edge
		local elemType
		local nodeType = lQuery("NodeType"):filter(
			function(obj)
				return lQuery(obj):id() == tonumber(elemTypeId)
			end)
		if nodeType:is_not_empty() then elemType = "NodeType" else elemType = "EdgeType" end
		
		--pielasa iespejamos stilus
		local row = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow")
		row:attr("id", viewStyleSetting:id())
		lQuery(row):find("/vTableCell"):delete()
			createVTableTextBox(elemTypeValue, "ElementType", viewStyleSetting:id()):link("vTableRow", row)
			createVTableTextBox("", "Path", viewStyleSetting:id()):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ""
				,id = viewStyleSetting:id()
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'CompartType']")
				,component = lQuery.create("D#Button", {
					id = elemTypeId .. " " .. lQuery(viewStyleSetting):id()--elementa instances id + AA#ViewStyleItem id
					,caption = "set compartType"
					,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.generateTree()")
				})
			}):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ""
				,id = viewStyleSetting:id()
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'StyleItem']")
				,component = {lQuery.create("D#ComboBox", {
					text = ""
					,item = {getElementStyleItem(elemType)}
					,id = lQuery(viewStyleSetting):id()--view instances id
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectElementStyleItem()")}
				})}
			}):link("vTableRow", row)	
			createVTableTextBox(activeCell, "Value", viewStyleSetting:id()):link("vTableRow", row)
			--createVTableTextBox("", "ConditionCompartType", viewStyleSetting:id()):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = viewStyleSetting:attr("conditionCompartType")
				,id = viewStyleSetting:id()
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'ConditionCompartType']")
				,component = {lQuery.create("D#ComboBox", {
					text = viewStyleSetting:attr("conditionCompartType")
					,item = {getConditionElemType(eType)}
					,id = lQuery(viewStyleSetting):id()--view instances id
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectConditionCompartType()")}
				})}
			}):link("vTableRow", row)
			--createVTableTextBox("", "ConditionChoiceItem", viewStyleSetting:id()):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = viewStyleSetting:attr("conditionChoiceItem")
				,id = viewStyleSetting:id()
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'ConditionChoiceItem']")
				,component = {lQuery.create("D#ComboBox", {
					text = viewStyleSetting:attr("conditionChoiceItem")
					,item = {getConditionChoiceItem(viewStyleSetting)}
					,id = lQuery(viewStyleSetting):id()--view instances id
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectConditionChoiceItem()")}
				})}
			}):link("vTableRow", row)
			generateAddMirrorCell(viewStyleSetting):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ""
				,id = viewStyleSetting:id()
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Extra']")
				,component = {lQuery.create("D#Button", {
					caption = "..."
					,id = viewStyleSetting:id()
					,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.extraStyle()")
				})}
			}):link("vTableRow", row)

		lQuery("D#VTable[id = 'TableViewStyle']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	end
end

--atlasa AddMirror sunas vertibu
function selectAddMirror()
	local activeCell = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow/activeCell")--aktiva suna
	local comID = lQuery(activeCell):find("/component"):attr("id")--componentes id
	local styleSetting
	local field = lQuery("AA#ViewStyleSetting"):each(function(obj)
		if obj:id() == tonumber(comID) then 
			styleSetting = obj
			return
		end end)
	local checked = activeCell:attr("value")
	styleSetting:attr("addMirror", checked)
end

--genere koku ar visiem dota ElemType CompartType-iem
function generateTree()
	local activeCell = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow/activeCell")--aktiva suna
	local comID = lQuery(activeCell):find("/component"):attr("id")--componentes id
	local space = string.find(comID, " ")
	local comID = string.sub(comID, 1, space-1)
	local elementType -- vajadziga AA#FieldStyleSetting instance
	local field = lQuery("ElemType"):each(function(obj)
		if obj:id() == tonumber(comID) then 
			elementType = obj
			return
		end end)
	
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.closeTree()")
  })
  
  local ok_button = lQuery.create("D#Button", {
    caption = "Ok"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.OkTree()")
  })

  local form = lQuery.create("D#Form", {
    id = "CompartmentTree"
    ,caption = "Select compartment"
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
							id = "treeCompartment",maximumWidth = 250,minimumWidth = 250,maximumHeight = 600,minimumHeight = 600
							,treeNode = lQuery.create("D#TreeNode", {
								text = elementType:attr("caption")
								,id = elementType:id()
								,childNode = createChildNode(elementType)
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
		  lQuery.create("D#VerticalBox", {id = "buttonsView"}) 
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

--ieraksta skatijuma stilu tabula celu un compartType
function OkTree()
	--atrast compartmetType
	local compartTypeId = lQuery("D#Tree[id='treeCompartment']/selected"):attr("id")
	local compartType = lQuery("CompartType"):filter(
		function(obj)
			return lQuery(obj):id() == tonumber(compartTypeId)
		end)
	if compartType:is_not_empty() then
	
	local activeCell = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow/activeCell")--aktiva suna
	local comID = lQuery(activeCell):find("/component"):attr("id")--componentes id
	local space = string.find(comID, " ")
	local viewStyleId = string.sub(comID, space+1)

	local viewStyle = lQuery("AA#ViewStyleSetting"):filter(
		function(obj)
			return lQuery(obj):id() == tonumber(viewStyleId)
		end)

	local node = lQuery("D#Tree[id='treeCompartment']/selected"):attr("text")
	
	viewStyle:attr("target", node)--ierakstam ViewStyleSetting instance targetu
	viewStyle:attr("isElementStyleSetting", false)--ierakstam ViewStyleSetting instance targetu
	
	--atrast celu
	
	--atrast celu lidz elementam
	local path = ""
	local l = 0
	local compartTypeT = compartType
	
		while l==0 do
			if compartTypeT:find("/elemType"):is_empty() then 
				local pat = lpeg.P("ASFictitious")
				if  not lpeg.match(pat, compartTypeT:find("/parentCompartType"):attr("id")) then path = compartTypeT:find("/parentCompartType"):attr("caption")  .. "/" .. path end
				compartTypeT = compartTypeT:find("/parentCompartType")
			else l=1 end
		end

		viewStyle:attr("path", path)--ierakstam ViewStyleSetting instance path
		
		--atjaunot sunas
		--atrast kas tika izvelets
		local activeCell = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow/activeCell"):attr("value")
		
		--noskaisrojam vai dotais ElemType ir no Node vai Edge
		local nodeType = lQuery("NodeType"):filter(
			function(obj)
				return lQuery(obj):id() == compartTypeT:find("/elemType"):id()
			end)
		local elemType
		if nodeType:is_not_empty() then elemType = "NodeType" else elemType = "EdgeType" end
		
		local f = lQuery("CompartType[isGroup = true]"):size()
		
		--noskaidrojam vai dota instance ir stilizejama
		if compartType:find("/elemType"):is_not_empty() or compartType:find("/parentCompartType"):attr("isGroup") == 'true' then 
			elemType = elemType
		else elemType = "NotStyleable" end
		local row = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow")
		
		--pielasam jaunas vertibas
		lQuery(row):find("/vTableCell"):delete()
		createVTableTextBox(viewStyle:attr("elementTypeName"), "ElementType", viewStyle:id()):link("vTableRow", row)
		createVTableTextBox(viewStyle:attr("path"), "Path", viewStyle:id()):link("vTableRow", row)
		createVTableTextBox(viewStyle:attr("target"), "CompartType", viewStyle:id()):link("vTableRow", row)
		lQuery.create("D#VTableCell", { value = ""
			,id = viewStyle:id()
			,vTableColumnType = lQuery("D#VTableColumnType[caption = 'StyleItem']")
			,component = {lQuery.create("D#ComboBox", {
				text = ""
				,item = {getCompartmentStyleItem(elemType)}
				,id = lQuery(viewStyle):id()--view instances id
				,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectCompartStyleItem()")}
			})}
		}):link("vTableRow", row)
		createVTableTextBox("", "Value", viewStyle:id()):link("vTableRow", row)
		lQuery.create("D#VTableCell", { value = viewStyle:attr("conditionCompartType")
			,id = viewStyle:id()
			,vTableColumnType = lQuery("D#VTableColumnType[caption = 'ConditionCompartType']")
			,component = {lQuery.create("D#ComboBox", {
				text = viewStyle:attr("conditionCompartType")
				,item = {getConditionCompartType(viewStyle)}
				,id = lQuery(viewStyle):id()--view instances id
				,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectConditionCompartType()")}
			})}
		}):link("vTableRow", row)
		lQuery.create("D#VTableCell", { value = viewStyle:attr("conditionChoiceItem")
			,id = viewStyle:id()
			,vTableColumnType = lQuery("D#VTableColumnType[caption = 'ConditionChoiceItem']")
			,component = {lQuery.create("D#ComboBox", {
				text = viewStyle:attr("conditionChoiceItem")
				,item = {getConditionChoiceItem(viewStyle)}
				,id = lQuery(viewStyle):id()--view instances id
				,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectConditionChoiceItem()")}
			})}
		}):link("vTableRow", row)
		generateAddMirrorCell(viewStyle):link("vTableRow", row)
		lQuery.create("D#VTableCell", { value = ""
			,id = viewStyle:id()
			,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Extra']")
			,component = {lQuery.create("D#Button", {
				caption = "..."
				,id = viewStyle:id()
				,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.extraStyle()")
			})}
		}):link("vTableRow", row)
		lQuery("D#VTable[id = 'TableViewStyle']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	end
	lQuery("D#Event"):delete()
	utilities.close_form("CompartmentTree")
	
end

--atlasa kokam pirma limena lapas (elementType-elementa tips, kuram ir jaatrod compartTypi)
function createChildNode(elementType)
	local values = elementType:find("/compartType"):map(
	  function(obj, i)
		local pat = lpeg.P("ASFictitious")
		if lpeg.match(pat, lQuery(obj):attr("id")) then 
			return {obj:find("/subCompartType"):attr("caption"), lQuery(obj):id(), obj:find("/subCompartType")}
		else
			return {lQuery(obj):attr("caption"), lQuery(obj):id(), obj}
		end
	  end)
	
	return lQuery.map(values, function(mode_value) 
		return lQuery.create("D#TreeNode", {
			text = mode_value[1]
			,id = mode_value[2]
			,childNode = createSubChildNode(mode_value[3])
			,expanded = true
		}) 
	end)
end

--atlasa kokam zemaka limena lapas (compartType-kompartmenta tips, kuram ir jaatrod apaks CompartType)
function createSubChildNode(compartType)

	local values = compartType:find("/subCompartType"):map(
	  function(obj, i)
		local pat = lpeg.P("ASFictitious")
		if lpeg.match(pat, lQuery(obj):attr("id")) then 
			return {obj:find("/subCompartType"):attr("caption"), lQuery(obj):id(), obj:find("/subCompartType")}
		else
			return {lQuery(obj):attr("caption"), lQuery(obj):id(), obj}
		end
	  end)
	
	return lQuery.map(values, function(mode_value) 
		return lQuery.create("D#TreeNode", {
			text = mode_value[1]
			,childNode = createSubChildNode(mode_value[3])
			,id = mode_value[2]
			,expanded = true
		}) 
	end)
end

--atlasa visus elementa tipus
function getElementType()
	local values = lQuery("ElemType:has(/graphDiagramType[id='OWL'])"):map(
	  function(obj, i)
		return {lQuery(obj):attr("id"), lQuery(obj):id()}
	  end)
	return lQuery.map(values, function(mode_value) 
		return lQuery.create("D#Item", {
			value = mode_value[1]
			,id = mode_value[2]
		}) 
	end)
end

--atver logu ar krasam prieks ElemType stiliem
function selectElementValuesColor()
--atrast aktivo shunu
--atrast tas componentes id
--atrrast AA#ViewStyleSetting instsnci
--ierakstit value = aktivas sunas vertiba
	local activeCell = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow/activeCell")--aktiva suna
	local comID = lQuery(activeCell):find("/component"):attr("id")--componentes id
	local styleSetting
	local field = lQuery("AA#ViewStyleSetting"):each(function(obj)
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

--nomaina ElemType Stila vertibu
function selectElementValues()--ja maina filda vertibu
	local activeCell = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow/activeCell")--aktiva suna
	local comID = lQuery(activeCell):find("/component"):attr("id")--componentes id
	local styleSetting 
	local field = lQuery("AA#ViewStyleSetting"):each(function(obj)
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
	
	local f = functionTable()
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

--ieraksta choiceItem, no ka ir atkariga stila instance 
function selectConditionChoiceItem()
		
	local activeCell = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow/activeCell")--aktiva suna
	local comID = lQuery(activeCell):find("/component"):attr("id")--componentes id
	local styleSetting -- vajadziga AA#FieldStyleSetting instance
	local field = lQuery("AA#ViewStyleSetting"):each(function(obj)
		if obj:id() == tonumber(comID) then 
			styleSetting = obj
			return
		end end)
		
	local value = lQuery(activeCell):attr("value")

	lQuery(styleSetting):attr("conditionChoiceItem", value)
	
end

--ieraksta compartType, no ka ir atkariga stila instance
function selectConditionCompartType()
	local activeCell = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow/activeCell")--aktiva suna
	local comID = lQuery(activeCell):find("/component"):attr("id")--componentes id
	local styleSetting -- vajadziga AA#FieldStyleSetting instance
	local field = lQuery("AA#ViewStyleSetting"):each(function(obj)
		if obj:id() == tonumber(comID) then 
			styleSetting = obj
			return
		end end)
		
	local value = lQuery(activeCell):attr("value")
	
	lQuery(styleSetting):attr("conditionCompartType", value)
	local compartType
	local elemTypeName = styleSetting:attr("elementTypeName")
	local elemType = lQuery("ElemType[caption='" .. elemTypeName .."']")
		
	if string.find(value, "/")==nil then
		local path = styleSetting:attr("path")
		local pathTable = split(path, "/")
		--ja compartType id dzili
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
			compartType = compartType:find("/subCompartType[caption='" .. value .. "']")
		else--ja ir pirma limenja lauks
			compartType = elemType:find("/compartType[caption='" .. value .. "']")
		end
		if compartType:is_not_empty() then 
			local row = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow")
			local conChoiceItemComponent = row:find("/vTableCell:has(/vTableColumnType[caption='ConditionChoiceItem'])/component")
			row:find("/vTableCell:has(/vTableColumnType[caption='ConditionChoiceItem'])/component/item"):delete()
			conChoiceItemComponent:link("item", {getConditionChoiceItem(styleSetting, compartType)})
			if conChoiceItemComponent:find("/item"):is_not_empty() then
				lQuery("D#VTable[id = 'TableViewStyle']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
			end
		end
	else
		local path = value
		local pathTable = split(path, "/")
		--ja compartType id dzili
		--print(dumptable(pathTable))
		if #pathTable ~= 1 then
			compartType = elemType:find("/compartType[caption='" .. pathTable[1] .. "']")
			--print()
			local pat = lpeg.P("ASFictitious")
			if lpeg.match(pat, compartType:attr("id")) then 
				compartType = compartType:find("/subCompartType[caption='" .. pathTable[1] .. "']")
			end
			for i=2,#pathTable,1 do 
				if pathTable[i] ~= "" then 
					compartType = compartType:find("/subCompartType[caption='" .. pathTable[i] .. "']")
					if compartType:is_not_empty() and lpeg.match(pat, compartType:attr("id")) then 
						compartType = compartType:find("/subCompartType[caption='" .. pathTable[i] .. "']")
					end
				end
			end
			--compartType = compartType:find("/subCompartType[caption='" .. value .. "']")
		else--ja ir pirma limenja lauks
			compartType = elemType:find("/compartType[caption='" .. value .. "']")
		end
		if compartType:is_not_empty() then 
			local row = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow")
			local conChoiceItemComponent = row:find("/vTableCell:has(/vTableColumnType[caption='ConditionChoiceItem'])/component")
			row:find("/vTableCell:has(/vTableColumnType[caption='ConditionChoiceItem'])/component/item"):delete()
			row:find("/vTableCell:has(/vTableColumnType[caption='ConditionChoiceItem'])"):attr("value", "")
			local cci = getConditionChoiceItem(styleSetting, compartType)
			--if cci:is_empty() then print("FFFFFFFFFFFFFFFFFFF") end
			conChoiceItemComponent:link("item", {cci})
			conChoiceItemComponent:attr("text", "")
			if conChoiceItemComponent:find("/item"):is_not_empty() then
			lQuery("D#VTable[id = 'TableViewStyle']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	
			end
		end
	end
end

--atlasa compartType iespejamus stilus
function selectCompartStyleItem()
	local o = lQuery("D#VTable[id = 'TableViewStyle']/vTableRow[id != '']"):last()
	--atrast kas tika izvelets
	local activeCell = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow/activeCell")--aktiva suna

	local comID = lQuery("D#VTable[id = 'TableViewStyle']/vTableRow[id != '']"):last():attr("id")--componentes id

	local ViewStyleSetting = lQuery("AA#ViewStyleSetting"):filter(
		function(obj)
			return lQuery(obj):id() == tonumber(comID)
		end)

	t = valuesTable()
	f = functionTable()
	local activeCell = lQuery("D#VTable[id = 'TableViewStyle']/vTableRow[id = '".. comID .. "']/vTableCell:has(/vTableColumnType[caption='StyleItem'])"):attr("value")
		
	local elemStyleItem = lQuery("AA#CompartStyleItem[itemName='" .. activeCell .. "']")
	if elemStyleItem:is_not_empty() then 
		ViewStyleSetting:link("fieldStyleFeature", elemStyleItem)
		
		local tt = t[activeCell]
		local ft = f[activeCell]
		
		local elemTypeId = lQuery("ElemType[caption='" .. ViewStyleSetting:attr("elementTypeName") .. "']"):id()
		local nodeType = lQuery("NodeType"):filter(
			function(obj)
				return lQuery(obj):id() == elemTypeId
			end)

		if activeCell == "picPos" or activeCell == "picStyle" then tt = t[activeCell .. "Com"] end
		  if activeCell == "adornment" or activeCell == "adjustment" then
			if nodeType:is_not_empty() then tt = t[activeCell .. "Box"]
			else tt = t[activeCell .. "Line"] end
		end
		-----------------
		local elemType = lQuery("ElemType[id='".. ViewStyleSetting:attr("elementTypeName") .. "']")
		local l = 0
		local target = ViewStyleSetting:attr("target")
		local path = ViewStyleSetting:attr("path")
		local pathTable = split(path, "/")
		local addMirror = ViewStyleSetting:attr("addMirror")
		local compartType
		
		local pat2 = lpeg.P("(")
		pat2 = anywhere(pat2)
		--caur celu atrodam vajadzigo CompartType instanci
		--ja lauks nav zem pirma limena lauka
		if #pathTable ~= 1 then
			compartType = elemType:find("/compartType[caption='" .. pathTable[1] .. "']")
			if compartType:is_empty() then compartType = elemType:find("/compartType[caption='ASFictitious" .. pathTable[1] .. "']") end
			local pat = lpeg.P("ASFictitious")
			if lpeg.match(pat, compartType:attr("id")) then 
				compartType = compartType:find("/subCompartType[caption='" .. pathTable[1] .. "']")
			end
			for i=2,#pathTable,1 do 
				if pathTable[i] ~= "" then 
					local compartType2 = compartType:find("/subCompartType[caption='" .. pathTable[i] .. "']")
					if compartType2:is_empty() then compartType = compartType:find("/subCompartType[caption='ASFictitious" .. pathTable[i] .. "']")
					else compartType = compartType2 end
					if lpeg.match(pat, compartType:attr("id")) then 
						compartType = compartType:find("/subCompartType[caption='" .. pathTable[i] .. "']")
					end
				end
			end
			local compartType2 = compartType:find("/subCompartType[caption='" .. target .. "']")
			if compartType2:is_empty() then compartType = compartType:find("/subCompartType[caption='ASFictitious" .. target .. "']")
			else compartType = compartType2 end
		else
			compartType = elemType:find("/compartType[caption='" .. target .. "']")
		end
		if activeCell=="isVisible" and (compartType:find("/elemType"):is_empty() and compartType:find("/parentCompartType"):attr("isGroup")~="true") then
			tt = t["isVisibleHidden"]
		end
		------------------		
		if string.find(activeCell, "Color")~=nil then--ja ir krasas stils
			local row = lQuery("D#VTable[id = 'TableViewStyle']/vTableRow[id = '".. comID .. "']")
			lQuery(row):find("/vTableCell"):delete()
			createVTableTextBox(ViewStyleSetting:attr("elementTypeName"), "ElementType", ViewStyleSetting:id()):link("vTableRow", row)
			createVTableTextBox(ViewStyleSetting:attr("path"), "Path"):link("vTableRow", row)
			createVTableTextBox(ViewStyleSetting:attr("target"), "CompartType"):link("vTableRow", row)
			createVTableTextBox(activeCell, "StyleItem"):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ""
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
				,component = {lQuery.create("D#Button", {
					caption = ""
					,id = lQuery(ViewStyleSetting):id()
					,eventHandler = {utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectElementValuesColor()")}
				})}
			}):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ViewStyleSetting:attr("conditionCompartType")
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'ConditionCompartType']")
				,component = {lQuery.create("D#ComboBox", {
					text = ViewStyleSetting:attr("conditionCompartType")
					,item = {getConditionCompartType(ViewStyleSetting)}
					,id = lQuery(ViewStyleSetting):id()--view instances id
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectConditionCompartType()")}
				})}
			}):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ViewStyleSetting:attr("conditionChoiceItem")
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'ConditionChoiceItem']")
				,component = {lQuery.create("D#ComboBox", {
					text = ViewStyleSetting:attr("conditionChoiceItem")
					,item = {getConditionChoiceItem(ViewStyleSetting)}
					,id = lQuery(ViewStyleSetting):id()--view instances id
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectConditionChoiceItem()")}
				})}
			}):link("vTableRow", row)
			generateAddMirrorCell(ViewStyleSetting):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ""
				,id = ViewStyleSetting:id()
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Extra']")
				,component = {lQuery.create("D#Button", {
					caption = "..."
					,id = ViewStyleSetting:id()
					,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.extraStyle()")
				})}
			}):link("vTableRow", row)
		elseif tt ~= nil or ft ~= nil then --ja stilam ir vertibu izveles iespejas
			--izveidot comboBox
			local values = {}
			if tt~= nil then
				for i,v in pairs(tt) do
					local g = {i, v}
					table.insert(values, g)
				end
			end
			if ft~= nil then
				for i,v in pairs(ft) do
					local g = {i, v}
					table.insert(values, g)
				end
			end
			table.sort(values, function(x,y) return x[1] < y[1] end)
			local row = lQuery("D#VTable[id = 'TableViewStyle']/vTableRow[id = '".. comID .. "']")
			lQuery(row):find("/vTableCell"):delete()
			createVTableTextBox(ViewStyleSetting:attr("elementTypeName"), "ElementType", ViewStyleSetting:id()):link("vTableRow", row)
			createVTableTextBox(ViewStyleSetting:attr("path"), "Path"):link("vTableRow", row)
			createVTableTextBox(ViewStyleSetting:attr("target"), "CompartType"):link("vTableRow", row)
			createVTableTextBox(activeCell, "StyleItem"):link("vTableRow", row)
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
					,id = lQuery(ViewStyleSetting):id()
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectElementValues()")}
				})}
				}):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ViewStyleSetting:attr("conditionCompartType")
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'ConditionCompartType']")
				,component = {lQuery.create("D#ComboBox", {
					text = ViewStyleSetting:attr("conditionCompartType")
					,item = {getConditionCompartType(ViewStyleSetting)}
					,id = lQuery(ViewStyleSetting):id()--view instances id
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectConditionCompartType()")}
				})}
			}):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ViewStyleSetting:attr("conditionChoiceItem")
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'ConditionChoiceItem']")
				,component = {lQuery.create("D#ComboBox", {
					text = ViewStyleSetting:attr("conditionChoiceItem")
					,item = {getConditionChoiceItem(ViewStyleSetting)}
					,id = lQuery(ViewStyleSetting):id()--view instances id
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectConditionChoiceItem()")}
				})}
			}):link("vTableRow", row)
			generateAddMirrorCell(ViewStyleSetting):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ""
				,id = ViewStyleSetting:id()
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Extra']")
				,component = {lQuery.create("D#Button", {
					caption = "..."
					,id = ViewStyleSetting:id()
					,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.extraStyle()")
				})}
			}):link("vTableRow", row)
		else--ja stilam nav vertibu izveles iespeju
			local row = lQuery("D#VTable[id = 'TableViewStyle']/vTableRow[id = '".. comID .. "']")
			lQuery(row):find("/vTableCell"):delete()
			createVTableTextBox(ViewStyleSetting:attr("elementTypeName"), "ElementType", ViewStyleSetting:id()):link("vTableRow", row)
			createVTableTextBox(ViewStyleSetting:attr("path"), "Path"):link("vTableRow", row)
			createVTableTextBox(ViewStyleSetting:attr("target"), "CompartType"):link("vTableRow", row)
			createVTableTextBox(activeCell, "StyleItem"):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ""
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
				,component = {lQuery.create("D#TextBox", {
					text = ""
					,id = lQuery(ViewStyleSetting):id()
					,eventHandler = {	utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectElementValues()")}
				})}
			}):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ViewStyleSetting:attr("conditionCompartType")
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'ConditionCompartType']")
				,component = {lQuery.create("D#ComboBox", {
					text = ViewStyleSetting:attr("conditionCompartType")
					,item = {getConditionCompartType(ViewStyleSetting)}
					,id = lQuery(ViewStyleSetting):id()--view instances id
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectConditionCompartType()")}
				})}
			}):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ViewStyleSetting:attr("conditionChoiceItem")
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'ConditionChoiceItem']")
				,component = {lQuery.create("D#ComboBox", {
					text = ViewStyleSetting:attr("conditionChoiceItem")
					,item = {getConditionChoiceItem(ViewStyleSetting)}
					,id = lQuery(ViewStyleSetting):id()--view instances id
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectConditionChoiceItem()")}
				})}
			}):link("vTableRow", row)
			generateAddMirrorCell(ViewStyleSetting):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ""
				,id = ViewStyleSetting:id()
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Extra']")
				,component = {lQuery.create("D#Button", {
					caption = "..."
					,id = ViewStyleSetting:id()
					,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.extraStyle()")
				})}
			}):link("vTableRow", row)
		end
		lQuery("D#VTable[id = 'TableViewStyle']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))	
	end
end	  

--atlasa ElemType iespejamus stilus	  
function selectElementStyleItem()
	t = valuesTable()
	f = functionTable()
	--atrast kas tika izvelets
	local activeCell = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow/activeCell"):attr("value")
	
	local elemStyleItem = lQuery("AA#ElemStyleItem[itemName='" .. activeCell .. "']")--vajadziga elemStyleItem instance
	if elemStyleItem:is_not_empty() then 
		local comID = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow/activeCell/component"):attr("id")--componentes id
		local ViewStyleSetting
		local field = lQuery("AA#ViewStyleSetting"):each(function(obj)
			if obj:id() == tonumber(comID) then 
				ViewStyleSetting = obj
				return
			end end)
			
		ViewStyleSetting:link("elemStyleFeature", elemStyleItem)

		local elemTypeValue = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow/vTableCell:has(/vTableColumnType[caption='ElementType'])"):attr("value")
		local tt = t[activeCell]
		local ft = f[activeCell]
		if activeCell == "picPos" or activeCell == "picStyle" then tt = t[activeCell .. "Node"]  end
		
		--noskaidrojam vai ElemType ir no Node vai Edge
		local elemTypeId = lQuery("ElemType[caption='" .. ViewStyleSetting:attr("elementTypeName") .. "']"):id()
		local nodeType = lQuery("NodeType"):filter(
			function(obj)
				return lQuery(obj):id() == elemTypeId
			end)

		if activeCell == "shapeCode" then
			if nodeType:is_not_empty() then tt = t[activeCell .. "Box"] 
			else tt = t[activeCell .. "Line"] end
		end
		
		if string.find(activeCell, "Color")~=nil then--ja krasas stils
			local row = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow")
			lQuery(row):find("/vTableCell"):delete()
			createVTableTextBox(ViewStyleSetting:attr("elementTypeName"), "ElementType", ViewStyleSetting:id()):link("vTableRow", row)
			createVTableTextBox("", "Path"):link("vTableRow", row)
			createVTableTextBox("", "CompartType"):link("vTableRow", row)
			createVTableTextBox(activeCell, "StyleItem"):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ""
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
				,component = {lQuery.create("D#Button", {
					caption = ""
					,id = lQuery(ViewStyleSetting):id()
					,eventHandler = {utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectElementValuesColor()")}
				})}
			}):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ViewStyleSetting:attr("conditionCompartType")
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'ConditionCompartType']")
				,component = {lQuery.create("D#ComboBox", {
					text = ViewStyleSetting:attr("conditionCompartType")
					,item = {getConditionElemType(lQuery("ElemType[caption='" .. ViewStyleSetting:attr("elementTypeName") .. "']"))}
					,id = lQuery(ViewStyleSetting):id()--view instances id
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectConditionCompartType()")}
				})}
			}):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ViewStyleSetting:attr("conditionChoiceItem")
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'ConditionChoiceItem']")
				,component = {lQuery.create("D#ComboBox", {
					text = ViewStyleSetting:attr("conditionChoiceItem")
					,item = {getConditionChoiceItem(ViewStyleSetting)}
					,id = lQuery(ViewStyleSetting):id()--view instances id
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectConditionChoiceItem()")}
				})}
			}):link("vTableRow", row)
			generateAddMirrorCell(ViewStyleSetting):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ""
				,id = ViewStyleSetting:id()
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Extra']")
				,component = {lQuery.create("D#Button", {
					caption = "..."
					,id = ViewStyleSetting:id()
					,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.extraStyle()")
				})}
			}):link("vTableRow", row)
		elseif tt ~= nil or ft ~= nil then --ja stilam ir vertibu izveles iespeju
			--izveidot comboBox
			local values = {}
			if tt~= nil then
				for i,v in pairs(tt) do
					local g = {i, v}
					table.insert(values, g)
				end
			end
			if ft~= nil then
				for i,v in pairs(ft) do
					local g = {i, v}
					table.insert(values, g)
				end
			end
			
			table.sort(values, function(x,y) return x[1] < y[1] end)
			local row = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow")

			lQuery(row):find("/vTableCell"):delete()
			createVTableTextBox(ViewStyleSetting:attr("elementTypeName"), "ElementType", ViewStyleSetting:id()):link("vTableRow", row)
			createVTableTextBox("", "Path"):link("vTableRow", row)
			createVTableTextBox("", "CompartType"):link("vTableRow", row)
			createVTableTextBox(activeCell, "StyleItem"):link("vTableRow", row)
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
					,id = lQuery(ViewStyleSetting):id()
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectElementValues()")}
				})}
			}):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ViewStyleSetting:attr("conditionCompartType")
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'ConditionCompartType']")
				,component = {lQuery.create("D#ComboBox", {
					text = ViewStyleSetting:attr("conditionCompartType")
					,item = {getConditionElemType(lQuery("ElemType[caption='" .. ViewStyleSetting:attr("elementTypeName") .. "']"))}
					,id = lQuery(ViewStyleSetting):id()--view instances id
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectConditionCompartType()")}
				})}
			}):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ViewStyleSetting:attr("conditionChoiceItem")
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'ConditionChoiceItem']")
				,component = {lQuery.create("D#ComboBox", {
					text = ViewStyleSetting:attr("conditionChoiceItem")
					,item = {getConditionChoiceItem(ViewStyleSetting)}
					,id = lQuery(ViewStyleSetting):id()--view instances id
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectConditionChoiceItem()")}
				})}
			}):link("vTableRow", row)
			generateAddMirrorCell(ViewStyleSetting):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ""
				,id = ViewStyleSetting:id()
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Extra']")
				,component = {lQuery.create("D#Button", {
					caption = "..."
					,id = ViewStyleSetting:id()
					,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.extraStyle()")
				})}
			}):link("vTableRow", row)
		else--ja stilam nav vertibu izveles iespeju
			local row = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow")
			lQuery(row):find("/vTableCell"):delete()
			createVTableTextBox(ViewStyleSetting:attr("elementTypeName"), "ElementType", ViewStyleSetting:id()):link("vTableRow", row)
			createVTableTextBox("", "Path"):link("vTableRow", row)
			createVTableTextBox("", "CompartType"):link("vTableRow", row)
			createVTableTextBox(activeCell, "StyleItem"):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ""
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Value']")
				,component = {lQuery.create("D#TextBox", {
					text = ""
					,id = lQuery(ViewStyleSetting):id()
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectElementValues()")}
				})}
			}):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ViewStyleSetting:attr("conditionCompartType")
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'ConditionCompartType']")
				,component = {lQuery.create("D#ComboBox", {
					text = ViewStyleSetting:attr("conditionCompartType")
					,item = {getConditionElemType(lQuery("ElemType[caption='" .. ViewStyleSetting:attr("elementTypeName") .. "']"))}
					,id = lQuery(ViewStyleSetting):id()--view instances id
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectConditionCompartType()")}
				})}
			}):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ViewStyleSetting:attr("conditionChoiceItem")
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'ConditionChoiceItem']")
				,component = {lQuery.create("D#ComboBox", {
					text = ViewStyleSetting:attr("conditionChoiceItem")
					,item = {getConditionChoiceItem(ViewStyleSetting)}
					,id = lQuery(ViewStyleSetting):id()--view instances id
					,eventHandler = {utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectConditionChoiceItem()")}
				})}
			}):link("vTableRow", row)
			generateAddMirrorCell(ViewStyleSetting):link("vTableRow", row)
			lQuery.create("D#VTableCell", { value = ""
				,id = ViewStyleSetting:id()
				,vTableColumnType = lQuery("D#VTableColumnType[caption = 'Extra']")
				,component = {lQuery.create("D#Button", {
					caption = "..."
					,id = ViewStyleSetting:id()
					,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.extraStyle()")
				})}
			}):link("vTableRow", row)
		end
		lQuery("D#VTable[id = 'TableViewStyle']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	end
end

--atlasa dota ContextType choiceItemus
function getConditionChoiceItem(viewStyle, compartType)
	local values
	if viewStyle:attr("conditionCompartType") ~= "" then
		if 	compartType~=nil then
			values = lQuery(compartType):find("/choiceItem"):map(
				  function(obj, i)
					return {lQuery(obj):attr("value"), lQuery(obj):id()}
				  end)
		else
			local elemTypeName = viewStyle:attr("elementTypeName")
			local elemType = lQuery("ElemType[caption='" .. elemTypeName .."']")
			local conditionCompartType = viewStyle:attr("conditionCompartType")
			local path = viewStyle:attr("path")
			local pathTable = split(path, "/")
			--ja compartType id dzili
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
				compartType = compartType:find("/subCompartType[caption='" .. conditionCompartType .. "']")
				
				values = lQuery(compartType):find("/choiceItem"):map(
				  function(obj, i)
					return {lQuery(obj):attr("value"), lQuery(obj):id()}
				  end)
			else--ja ir pirma limenja lauks
				compartType = elemType:find("/compartType[caption='" .. conditionCompartType .. "']")
				 values = lQuery(compartType):find("/choiceItem"):map(
				  function(obj, i)
					return {lQuery(obj):attr("value"), lQuery(obj):id()}
				  end)
			end
		end
		return lQuery.map(values, function(item_value) 
			return lQuery.create("D#Item", {
				value = item_value[1]
				,id = item_value[2]
			}) 
		end)
	end
end

function anywhere (p)
  return lpeg.P{ p + 1 * lpeg.V(1) }
end

function getConditionElemType(elemType)
	local com = elemType:find("/compartType")
	local comTable = {}
	com:each(function(obj)
		if obj:find("/choiceItem"):is_not_empty() then 
			local path = ""
			local l = 0
			local compartTypeT = obj
							
			while l==0 do
				if compartTypeT:find("/elemType"):is_empty() then 
					local pat = lpeg.P("ASFictitious")
					if  not lpeg.match(pat, compartTypeT:find("/parentCompartType"):attr("id")) then path = compartTypeT:find("/parentCompartType"):attr("caption")  .. "/" .. path end
					compartTypeT = compartTypeT:find("/parentCompartType")
				else l=1 end
			end
			table.insert(comTable, {path .. lQuery(obj):attr("caption") .. "/", lQuery(obj):id()}) 
		end
		comTable = subTypes(obj:find("/subCompartType"), comTable)
	end)

	local values = comTable

	return lQuery.map(values, function(item_value) 
		return lQuery.create("D#Item", {
			value = item_value[1]
			,id = item_value[2]
		}) 
	end)
end

--atlasa CompartType instances (kurien ir CHoiceItemi) no vajadziga limena
function getConditionCompartType(viewStyle)
	local compartTypeName = viewStyle:attr("target")
	local elemTypeName = viewStyle:attr("elementTypeName")
	local elemType = lQuery("ElemType[caption='" .. elemTypeName .."']")
	--jaatrod compartType zem elemType
	local path = viewStyle:attr("path")
	local pathTable = split(path, "/")
	local compartType
	local values
	if compartTypeName ~= "" then 	
		if #pathTable ~= 1 then
			compartType = elemType:find("/compartType[caption='" .. pathTable[1] .. "']")
			if compartType:is_empty() then compartType = elemType:find("/compartType[caption='ASFictitious" .. pathTable[1] .. "']") end
			local pat = lpeg.P("ASFictitious")
			if lpeg.match(pat, compartType:attr("id")) then 
				compartType = compartType:find("/subCompartType[caption='" .. pathTable[1] .. "']")
			end
			for i=2,#pathTable,1 do 
				if pathTable[i] ~= "" then 
					local compartType2 = compartType:find("/subCompartType[caption='" .. pathTable[i] .. "']")
					if compartType2:is_empty() then compartType:find("/subCompartType[caption='ASFictitious" .. pathTable[i] .. "']")
					else
						compartType=compartType2
					end
					local pat = lpeg.P("(")
					pat = anywhere(pat)
					
					if lpeg.match(pat, pathTable[i])~= nil then 
						pathTable[i] = string.sub(pathTable[i], 1, lpeg.match(pat, pathTable[i])-2)
					end
					if lpeg.match(pat, compartType:attr("id")) then 
						compartType = compartType:find("/subCompartType[caption='" .. pathTable[i] .. "']")
					end
				end
			end
			local pat = lpeg.P("ASFictitious")

			values = lQuery(compartType):find("/subCompartType"):filter(
				function(obj)
					return lQuery(obj):find("/choiceItem"):size() ~= 0
				end)
				
				
			local com = elemType:find("/compartType")
			local comTable = {}
			com:each(function(obj)
				if obj:find("/choiceItem"):is_not_empty() then 
					local path = ""
					local l = 0
					local compartTypeT = obj
							
					while l==0 do
						if compartTypeT:find("/elemType"):is_empty() then 
							local pat = lpeg.P("ASFictitious")
							if  not lpeg.match(pat, compartTypeT:find("/parentCompartType"):attr("id")) then path = compartTypeT:find("/parentCompartType"):attr("caption")  .. "/" .. path end
							compartTypeT = compartTypeT:find("/parentCompartType")
						else l=1 end
					end
					table.insert(comTable, {path .. lQuery(obj):attr("caption") .. "/", lQuery(obj):id()}) 
				end
				comTable = subTypes(obj:find("/subCompartType"), comTable)
			end)
	
			values = values:map(
			  function(obj, i)
				return {lQuery(obj):attr("caption"), lQuery(obj):id()}
			  end)
			values = lQuery.merge(values, comTable)
		else--ja ir pirma limenja lauks
			compartType = elemType:find("/compartType[caption='" .. compartTypeName .. "']")
			if compartType:is_empty() then compartType = elemType:find("/compartType[caption='ASFictitious" .. compartTypeName .. "']") end
			local pat = lpeg.P("ASFictitious")
			if lpeg.match(pat, compartType:attr("id")) then 
				compartType = compartType:find("/subCompartType[caption='" .. compartTypeName .. "']")
			end
			values = lQuery(elemType):find("/compartType"):filter(
				function(obj)
					return lQuery(obj):find("/choiceItem"):size() ~= 0
				end)
			values = values:map(
			  function(obj, i)
				return {lQuery(obj):attr("caption"), lQuery(obj):id()}
			  end)
			 
			 
			local com = elemType:find("/compartType/subCompartType")
			local comTable = {}
			com:each(function(obj)
				if obj:find("/choiceItem"):is_not_empty() then 
					local path = ""
					local l = 0
					local compartTypeT = obj
							
					while l==0 do
						if compartTypeT:find("/elemType"):is_empty() then 
							local pat = lpeg.P("ASFictitious")
							if  not lpeg.match(pat, compartTypeT:find("/parentCompartType"):attr("id")) then path = compartTypeT:find("/parentCompartType"):attr("caption")  .. "/" .. path end
							compartTypeT = compartTypeT:find("/parentCompartType")
						else l=1 end
					end
					table.insert(comTable, {path .. lQuery(obj):attr("caption") .. "/", lQuery(obj):id()}) 
				end
				comTable = subTypes(obj:find("/subCompartType"), comTable)
			end)
			values = lQuery.merge(values, comTable)
		end
		return lQuery.map(values, function(item_value) 
			return lQuery.create("D#Item", {
				value = item_value[1]
				,id = item_value[2]
			}) 
		end)
	end
end

function subTypes(com, comTable)
	com:each(function(obj)
		
		
		if obj:find("/choiceItem"):is_not_empty() then 
		    local path = ""
			local l = 0
			local compartTypeT = obj
					
			while l==0 do
				if compartTypeT:find("/elemType"):is_empty() then 
					local pat = lpeg.P("ASFictitious")
					if  not lpeg.match(pat, compartTypeT:find("/parentCompartType"):attr("id")) then path = compartTypeT:find("/parentCompartType"):attr("caption")  .. "/" .. path end
					compartTypeT = compartTypeT:find("/parentCompartType")
				else l=1 end
			end
		    table.insert(comTable, {path .. lQuery(obj):attr("caption") .. "/", lQuery(obj):id()}) 
		end
		comTable = subTypes(obj:find("/subCompartType"), comTable)
	end)
	return comTable
end

--???
function getCompartmentStyleItem(ElemType)
	local values
	if ElemType == "NodeType" then 
	values = lQuery("AA#CompartStyleItem[forNodeCompart = 1]"):map(
	  function(obj, i)
		return {lQuery(obj):attr("itemName"), lQuery(obj):id()}
	  end)
	elseif ElemType == "EdgeType" then 
	values = lQuery("AA#CompartStyleItem[forEdgeCompart = 1]"):map(
	  function(obj, i)
		return {lQuery(obj):attr("itemName"), lQuery(obj):id()}
	  end)
	
	elseif ElemType == "NotStyleable" then 
	values = lQuery("AA#CompartStyleItem[forAttribCompart = 1]"):map(
	  function(obj, i)
		return {lQuery(obj):attr("itemName"), lQuery(obj):id()}
	  end)
	end
	return lQuery.map(values, function(item_value) 
		return lQuery.create("D#Item", {
			value = item_value[1]
			,id = item_value[2]
		}) 
	end)
end

--???
function getElementStyleItem(ElemType)
	local values1
	if ElemType == "NodeType" then 
	values1 = lQuery("AA#NodeStyleItem"):map(
	  function(obj, i)
		return {lQuery(obj):attr("itemName"), lQuery(obj):id()}
	  end)
	elseif ElemType == "EdgeType" then 
	values1 = lQuery("AA#EdgeStyleItem"):map(
	  function(obj, i)
		return {lQuery(obj):attr("itemName"), lQuery(obj):id()}
	  end)
	end
	local values2 = lQuery("AA#AnyElemStyleItem"):map(
		  function(obj, i)
			return {lQuery(obj):attr("itemName"), lQuery(obj):id()}
		  end)
	values = lQuery.merge(values2, values1)
	return lQuery.map(values, function(item_value) 
		return lQuery.create("D#Item", {
			value = item_value[1]
			,id = item_value[2]
		}) 
	end)
end

--parvers skaitli binarajaa pierakstaa
function toBin(num)
	local bin = {}
	num = math.floor(num)
	repeat
	table.insert(bin, num%2)
	num = math.floor(num/2)
	until num == 0
	return table.concat(bin):reverse()
end

--izveido AddMirror skatijumu tabulas sunu
function generateAddMirrorCell(viewStyle)
	local activeRow = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow")
	local elemTypeId = viewStyle:attr("elementTypeName")
	local elemType = lQuery("ElemType[caption='" .. elemTypeId .. "']")
	local styleItem	= viewStyle:find("/elemStyleFeature"):attr("itemName")
	local target = viewStyle:attr("target")
	
	if styleItem == nil then styleItem = "" end
	local compartType
	-- atrast compartType
	local path = viewStyle:attr("path")
	local pathTable = split(path, "/")
	if #pathTable ~= 1 then
		compartType = elemType:find("/compartType[caption='" .. pathTable[1] .. "']")
		if compartType:is_empty() then compartType = elemType:find("/compartType[caption='ASFictitious" .. pathTable[1] .. "']") end
		local pat = lpeg.P("ASFictitious")
		if lpeg.match(pat, compartType:attr("id")) then 
			compartType = compartType:find("/subCompartType[caption='" .. pathTable[1] .. "']")
		end
		for i=2,#pathTable,1 do 
			if pathTable[i] ~= "" then 
				local compartType2 = compartType:find("/subCompartType[caption='" .. pathTable[i] .. "']")
				if compartType2:is_empty() then compartType = compartType:find("/subCompartType[caption='ASFictitious" .. pathTable[i] .. "']") else
				    compartType =compartType2
				end
				if lpeg.match(pat, compartType:attr("id")) then 
					compartType = compartType:find("/subCompartType[caption='" .. pathTable[i] .. "']")
				end
			end
		end
		compartType = compartType:find("/subCompartType[caption='" .. target .. "']")
	else--ja ir pirma limenja lauks
		compartType = elemType:find("/compartType[caption='" .. target .. "']")
	end
	
	if (string.find(styleItem, "start") ~= nil or string.find(styleItem, "end") ~= nil) and elemTypeId == "Association" then 
		return lQuery.create("D#VTableCell", { value = viewStyle:attr("addMirror")
			,vTableColumnType = lQuery("D#VTableColumnType[caption = 'AddMirror']")
			,component = lQuery.create("D#CheckBox", {
				id = lQuery(viewStyle):id()
				,checked = viewStyle:attr("addMirror")
				,editable = "true"
				,eventHandler = {
					utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectAddMirror()")
				}
			})
		})
	elseif compartType:find("/aa#mirror"):is_not_empty() or compartType:find("/aa#mirrorInv"):is_not_empty() then
		return lQuery.create("D#VTableCell", {viewStyle:attr("addMirror")
			,vTableColumnType = lQuery("D#VTableColumnType[caption = 'AddMirror']")
			,component = lQuery.create("D#CheckBox", {
				id = lQuery(viewStyle):id()
				,checked = viewStyle:attr("addMirror")
				,editable = "true"
				,eventHandler = {
					utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.selectAddMirror()")
				}
			})
		})
	else
		return lQuery.create("D#VTableCell", { value = ''
			,vTableColumnType = lQuery("D#VTableColumnType[caption = 'AddMirror']")
			,component = lQuery.create("D#TextBox", {
				id = lQuery(viewStyle):id()
				,text = ''
			})
		})
	end
	
	local id = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow/vTableCell:has(/vTableColumnType[caption='ElementType'])"):attr("id")
end

--atgriez tabulu ar stilu funkcijam
function functionTable()
	tableValues = {}
	tableValues["width"] = {["(Dynamic 110-220-330)"] = "setAutoWidth"}
--	tableValues["textDirection"] = {["(Left)"]="jjjjjjjjjj"}
	return tableValues
end


function extraStyle()
	local close_button = lQuery.create("D#Button", {
		caption = "Close"
		,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.closeExtraStyle()")
	  })
	  
	  local form = lQuery.create("D#Form", {
		id = "ExtraStyle"
		,caption = "Extra style setting"
		,buttonClickOnClose = false
		,cancelButton = close_button
		,defaultButton = close_button
		,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.closeExtraStyle()")
		,component = {
			lQuery.create("D#VerticalBox", {
				id = "TableExtraStyle"
				,minimumHeight = 250
				,component = {
					lQuery.create("D#VTable", {
						id = "ExtraStyleTable"
						,column = {
							lQuery.create("D#VTableColumnType", {
								caption = "DependsOnElemType",editable = true,width = 100
							})
							,lQuery.create("D#VTableColumnType", {
								caption = "DependsOnCompartType",editable = true,width = 100
							})
							,lQuery.create("D#VTableColumnType", {
								caption = "ParameterName",editable = true,width = 100
							})
							,lQuery.create("D#VTableColumnType", {
								caption = "ParameterValue",editable = true,width = 100
							})
						}
						,vTableRow = {
							getViewExtraStyle()
						}
					})
					,lQuery.create("D#HorizontalBox", {
						component={
						lQuery.create("D#Button", {
							caption = "Create New Style Dependency"
							,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.createNewStyleDependency()")
						})
						,lQuery.create("D#Button", {
							caption = "Delete Style Dependency"
							,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.deleteStyleDependency()")
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

function getDependsOnElemTypeItem()
	local elemTypeValue = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow/vTableCell:has(/vTableColumnType[caption='ElementType'])"):attr("value")
	local eType = lQuery("ElemType[id='" .. elemTypeValue .. "']")

	local values = eType
	values = values:add(eType:find("/eStart"))
	values = values:add(eType:find("/eEnd"))
	values = values:add(eType:find("/end"))
	values = values:add(eType:find("/start"))
	values = values:unique()
	
	local values = values:map(function(value)
		return {value:attr("id"), value:id()}
	end)

	return lQuery.map(values, function(value) 
		return lQuery.create("D#Item", {id = value[2] ,value = value[1]})
	end)
end


function createNewStyleDependency()
	--pievieno tukso rindu
		lQuery.create("D#VTableRow", {
			vTableCell = {
				lQuery.create("D#VTableCell", { value = ""
					--,id = mode_value[7]
					,vTableColumnType = lQuery("D#VTableColumnType[caption = 'DependsOnElemType']")
					,component = {lQuery.create("D#ComboBox", {
						text = ""
						,item = {getDependsOnElemTypeItem()}
						--,id = mode_value[7]
						,eventHandler = utilities.d_handler("Change", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.dependentElemTypeCompartTypes()")
					})}
				})
				--createVTableTextBox("", "DependsOnElemType")
				,createVTableTextBox("", "DependsOnCompartType")
				,createVTableTextBox("", "ParameterName")
				,createVTableTextBox("", "ParameterValue")
			}
		}):link("vTable", lQuery("D#VTable[id = 'ExtraStyleTable']"))
		lQuery("D#VTable[id = 'ExtraStyleTable']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

function dependentElemTypeCompartTypes()
	local row = lQuery("D#VTable[id = 'ExtraStyleTable']/selectedRow")
	--row:attr("id", viewStyleSetting:id())
	local dependsOnElemTypeValue = row:find("/vTableCell:has(/vTableColumnType[caption='DependsOnElemType'])"):attr("value")
	lQuery(row):find("/vTableCell"):delete()
	lQuery.create("D#VTableCell", { value = dependsOnElemTypeValue
		--,id = viewStyleSetting:id()
		,vTableColumnType = lQuery("D#VTableColumnType[caption = 'DependsOnElemType']")
		,component = lQuery.create("D#InputField", {text = dependsOnElemTypeValue})
	}):link("vTableRow", row)
	lQuery.create("D#VTableCell", { value = ""
		--,id = viewStyleSetting:id()
		,vTableColumnType = lQuery("D#VTableColumnType[caption = 'DependsOnCompartType']")
		,component = lQuery.create("D#Button", {
			--id = elemTypeId .. " " .. lQuery(viewStyleSetting):id()--elementa instances id + AA#ViewStyleItem id
			caption = "set compartType"
			,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.generateDependentTree()")
		})
	}):link("vTableRow", row)
	createVTableTextBox("", "ParameterName"):link("vTableRow", row)
	createVTableTextBox("", "ParameterValue"):link("vTableRow", row)
	lQuery("D#VTable[id = 'ExtraStyleTable']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
end

--genere koku ar visiem dota ElemType CompartType-iem
function generateDependentTree()
	local row = lQuery("D#VTable[id = 'ExtraStyleTable']/selectedRow")--aktiva suna
	local dependsOnElemTypeValue = row:find("/vTableCell:has(/vTableColumnType[caption='DependsOnElemType'])"):attr("value")
	local elementType = lQuery("ElemType[id='" .. dependsOnElemTypeValue .. "']")
	
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.closeTree()")
  })
  
  local ok_button = lQuery.create("D#Button", {
    caption = "Ok"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_UserFields.styleMechanism.OkTreeDependent()")
  })

  local form = lQuery.create("D#Form", {
    id = "CompartmentTree"
    ,caption = "Select compartment"
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
							id = "treeCompartment",maximumWidth = 250,minimumWidth = 250,maximumHeight = 600,minimumHeight = 600
							,treeNode = lQuery.create("D#TreeNode", {
								text = elementType:attr("caption")
								,id = elementType:id()
								,childNode = createChildNode(elementType)
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

--ieraksta skatijuma stilu tabula celu un compartType
function OkTreeDependent()
	--atrast compartmetType
	local compartTypeId = lQuery("D#Tree[id='treeCompartment']/selected"):attr("id")
	local compartType = lQuery("CompartType"):filter(
		function(obj)
			return lQuery(obj):id() == tonumber(compartTypeId)
		end)
	if compartType:is_not_empty() then

	local node = lQuery("D#Tree[id='treeCompartment']/selected"):attr("text")

	--atrast celu lidz elementam
	local path = ""
	local l = 0
	local compartTypeT = compartType
	
		while l==0 do
			if compartTypeT:find("/elemType"):is_empty() then 
				local pat = lpeg.P("ASFictitious")
				if  not lpeg.match(pat, compartTypeT:find("/parentCompartType"):attr("id")) then path = compartTypeT:find("/parentCompartType"):attr("caption")  .. "/" .. path end
				compartTypeT = compartTypeT:find("/parentCompartType")
			else l=1 end
		end
		
		--noskaisrojam vai dotais ElemType ir no Node vai Edge
		local nodeType = lQuery("NodeType"):filter(
			function(obj)
				return lQuery(obj):id() == compartTypeT:find("/elemType"):id()
			end)
		local elemType
		if nodeType:is_not_empty() then elemType = "NodeType" else elemType = "EdgeType" end
		
		--local f = lQuery("CompartType[isGroup = true]"):size()
		
		--noskaidrojam vai dota instance ir stilizejama
		if compartType:find("/elemType"):is_not_empty() or compartType:find("/parentCompartType"):attr("isGroup") == 'true' then 
			elemType = elemType
		else elemType = "NotStyleable" end
		local row = lQuery("D#VTable[id = 'ExtraStyleTable']/selectedRow")
		local dependsOnElemTypeValue = row:find("/vTableCell:has(/vTableColumnType[caption='DependsOnElemType'])"):attr("value")
		--pielasam jaunas vertibas
		lQuery(row):find("/vTableCell"):delete()
		createVTableTextBox(dependsOnElemTypeValue, "DependsOnElemType"):link("vTableRow", row)
		createVTableTextBox(path .. node, "DependsOnCompartType"):link("vTableRow", row)
		--createVTableTextBox("", "ParameterName"):link("vTableRow", row)
		
		lQuery.create("D#VTableCell", { value = ""
			--,id = viewStyleSetting:id()
			,vTableColumnType = lQuery("D#VTableColumnType[caption = 'ParameterName']")
			,component = lQuery.create("D#ComboBox", {
				item = {getParameterName()}
			})
		}):link("vTableRow", row)
		
		createVTableTextBox("", "ParameterValue"):link("vTableRow", row)
		
		lQuery("D#VTable[id = 'ExtraStyleTable']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	end
	lQuery("D#Event"):delete()
	utilities.close_form("CompartmentTree")
end

function getParameterName()
	local values = {"value", "input", "procCondition"}
	return lQuery.map(values, function(value) 
		return lQuery.create("D#Item", {value = value})
	end)
end

function deleteStyleDependency()
	local activeRow = lQuery("D#VTable[id = 'ExtraStyleTable']/selectedRow")
	local id = lQuery("D#VTable[id = 'ExtraStyleTable']/selectedRow"):attr("id")
	local customStyleSetting = lQuery("AA#CustomStyleSetting"):filter(
		function(obj)
			return lQuery(obj):id() == tonumber(id)
		end)
	if id ~= "" then
		customStyleSetting:delete()
		--izdzest rindu, atjaunot tabulu
		lQuery(activeRow):delete()
		lQuery("D#VTable[id = 'ExtraStyleTable']"):link("command", utilities.enqued_cmd("D#Command", {info = "Refresh"}))
	end
end

function getViewExtraStyle()
	local activeCell = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow/activeCell")--aktiva suna
	local viewStyleId = lQuery(activeCell):find("/component"):attr("id")--componentes id
	local viewStyle = lQuery("AA#ViewStyleSetting"):filter(
		function(obj)
			return lQuery(obj):id() == tonumber(viewStyleId)
		end)
	local values = lQuery(viewStyle):find("/customStyleSetting"):map(function(view)
		return {view:attr("elementTypeName"), view:attr("compartTypeName"), view:attr("parameterName"), view:attr("parameterValue"), view:id()}
	end)
		return lQuery.map(values, function(value) 
			return lQuery.create("D#VTableRow", {
				id = value[5]
				,vTableCell = {
					 createVTableTextBox(value[1], "DependsOnElemType")
					,createVTableTextBox(value[2], "DependsOnCompartType")
					,createVTableTextBox(value[3], "ParameterName")
					,createVTableTextBox(value[4], "ParameterValue")
				}
			})
		end)
end

function setExtraStyles(extension, viewStyleSetting, styleSetting, settingType)
	viewStyleSetting:find("/customStyleSetting"):each(function(customStyle)
		local elemType = lQuery("ElemType[id='" .. customStyle:attr("elementTypeName") .. "']")
		if elemType:is_not_empty() then
			local compartType = findCompartType(customStyle:attr("compartTypeName"), elemType)
			
			--ja CompartType tika atrasts veidojam skatijuma stilu instances
			if compartType:size() ~= 0 then
				styleSetting:link("dependsOnCompartType", compartType)
				local styleType = "Elem"
				if settingType == "compartment" then styleType = "Compart" end
				styleSetting:attr("procCondition", "set" .. styleType .. "StyleByExtraStyle")
				styleSetting:attr("strength", 10)
				
				if customStyle:attr("parameterName") == "procCondition" then
					styleSetting:attr("procCondition", customStyle:attr("parameterValue"))
				end
				
				if lQuery(compartType):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDependentStyle']"):is_empty() then
					lQuery.create("Translet", {extensionPoint = 'procFieldEntered', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDependentStyle'})
					:link("type", compartType)
				end
				
				lQuery.create("SettingTag", {tagName = customStyle:attr("parameterName"), tagValue = customStyle:attr("parameterValue")})
					:link(settingType .. "StyleSetting", styleSetting)
					:link("ref", compartType)
			else
				lQuery.create("SettingTag", {tagName = customStyle:attr("parameterName"), tagValue = customStyle:attr("parameterValue")})
					:link(settingType .. "StyleSetting", styleSetting)
				-- customStyle:delete()
			end
		end
	end)
end

function findCompartType(path, elemType)
	local pathTable = split(path, "/")
	local compartType
	local pat2 = lpeg.P("(")
	pat2 = anywhere(pat2)
	--caur celu atrodam vajadzigo CompartType instanci
	--ja lauks nav zem pirma limena lauka
	if #pathTable ~= 1 then
		compartType = elemType:find("/compartType[caption='" .. pathTable[1] .. "']")
		if compartType:is_empty() then compartType = elemType:find("/compartType[caption='ASFictitious" .. pathTable[1] .. "']") end
		local pat = lpeg.P("ASFictitious")
		if lpeg.match(pat, compartType:attr("id")) then 
			compartType = compartType:find("/subCompartType[caption='" .. pathTable[1] .. "']")
		end
		for i=2,#pathTable,1 do 
			if pathTable[i] ~= "" then 
				local compartType2 = compartType:find("/subCompartType[caption='" .. pathTable[i] .. "']")
				if compartType2:is_empty() then compartType = compartType:find("/subCompartType[caption='ASFictitious" .. pathTable[i] .. "']")
				else compartType = compartType2 end
				if lpeg.match(pat, compartType:attr("id")) then 
					compartType = compartType:find("/subCompartType[caption='" .. pathTable[i] .. "']")
				end
			end
		end
		-- local compartType2 = compartType:find("/subCompartType[caption='" .. target .. "']")
		-- if compartType2:is_empty() then compartType = compartType:find("/subCompartType[caption='ASFictitious" .. target .. "']")
		-- else compartType = compartType2 end
		--ja ir pirma limenja lauks
	-- else
		-- compartType = elemType:find("/compartType[caption='" .. target .. "']")
		-- if compartType:is_empty() then compartType = elemType:find("/compartType[caption='ASFictitious" .. target .. "']") end
	end
	
	return compartType
end

--atgriez tabulu ar stilu vertibam
function valuesTable()
	tableValues = {}
	
	--AA#CompartStyleItem instances:
	tableValues["textDirection"] = {Left=0, Center=1, Right=2}
	tableValues["fontSize"] = {[8]=8, [9]=9, [10]=10, [12]=12, [14]=14, [16]=16, [18]=18, [20]=20, [22]=22, [24]=24, [26]=26, [28]=28, [36]=36, [48]=48, [72]=72}
	tableValues["fontColor"] = {Black=15790320, Maroon=08388608, Green=00032768, Olive=08421376, Navy=00000128, Purple=08388736, Teal=00032896, Gray=08421504, Silver=12632256, Red=255, Blue=13369344}
	tableValues["fontTypeFace"] = {["Agatha"] = "Agatha", ["Arial"] = "Arial", ["Arial Black"] = "Arial Black", ["Comic Sans MS"] = "Comic Sans MS", ["Courier New"] = "Courier New", ["Estrangelo Edessa"] = "Estrangelo Edessa", ["Franklin Gothic Medium"] = "Franklin Gothic Medium", ["Gautami"] = "Gautami", ["Georgia"] = "Georgia", ["Impact"] = "Impact", ["Latha"] = "Latha", ["Lucida Console"] = "Lucida Console", ["Lucida Sans Unicode"] = "Lucida Sans Unicode", ["Mangal"] = "Mangal", ["Marlett"] = "Marlett", ["Microsoft Sans Serif"] = "Microsoft Sans Serif", ["MV Boli"] = "MV Boli", ["Palatino Linotype"] = "Palatino Linotype", ["Raavi"] = "Raavi", ["Shruti"] = "Shruti", ["Sylfaen"] = "Sylfaen", ["Symbol"] = "Symbol", ["Tahoma"] = "Tahoma", ["Times New Roman"] = "Times New Roman", ["Trebuchet MS"] = "Trebuchet MS", ["Tunga"] = "Tunga", ["Verdana"] = "Verdana", ["Webdings"] = "Webdings", ["Wingdings"] = "Wingdings"}
	tableValues["fontStyleBold"] = {No=0, Yes=1}
	tableValues["fontStyleItalic"] = {No=0, Yes=1}
	tableValues["fontStyleUnderline"] = {No=0, Yes=1}
	tableValues["fontStyleStrikeout"] = {No=0, Yes=1}
	tableValues["fontPitch"] = {Default=0, Variable=1, Fixed = 2}
	tableValues["fontCharSet"] = {["Central European"]=-18, Baltic=-70, Vietnamese=-93, Turkish=-94, Greek=-95, Arabic=-78, Hebrew=-79, Western=0, Cyrillic=-52}
	tableValues["lineColor"] = {Black=15790320, Maroon=08388608, Green=00032768, Olive=08421376, Navy=00000128, Purple=08388736, Teal=00032896, Gray=08421504, Silver=12632256, Red=255, Blue=13369344}
	tableValues["alignment"] = {Left=0, Center=1, Right=2}
	tableValues["adornmentBox"] = {UnderLine = 1, UpperLine = 3}
	tableValues["adornmentLine"] = {BlackTriangle = 2, DirectionArrow = 4, ReverseBlackTriangle = 5, ReverseDirectionArrow = 6}
	tableValues["picStyleCom"] = {[0]=0}
	tableValues["picPosCom"] = {[0]=0, [1]=1, [2]=2, [3]=3}
	--var summet
	tableValues["adjustmentBox"] = {Left = 1, Top = 2, Right = 4, Bottom = 8, TopLeft = 16, TopRight = 32, BottomLeft = 64, BottomRight = 128, Any = -1}
	--var summet
	tableValues["adjustmentLine"] = {StartLeft = 5, StartRight = 9, EndLeft = 6, EndRight = 10, MiddleLeft = 20, MiddleRight = 24,  Any = -1}
	tableValues["isVisible"] = {No=0, Yes=1, ["Icon only"]=255}
	tableValues["isVisibleHidden"] = {No=0, Yes=1}
	tableValues["breakAtSpace"] = {No=0, Yes=1}
	tableValues["compactVisible"] = {No=0, Yes=1}

	--AA#ElemStyleItem instances:
	tableValues["shapeStyleShadow"] = {No=0, Yes=1}
	tableValues["shapeStyle3D"] = {No=0, Yes=1}
	tableValues["shapeStyleMultiple"] = {No=0, Yes=1}
	tableValues["shapeStyleNoBorder"] = {No=0, Yes=1}
	tableValues["shapeStyleNoBackground"] = {No=0, Yes=1}
	tableValues["shapeStyleNotLinePen"] = {No=0, Yes=1}
	tableValues["shapeCodeBox"] = {Rectangle = 1, RoundRectangle = 2, Parallelogram = 3, Arrow = 4, Ellipse = 5, Hexagon = 6, Trapeze = 7, DownwardTrapeze = 8, Diamond = 9, Triangle = 10, Note = 11, InArrow = 12, OutArrow = 13, Octagon = 14, LittleMan = 15, BigArrow = 18, Activity_State = 17, Package = 16, BlackLine = 19, Component = 20, VertCylinder = 21, HorzCylinder = 22, VertBlackLine = 23, SandGlass = 24}
	tableValues["shapeCodeLine"] = {None = 1, Arrow = 2, PureArrow = 3, Circle = 4, Diamond = 10, Triangle = 11, Square = 15, Card_0toN = 16, Card_1toN = 17, Card_1to1 = 18, Card_0to1 = 19, BigCircle = 5, HalfArrow = 6, DiamondOblique=21, Oblique=20, ArrowSquare=14, DoableSquare=13, ArrowDoableSquare = 12}
	tableValues["bkgColor"] = {Black=15790320, Maroon=08388608, Green=00032768, Olive=08421376, Navy=00000128, Purple=08388736, Teal=00032896, Gray=08421504, Silver=12632256, Red=255, Blue=13369344}
	--tableValues["widthProc"] = {No=0, Yes=1}
	
	--AA#NodeStyleItem instances:
	tableValues["picStyleNode"] = {[0]=0, [1]=1, [2]=2}
	tableValues["picPosNode"] = {[1]=1, [2]=2, [3]=3, [4]=4, [5]=5}
	
	--AA#EdgeSyleItem instances:
	tableValues["lineType"] = {Rectilinear = 1, Polyline = 16, LineSegment = 2, Spline = 4}
	tableValues["lineDirection"] = {Any = 0, Up = 1, Down = 2, Left = 4, Right = 8}
	tableValues["lineStartDirection"] = {Any = 0, Up = 1, Down = 2, Left = 4, Right = 8}
	tableValues["lineEndDirection"] = {Any = 0, Up = 1, Down = 2, Left = 4, Right = 8}
	tableValues["startShapeCode"] = {None = 1, Arrow = 2, PureArrow = 3, Circle = 4, Diamond = 10, Triangle = 11, Square = 15, Card_0toN = 16, Card_1toN = 17, Card_1to1 = 18, Card_0to1 = 19, BigCircle = 5, HalfArrow = 6}
	tableValues["middleShapeCode"] = {None = 1, Arrow = 2, PureArrow = 3, Circle = 4, Diamond = 10, Triangle = 11, Square = 15, Card_0toN = 16, Card_1toN = 17, Card_1to1 = 18, Card_0to1 = 19, BigCircle = 5, HalfArrow = 6}
	tableValues["endShapeCode"] = {None = 1, Arrow = 2, PureArrow = 3, Circle = 4, Diamond = 10, Triangle = 11, Square = 15, Card_0toN = 16, Card_1toN = 17, Card_1to1 = 18, Card_0to1 = 19, BigCircle = 5, HalfArrow = 6}
	tableValues["startLineColor"] = {Black=15790320, Maroon=08388608, Green=00032768, Olive=08421376, Navy=00000128, Purple=08388736, Teal=00032896, Gray=08421504, Silver=12632256, Red=255, Blue=13369344}
	tableValues["startBkgColor"] = {Black=15790320, Maroon=08388608, Green=00032768, Olive=08421376, Navy=00000128, Purple=08388736, Teal=00032896, Gray=08421504, Silver=12632256, Red=255, Blue=13369344}
	tableValues["middleBkgColor"] = {Black=15790320, Maroon=08388608, Green=00032768, Olive=08421376, Navy=00000128, Purple=08388736, Teal=00032896, Gray=08421504, Silver=12632256, Red=255, Blue=13369344}
	tableValues["middleLineColor"] = {Black=15790320, Maroon=08388608, Green=00032768, Olive=08421376, Navy=00000128, Purple=08388736, Teal=00032896, Gray=08421504, Silver=12632256, Red=255, Blue=13369344}
	tableValues["endLineColor"] = {Black=15790320, Maroon=08388608, Green=00032768, Olive=08421376, Navy=00000128, Purple=08388736, Teal=00032896, Gray=08421504, Silver=12632256, Red=255, Blue=13369344}
	tableValues["endBkgColor"] = {Black=15790320, Maroon=08388608, Green=00032768, Olive=08421376, Navy=00000128, Purple=08388736, Teal=00032896, Gray=08421504, Silver=12632256, Red=255, Blue=13369344}
	
	return tableValues
end

function dependentStylesTable()
	local t = {}
	local temp = {"Association/Role/Name/Name", "Association", "OWL_specific.change_OWL_assoc_style_from_compartment"}
	table.insert(t, temp)
	temp = {"Association/InvRole/Name/Name", "Association", "OWL_specific.change_OWL_assoc_style_from_compartment"}
	table.insert(t, temp)
	temp = {"Association/Role/IsComposition", "Association", "OWL_specific.set_assoc_style"}
	table.insert(t, temp)
	temp = {"Association/InvRole/IsComposition", "Association", "OWL_specific.set_assoc_style"}
	table.insert(t, temp)
	temp = {"Association/Role/EquivalentProperties", "Association", "OWL_specific.set_assoc_style"}
	table.insert(t, temp)
	temp = {"Link/Direct/Property", "Link", "OWL_specific.change_OWL_link_style_from_compartment"}
	table.insert(t, temp)
	temp = {"Link/InvProperty/Property", "Link", "OWL_specific.change_OWL_link_style_from_compartment"}
	table.insert(t, temp)
	return t
end

function closeExtraStyle()
	local activeCell = lQuery("D#VTable[id = 'TableViewStyle']/selectedRow/activeCell")--aktiva suna
	local viewStyleId = lQuery(activeCell):find("/component"):attr("id")--componentes id
	local viewStyle = lQuery("AA#ViewStyleSetting"):filter(
		function(obj)
			return lQuery(obj):id() == tonumber(viewStyleId)
		end)
	local extraStyles = lQuery("D#VTable[id = 'ExtraStyleTable']/vTableRow"):each(function(extraStyle)
		local dependsOnElemType = extraStyle:find("/vTableCell:has(/vTableColumnType[caption='DependsOnElemType'])"):attr("value")
		local dependsOnCompartType = extraStyle:find("/vTableCell:has(/vTableColumnType[caption='DependsOnCompartType'])"):attr("value")
		local parameterName = extraStyle:find("/vTableCell:has(/vTableColumnType[caption='ParameterName'])"):attr("value")
		local parameterValue = extraStyle:find("/vTableCell:has(/vTableColumnType[caption='ParameterValue'])"):attr("value")
		
		if viewStyle:find("/customStyleSetting[elementTypeName='" .. dependsOnElemType .. "'][compartTypeName='" .. dependsOnCompartType .. "'][parameterName='" .. parameterName .. "'][parameterValue='" .. parameterValue .. "']"):is_empty() then
			lQuery.create("AA#CustomStyleSetting", {elementTypeName = dependsOnElemType, compartTypeName = dependsOnCompartType, parameterName = parameterName, parameterValue = parameterValue})
				:link("viewStyleSetting", viewStyle)
		end
	end)
	
	lQuery("D#Event"):delete()
	utilities.close_form("ExtraStyle")
end

function closeViewsInDiagram()
  lQuery("D#Event"):delete()
  utilities.close_form("ViewsInDiagram")
end

function closeTree()
  lQuery("D#Event"):delete()
  utilities.close_form("CompartmentTree")
end