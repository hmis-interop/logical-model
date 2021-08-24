module(..., package.seeall)

require("lua_tda")
require "lpeg"
require "core"
extensionCreate = require "OWLGrEd_UserFields.extensionCreate"
owl_fields_specific = require "OWLGrEd_UserFields.owl_fields_specific"
styleMechanism = require "OWLGrEd_UserFields.styleMechanism"
axiom = require "OWLGrEd_UserFields.axiom"
specific = require "OWL_specific"

--izdzes tadus prieks lietotaju defineto lauku semantikas eksporta
function deleteGetAxiomAnnotationTranslets()
	local translets = lQuery("Translet[extensionPoint='OWLGrEd_GetAxiomAnnotation']"):each(function(obj)
		if obj:find("/type/axiomAnnotationTag[key='owl_Axiom_Annotation']"):is_empty() then obj:delete() end
	end)
end

--veic pirma limena lauku sinhronizaciju
function syncProfile(profileName)
	--izdzes tadus prieks lietotaju defineto lauku semantikas eksporta
	deleteGetAxiomAnnotationTranslets()
	local markStyleChange = 20
	local profile = lQuery("AA#Profile[name = '" .. profileName .. "']")
	local extension = lQuery("Extension[id = '" .. profileName .. "'][type='aa#Profile']")
	local fields = lQuery(profile):find("/field")
	local compartType = lQuery(extension):find("/type")

	local link = {}--tabula ar AAField un CompartType saderibam
	fields:each(function(objF)
		compartType:each(function(objCT)
			local parent = objCT:find("/parentCompartType")
			if parent:is_empty() then parent = objCT:find("/elemType") end
			local elemType
			local compType = objCT
			local l = 0
			while l == 0 do
				elemType = compType:find("/elemType")
				if elemType:is_not_empty() then l = 1
				else
					compType = compType:find("/parentCompartType")
				end
			end

			--noskaidrojam kadiem AAField ir saderibas CompartType
			if objF:attr("name")==objCT:attr("caption") and objF:find("/context"):attr("type") == parent:attr("caption") 
			and elemType:attr("caption") == objF:find("/context"):attr("elTypeName") then
				local linkPair = {}
				table.insert(linkPair, objF)
				table.insert(linkPair, objCT)
				table.insert(link, linkPair)
			elseif objF:find("/context"):attr("type") == "Role" and parent:attr("caption") == "InvRole" and objF:attr("name")==objCT:attr("caption")
			and elemType:attr("caption") == objF:find("/context"):attr("elTypeName") then
				local linkPair = {}
				table.insert(linkPair, objF)
				table.insert(linkPair, objCT)
				table.insert(link, linkPair)
			elseif objF:find("/context"):attr("type") == "Direct" and parent:attr("caption") == "Inverse" and objF:attr("name")==objCT:attr("caption")
			and elemType:attr("caption") == objF:find("/context"):attr("elTypeName") then
				local linkPair = {}
				table.insert(linkPair, objF)
				table.insert(linkPair, objCT)
				table.insert(link, linkPair)
			elseif objF:attr("name")==objCT:attr("caption") and "CheckBoxFictitious" .. objF:find("/context"):attr("type") == parent:attr("caption") 
			and elemType:attr("caption") == objF:find("/context"):attr("elTypeName") then
				local linkPair = {}
				table.insert(linkPair, objF)
				table.insert(linkPair, objCT)
				table.insert(link, linkPair)
			elseif objF:find("/context"):attr("elTypeName") =="" 
			and objF:attr("name")==objCT:attr("caption") and objF:find("/context"):attr("type") == parent:attr("caption")  then
				local linkPair = {}
				table.insert(linkPair, objF)
				table.insert(linkPair, objCT)
				table.insert(link, linkPair)
			elseif parent:find("/parentCompartType"):is_not_empty() and objF:attr("name")==objCT:attr("caption") and 
			objF:find("/context"):attr("type") == "Attributes" and 
			objF:find("/context"):attr("type") == parent:find("/parentCompartType"):attr("caption") 
			and elemType:attr("caption") == objF:find("/context"):attr("elTypeName") then
				local linkPair = {}
				table.insert(linkPair, objF)
				table.insert(linkPair, objCT)
				table.insert(link, linkPair)
			elseif parent:find("/parentCompartType"):is_not_empty() and objF:attr("name")==objCT:attr("caption") and 
			objF:find("/context"):attr("type") == "Role" and 
			objF:find("/context"):attr("type") == parent:find("/parentCompartType"):attr("caption") 
			and elemType:attr("caption") == objF:find("/context"):attr("elTypeName") then
				local linkPair = {}
				table.insert(linkPair, objF)
				table.insert(linkPair, objCT)
				table.insert(link, linkPair)
			elseif parent:find("/parentCompartType"):is_not_empty() and objF:attr("name")==objCT:attr("caption") and 
			objF:find("/context"):attr("type") == "Role" and 
			parent:find("/parentCompartType"):attr("caption") == "InvRole"
			and elemType:attr("caption") == objF:find("/context"):attr("elTypeName") then
				local linkPair = {}
				table.insert(linkPair, objF)
				table.insert(linkPair, objCT)
				table.insert(link, linkPair)
			-- elseif objF:attr("isExistingField") == "true" then 
				-- print("HHHHHHHHHH")
				-- local linkPair = {}
				-- table.insert(linkPair, objF)
				-- table.insert(linkPair, objCT)
				-- table.insert(link, linkPair)
			end
		end)
	end)
	
--	print(dumptable(link), "OOOO")
	
	--AA#Field kuriem nav saderibas CompartType
	local profileNotMapped = {}
	fields:each(function(objF)
		local l = 0
		for i,v in pairs(link) do
			if v[1]:id()==objF:id() then 
				l = 1
				break
			end
		end
		if l==0 then table.insert(profileNotMapped, objF) end
	end)
	for i,v in pairs(profileNotMapped) do 
		--lauku sinhronizacija
		local parrent = lQuery(v):find("/context")
		extensionCreate.fields(v, extension)
	end
	--CompartType kuriem nav atbilstibas AA#Field
	local extensionNotMapped = {}
	compartType:each(function(objCT)
		local l = 0
		--print(dumptable(link))
		for i,v in pairs(link) do
			if v[2]:id()==objCT:id() then 
				l = 1
				break
			end
		end
		if l==0 then
			--if v[2]:attr("isExistingField")~= "true" then
				table.insert(extensionNotMapped, objCT)
			--end
		end
	end)
	for i,v in pairs(extensionNotMapped) do 
		--lauku dzesana
		deleteCompartType(v)
	end
	local elemStyleChange = 0
	local compartStyleChange = 0
	for i,v in pairs(link) do
		local elemStyleChangeTemp, compartStyleChangeTemp = syncField(v[1], v[2])--pa visiem pirma limena laukiem, kam ir sadaribas abas puses
		if elemStyleChangeTemp ~= nil then elemStyleChange = elemStyleChange + elemStyleChangeTemp end
		if compartStyleChangeTemp ~= nil then compartStyleChange = compartStyleChange + compartStyleChangeTemp end
	end

	--palaist visiem projekta elementiem un compartmentiem proceduru, kas parstada stilus
	lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
		if elemStyleChange > 0 then 
			lQuery(diagram):find("/element:has(/elemType/elementStyleSetting)"):each(function(obj)
				owl_fields_specific.ElemStyleBySettings(obj, "Change")
			end)
		end
		if compartStyleChange > 0 then 
			lQuery(diagram):find("/element/compartment:has(/compartType/compartmentStyleSetting)"):each(function(obj)
				owl_fields_specific.CompartStyleBySetting(obj, "Change")
			end)
			--parrekinas compartmenta vertibas, ja ir uzstaditi prefiksi vai sufiksi
			lQuery("Translet[extensionPoint = 'procGetPrefix']/type/compartment"):each(function(pr)
				core.set_parent_value(pr)
			end)
			lQuery("Translet[extensionPoint = 'procGetSuffix']/type/compartment"):each(function(pr)
				core.set_parent_value(pr)
			end)
		end
		--atjaunojam tos elementus, kur bija compartmentu stila izmaina
		local elem = lQuery(diagram):find("/element:has(/compartment/compartType/compartmentStyleSetting)")
		elem:add(lQuery(diagram):find("/element:has(/compartment/subCompartment/compartType/compartmentStyleSetting)"))
			
		utilities.refresh_element(elem, diagram) 
		
		local cmd = lQuery.create("OkCmd")
		cmd:link("graphDiagram", diagram)
		utilities.execute_cmd_obj(cmd)
		
		require("graph_diagram_style_utils")
		graph_diagram_style_utils.save_diagram_element_and_compartment_styles(diagram)
		
	--	utilities.execute_cmd("SaveStylesCmd", {graphDiagram = diagram})
		--utilities.execute_cmd("AfterConfigCmd", {graphDiagram = diagram})
	end)
	--jaatjauno visi elementi
	-- local elem = lQuery("Element:has(/elemType/elementStyleSetting)"):each(function(obj)
		-- utilities.refresh_element(obj, obj:find("/graphDiagram"))
	-- end)
	--izdzesam visus stilus, kas atzimeti dzesanai
	styleMechanism.deleteIsDeletedStyleSetting()
	--savacam semantiku prieks importa
	importSemantics()
	
	lQuery("PropertyTab"):each(function(tab)
		if tab:find("/propertyRow"):is_empty() then tab:delete() end
	end)
end

--savac semantiku prieks importa
function importSemantics()
	local prefix = "Prefix(owlFields:=<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#>)"
	lQuery("ToolType/tag[key = 'owl_NamespaceDef']"):delete()
	lQuery.create("Tag", {value = "owlFields:=<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#>", key = "owl_NamespaceDef"}):link("type", lQuery("ToolType"))
	lQuery.create("Tag", {value = "owlgred:=<http://lumii.lv/2011/1.0/owlgred#>", key = "owl_NamespaceDef"}):link("type", lQuery("ToolType"))
	lQuery("AA#Profile/tag[tagKey = 'owl_Import_Prefixes']"):each(function(pr)
		lQuery.create("Tag", {key = 'owl_NamespaceDef', value=pr:attr("tagValue")}):link("type", lQuery("ToolType"))
		prefix = prefix .. "\nPrefix(" .. pr:attr("tagValue") .. ")"
	end)
	
	--lQuery("ToolType/tag[key = 'owl_Import_Prefixes']"):attr("value", prefix)
	
	local String = ""
	local tag = lQuery("Tag[key = 'owl_Fields_ImportSpec']"):each(function(obj)
		if obj:attr("value")~="" and obj:find("/choiceItem"):is_not_empty() then
			String = String .. "\n" .. axiom.gramarImport2(obj:attr("value"), obj:find("/choiceItem"):attr("value"))
		elseif obj:attr("value")~="" and obj:find("/type"):is_not_empty() then
			String = String .. "\n" .. axiom.gramarImport2(obj:attr("value"), obj:find("/type"):attr("id"))
		end
	end)
	lQuery("ToolType/tag[key = 'owl_Annotation_Import']"):attr("value", String)
end

--uzstada lauku diagaramas elemanta pareizalaa vietaa (field-AA#Field daljas lauks, compartType-tipu dalas lauks)
function createDisplayPlaceBefore(field,compartType)
		--atrast to kas ir noradita displayPlaceBefore atributaa
		--ievietot tabula pirms tas jauno instanci
		--atjaunot saites
	--ja ir pirma limena compartments
	if lQuery(field):attr("displayPlaceBefore") ~= "" and compartType:find("/elemType"):is_not_empty() then 
		--atrast elemType
		local elemType = lQuery(compartType):find("/elemType")
		--atlasit visas piesaistitas compartType instances, ierakstit tas tabulaa
		local l = 0
		local t = {}--tabula ar visiem compartType, kas pieder dotajam ElemType
		lQuery(elemType):find("/compartType"):each(function(obj)
			if obj:attr("caption") == lQuery(field):attr("displayPlaceBefore") then
				--ievietojam jaunu lauku vajadzigaja vietaa
				table.insert(t, compartType)
				l = 1
			end
			if obj:id() ~= compartType:id() then
				table.insert(t, obj)
			end
			obj:remove_link("elemType", elemType)
		end)
		--atjaunojam saites
		for i,v in pairs(t) do
			v:link("elemType", elemType)
		end
		--ja ir uzrakstits neeksistejoss lauks pirms kura ir japievieno, tad pievienojam lauku beigas
		if l == 0 then compartType:link("elemType", elemType) end 
	--ja pie zemaka limena laukiem	
	elseif lQuery(field):attr("displayPlaceBefore") ~= "" then
		--atrast parentCompartType
		local parentCompartType = compartType:find("/parentCompartType")
		--atlasit visas piesaistitas compartType instances, ierakstit tas gtabulaa
		local l = 0
		local t = {}--tabula ar visiem compartType, kas pieder dotajam ElemType
		lQuery(parentCompartType):find("/subCompartType"):each(function(obj)
			if obj:attr("caption") == lQuery(field):attr("displayPlaceBefore") then
				table.insert(t, compartType)
				l = 1
			end
			table.insert(t, obj)
			obj:remove_link("parentCompartType", parentCompartType)
		end)
		--atjaunojam saites
		for i,v in pairs(t) do
			v:link("parentCompartType", parentCompartType)
		end
		--ja ir uzrakstits neeksistejoss lauks pirms kura ir japievieno, tad pievienojam lauku beigas
		if l == 0 then compartType:link("parentCompartType", parentCompartType) end 
	end
end

--izveido choiceItem-us (field-AA#Field daljas lauks, compartType-tipu dalas lauks)
function createChoiceItems(field, compartType)
	local choiceItemsF = lQuery(field):find("/choiceItem")
	local choiceItemCT = lQuery(compartType):find("/choiceItem")
	local link = {}--tabula ar choiceItem, kam ir saderibas abas puses
	choiceItemsF:each(function(objF)
		choiceItemCT:each(function(objCT)
			if objF:attr("caption")==objCT:attr("value") then
				local linkPair = {}
				table.insert(linkPair, objF)
				table.insert(linkPair, objCT)
				table.insert(link, linkPair)
			end
		end)
	end)
	--kam nav saderibas tipu dalaa
	local fieldNotMapped = {}
	choiceItemsF:each(function(objF)
		local l = 0
		for i,v in pairs(link) do
			if v[1]:id()==objF:id() then 
				l = 1
				break
			end
		end
		if l==0 then table.insert(fieldNotMapped, objF) end
	end)
	--izveidojam iztrukstosos
	for i,v in pairs(fieldNotMapped) do 
		createChoiceItem(v, compartType)
	end
	--kam nav saderibas AA#ChoiceItem dalaa
	local contextTypeNotMapped = {}
	choiceItemCT:each(function(objCT)
		local l = 0
		for i,v in pairs(link) do
			if v[2]:id()==objCT:id() then 
				l = 1
				break
			end
		end
		if l==0 then table.insert(contextTypeNotMapped, objCT) end
	end)
	--izdzesam choiceItem-us
	for i,v in pairs(contextTypeNotMapped) do 
		deleteChoiceItem(v)
	end
	--choiceItem sinhronizacija
	local elemStyleChange = 0
	local compartStyleChange = 0
	for i,v in pairs(link) do

		--notation
		--if lQuery(v[2]):find("/field/fieldType"):attr("typeName") == "CheckBox" then
		if lQuery(v[2]):find("/field"):attr("fieldType") == "CheckBox" then
			lQuery(v[2]):find("/notation"):attr("value", lQuery(v[1]):attr("notation"))
		end
		--semantics
		lQuery(v[2]):find("/tag"):delete()
		lQuery(v[1]):find("/tag"):each(function(objTag)--sementics
				if lQuery(objTag):attr("tagValue") ~= "" then
					local tag = lQuery.create("Tag", {
						value = lQuery(objTag):attr("tagValue")
						,key = lQuery(objTag):attr("tagKey")
					}):link("choiceItem", v[2])
					
					if lQuery(objTag):attr("tagKey") == "owl_Field_axiom" then
						extensionCreate.createImportSemanticsChoiceItem(field, v[2], objTag)
					end
					
					if lQuery(objTag):attr("tagKey") == "owl_Axiom_Annotation" then
						--atrast vecak elementu
						local parent = v[2]:find("/compartType/parentCompartType")
						if parent:is_empty() then parent = v[2]:find("/compartType/elemType") end
						parent = extensionCreate.findAxiomAnnotationPath(objTag, parent)
						if parent:find("/translet[extensionPoint='OWLGrEd_GetAxiomAnnotation'][procedureName = 'OWLGrEd_UserFields.axiom.getAxiomAnnotation']"):is_empty() then
							lQuery.create("Translet", {extensionPoint = 'OWLGrEd_GetAxiomAnnotation', procedureName = 'OWLGrEd_UserFields.axiom.getAxiomAnnotation'})
							:link("type", parent)
						end
						tag:link("axiomAnnotationType", parent)
					end
				end
			end)

		--style
		elemStyleChange = elemStyleChange + syncChoiceItemStyleElem(v[1], v[2])
		compartStyleChange = compartStyleChange + syncChoiceItemStyleCompart(v[1], v[2])
	end
	return elemStyleChange, compartStyleChange
end

--izveido tad-us (field-AA#Field daljas lauks, compartType-tipu dalas lauks, types - kompartmenta tips, pie ku japiesaista tags)
function createSemantics(field, compartType, types)
	lQuery(field):find("/tag"):each(function(objTag)--semantics
		if lQuery(objTag):attr("tagValue") ~= "" then
			local tag = lQuery.create("Tag", {
				value = lQuery(objTag):attr("tagValue")
				,key = lQuery(objTag):attr("tagKey")
			}):link("type", types)
			
			if lQuery(objTag):attr("tagKey") == "owl_Field_axiom" then
				extensionCreate.createImportSemanticsField(field ,types, objTag)
			end
			
			if lQuery(objTag):attr("tagKey") == "owl_Axiom_Annotation" then
				--atrast vecak elementu
				local parent = compartType:find("/parentCompartType")
				if parent:is_empty() then parent = compartType:find("/elemType") end
					
				parent = extensionCreate.findAxiomAnnotationPath(objTag, parent)

				if parent:find("/translet[extensionPoint='OWLGrEd_GetAxiomAnnotation'][procedureName = 'OWLGrEd_UserFields.axiom.getAxiomAnnotation']"):is_empty() then
					lQuery.create("Translet", {extensionPoint = 'OWLGrEd_GetAxiomAnnotation', procedureName = 'OWLGrEd_UserFields.axiom.getAxiomAnnotation'})
					:link("type", parent)
				end
				tag:link("axiomAnnotationType", parent)
			end
		end
	end)
end

--izveido translet-us (field-AA#Field daljas lauks, compartType-tipu dalas lauks, types - kompartmenta tips, pie ku japiesaista tags, specTranslete-translets stilu parrekinasanai)
function createTranslets(field, compartType, types, specTranslete)
	local translet = lQuery(field):find("/translet"):each(function(obj)
		lQuery.create("Translet", {
			procedureName = lQuery(obj):attr("procedure")
			,extensionPoint = lQuery(obj):find("/task"):attr("taskName")
		}):link("type", types)
	end)
	if specTranslete:is_not_empty() then
		lQuery.create("Translet", {extensionPoint = 'procFieldEntered', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDependentStyle'})
		:link("type", types)
	end
end

--izveido jauno kompartType stilus (field-AA#Field daljas lauks, compartType-tipu dalas lauks)
function createFieldStyle(field, compartType)
	--atrast ContextType
		local contextType = lQuery(field):find("/context"):attr("type")
		--atrast CompartStyle instanci
		local compartStyle = lQuery(compartType):find("/compartStyle")
		--atrast laukam piederosus stila uzstadijumus
		lQuery(compartStyle):attr("alignment", 0)
		lQuery(compartStyle):attr("adjustment", 0)
		lQuery(compartStyle):attr("lineWidth", 1)
		lQuery(compartStyle):attr("lineColor", 0)
		lQuery(compartStyle):attr("fontTypeFace", "Arial")
		lQuery(compartStyle):attr("fontCharSet", 1)
		lQuery(compartStyle):attr("fontColor", 0)
		lQuery(compartStyle):attr("fontSize", 9)
		lQuery(compartStyle):attr("fontPitch", 0)
		lQuery(compartStyle):attr("fontStyle", 0)
		lQuery(compartStyle):attr("isVisible", 1)
		
		local fieldStyle = lQuery(field):find("/selfStyleSetting"):each(function(obcFS)
			
			local fieldStyleFeature = obcFS:find("/fieldStyleFeature"):attr("itemName")
			local style = obcFS:attr("value")
			local val = style
			if fieldStyleFeature == "adjustment" then
				if compartType:find("/parentCompartType"):attr("caption") == "InvRole" and field:find("/context"):attr("type") == "Role" then
					local t = styleMechanism.valuesTable()
					a = t[fieldStyleFeature .. "Line"]
					for i,v in pairs(a) do 
						if tonumber(v) == tonumber(val) then val = i end
					end
					if string.find(val, "Start") ~= nil then
					local startStyle = string.sub(val, 6)
					val = "End" .. startStyle
					elseif string.find(val, "End") ~= nil then
						local startStyle = string.sub(val, 4)
						val = "Start" .. startStyle
					end
					style = a[val]
				end	
			end
				
			if fieldStyleFeature == "fontStyleBold" then
				local num = tostring(styleMechanism.toBin(tonumber(lQuery(compartStyle):attr("fontStyle"))))
				local len = string.len(num)
				val = lQuery(compartStyle):attr("fontStyle")
				if string.sub(num, len, len) ~= "1" and style == "1" then 
				val = val + 1 --* obcFS:attr("value")
				elseif string.sub(num, len, len) == "1" and style == "0" then
				val = val - 1
				end
				lQuery(compartStyle):attr("fontStyle", val)
			elseif fieldStyleFeature == "fontStyleItalic" then
				local num = tostring(styleMechanism.toBin(tonumber(lQuery(compartStyle):attr("fontStyle"))))
				local len = string.len(num)
				val = lQuery(compartStyle):attr("fontStyle")
				if string.sub(num, len-1, len-1) ~= "1" and style == "1" then 
				val = val + 2 
				elseif string.sub(num, len-1, len-1) == "1" and style == "0" then
				val = val - 2
				end
				lQuery(compartStyle):attr("fontStyle", val)
			elseif fieldStyleFeature == "fontStyleUnderline" then
				local num = tostring(styleMechanism.toBin(tonumber(lQuery(compartStyle):attr("fontStyle"))))
				local len = string.len(num)
				val = lQuery(compartStyle):attr("fontStyle")
				if string.sub(num, len-2, len-2) ~= "1" and style == "1" then 
				val = val + 4 
				elseif string.sub(num, len-2, len-2) == "1" and style == "0" then
				val = val - 4
				end
				lQuery(compartStyle):attr("fontStyle", val)
			elseif fieldStyleFeature == "fontStyleStrikeout" then
				local num = tostring(styleMechanism.toBin(tonumber(lQuery(compartStyle):attr("fontStyle"))))
				local len = string.len(num)
				val = lQuery(compartStyle):attr("fontStyle")
				if string.sub(num, len-3, len-3) ~= "1" and style == "1" then 
				val = val + 8 --* obcFS:attr("value")
				elseif string.sub(num, len-3, len-3) == "1" and style == "0" then
				val = val - 8
				end
				lQuery(compartStyle):attr("fontStyle", val)			
			else
				if string.find(fieldStyleFeature, "prefix-") == nil and string.find(fieldStyleFeature, "suffix-") == nil then
				lQuery(compartStyle):attr(fieldStyleFeature, style)
				end
			end
		end)
end

--sinhronize laukus (field-AA# dalas lauks, compartType-tipu dalas lauks)
function syncField(field, compartType)
	compartType:find("/parentCompartType/translet[extensionPoint='OWLGrEd_GetAxiomAnnotation'][procedureName = 'OWLGrEd_UserFields.axiom.getAxiomAnnotation']"):delete()
	compartType:find("/elemType/translet[extensionPoint='OWLGrEd_GetAxiomAnnotation'][procedureName = 'OWLGrEd_UserFields.axiom.getAxiomAnnotation']"):delete()
	
	local elemStyleChange, compartStyleChange
	--parrakstam vertibas no AA#Field uz CompartType
	--local fieldTypes = lQuery(field):find("/fieldType"):attr("typeName")
	if field:attr("isExistingField") == "true" then
		local CItype
		local fieldTypes = lQuery(field):attr("fieldType")
		if fieldTypes == "TextArea+Button" then 
			lQuery(compartType):find("/subCompartType/tag"):delete()
			CItype = compartType:find("/subCompartType")
		else
			lQuery(compartType):find("/tag"):delete()
			CItype = compartType
		end
		createSemantics(field, compartType, CItype)
	else
		local fieldTypes = lQuery(field):attr("fieldType")
		if fieldTypes == "TextArea+Button" then 
			lQuery(compartType):attr("concatStyle", lQuery(field):attr("delimiter"))
			lQuery(compartType):find("/subCompartType"):attr("startValue", lQuery(field):attr("defaultValue"))
			lQuery(compartType):find("/subCompartType"):attr("adornmentPrefix", lQuery(field):attr("prefix"))
			lQuery(compartType):find("/subCompartType"):attr("adornmentSuffix", lQuery(field):attr("suffix"))
			lQuery(compartType):find("/subCompartType"):attr("pattern", lQuery(field):attr("pattern"))
		else
			lQuery(compartType):attr("startValue", lQuery(field):attr("defaultValue"))
			lQuery(compartType):attr("adornmentPrefix", lQuery(field):attr("prefix"))
			lQuery(compartType):attr("adornmentSuffix", lQuery(field):attr("suffix"))
			lQuery(compartType):attr("pattern", lQuery(field):attr("pattern"))
			lQuery(compartType):attr("concatStyle", lQuery(field):attr("delimiter"))
		end
		
	--DisplayPlaceBefore
		createDisplayPlaceBefore(field, compartType)
	--PropertyEditorTab
	--PropertyEditorPlaceBefore
		local contextType = lQuery(field):find("/context"):attr("type")
		local propertyEditorTab = lQuery(field):attr("propertyEditorTab")
		local propertyRow = lQuery(compartType):find("/propertyRow")	
		propertyRow:remove_link("propertyDiagram", propertyRow:find("/propertyDiagram"))
		if lQuery(field):find("/context"):attr("mode") == "Element" then 
			extensionCreate.createPropertyEditorTab(field, contextType, propertyRow, propertyEditorTab, compartType, lQuery("ElemType[caption = '" .. contextType .. "']"))
		else
			if compartType:find("/propertyRow/propertyTab"):is_not_empty() then propertyEditorTab = compartType:find("/propertyRow/propertyTab"):attr("caption") end
			extensionCreate.createPropertyEditorTab(field, contextType, propertyRow, propertyEditorTab, compartType)
		end

	--subFields
		local subFields = lQuery(field):find("/subField")
		local subCompartType
		local dia
		if fieldTypes == "TextArea+Button" then 
			subCompartType = lQuery(compartType):find("/subCompartType/subCompartType")
			dia = lQuery(compartType):find("/propertyDiagram")
		else subCompartType = lQuery(compartType):find("/subCompartType") end
		
		if fieldTypes == "InputField+Button" then dia = lQuery(compartType):find("/propertyDiagram") end
		
		local link = {}--tabula ar laukiem, kam ir saderibas abas puses
		subFields:each(function(objF)
			subCompartType:each(function(objCT)
				if objF:attr("name")==objCT:attr("caption") then
					local linkPair = {}
					table.insert(linkPair, objF)
					table.insert(linkPair, objCT)
					table.insert(link, linkPair)
				end
			end)
		end)
		--tabula ar laukiem kam nav saderibas tipu dalaa
		local fieldNotMapped = {}
		subFields:each(function(objF)
			local l = 0
			for i,v in pairs(link) do
				if v[1]:id()==objF:id() then 
					l = 1
					break
				end
			end
			if l==0 then table.insert(fieldNotMapped, objF) end
		end)
		--izveidojam iztrukstosos laukus
		for i,v in pairs(fieldNotMapped) do 
			local parrent = lQuery(v):find("/context")
			if fieldTypes == "TextArea+Button" then extensionCreate.subFields(compartType:find("/subCompartType"), v, dia)
			elseif fieldTypes == "InputField+Button" then extensionCreate.subFields(compartType, v, dia)
			else extensionCreate.subFields(compartType, v) end
		end
		--tabula ar laukiem, kam nav saderibas AA#Field dalaa
		local contextTypeNotMapped = {}
		subCompartType:each(function(objCT)
			local l = 0
			for i,v in pairs(link) do
				if v[2]:id()==objCT:id() then 
					l = 1
					break
				end
			end
			if l==0 then table.insert(contextTypeNotMapped, objCT) end
		end)
		--izdzesama laukus un visu, kas ar tiem ir saistits
		for i,v in pairs(contextTypeNotMapped) do 
			deleteCompartType(v)
		end
		--singronizejam pa visiem apakslaukiem, kam ir saderibas abas puses
		for i,v in pairs(link) do
			syncField(v[1], v[2])
		end
	--choiceItemi
		elemStyleChange, compartStyleChange = createChoiceItems(field, compartType)
	--rowType
		--atrast PropertyRow instanci
		local propertyRow = lQuery(compartType):find("/propertyRow")
		--atrast lauka RowType
		--local rowType = lQuery(field):find("/fieldType")
		local rowType = lQuery(field)
		--parrakstit atributu rowType
		propertyRow:attr("rowType", rowType:attr("fieldType"))
	--semantics
		local CItype
		if fieldTypes == "TextArea+Button" then 
			lQuery(compartType):find("/subCompartType/tag"):delete()
			CItype = compartType:find("/subCompartType")
		else
			lQuery(compartType):find("/tag"):delete()
			CItype = compartType
		end
		createSemantics(field, compartType, CItype)
	--transleti
		local specTranslete
		if fieldTypes == "TextArea+Button" then 
			specTranslete = lQuery(compartType):find("/subCompartType/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDependentStyle']")
			lQuery(compartType):find("/subCompartType/translet"):delete()
		else 
			specTranslete = lQuery(compartType):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDependentStyle']")
			lQuery(compartType):find("/translet"):delete()
		end
		
		local types
		if fieldTypes == "TextArea+Button" then 
			types = compartType:find("/subContextType")
		else
			types = compartType
		end
		createTranslets(field, compartType, types, specTranslete)
	--stili
		if lQuery(field):find("/context"):is_not_empty() then--stilus tikai pirma limena laukiem
			createFieldStyle(field, compartType)
			
			--izveidojam AA#CompartmentStyleSeting Instances	
			extensionCreate.createFieldCompartTypeStyle("", compartType, "", field)

		--	compartStyle:remove_link("compartType", compartType)
		--	compartStyle:link("compartType", compartType)
			
			--[[local compartment=compartType:find("/compartment")
			compartment:remove_link("compartStyle")
			compartment:link("compartStyle",compartStyle)
			compartment:attr("style","#")--]]
		end
	end
	return elemStyleChange, compartStyleChange
end

function anywhere (p)
  return lpeg.P{ p + 1 * lpeg.V(1) }
end

--singronize ElemType stilus, kas ir atkarigi no choiceItem(choiceItemProf-choiseItem instance no AA# dalas, coiceItemExt-choiceItem Instance no tipu dalas)
function syncChoiceItemStyleElem(choiceItemProf, coiceItemExt)
	local styleChange = 0
	
	local aaStyleElem = lQuery(choiceItemProf):find("/styleSetting[isElementStyleSetting = true]")
	local aaElemStyleSetting = lQuery(coiceItemExt):find("/elementStyleSetting")
	local compartType = lQuery(choiceItemProf):find("/field/context"):attr("type")
	
	local link = {}--tabula ar stiliem ar saderibam abas pusses
	aaStyleElem:each(function(objESP)
		aaElemStyleSetting:each(function(objESE)
			local conType = objESP:find("/choiceItem/field/context"):attr("type")
			if lQuery("ElemType[caption='" .. conType .. "']"):is_empty() then conType = objESP:find("/choiceItem/field/context"):attr("elTypeName") end
			
			if objESP:find("/elemStyleFeature"):attr("itemName")==objESE:attr("setting") and 
				objESP:attr("value")==objESE:attr("value") and
				conType==objESE:find("/elemType"):attr("id")
			then
				local linkPair = {}
				table.insert(linkPair, objESP)
				table.insert(linkPair, objESE)
				table.insert(link, linkPair)
			end
		end)
	end)
	--stili, kam nav saderibas tipu dalaa
	local profileNotMapped = {}
	aaStyleElem:each(function(objESP)
		local l = 0
		for i,v in pairs(link) do
			if v[1]:id()==objESP:id() then 
				l = 1
				break
			end
		end
		if l==0 then 
			table.insert(profileNotMapped, objESP)
			styleChange=1
		end
	end)
	--izveodi iztrukstosos stilus
	for i,v in pairs(profileNotMapped) do 
		--pielikt lauku sinhronizaciju
		--izveidot stilu ElementStyleSetting
		local contextType = lQuery(choiceItemProf):find("/field/context"):attr("type")
		local mode = lQuery(choiceItemProf):find("/field/context"):attr("mode")
		local elTypeName = lQuery(choiceItemProf):find("/field/context"):attr("elTypeName")
		if mode == "Element" then
			local elemType = lQuery("ElemType[id = '" .. contextType .. "']")
			createElemStyleSetting(coiceItemExt, elemType, v)
		elseif mode == "Group" then
			local elemType = lQuery("ElemType[id = '" .. elTypeName .. "']")
			createElemStyleSetting(coiceItemExt, elemType, v)
		end
	end
	--stili kuriem nav saderibas AA# dala
	local extensionNotMapped = {}
	aaElemStyleSetting:each(function(objESE)
		local l = 0
		for i,v in pairs(link) do
			if v[2]:id()==objESE:id() then 
				l = 1
				break
			end
		end
		if l==0 then 
			table.insert(extensionNotMapped, objESE) 
			styleChange = 1
		end
	end)
	--dzesam stilus
	for i,v in pairs(extensionNotMapped) do 
		--pielikt dzesanu
		deleteElemStyleSetting(v)
	end
	return styleChange
end

--singronize CompartType stilus, kas ir atkarigi no choiceItem(choiceItemProf-choiseItem instance no AA# dalas, coiceItemExt-choiceItem Instance no tipu dalas)
function syncChoiceItemStyleCompart(choiceItemProf, coiceItemExt)
	local styleChange = 0
	local aaStyleCompart = lQuery(choiceItemProf):find("/styleSetting[isElementStyleSetting != true]")
	--local compartmentStyleSetting = lQuery(coiceItemExt):find("/compartmentStyleSetting")
	local compartmentStyleSetting = lQuery(coiceItemExt):find("/compartmentStyleSetting"):filter(
			function(obj)
				return lQuery(obj):find("/extension"):size() == 0
			end)
	local compartType = lQuery(choiceItemProf):find("/field/context"):attr("type")
	
	local link = {}--tabula ar stiliem ar saderibam abas dalas
	aaStyleCompart:each(function(objCSP)
		compartmentStyleSetting:each(function(objCSE)
			if objCSP:find("/fieldStyleFeature"):attr("itemName")==objCSE:attr("setting") and 
				objCSP:attr("value")==objCSE:attr("value") and
				objCSP:attr("target")==objCSE:find("/compartType"):attr("id")
			then
				local linkPair = {}
				table.insert(linkPair, objCSP)
				table.insert(linkPair, objCSE)
				table.insert(link, linkPair)
			elseif objCSP:find("/fieldStyleFeature"):attr("itemName")==objCSE:attr("setting") .. "-" .. objCSE:attr("settingMode") and 
				objCSP:attr("value")==objCSE:attr("value") and
				objCSP:attr("target")==objCSE:find("/compartType"):attr("id")
			then
				local linkPair = {}
				table.insert(linkPair, objCSP)
				table.insert(linkPair, objCSE)
				table.insert(link, linkPair)
			end
		end)
	end)
	--stili, kam nav saderibas tipu dalaa
	local profileNotMapped = {}
	aaStyleCompart:each(function(objCSP)
		local l = 0
		for i,v in pairs(link) do
			if v[1]:id()==objCSP:id() then 
			--	table.insert(profileMapped, v[1])
				l = 1
				break
			end
		end
		if l==0 then 
			table.insert(profileNotMapped, objCSP) 
			styleChange = 1
		end
	end)
	--izveidojam iztrukstosos stilus
	for i,v in pairs(profileNotMapped) do 
		createCompartmentStyleSetting(coiceItemExt, v, lQuery(choiceItemProf):find("/field/context"):attr("mode"))
	end
	--stili, kam nav saderibas AA# dalaa
	local extensionNotMapped = {}
	compartmentStyleSetting:each(function(objCSE)
		local l = 0
		for i,v in pairs(link) do
			if v[2]:id()==objCSE:id() then 
				l = 1
				break
			end
		end
		if l==0 then 
			table.insert(extensionNotMapped, objCSE)
			styleChange = 1
		end
	end)
	for i,v in pairs(extensionNotMapped) do 
		--dzesam stilus
		deleteCompartStyleSetting(v)
	end
	return styleChange
end

--izveido CompartType stilus, kas ir atkarigi no choiceItem (coiceItemExt-choiceItem Instance no tipu dalas, style-stila instance)
function createCompartmentStyleSetting(coiceItemExt, style, mode)
	local parentCompartTypeExt = coiceItemExt:find("/compartType/parentCompartType")
	if parentCompartTypeExt:is_empty() then parentCompartTypeExt = coiceItemExt:find("/compartType/elemType") end--ja ir jamekle pie elementa

	local pat = lpeg.P("ASFictitious")
	if lpeg.match(pat, parentCompartTypeExt:attr("id")) then 
		parentCompartTypeExt2 = parentCompartTypeExt:find("/parentCompartType")
		if parentCompartTypeExt2:is_empty() then parentCompartTypeExt = parentCompartTypeExt:find("/elemType") 
		else parentCompartTypeExt = parentCompartTypeExt2 end--ja ir jamekle pie elementa
	end
	local contextType = lQuery(style):find("/choiceItem/field/context"):attr("type")

	local mode = lQuery(style):find("/choiceItem/field/context"):attr("mode")
	local elTypeName = lQuery(style):find("/choiceItem/field/context"):attr("elTypeName")
	
	local comType = parentCompartTypeExt:find("/subCompartType[id = '" .. lQuery(style):attr("target") .. "']")
	if comType:is_empty() then comType = parentCompartTypeExt:find("/compartType[id = '" .. lQuery(style):attr("target") .. "']") end
	local inv=0
	if parentCompartTypeExt:attr("id")=="InvRole" then inv=1 end
	comType = extensionCreate.getTarget(lQuery(style):find("/choiceItem"), lQuery(style):attr("target"), style, inv)
	--izveidojam stilu
	local elStSet = lQuery.create("CompartmentStyleSetting", {
		setting = lQuery(style):find("/fieldStyleFeature"):attr("itemName")
		,value = lQuery(style):attr("value")
		,procCondition = "setCompartStyleByChoiceItem"
		,procSetValue = lQuery(style):attr("procSetValue")
		,strength = 5
	})
	:link("compartType", comType)
	:link("choiceItem", coiceItemExt)
	
	local elemType = comType
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
	
	local setting = elStSet:attr("setting")
	--ja ir prefix stils parliekam transtletu
	if string.find(setting, "prefix-")~= nil then 
		elStSet:attr("setting", "prefix")
		elStSet:attr("settingMode", string.sub(setting, 8))
		
		if lQuery(comType):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setAllPrefixesView']"):is_empty() then
			lQuery.create("Translet", {extensionPoint = 'procGetPrefix', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setAllPrefixesView'})
			:link("type", comType)
		end
		elStSet:attr("procCondition", "setTextStyle")
	--ja ir suffix stils parliekam transtletu
	elseif string.find(setting, "suffix-")~= nil then 
		elStSet:attr("setting", "suffix")
		elStSet:attr("settingMode", string.sub(setting, 8))
		if lQuery(comType):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setAllSuffixesView']"):is_empty() then
			lQuery.create("Translet", {extensionPoint = 'procGetSuffix', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setAllSuffixesView'})
			:link("type", comType)
		end
		elStSet:attr("procCondition", "setTextStyle")
	--ja ir isVissible stils pie nestilizejama compartType parliekam transtletu
	elseif setting == "isVisible" then 
		if lQuery(comType):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setIsHidden']"):is_empty() then
			lQuery.create("Translet", {extensionPoint = 'procIsHidden', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setIsHidden'})
			:link("type", comType)
		end
		--jauzzina vai target ir stilezejams elements
		if comType:find("/elemType"):is_empty() and comType:find("/parentCompartType"):attr("isGroup") ~= "true" then 
		--if mode == "Group Item" or mode == "Text" then 
			elStSet:attr("procCondition", "setTextStyle")
		end
	end
	local ct = lQuery(coiceItemExt):find("/compartType")
	--ja vel nav targeta, tad to izveidojam
	if lQuery(ct):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDependentStyle']"):is_empty() then
		lQuery.create("Translet", {extensionPoint = 'procFieldEntered', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDependentStyle'})
		:link("type", ct)
	end
end

--izveido ElemType stilus, kas ir atkarigi no choiceItem (coiceItemExt-choiceItem Instance no tipu dalas, elemType-elementa tips kam japiekarto stils, style-stila instance)
function createElemStyleSetting(coiceItemExt, elemType, style)
	--japarbauda, vai gadijuma nav javeido stils prieks invRow
	local val = lQuery(style):find("/elemStyleFeature"):attr("itemName")
	if coiceItemExt:find("/compartType/parentCompartType"):attr("id") == "InvRole" then
		if string.find(val, "start") ~= nil then
			local startStyle = string.sub(val, 6)
			val = "end" .. startStyle
		elseif string.find(val, "end") ~= nil then
			local startStyle = string.sub(val, 4)
			val = "start" .. startStyle
		end
	end
	--izveidojam stilu
	local elStSet = lQuery.create("ElementStyleSetting", {
		setting = val
		,value = lQuery(style):attr("value")
		,procCondition = "setElemStyleByChoiceItem"
		,procSetValue = lQuery(style):attr("procSetValue")
		,strength = 5
	})
	:link("elemType", elemType)
	:link("choiceItem", coiceItemExt)
	
	--styleMechanism.setExtraStyles(coiceItemExt, style, elStSet, "element")
	
	local ct = lQuery(coiceItemExt):find("/compartType")
	if val == "widthProc" then 
		elStSet:attr("procSetValue", "setAutoWidth") 
		elStSet:attr("setting", "width") 
	end
	
	--ja vel nav transleta, tad to izveidojam
	if lQuery(ct):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDependentStyle']"):is_empty() then
		lQuery.create("Translet", {extensionPoint = 'procFieldEntered', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDependentStyle'})
		:link("type", ct)
	end
	if lQuery(elemType):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDefaultStyle']"):is_empty() then
		lQuery.create("Translet", {extensionPoint = 'procNewElement', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDefaultStyle'})
		:link("type", elemType)
	end
	if lQuery(elemType):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.styleCode']"):is_empty() then
		lQuery.create("Translet", {extensionPoint = 'procCopied', procedureName = 'OWLGrEd_UserFields.owl_fields_specific.styleCode'})
		:link("type", elemType)
	end
end

--izveido ChoiceItem-u(choiceItem-AA# dalas choiceItem, compartType-kompartmenta tips, kam ir japiekarto choiceItem)
function createChoiceItem(choiceItem, compartType)
	local ci = lQuery.create("ChoiceItem", {
		value = lQuery(choiceItem):attr("caption")
	}):link("compartType", compartType)
	--izveidot notaciju
	--if lQuery(choiceItem):find("/field/fieldType"):attr("typeName") == "CheckBox" then
	if lQuery(choiceItem):find("/field"):attr("fieldType") == "CheckBox" then
		local notation = lQuery.create("Notation", {value = lQuery(choiceItem):attr("notation")}):link("choiceItem", ci)
	else local notation = lQuery.create("Notation", {value = lQuery(choiceItem):attr("caption")}):link("choiceItem", ci)end
	local tagItem = lQuery(choiceItem):find("/tag"):each(function(objTag)--semantics
		if lQuery(objTag):attr("tagValue") ~= "" then
			local tag = lQuery.create("Tag", {
				value = lQuery(objTag):attr("tagValue")
				,key = lQuery(objTag):attr("tagKey")
			}):link("choiceItem", ci)
			
			if lQuery(objTag):attr("tagKey") == "owl_Field_axiom" then
				extensionCreate.createImportSemanticsChoiceItem(field, ci, objTag)
			end
			
			if lQuery(obj):attr("tagKey") == "owl_Axiom_Annotation" then
				--atrast vecak elementu
				local parent = ci:find("/compartType/parentCompartType")
				if parent:is_empty() then parent = ci:find("/compartType/elemType") end
							
				parent = extensionCreate.findAxiomAnnotationPath(obj, parent)
				if parent:find("/translet[extensionPoint='OWLGrEd_GetAxiomAnnotation'][procedureName = 'OWLGrEd_UserFields.axiom.getAxiomAnnotation']"):is_empty() then
					lQuery.create("Translet", {extensionPoint = 'OWLGrEd_GetAxiomAnnotation', procedureName = 'OWLGrEd_UserFields.axiom.getAxiomAnnotation'})
					:link("type", parent)
				end
				tag:link("axiomAnnotationType", parent)
			end
		end
	end)
end

--izdzes compartType stlus, kas ir atzimeti dzesanai (styleSetting-stils, kas jadzes)
function deleteCompartStyleSetting(styleSetting)
--ja compartmentam vairs nav citu piesaistito stilu, tad ir jaidzes specifisks translets
	local compartType = lQuery(styleSetting):find("/choiceItem/compartType")
	local size = lQuery(compartType):find("/choiceItem/compartmentStyleSetting"):size()
	if size <=1 then 
		lQuery(compartType):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDependentStyle']"):delete()
	end
	lQuery(styleSetting):delete()
end

--izdzes elemType stlus, kas ir atzimeti dzesanai (styleSetting-stils, kas jadzes)
function deleteElemStyleSetting(styleSetting)
	--ja compartmentam vairs nav citu piesaistito stilu, tad ir jaidzes specifisks translets
	local compartType = lQuery(styleSetting):find("/choiceItem/compartType")
	local size = lQuery(compartType):find("/choiceItem/elementStyleSetting"):size()
	if size <=1 then 
		lQuery(compartType):find("/translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDependentStyle']"):delete()
	end
	lQuery(styleSetting):delete()
end

--izdzes choiceItem ar visiem saistitam instancem(choiceItem- choiceItem, kas ir jadzes)
function deleteChoiceItem(choiceItem)
	local compartment = lQuery(choiceItem):find("/compartType/compartment"):filter(
		function(obj)
			return lQuery(obj):attr("value") == lQuery(choiceItem):attr("value")
		end)
	lQuery(compartment):delete()
	lQuery(choiceItem):find("/elementStyleSetting"):delete()
	lQuery(choiceItem):find("/compartmentStyleSetting"):delete()
	lQuery(choiceItem):find("/tag"):delete()
	lQuery(choiceItem):find("/notation"):delete()
	lQuery(choiceItem):delete()
end

--izdezes kompartType ar visiem saistitam instancem(compartType- compartType, kas ir jadzes)
function deleteCompartType(compartType)

	local propRowSize = lQuery(compartType):find("/propertyRow/propertyTab/propertyRow"):size()
	if propRowSize <=1 then lQuery(compartType):find("/propertyRow/propertyTab"):delete() end
	
	lQuery(compartType):find("/choiceItem/elementStyleSetting"):attr("isDeleted", 1)
	lQuery(compartType):find("/choiceItem/compartmentStyleSetting"):attr("isDeleted", 1)
	lQuery(compartType):find("/choiceItem/elementStyleSetting/elemType/element"):each(function(obj)
		owl_fields_specific.ElemStyleBySettings(obj, "Change")
	end)
	lQuery(compartType):find("/choiceItem/compartmentStyleSetting/compartType/compartment"):each(function(obj)
		owl_fields_specific.CompartStyleBySetting(obj, "Change")
	end)
	
	lQuery(compartType):find("/propertyRow"):delete()
	lQuery(compartType):find("/propertyDiagram"):delete()
	lQuery(compartType):find("/choiceItem/elementStyleSetting"):delete()
	lQuery(compartType):find("/choiceItem/compartmentStyleSetting"):delete()
	lQuery(compartType):find("/compartmentStyleSetting"):delete()----------------------
	lQuery(compartType):find("/choiceItem/tag"):delete()
	lQuery(compartType):find("/parentCompartType/translet[extensionPoint='OWLGrEd_GetAxiomAnnotation'][procedureName = 'OWLGrEd_UserFields.axiom.getAxiomAnnotation']"):delete()
	lQuery(compartType):find("/elemType/translet[extensionPoint='OWLGrEd_GetAxiomAnnotation'][procedureName = 'OWLGrEd_UserFields.axiom.getAxiomAnnotation']"):delete()
	lQuery(compartType):find("/choiceItem/notation"):delete()
	lQuery(compartType):find("/choiceItem"):delete()
	lQuery(compartType):find("/tag"):delete()
	lQuery(compartType):find("/translet"):delete()
	lQuery(compartType):find("/compartStyle"):delete()
	lQuery(compartType):find("/compartment"):delete()
	
	--ja ir jaizdzes palig virskompartments
	if compartType:find("/parentCompartType"):is_not_empty() and string.find(compartType:find("/parentCompartType"):attr("id"), "AutoGeneratedGroup")~=nil then
		local pr = compartType:find("/parentCompartType"):attr("adornmentPrefix")
		local suf = compartType:find("/parentCompartType"):attr("adornmentSuffix")
		--atrast vecako
		local parent = compartType:find("/parentCompartType/parentCompartType")
		--ja ir pie elemType
		if parent:is_empty() then 
			parent = compartType:find("/parentCompartType/elemType") 
			local autoGenGroup = compartType:find("/parentCompartType")
			if autoGenGroup:find("/subCompartType"):size() == 2 then 
				local tab = compartType:find("/parentCompartType/propertyRow/propertyTab")
				local dia = compartType:find("/parentCompartType/propertyRow/propertyDiagram")
				local subComparTypes = autoGenGroup:find("/subCompartType")
				subComparTypes:each(function(obj)
					if autoGenGroup:attr("id") ~= "AutoGeneratedGroupMultiplicity" then
						obj:find("/propertyRow"):remove_link("propertyTab", obj:find("/propertyRow/propertyTab"))
						obj:find("/propertyRow"):remove_link("propertyDiagram", obj:find("/propertyRow/propertyDiagram"))
					end
				end)
				subComparTypes:remove_link("parentCompartType", autoGenGroup)
				subComparTypes:link("compartStyle", autoGenGroup:find("/compartStyle"))
				local t = {}
				--saliekam dizgrama pareizeja vieta
				parent:find("/compartType"):each(function(obj)
					if obj:id() == autoGenGroup:id() then
						table.insert(t, subComparTypes)
					end
					table.insert(t, obj)
					obj:remove_link("elemType", parent)
				end)
				for i,v in pairs(t) do
					v:link("elemType", parent)
				end
				--saliekam ipasibu dialoga pareizaja vieta
				t = {}
				dia:find("/propertyRow"):each(function(obj)
					if obj:id() == autoGenGroup:find("/propertyRow"):id() then
						table.insert(t, subComparTypes:find("/propertyRow"))
					end
					table.insert(t, obj)
					obj:remove_link("propertyDiagram", dia)
				end)
				for i,v in pairs(t) do
					v:link("propertyDiagram", dia)
				end
				
				t = {}
				tab:find("/propertyRow"):each(function(obj)
					if obj:id() == autoGenGroup:find("/propertyRow"):id() then
						table.insert(t, subComparTypes:find("/propertyRow"))
					end
					table.insert(t, obj)
					obj:remove_link("propertyTab", tab)
				end)
				for i,v in pairs(t) do
					v:link("propertyTab", tab)
				end

				subComparTypes:attr("adornmentPrefix", pr)
				subComparTypes:attr("adornmentSuffix", suf)
				autoGenGroup:find("/propertyRow"):delete()
				autoGenGroup:find("/propertyDiagram"):delete()
				autoGenGroup:delete()
			end
		--ja ir pie compartType
		else
			local autoGenGroup = compartType:find("/parentCompartType")
			if autoGenGroup:find("/subCompartType"):size() == 2 then 
				local tab = compartType:find("/parentCompartType/propertyRow/propertyTab")
				local dia = compartType:find("/parentCompartType/propertyRow/propertyDiagram")
				local subComparTypes = autoGenGroup:find("/subCompartType")
				subComparTypes:each(function(obj)
					if autoGenGroup:attr("id") ~= "AutoGeneratedGroupMultiplicity" then
						obj:find("/propertyRow"):remove_link("propertyTab", obj:find("/propertyRow/propertyTab"))
						obj:find("/propertyRow"):remove_link("propertyDiagram", obj:find("/propertyRow/propertyDiagram"))
					end
				end)
				subComparTypes:remove_link("parentCompartType", autoGenGroup)
				subComparTypes:attr("adornmentPrefix", pr)
				subComparTypes:attr("adornmentSuffix", suf)
				
				local t = {}
				parent:find("/subCompartType"):each(function(obj)
					if obj:id() == autoGenGroup:id() then
						table.insert(t, subComparTypes)
					end
					table.insert(t, obj)
					obj:remove_link("parentCompartType", parent)
				end)
				for i,v in pairs(t) do
					v:link("parentCompartType", parent)
				end
				t = {}
				dia:find("/propertyRow"):each(function(obj)
					if obj:id() == autoGenGroup:find("/propertyRow"):id() then
						table.insert(t, subComparTypes:find("/propertyRow"))
					end
					table.insert(t, obj)
					obj:remove_link("propertyDiagram", dia)
				end)
				for i,v in pairs(t) do
					v:link("propertyDiagram", dia)
				end
				
				t = {}
				tab:find("/propertyRow"):each(function(obj)
					if obj:id() == autoGenGroup:find("/propertyRow"):id() then
						table.insert(t, subComparTypes:find("/propertyRow"))
					end
					table.insert(t, obj)
					obj:remove_link("propertyTab", tab)
				end)
				for i,v in pairs(t) do
					v:link("propertyTab", tab)
				end
				autoGenGroup:find("/propertyRow"):delete()
				autoGenGroup:find("/propertyDiagram"):delete()
				autoGenGroup:delete()
			end
		end
	end
	--ja ir jaizdzes checkBox+Buttom
	if compartType:find("/parentCompartType"):is_not_empty() and string.find(compartType:find("/parentCompartType"):attr("id"), "CheckBoxFictitious")~=nil then
		local pr = compartType:find("/parentCompartType"):attr("adornmentPrefix")
		local suf = compartType:find("/parentCompartType"):attr("adornmentSuffix")
		--atrast vecako
		local parent = compartType:find("/parentCompartType/parentCompartType")
		--ja ir pie elemType
		if parent:is_empty() then 
			parent = compartType:find("/parentCompartType/elemType") 
			local checkBoxFic = compartType:find("/parentCompartType")
			if checkBoxFic:find("/subCompartType"):size() == 2 then 
				local subCheckBox = checkBoxFic:find("/subCompartType")
				subCheckBox:find("/propertyRow"):attr("rowType", "CheckBox")
				subCheckBox:find("/propertyDiagram"):delete()
				subCheckBox:remove_link("parentCompartType", checkBoxFic)
				subCheckBox:link("elemType", parent)
				checkBoxFic:delete()
				subCheckBox:attr("adornmentPrefix", pr)
				subCheckBox:attr("adornmentSuffix", suf)
			end
		--ja ir pie compartType
		else
			local checkBoxFic = compartType:find("/parentCompartType")
			if checkBoxFic:find("/subCompartType"):size() == 2 then 
				local subCheckBox = checkBoxFic:find("/subCompartType")
				subCheckBox:find("/propertyRow"):attr("rowType", "CheckBox")
				subCheckBox:find("/propertyDiagram"):delete()
				subCheckBox:remove_link("parentCompartType", checkBoxFic)
				checkBoxFic:delete()
				subCheckBox:link("parentCompartType", parent)
				subCheckBox:attr("adornmentPrefix", pr)
				subCheckBox:attr("adornmentSuffix", suf)
			end
		end
	end
	
	lQuery(compartType):find("/subCompartType"):each(function(obj)
		deleteCompartType(obj)
	end)
	
	lQuery(compartType):delete()
end

function attrdir (path)
	local t = {}
	for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path..'/'..file
			if string.find(file,"%.txt$") then table.insert(t, f) end
        end
    end
	return t
end