module(..., package.seeall)

require("lua_tda")
require "lpeg"
require "core"
-- require "progress_reporter"
require "OWL_specific"
require("graph_diagram_style_utils")

specific = require "OWL_specific"
owl_fields_specific = require "OWLGrEd_UserFields.owl_fields_specific"
styleMechanism = require "OWLGrEd_UserFields.styleMechanism"

--genere kodu, kas pieliek stilu uzliksanu pie paste komandas
function styleCode(element)
	local owl_fields_specific = require "OWLGrEd_UserFields.owl_fields_specific"
	local diagram_type_code = 'element = ' .. utilities.make_obj_to_var(element) .. '\n'
	return diagram_type_code .. "r = require 'OWLGrEd_UserFields.owl_fields_specific'\n r.setCopiedStyle(element)\n"
end

function setStylesForAllDiagrams(diagrams)
	local diagramsId = ""
	diagrams:each(function(diagram)
		diagramsId = diagramsId .. tostring(diagram:id()) .. ","
	end)
	-- tda.CallFunctionWithPleaseWaitWindow("OWLGrEd_UserFields.owl_fields_specific.setStylesForAllDiagramsProgressBar", diagramsId)
	setStylesForAllDiagramsProgressBar(diagramsId)
end

function setStylesForAllDiagramsProgressBar(diagramsId)
	local grammar = re.compile([[
		gMain <- ((VarName ",")*)->{}
		VarName <- ({[0-9]*})
	]])
	local numberOfSteps = 0
	local diagramsIdTable = re.match(diagramsId, grammar)
	for i,v in pairs(diagramsIdTable) do
		local diagram = lQuery("GraphDiagram"):filter(function(dia)
			return dia:id()==tonumber(v)
		end)
		numberOfSteps = numberOfSteps + diagram:find("/element:has(/elemType/elementStyleSetting)"):size()
		numberOfSteps = numberOfSteps + diagram:find("/element/compartment:has(/compartType/compartmentStyleSetting)"):size()
		numberOfSteps = numberOfSteps + diagram:find("/element/compartment/subCompartment:has(/compartType/compartmentStyleSetting)"):size()
	end
	-- local progress_reporter = progress_reporter.create_progress_logger(numberOfSteps, "Recalculating styles...")
	for i,v in pairs(diagramsIdTable) do
		local diagram = lQuery("GraphDiagram"):filter(function(dia)
			return dia:id()==tonumber(v)
		end)
		diagram:find("/element"):each(function(element)
			setDefaultStyle(element, nil)
			-- setDefaultStyle(element, progress_reporter)
		end)
	end
end

--uzstada stilus importa laika (diagram-diagrama, kurai uzstadam stilus)
function setImportStyles(diagram)
	-- tda.CallFunctionWithPleaseWaitWindow("OWLGrEd_UserFields.owl_fields_specific.setImportStylesProgressBar", tostring(diagram:id()))
	setImportStylesProgressBar(tostring(diagram:id()))
	-- diagram:find("/element"):each(function(element)
		-- setDefaultStyle(element)
	-- end)
end

function setImportStylesProgressBar(diagramId)
	local diagram = lQuery("GraphDiagram"):filter(function(obj)
		return obj:id()==tonumber(diagramId)
	end)
	
	diagram:find("/element:has(/elemType[id='Association'])/compartment/subCompartment:has(/compartType[id='IsComposition'])"):each(function(com)
	    OWL_specific.set_assoc_style(com)
	end)
	
	local numberOfSteps = diagram:find("/element:has(/elemType/elementStyleSetting)"):size()
	numberOfSteps = numberOfSteps + diagram:find("/element/compartment:has(/compartType/compartmentStyleSetting)"):size()
	numberOfSteps = numberOfSteps + diagram:find("/element/compartment/subCompartment:has(/compartType/compartmentStyleSetting)"):size()
	
	-- local progress_reporter = progress_reporter.create_progress_logger(numberOfSteps, "Recalculating styles...")
	
	diagram:find("/element"):each(function(element)
		setDefaultStyle(element, nil)
		-- setDefaultStyle(element, progress_reporter)
	end)
end

function setCopiedStyle(element)
	local diagram = utilities.current_diagram()
	graph_diagram_style_utils.save_diagram_element_and_compartment_styles(diagram)
		

	if element:find("/elemType/elementStyleSetting"):is_not_empty() then 
		local parameterTable = {}
		parameterTable["copy"] = "true"
		ElemStyleBySettings(element, 0, 0, 1, parameterTable) 
	end

	local a = lQuery(element):find("/compartment:has(/compartType/compartmentStyleSetting)"):map(function(obj)
			return obj
	end)
	local b = lQuery(element):find("/compartment/subCompartment:has(/compartType/compartmentStyleSetting)"):map(function(obj)
		return obj
	end)
	local values = lQuery.merge(a, b)
	for i,v in pairs(values) do
		
		local parameterTable = {}
		parameterTable["copy"] = "true"
		CompartStyleBySetting(v, 0, 0, 1, parameterTable)
	end
	
	lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
			graph_diagram_style_utils.save_diagram_element_and_compartment_styles(diagram)
	end)
end

--uzstadam nokluseto stilu (element - elements, kam tiek uzstadits stils)
function setDefaultStyle(element, progress_reporter_fn)
	-- progress_reporter_fn = progress_reporter_fn or function() end
	
	if element:find("/elemType/elementStyleSetting"):is_not_empty() then 
		-- progress_reporter_fn()
		
		local parameterTable = {}
		parameterTable["import"] = "true"
		ElemStyleBySettings(element, 0, 0, 1, parameterTable) 
	end

	local a = lQuery(element):find("/compartment:has(/compartType/compartmentStyleSetting)"):map(function(obj)
			return obj
	end)
	local b = lQuery(element):find("/compartment/subCompartment:has(/compartType/compartmentStyleSetting)"):map(function(obj)
		return obj
	end)
	local values = lQuery.merge(a, b)
	for i,v in pairs(values) do
		-- progress_reporter_fn()
		CompartStyleBySetting(v, 0, 0, 1)
	end
	
	lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
			graph_diagram_style_utils.save_diagram_element_and_compartment_styles(diagram)
	end)
end

--atkodejam node style atributa vertibas (text-style atributa vertiba)
function parseNodeStyle(text)
	local Letter = lpeg.R("az") + lpeg.R("AZ") + lpeg.R("09") + lpeg.S("_ ")
	local String = lpeg.C(Letter * (Letter) ^ 0)
	
	local separater = lpeg.P(";")
	local open = lpeg.P("[")
	local close = lpeg.P("]")
	local a = lpeg.P("#")

	
	local Exp, NodeStyle, Shape, Picture = lpeg.V"Exp", lpeg.V"NodeStyle", lpeg.V"Shape", lpeg.V"Picture"
	G = lpeg.P{Exp,
		Exp = open * NodeStyle * close + a;
		NodeStyle = open * Shape * close * open * Picture * close;
		Shape = String * separater * (String * separater) ^ 0;
		Picture = String * separater * (String * separater) ^ 0 + separater;
	}
	
	local FunNamePat = lpeg.P(lpeg.Ct(G))
	local t = lpeg.match(FunNamePat, text)
	return t
end   

-- atkodeja nede width un height vertibas (text-style atributa vertiba)
function parseLocation(text)
	local Letter = lpeg.R("09")
	local String = lpeg.C(Letter * (Letter) ^ 0)
	
	local separater = lpeg.P(";")
	local a = lpeg.P("#")

	
	local Exp = lpeg.V"Exp"
	G = lpeg.P{Exp,
		Exp = String * separater * (String * separater) ^ 0;
	}
	
	local FunNamePat = lpeg.P(lpeg.Ct(G))
	local t = lpeg.match(FunNamePat, text)
	return t
end

--atkodejam Edge style atributa vertibas (text-style atributa vertiba)
function parseEdgeStyle(text)
	local Letter = lpeg.R("az") + lpeg.R("AZ") + lpeg.R("09") + lpeg.S("_ ")
	local String = lpeg.C(Letter * (Letter) ^ 0)
	
	local separater = lpeg.P(";")
	local open = lpeg.P("[")
	local close = lpeg.P("]")
	local a = lpeg.P("#")
	
	local Exp, EdgeStyle, Shape = lpeg.V"Exp", lpeg.V"EdgeStyle", lpeg.V"Shape"
	G = lpeg.P{Exp,
		Exp = open * EdgeStyle * close + a;
		EdgeStyle = open * Shape * close * String * separater * String * separater * (String * separater * String * separater)^0 * open * Shape * close * open * Shape * close * open * Shape * close;
		Shape = String * separater * (String * separater) ^ 0;
	}
	
	local FunNamePat = lpeg.P(lpeg.Ct(G))
	local t = lpeg.match(FunNamePat, text)
	return t
end 

--atkodejam compartment style atributa vertibas (text-style atributa vertiba)
function parseCompartStyle(text)

	local Letter = lpeg.R("az") + lpeg.R("AZ") + lpeg.R("09") + lpeg.S("_ (<>=#/)-")
	local String = lpeg.C(Letter * (Letter) ^ 0)
	
	local separater = lpeg.P(";")
	local open = lpeg.P("[")
	local close = lpeg.P("]")
	local a = lpeg.P("#")
	local b = lpeg.P("")
	
	local Exp, CompartStyle, Shape, Picture = lpeg.V"Exp", lpeg.V"CompartStyle", lpeg.V"Shape", lpeg.V"Picture"
	G = lpeg.P{Exp,
		Exp = open * CompartStyle * close + a + b;
		CompartStyle = String * separater * String * separater * String * separater * String * separater * open * Shape * close * 
			String * separater * String * separater * String * separater * String * separater * String * separater * String * separater * String * separater * open * Shape * close * 
			open * Picture * close;
		Shape = String * separater * (String * separater) ^ 0;
		Picture = String * separater * (String * separater) ^ 0 + separater;
	}
	
	local FunNamePat = lpeg.P(lpeg.Ct(G))
	local t = lpeg.match(FunNamePat, text)
	--print(dumptable(t))
	return t
end 

--uzstada stila vienumus (compartment - kompartments, kam uzstada stilus)   
function setStyleSetting(compartment)
	lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
			utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
	end)
	local elem
	local l = 0
	while l==0 do
		elem = compartment:find("/element")
		if elem:is_not_empty() then l=1
		else
			compartment = compartment:find("/parentCompartment")
		end
	end
	if elem:find("/elemType/elementStyleSetting"):is_not_empty() then ElemStyleBySettings(elem, 0, 0, 1) end
	local a = lQuery(elem):find("/compartment:has(/compartType/compartmentStyleSetting)"):map(function(obj)
			return obj
	end)
	local b = lQuery(elem):find("/compartment/subCompartment:has(/compartType/compartmentStyleSetting)"):map(function(obj)
		return obj
	end)
	local values = lQuery.merge(a, b)
	for i,v in pairs(values) do
		CompartStyleBySetting(v, 0, 0, 1)
	end
	
	lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
			graph_diagram_style_utils.save_diagram_element_and_compartment_styles(diagram)
	end)
end

--uzstada pazimi, ka lauks ir jaslepj
function setIsHiddenYes()
	return true
end

--uzstada pazimi, ka lauks ir jarada
function setIsHiddenNo()
	return false
end

function setTextStyle()
end

--paslepj vai rada dzilaka limena kompartmentu no skatijums (compartment - kompartments, kam uzstada stilus)
function setIsHiddenView(compartment)
	-- print("MMMMMMMMMMMMMMMMMMMMMMMM")
	local result = false
	local compartStyleSetting = compartment:find("/compartType/compartmentStyleSetting[setting='isVisible']:has(/extension)"):each(function(obj)
		if setCompartStyleByExtension(compartment, obj) == true then 
			if obj:attr("value")=="0" then result = true end
		end
	end)
	return result
end

function setAllPrefixesView(dataCompartType, dataCompartment, parsingCompartment)
	local result = ""
	local oldPrefix
	if dataCompartment~=nil then
		oldPrefix = dataCompartment:find("/compartType"):attr("adornmentPrefix")
	else
		oldPrefix = dataCompartType:attr("adornmentPrefix")
	end
	oldPrefix = setPrefixView(dataCompartType, dataCompartment, parsingCompartment, oldPrefix)
	oldPrefix = setPrefix(dataCompartType, dataCompartment, parsingCompartment, oldPrefix)
	oldPrefix = setPrefixViewAndChoiceItem(dataCompartType, dataCompartment, parsingCompartment, oldPrefix)
	result = oldPrefix
	--print(result)
	return result
end

function setAllSuffixesView(dataCompartType, dataCompartment, parsingCompartment)
	local result = ""
	local oldSuffix
	if dataCompartment~=nil then
		oldSuffix = dataCompartment:find("/compartType"):attr("adornmentSuffix")
	else
		oldSuffix = dataCompartType:attr("adornmentSuffix")
	end
	oldSuffix = setSuffixView(dataCompartType, dataCompartment, parsingCompartment, oldSuffix)
	oldSuffix = setSuffix(dataCompartType, dataCompartment, parsingCompartment, oldSuffix)
	oldSuffix = setSuffixViewAndChoiceItem(dataCompartType, dataCompartment, parsingCompartment, oldSuffix)
	result = oldSuffix
	return result
end

--uzstada prefiksus no skatijuma (dataCompartType-kompartmenta tips no kura ir atkariga prefiksa uzliksana, dataCompartment-kompartments no kura ir atkariga prefiksa uzliksana, parsingCompartment-kompartment, kam jaustada prefikss)
function setPrefixView(dataCompartType, dataCompartment, parsingCompartment, oldPrefix)
	local result = ""
	if dataCompartment~=nil then
	--	local oldPrefix = dataCompartment:find("/compartType"):attr("adornmentPrefix")
		local compartStyleSetting = dataCompartment:find("/compartType/compartmentStyleSetting[setting='prefix'][strength='3']:has(/extension)"):each(function(obj)
			if setCompartStyleByExtension(dataCompartment, obj) == true then 
				if obj:attr("settingMode") == "inside" then
					oldPrefix = oldPrefix .. obj:attr("value")
				elseif obj:attr("settingMode") == "outside" then
					oldPrefix = obj:attr("value") .. oldPrefix
				elseif obj:attr("settingMode") == "inPlace" then
					oldPrefix = obj:attr("value")
				end
			end
		end)
		result = oldPrefix
	else
		--local oldPrefix = dataCompartType:attr("adornmentPrefix")
		local compartStyleSetting = dataCompartType:find("/compartmentStyleSetting[setting='prefix'][strength='3']:has(/extension)"):each(function(obj)
			if setCompartStyleByExtension(parsingCompartment, obj, dataCompartType) == true then 
				if obj:attr("settingMode") == "inside" then
					oldPrefix = oldPrefix .. obj:attr("value")
				elseif obj:attr("settingMode") == "outside" then
					oldPrefix = obj:attr("value") .. oldPrefix
				elseif obj:attr("settingMode") == "inPlace" then
					oldPrefix = obj:attr("value")
				end
			end
		end)
		result = oldPrefix
	end
	return result
end

--uzstada sufiksus no skatijuma (dataCompartType-kompartmenta tips no kura ir atkariga sufiksa uzliksana, dataCompartment-kompartments no kura ir atkariga sufiksa uzliksana, parsingCompartment-kompartment, kam jaustada sufikss)
function setSuffixView(dataCompartType, dataCompartment, parsingCompartment, oldSuffix)
	local result = ""
	if dataCompartment~=nil then
		--local oldSuffix = dataCompartment:find("/compartType"):attr("adornmentPrefix")
		local compartStyleSetting = dataCompartment:find("/compartType/compartmentStyleSetting[setting='suffix'][strength='3']:has(/extension)"):each(function(obj)
			if setCompartStyleByExtension(dataCompartment, obj) == true then 
				if obj:attr("settingMode") == "inside" then
					oldSuffix = obj:attr("value") .. oldSuffix
				elseif obj:attr("settingMode") == "outside" then
					oldSuffix = oldSuffix .. obj:attr("value")
				elseif obj:attr("settingMode") == "inPlace" then
					oldSuffix = obj:attr("value")
				end
			end
		end)
		result = oldSuffix
	else
		--local oldSuffix = dataCompartType:attr("adornmentPrefix")
		local compartStyleSetting = dataCompartType:find("/compartmentStyleSetting[setting='suffix'][strength='3']:has(/extension)"):each(function(obj)
			if setCompartStyleByExtension(dataCompartment, obj, dataCompartType) == true then 
				if obj:attr("settingMode") == "inside" then
					oldSuffix = obj:attr("value") .. oldSuffix
				elseif obj:attr("settingMode") == "outside" then
					oldSuffix = oldSuffix .. obj:attr("value")
				elseif obj:attr("settingMode") == "inPlace" then
					oldSuffix = obj:attr("value")
				end
			end
		end)
		result = oldSuffix
	end
	return result
end

--uzstada prefiksus no izveles vienuma (dataCompartType-kompartmenta tips no kura ir atkariga prefiksa uzliksana, dataCompartment-kompartments no kura ir atkariga prefiksa uzliksana, parsingCompartment-kompartment, kam jaustada prefikss)
function setPrefixViewAndChoiceItem(dataCompartType, dataCompartment, parsingCompartment, oldPrefix)
	local result = false
	local resultEx = false
	local resultCI = false
	
	--atrast elementu no compartmenta

	local prefix = ""
	if dataCompartment~=nil then
		--atrodam tekoso prefiksu
		--local oldPrefix = dataCompartment:find("/compartType"):attr("adornmentPrefix")
		local dataCompartType = dataCompartment:find("/compartType")
		dataCompartType:find("/compartmentStyleSetting[setting='prefix'][strength='10']"):each(function(css)
			local choiceItem = css:find("/choiceItem")
			local choiceItemCompartType = css:find("/choiceItem/compartType")
			local compartTypeMin = findCompartTypeMin(dataCompartType, choiceItemCompartType)
			local compartmentMinTop = compartTypeMin:find("/compartment")
			--jadabu istais compartments
			
			local compartmentMinTop = findCompartment(dataCompartment, compartTypeMin)
			local choiceItemCompartment = findChoiceItemCompartment(compartmentMinTop, choiceItemCompartType)
			
			if choiceItemCompartment~=nil and choiceItemCompartment:attr("value") == choiceItem:attr("value") and setCompartStyleByExtension(dataCompartment, css, dataCompartType)==true then 
				if css:attr("settingMode") == "inside" then
					oldPrefix = oldPrefix .. css:attr("value")
				elseif css:attr("settingMode") == "outside" then
					oldPrefix = css:attr("value") .. oldPrefix
				elseif css:attr("settingMode") == "inPlace" then
					oldPrefix = css:attr("value")
				end
			end
		end)
		prefix = oldPrefix
	else
		--atrodam tekoso prefiksu
		--local oldPrefix = dataCompartType:attr("adornmentPrefix")
		dataCompartType:find("/compartmentStyleSetting[setting='prefix'][strength='10']"):each(function(css)
			local choiceItem = css:find("/choiceItem")
			local choiceItemCompartType = css:find("/choiceItem/compartType")
			local compartTypeMin = findCompartTypeMin(parsingCompartment:find("/compartType"), choiceItemCompartType)
			--jadabu istais compartments
			local compartmentMinTop = findCompartment(parsingCompartment, compartTypeMin)
			local choiceItemCompartment = findChoiceItemCompartment(compartmentMinTop, choiceItemCompartType)
			if choiceItemCompartment~=nil and choiceItemCompartment:attr("value") == choiceItem:attr("value") and setCompartStyleByExtension("", css, dataCompartType)==true then 
				if css:attr("settingMode") == "inside" then
					oldPrefix = oldPrefix .. css:attr("value")
				elseif css:attr("settingMode") == "outside" then
					oldPrefix = css:attr("value") .. oldPrefix
				elseif css:attr("settingMode") == "inPlace" then
					oldPrefix = css:attr("value")
				end
			end
		end)
		prefix = oldPrefix
	end
	return prefix
end

--uzstada sufiksus no izveles vienuma (dataCompartType-kompartmenta tips no kura ir atkariga sufiksa uzliksana, dataCompartment-kompartments no kura ir atkariga sufiksa uzliksana, parsingCompartment-kompartment, kam jaustada sufikss)
function setSuffixViewAndChoiceItem(dataCompartType, dataCompartment, parsingCompartment, oldSuffix)

	local suffix = ""
	if dataCompartment~=nil then
		--atrodam tekoso sufiksu
		--local oldSuffix = dataCompartment:find("/compartType"):attr("adornmentPrefix")
		local dataCompartType = dataCompartment:find("/compartType")
		dataCompartType:find("/compartmentStyleSetting[setting='suffix'][strength='10']"):each(function(css)
			local choiceItem = css:find("/choiceItem")
			local choiceItemCompartType = css:find("/choiceItem/compartType")
			local compartTypeMin = findCompartTypeMin(dataCompartType, choiceItemCompartType)
			local compartmentMinTop = compartTypeMin:find("/compartment")
			--jadabu istais compartments
			
			local compartmentMinTop = findCompartment(dataCompartment, compartTypeMin)
			local choiceItemCompartment = findChoiceItemCompartment(compartmentMinTop, choiceItemCompartType)
			
			if choiceItemCompartment~=nil and choiceItemCompartment:attr("value") == choiceItem:attr("value") and setCompartStyleByExtension(dataCompartment, css, dataCompartType)==true then 
				if css:attr("settingMode") == "inside" then
					oldSuffix = oldSuffix .. css:attr("value")
				elseif css:attr("settingMode") == "outside" then
					oldSuffix = css:attr("value") .. oldSuffix
				elseif css:attr("settingMode") == "inPlace" then
					oldSuffix = css:attr("value")
				end
			end
		end)
		
		suffix = oldSuffix
	else
		--atrodam tekoso sufiksu
		--local oldSuffix = dataCompartType:attr("adornmentPrefix")
		dataCompartType:find("/compartmentStyleSetting[setting='suffix'][strength='10']"):each(function(css)
			local choiceItem = css:find("/choiceItem")
			local choiceItemCompartType = css:find("/choiceItem/compartType")
			local compartTypeMin = findCompartTypeMin(parsingCompartment:find("/compartType"), choiceItemCompartType)

			--jadabu istais compartments
			
			local compartmentMinTop = findCompartment(parsingCompartment, compartTypeMin)
		
			local choiceItemCompartment = findChoiceItemCompartment(compartmentMinTop, choiceItemCompartType)
			
			if choiceItemCompartment~=nil and choiceItemCompartment:attr("value") == choiceItem:attr("value") and setCompartStyleByExtension("", css, dataCompartType)==true then 
				if css:attr("settingMode") == "inside" then
					oldSuffix = oldSuffix .. css:attr("value")
				elseif css:attr("settingMode") == "outside" then
					oldSuffix = css:attr("value") .. oldSuffix
				elseif css:attr("settingMode") == "inPlace" then
					oldSuffix = css:attr("value")
				end
			end
		end)
		
		suffix = oldSuffix
	end
	return suffix
end

--paslepj vai rada dzilaka limena kompartmentu no skatijuma un izveles vienuma (compartment - kompartments, kam uzstada stilus)
function setIsHiddenViewAndChoiceItem(compartment)
	local result = false
	local resultEx = false
	local resultCI = false
	--atrast elementu no compartmenta
	local compartment2 = compartment
	local compartType = compartment:find("/compartType")
	local element
	local l = 0
	while l == 0 do
		if compartment:find("/element"):is_not_empty() then
			element = compartment:find("/element")
			l=1
		else
			compartment = compartment:find("/parentCompartment")
			if compartment:is_empty() then break end
		end
	end
	if element~=nil then 
		local graphDiagram = element:find("/graphDiagram")
		compartment2:find("/compartType/compartmentStyleSetting[setting='isVisible']"):each(function(compartStyleSetting)
			local extension = compartStyleSetting:find("/extension")
			--noskaidrojam vai dotajai diagramai ir uzstadits views
			graphDiagram:find("/activeExtension"):each(function(ext)
				if extension:id() == ext:id() and compartType:id() == compartStyleSetting:find("/compartType"):id() then resultEx = true end
			end)
			--no compartmenta atrast vecakelementu
			--atrast visus ta pasa limena elementus
			local parent = compartment2:find("/parentCompartment")
			
			if parent:is_empty() then 
				parent = compartment2:find("/element")
				local subCompartment = lQuery(compartStyleSetting):find("/choiceItem/compartType/compartment"):filter(
					function(obj)
						return lQuery(obj):find("/element"):id() == lQuery(parent):id()
					end)
				lQuery(subCompartment):each(function(obj)
					local compartValue = lQuery(obj):attr("value")
					lQuery(compartStyleSetting):find("/choiceItem"):each(function(objI)
						if compartValue == lQuery(objI):attr("value") then resultCI = true end
					end)
				end)
			else
				local subCompartment = lQuery(compartStyleSetting):find("/choiceItem/compartType/compartment"):filter(
					function(obj)
						return lQuery(obj):find("/parentCompartment"):id() == lQuery(parent):id()
					end)
				lQuery(subCompartment):each(function(obj)
					local compartValue = lQuery(obj):attr("value")
					lQuery(compartStyleSetting):find("/choiceItem"):each(function(objI)
						if compartValue == lQuery(objI):attr("value") then resultCI = true end
					end)
				end)
			end
			if resultEx == true and resultCI == true then 
				if compartStyleSetting:attr("value") == "0" then result = true
				else result = false end
			end
		end)
	end
	return result
end

--paslepj vai rada dzilaka limena kompartmentu no izveles vienuma (compartment - kompartments, kam uzstada stilus)
function setIsHidden(compartment)
	local ret = false
	if compartment:find("/parentCompartment"):is_not_empty() then 
		local compartmentElement
		local com1 = compartment
		local l = 0
		while l==0 do
			compartmentElement = com1:find("/element")
			if compartmentElement:is_empty() then com1 = com1:find("/parentCompartment")
			else l = 1 end
		end
		local parentCompartmentId = compartment:find("/parentCompartment"):id()
		compartment:find("/compartType/compartmentStyleSetting[setting='isVisible']"):each(function(obj)
			if obj:attr("value")=="0" then
				
				local com = obj:find("/choiceItem/compartType/compartment")
				if com:is_not_empty() then 
					com = com:filter(function(objC)
						local elem
						local com1 = com
						local l = 0
						while l==0 do
							elem = com1:find("/element")
							if elem:is_empty() then com1 = com1:find("/parentCompartment")
							else l = 1 end
						end
						return elem:id() == compartmentElement:id()
					end)
					local choiceItemValue = obj:find("/choiceItem"):attr("value")
					com:each(function(objC)
						if objC:attr("value") == choiceItemValue then ret=true end
					end)
				end
				
				-- local choiceItemValue = obj:find("/choiceItem"):attr("value")
				-- local com = obj:find("/choiceItem/compartType/compartment")
				-- com = com:filter(function(objC)
					-- return objC:find("/parentCompartment"):id() == parentCompartmentId
				-- end)
				-- com:each(function(objC)
					-- if objC:attr("value") == choiceItemValue then ret=true end
				-- end)
			end
		end)
	end
	return ret
end

--uzstada lietotaja defineta lauka prefiksu (dataCompartType-kompartmenta tips no kura ir atkariga prefiksa uzliksana, dataCompartment-kompartments no kura ir atkariga prefiksa uzliksana, parsingCompartment-kompartment, kam jaustada prefikss)
function setPrefixField(dataCompartType, compartment, parsingCompartment)
	local prefix = ""
	if compartment~=nil then
		local compartType = compartment:find("/compartType")
		local oldPrefix = compartType:attr("adornmentPrefix")
		local css = compartType:find("/compartmentStyleSetting[setting='prefix']"):filter(function(obj)
			return lQuery(obj):find("/choiceItem"):is_empty()
		end)
		css:each(function(obj)
			if obj:attr("settingMode") == "inside" then
				oldPrefix = oldPrefix .. obj:attr("value")
			elseif obj:attr("settingMode") == "outside" then
				oldPrefix = obj:attr("value") .. oldPrefix
			elseif obj:attr("settingMode") == "inPlace" then
				oldPrefix = obj:attr("value")
			end
		end)
		prefix = oldPrefix
	else
		local compartType = dataCompartType
		local oldPrefix = compartType:attr("adornmentPrefix")
		local css = compartType:find("/compartmentStyleSetting[setting='prefix']"):filter(function(obj)
			return lQuery(obj):find("/choiceItem"):is_empty()
		end)
		css:each(function(obj)
			if obj:attr("settingMode") == "inside" then
				oldPrefix = oldPrefix .. obj:attr("value")
			elseif obj:attr("settingMode") == "outside" then
				oldPrefix = obj:attr("value") .. oldPrefix
			elseif obj:attr("settingMode") == "inPlace" then
				oldPrefix = obj:attr("value")
			end
		end)
		prefix = oldPrefix
	end
	return prefix
end

--uzstada lietotaja defineta lauka sufiksu (dataCompartType-kompartmenta tips no kura ir atkariga sufiksa uzliksana, dataCompartment-kompartments no kura ir atkariga sufiksa uzliksana, parsingCompartment-kompartment, kam jaustada sufikss)
function setSuffixField(dataCompartType, compartment, parsingCompartment)
	local suffix = ""
	if compartment~=nil then
		local compartType = compartment:find("/compartType")
		local oldSuffix = compartType:attr("adornmentPrefix")
		local css = compartType:find("/compartmentStyleSetting[setting='suffix']"):filter(function(obj)
			return lQuery(obj):find("/choiceItem"):is_empty()
		end)
		css:each(function(obj)
			if obj:attr("settingMode") == "inside" then
				oldSuffix = obj:attr("value") .. oldSuffix
			elseif obj:attr("settingMode") == "outside" then
				oldSuffix = oldSuffix .. obj:attr("value")
			elseif obj:attr("settingMode") == "inPlace" then
				oldSuffix = obj:attr("value")
			end
		end)
		suffix = oldSuffix
	else
		local compartType = dataCompartType
		local oldSuffix = compartType:attr("adornmentPrefix")
		local css = compartType:find("/compartmentStyleSetting[setting='suffix']"):filter(function(obj)
			return lQuery(obj):find("/choiceItem"):is_empty()
		end)
		css:each(function(obj)
			if obj:attr("settingMode") == "inside" then
				oldSuffix = obj:attr("value") .. oldSuffix
			elseif obj:attr("settingMode") == "outside" then
				oldSuffix = oldSuffix .. obj:attr("value")
			elseif obj:attr("settingMode") == "inPlace" then
				oldSuffix = obj:attr("value")
			end
		end)
		suffix = oldSuffix
	end
	return suffix
end

--atrod cik dzili atrodas compartmenta tips (compartType-kompartmenta tips, kam jaatrod dzilums)
function findHeight(compartType)
	local elemType
	local count = 0
	local l = 0
	while l == 0 do
		if compartType:find("/elemType"):is_not_empty() then
			elemType = compartType:find("/elemType")
			l=1
		else
			compartType = compartType:find("/parentCompartType")
			count = count + 1
		end
	end
	return count
end

--atrod minimalo vecak elementu diviem kompartmenta tipiem
function findCompartTypeMin(dataCompartType, choiceItemCompartType)
	--saskaitit dzilumu
	local heightDataCompartType = findHeight(dataCompartType)
	local heightChoiceItemCompartType = findHeight(choiceItemCompartType)
	--parbaudit, vai kads nav piesiets uzreiz pie elemType
	if heightDataCompartType == 0 then return dataCompartType:find("/elemType") end
	if heightChoiceItemCompartType == 0 then return choiceItemCompartType:find("/elemType") end
	local l = 0
	while l == 0 do 
		if dataCompartType:attr("id") == choiceItemCompartType:attr("id") then 
			l=1
			return dataCompartType
		else
			if heightDataCompartType>=heightChoiceItemCompartType then 
				if dataCompartType:find("/parentCompartType"):is_not_empty() then dataCompartType = dataCompartType:find("/parentCompartType")
				else return dataCompartType:find("/elemType") end
				heightDataCompartType = heightDataCompartType - 1
			else 
				if choiceItemCompartType:find("/parentCompartType"):is_not_empty() then choiceItemCompartType = choiceItemCompartType:find("/parentCompartType")
				else return choiceItemCompartType:find("/elemType") end
				heightChoiceItemCompartType = heightChoiceItemCompartType - 1
			end
		end
	end
end

--no dota kompartmenta atrod minimalo vecako(compartment-dotais kompartments, compartTypeMin-mimumala vecak elementa tips)
function findCompartment(compartment, compartTypeMin)
	local l = 0
	while l == 0 do
		if compartment:find("/compartType"):attr("id") == compartTypeMin:attr("id") then return compartment 
		else
			if compartment:find("/parentCompartment"):is_not_empty() then
				compartment = compartment:find("/parentCompartment")
			else
				compartment = compartment:find("/element")
				return compartment 
			end
		end
	end
end

--atrod atkarigo compartmentu
function findChoiceItemCompartment(compartmentMinTop, choiceItemCompartType)
	local a 
	choiceItemCompartType:find("/compartment"):each(function(chc)
		local cMinTop = findCompartment(chc, compartmentMinTop:find("/compartType"))
		if cMinTop:id() == compartmentMinTop:id() then 
		a = chc end
	end)
	return a
end

--uzstada prefiksus (dataCompartType-kompartmenta tips no kura ir atkariga prefiksa uzliksana, dataCompartment-kompartments no kura ir atkariga prefiksa uzliksana, parsingCompartment-kompartment, kam jaustada prefikss)
function setPrefix(dataCompartType, dataCompartment, parsingCompartment, oldPrefix)
	local prefix = ""
	if dataCompartment~=nil then
		--atrodam tekoso prefiksu
		--local oldPrefix = dataCompartment:find("/compartType"):attr("adornmentPrefix")
		local dataCompartType = dataCompartment:find("/compartType")
		dataCompartType:find("/compartmentStyleSetting[setting='prefix'][strength='5']"):each(function(css)
			local choiceItem = css:find("/choiceItem")
			local choiceItemCompartType = css:find("/choiceItem/compartType")
			local compartTypeMin = findCompartTypeMin(dataCompartType, choiceItemCompartType)
			local compartmentMinTop = compartTypeMin:find("/compartment")
			--jadabu istais compartments
			
			local compartmentMinTop = findCompartment(dataCompartment, compartTypeMin)
			local choiceItemCompartment = findChoiceItemCompartment(compartmentMinTop, choiceItemCompartType)
			
			if choiceItemCompartment~=nil and choiceItemCompartment:attr("value") == choiceItem:attr("value") then 
				if css:attr("settingMode") == "inside" then
					oldPrefix = oldPrefix .. css:attr("value")
				elseif css:attr("settingMode") == "outside" then
					oldPrefix = css:attr("value") .. oldPrefix
				elseif css:attr("settingMode") == "inPlace" then
					oldPrefix = css:attr("value")
				end
			end
		end)
		prefix = oldPrefix
	else
		--atrodam tekoso prefiksu
		--local oldPrefix = dataCompartType:attr("adornmentPrefix")
		dataCompartType:find("/compartmentStyleSetting[setting='prefix'][strength='5']"):each(function(css)
			local choiceItem = css:find("/choiceItem")
			local choiceItemCompartType = css:find("/choiceItem/compartType")
			local compartTypeMin = findCompartTypeMin(parsingCompartment:find("/compartType"), choiceItemCompartType)
			--jadabu istais compartments
			
			local compartmentMinTop = findCompartment(parsingCompartment, compartTypeMin)
			
			local choiceItemCompartment = findChoiceItemCompartment(compartmentMinTop, choiceItemCompartType)
			
			if choiceItemCompartment~=nil and choiceItemCompartment:attr("value") == choiceItem:attr("value") then 
				if css:attr("settingMode") == "inside" then
					oldPrefix = oldPrefix .. css:attr("value")
				elseif css:attr("settingMode") == "outside" then
					oldPrefix = css:attr("value") .. oldPrefix
				elseif css:attr("settingMode") == "inPlace" then
					oldPrefix = css:attr("value")
				end
			end
		end)
		prefix = oldPrefix
	end
	return prefix
end

--uzstada sufiksus (dataCompartType-kompartmenta tips no kura ir atkariga sufiksa uzliksana, dataCompartment-kompartments no kura ir atkariga sufiksa uzliksana, parsingCompartment-kompartment, kam jaustada sufikss)
function setSuffix(dataCompartType, dataCompartment, parsingCompartment, oldSuffix)
	local suffix = ""
	if dataCompartment~=nil then
		--atrodam tekoso prefiksu
		--local oldSuffix = dataCompartment:find("/compartType"):attr("adornmentPrefix")
		local dataCompartType = dataCompartment:find("/compartType")
		dataCompartType:find("/compartmentStyleSetting[setting='suffix'][strength='5']"):each(function(css)
			local choiceItem = css:find("/choiceItem")
			local choiceItemCompartType = css:find("/choiceItem/compartType")
			local compartTypeMin = findCompartTypeMin(dataCompartType, choiceItemCompartType)
			--local compartmentMinTop = compartTypeMin:find("/compartment")
			--jadabu istais compartments
			
			local compartmentMinTop = findCompartment(dataCompartment, compartTypeMin)
			
			local choiceItemCompartment = findChoiceItemCompartment(compartmentMinTop, choiceItemCompartType)
			
			if choiceItemCompartment~=nil and choiceItemCompartment:attr("value") == choiceItem:attr("value") then 
				if css:attr("settingMode") == "inside" then
					oldSuffix = oldSuffix .. css:attr("value")
				elseif css:attr("settingMode") == "outside" then
					oldSuffix = css:attr("value") .. oldSuffix
				elseif css:attr("settingMode") == "inPlace" then
					oldSuffix = css:attr("value")
				end
			end
		end)
		suffix = oldSuffix
	else
		--atrodam tekoso prefiksu
		--local oldSuffix = dataCompartType:attr("adornmentPrefix")
		dataCompartType:find("/compartmentStyleSetting[setting='suffix'][strength='5']"):each(function(css)
			local choiceItem = css:find("/choiceItem")
			local choiceItemCompartType = css:find("/choiceItem/compartType")
			local compartTypeMin = findCompartTypeMin(parsingCompartment:find("/compartType"), choiceItemCompartType)
			
			--jadabu istais compartments
			local compartmentMinTop = findCompartment(parsingCompartment, compartTypeMin)
			
			local choiceItemCompartment = findChoiceItemCompartment(compartmentMinTop, choiceItemCompartType)
			
			if choiceItemCompartment~=nil and choiceItemCompartment:attr("value") == choiceItem:attr("value") then 
				if css:attr("settingMode") == "inside" then
					oldSuffix = oldSuffix .. css:attr("value")
				elseif css:attr("settingMode") == "outside" then
					oldSuffix = css:attr("value") .. oldSuffix
				elseif css:attr("settingMode") == "inPlace" then
					oldSuffix = css:attr("value")
				end
			end
		end)
		suffix = oldSuffix
	end
	return suffix
end

--uzstada stilus, kas ir atkarigi no izveleta izveles vienuma (compartment-kompartments, kura tika izvelets vienums, oldValue-veca kompartmenta vertiba)
function setDependentStyle(compartment, oldValue)
	local newValue = compartment:attr("value")
	if oldValue~=nil and newValue~=oldValue then 
		lQuery(compartment):find("/compartType/choiceItem/compartmentStyleSetting[procCondition='setTextStyle']/compartType"):each(function(obj)
			local compartTypeMin = findCompartTypeMin(obj, lQuery(compartment):find("/compartType"))
			local compartmentMinTop = findCompartment(compartment, compartTypeMin)

			local choiceItemCompartment = findChoiceItemCompartment(compartmentMinTop, obj)
			if choiceItemCompartment~=nil then
				core.make_compart_value_from_sub_comparts(choiceItemCompartment)
				core.set_parent_value(choiceItemCompartment)
			end
		end)
		
		lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
			utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
		end)
		local newValue = compartment:attr("value")
		
		--atrast no compartmenta elementu
		local compartment2= compartment
		local element 
		local l = 0
		while l==0 do
			element = compartment2:find("/element")
			if element:is_empty() then compartment2 = compartment2:find("/parentCompartment")
			else l = 1 end
		end
		if compartment:find("/compartType/choiceItem/elementStyleSetting"):is_not_empty() then
			ElemStyleBySettings(element, "ChoiceItem", compartment:find("/compartType/choiceItem[value='" .. oldValue .. "']"), 0)
		end
		if compartment:find("/compartType/settingTag/elementStyleSetting"):is_not_empty() then
			ElemStyleBySettings(element, "ChangeExtra", compartment:find("/compartType"), 0)
		end
		
		local compartments = lQuery(compartment):find("/compartType/choiceItem[value='" .. oldValue .. "']/compartmentStyleSetting[procCondition!='setTextStyle']/compartType/compartment")
		compartments:add(lQuery(compartment):find("/compartType/choiceItem[value='" .. newValue .. "']/compartmentStyleSetting[procCondition!='setTextStyle']/compartType/compartment")):each(function(obj)
			local com = obj
			local elem
			local l = 0
			while l==0 do
				elem = com:find("/element")
				if elem:is_empty() then com = com:find("/parentCompartment")
				else l = 1 end
			end
			if elem:id() == element:id() then
				CompartStyleBySetting(obj, "ChoiceItem", compartment:find("/compartType/choiceItem[value='" .. oldValue .. "']"), 0)
				
				--[[-- lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
					local diagram = utilities.current_diagram()
					local elem = lQuery("Element")
					utilities.refresh_element(elem, diagram) 
					utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
					
					graph_diagram_style_utils.save_diagram_element_and_compartment_styles(diagram)
				-- end)--]]
			end
		end)
		compartment:find("/compartType/settingTag/compartmentStyleSetting[procCondition!='setTextStyle']/compartType/compartment"):each(function(obj)
			local com = obj
			local elem
			local l = 0
			while l==0 do
				elem = com:find("/element")
				if elem:is_empty() then com = com:find("/parentCompartment")
				else l = 1 end
			end
			if elem:id() == element:id() then
				CompartStyleBySetting(obj, "ChangeExtra", compartment:find("/compartType"), 0)
				--[[
				-- lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
					local diagram = utilities.current_diagram()
					local elem = lQuery("Element")
					utilities.refresh_element(elem, diagram) 
					utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
			
					graph_diagram_style_utils.save_diagram_element_and_compartment_styles(diagram)
				-- end)--]]
			end
		end)
		-- lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
					local diagram = utilities.current_diagram()
					local elem = lQuery("Element")
					utilities.refresh_element(elem, diagram) 
					utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
					
					graph_diagram_style_utils.save_diagram_element_and_compartment_styles(diagram)
				-- end)
		
	end
	--print("END")
end

--uzstada jaunu stilu elementam (styleTable - stila vienumu tabula, newStyle-jaunais stils)
function setNewElementStyleSetting(newStyleTableDelta, styleTable, newStyle, element)
	for i,v in pairs(styleTable) do
		local setting = lQuery(v):attr("setting")
	--	if setting == "shapeCode" and element~=nil and element:find("/elemType"):attr("id") == "HorizontalFork" and element:find("/compartment:has(/compartType[id='Fork Style'])"):attr("value")~="" then
		--elseif setting == "shapeStyleNoBorder" then
		if setting == "shapeStyleNoBorder" then
			local num = tostring(styleMechanism.toBin(tonumber(lQuery(newStyle):attr("shapeStyle"))))
			local len = string.len(num)
			val = lQuery(newStyle):attr("shapeStyle")
			if string.sub(num, len, len) ~= "1" and lQuery(v):attr("value") == "1" then 
				val = val + 1 
			elseif string.sub(num, len, len) == "1" and lQuery(v):attr("value") == "0" then
				val = val - 1
			end
			lQuery(newStyle):attr("shapeStyle", val)
			newStyleTableDelta["shapeStyle"]=val
		elseif setting == "shapeStyleShadow" then
			local num = tostring(styleMechanism.toBin(tonumber(lQuery(newStyle):attr("shapeStyle"))))
			local len = string.len(num)
			val = lQuery(newStyle):attr("shapeStyle")
			if string.sub(num, len-1, len-1) ~= "1" and lQuery(v):attr("value") == "1" then 
				val = val + 2 
			elseif string.sub(num, len-1, len-1) == "1" and lQuery(v):attr("value") == "0" then
				val = val - 2
			end
			lQuery(newStyle):attr("shapeStyle", val)
			newStyleTableDelta["shapeStyle"]=val
		elseif setting == "shapeStyle3D" then
			local num = tostring(styleMechanism.toBin(tonumber(lQuery(newStyle):attr("shapeStyle"))))
			local len = string.len(num)
			val = lQuery(newStyle):attr("shapeStyle")
			if string.sub(num, len-2, len-2) ~= "1" and lQuery(v):attr("value") == "1" then 
				val = val + 4 
			elseif string.sub(num, len-2, len-2) == "1" and lQuery(v):attr("value") == "0" then
				val = val - 4
			end
			lQuery(newStyle):attr("shapeStyle", val)
			newStyleTableDelta["shapeStyle"]=val
		elseif setting == "shapeStyleMultiple" then
			local num = tostring(styleMechanism.toBin(tonumber(lQuery(newStyle):attr("shapeStyle"))))
			local len = string.len(num)
			val = lQuery(newStyle):attr("shapeStyle")
			if string.sub(num, len-3, len-3) ~= "1" and lQuery(v):attr("value") == "1" then 
				val = val + 8 
			elseif string.sub(num, len-3, len-3) == "1" and lQuery(v):attr("value") == "0" then
				val = val - 8
			end
			lQuery(newStyle):attr("shapeStyle", val)
			newStyleTableDelta["shapeStyle"]=val
		elseif setting == "shapeStyleNoBackground" then
			local num = tostring(styleMechanism.toBin(tonumber(lQuery(newStyle):attr("shapeStyle"))))
			local len = string.len(num)
			val = lQuery(newStyle):attr("shapeStyle")
			if string.sub(num, len-5, len-5) ~= "1" and lQuery(v):attr("value") == "1" then 
				val = val + 32 
			elseif string.sub(num, len-5, len-5) == "1" and lQuery(v):attr("value") == "0" then
				val = val - 32
			end
			lQuery(newStyle):attr("shapeStyle", val)
			newStyleTableDelta["shapeStyle"]=val
		elseif setting == "shapeStyleNotLinePen" then
			local num = tostring(styleMechanism.toBin(tonumber(lQuery(newStyle):attr("shapeStyle"))))
			local len = string.len(num)
			val = lQuery(newStyle):attr("shapeStyle")
			if string.sub(num, len-6, len-6) ~= "1" and lQuery(v):attr("value") == "1" then 
				val = val + 64 
			elseif string.sub(num, len-6, len-6) == "1" and lQuery(v):attr("value") == "0" then
				val = val - 64
			end
			lQuery(newStyle):attr("shapeStyle", val)
			newStyleTableDelta["shapeStyle"]=val
		else
			local val = lQuery(v):attr("value")
			if v:attr("procSetValue")~="" then
				val = assert(loadstring('return ' .. owl_fields_specific2.. '.'..lQuery(v):attr("procSetValue")..'(...)'))(element)
			end
			lQuery(newStyle):attr(setting, val)
			newStyleTableDelta[setting]=val
		end
	end
	return newStyleTableDelta
end

--uzstada kastes platumu atkariba no ierakstito simbolu skaita(element-elements, kam jauzstada platums)
--nav realizets
function setAutoWidth(element)
	local width = 110
	local compartment = element:find("/compartment")
	local compartmentInput = ""
	compartment:each(function(com)
		compartmentInput = compartmentInput .. com:attr("input")
	end)
	local compartmentInputTable = styleMechanism.split(compartmentInput, "\n")
	local count = 0
	for i,v in pairs(compartmentInputTable) do
		if (string.len(v)/20)>=3 and width<220 then width = 220  end
		if (string.len(v)/20)>=5 and width<330 then width = 330  end
	end
	return width
end

--novac FontStyle uzstaditus stila vienumus (v-stila vienums, newStyle-jaunais stils)
function removeFontStyleSetting(styleItem, newStyle, newStyleTableDelta)
		local v = styleItem:attr("setting")
		if v == "fontStyleBold" then
			local num = tostring(styleMechanism.toBin(tonumber(lQuery(newStyle):attr("fontStyle"))))
			local len = string.len(num)
			val = lQuery(newStyle):attr("fontStyle")
			if styleItem:attr("value") == "1" then val = val - 1
			else val = val + 1 end
			lQuery(newStyle):attr("fontStyle", val)
			newStyleTableDelta["fontStyle"] = val
		elseif v == "fontStyleItalic" then
			local num = tostring(styleMechanism.toBin(tonumber(lQuery(newStyle):attr("fontStyle"))))
			local len = string.len(num)
			val = lQuery(newStyle):attr("fontStyle")
			if styleItem:attr("value") == "1" then val = val - 2
			else val = val + 2 end
			lQuery(newStyle):attr("fontStyle", val)
			newStyleTableDelta["fontStyle"] = val
		elseif v == "fontStyleUnderline" then
			local num = tostring(styleMechanism.toBin(tonumber(lQuery(newStyle):attr("fontStyle"))))
			local len = string.len(num)
			val = lQuery(newStyle):attr("fontStyle")
			if styleItem:attr("value") == "1" then val = val - 4
			else val = val + 4 end
			lQuery(newStyle):attr("fontStyle", val)
			newStyleTableDelta["fontStyle"] = val
		elseif v == "fontStyleStrikeout" then
			local num = tostring(styleMechanism.toBin(tonumber(lQuery(newStyle):attr("fontStyle"))))
			local len = string.len(num)
			val = lQuery(newStyle):attr("fontStyle")
			if styleItem:attr("value") == "1" then val = val - 8
			else val = val + 8 end
			lQuery(newStyle):attr("fontStyle", val)	
			newStyleTableDelta["fontStyle"] = val
		end
end

--uzstada jaunu stilu kompartmentam (styleTable - stila vienumu tabula, newStyle-jaunais stils)
function setNewCompartStyleSetting(styleTable, newStyle, newStyleTableDelta)
	for i,v in pairs(styleTable) do
		local fieldStyleFeature = lQuery(v):attr("setting")
		if fieldStyleFeature == "fontStyleBold" then
			local num = tostring(styleMechanism.toBin(tonumber(lQuery(newStyle):attr("fontStyle"))))
			local len = string.len(num)
			val = lQuery(newStyle):attr("fontStyle")
			if string.sub(num, len, len) ~= "1" and lQuery(v):attr("value") == "1" then 
				val = val + 1 --* obcFS:attr("value")
			elseif string.sub(num, len, len) == "1" and lQuery(v):attr("value") == "0" then
				val = val - 1
			end
			lQuery(newStyle):attr("fontStyle", val)
			newStyleTableDelta["fontStyle"] = val
		elseif fieldStyleFeature == "fontStyleItalic" then
			local num = tostring(styleMechanism.toBin(tonumber(lQuery(newStyle):attr("fontStyle"))))
			local len = string.len(num)
			val = lQuery(newStyle):attr("fontStyle")
			if string.sub(num, len-1, len-1) ~= "1" and lQuery(v):attr("value") == "1" then 
				val = val + 2 --* obcFS:attr("value")
			elseif string.sub(num, len-1, len-1) == "1" and lQuery(v):attr("value") == "0" then
				val = val - 2
			end
			lQuery(newStyle):attr("fontStyle", val)
			newStyleTableDelta["fontStyle"] = val
		elseif fieldStyleFeature == "fontStyleUnderline" then
			local num = tostring(styleMechanism.toBin(tonumber(lQuery(newStyle):attr("fontStyle"))))
			local len = string.len(num)
			val = lQuery(newStyle):attr("fontStyle")
			if string.sub(num, len-2, len-2) ~= "1" and lQuery(v):attr("value") == "1" then 
				val = val + 4 --* obcFS:attr("value")
			elseif string.sub(num, len-2, len-2) == "1" and lQuery(v):attr("value") == "0" then
				val = val - 4
			end
			lQuery(newStyle):attr("fontStyle", val)
			newStyleTableDelta["fontStyle"] = val
		elseif fieldStyleFeature == "fontStyleStrikeout" then
			local num = tostring(styleMechanism.toBin(tonumber(lQuery(newStyle):attr("fontStyle"))))
			local len = string.len(num)
			val = lQuery(newStyle):attr("fontStyle")
			if string.sub(num, len-3, len-3) ~= "1" and lQuery(v):attr("value") == "1" then 
				val = val + 8 --* obcFS:attr("value")
			elseif string.sub(num, len-3, len-3) == "1" and lQuery(v):attr("value") == "0" then
				val = val - 8
			end
			lQuery(newStyle):attr("fontStyle", val)
			newStyleTableDelta["fontStyle"] = val
		else
			lQuery(newStyle):attr(fieldStyleFeature, lQuery(v):attr("value"))
			newStyleTableDelta[fieldStyleFeature] = lQuery(v):attr("value")
		end
	end
end

--stili, kas ir iekodeti nodes atributa
function nodeStyleAttribute()
	return {"shapeCode", "shapeStyle", "lineWidth", "dashLength", "breakLength", "adornment", "bkgColor", "lineColor", "picture",  
	"picStyle", "picPos",  "picWidth", "picHeight"}
end

--stili, kas ir ierakstami nodeStyle instance
function nodeStyleInstance()
	return {["shapeCode"] = 1, ["shapeStyle"] = 1, ["lineWidth"] = 1, ["dashLength"] = 1, 
	["breakLength"] = 1, ["bkgColor"] = 1, ["lineColor"] = 1, ["picture"] = 1,  
	["picStyle"] = 1, ["picPos"] = 1,  ["picWidth"] = 1, ["picHeight"] = 1}
end

--stili, kas ir iekodeti edge atributa
function edgeStyleAttribute()
	return {"shapeCode", "shapeStyle", "lineWidth", "dashLength", "breakLength", "adornment", "bkgColor", "lineColor", 
	"lineType", "lineDirection", "lineStartDirection", "lineEndDirection", "startShapeCode", "startShapeStyle", "startLineWidth", "startTotalWidth", "startTotalHeight", "startAdornment", "startBkgColor", "startLineColor",
	"endShapeCode", "endShapeStyle", "endLineWidth", "endTotalWidth", "endTotalHeight", "endAdornment", "endBkgColor", "endLineColor",
	"middleShapeCode", "middleShapeStyle", "middleLineWidth", "middleDashLength", "middleBreakLength", "middleAdornment", "middleBkgColor", "middleLineColor"}
end

--stili, kas ir ierakstami edgeStyle instance
function edgeStyleInstance()
	return {["shapeCode"] = 1, ["shapeStyle"] = 1, ["lineWidth"] = 1, ["dashLength"] = 1,["breakLength"] = 1, ["bkgColor"] = 1, ["lineColor"] = 1, ["lineType"] = 1,
	["lineDirection"] = 1, ["lineStartDirection"] = 1, ["lineEndDirection"] = 1, ["startShapeCode"] = 1, ["startLineWidth"] = 1,["startTotalWidth"] = 1, ["startTotalHeight"] = 1, ["startBkgColor"] = 1,
	["startLineColor"] = 1, ["endShapeCode"] = 1, ["endLineWidth"] = 1,["endTotalWidth"] = 1, ["endTotalHeight"] = 1, ["endBkgColor"] = 1, 
	["endLineColor"] = 1, ["middleShapeCode"] = 1, ["middleLineWidth"] = 1,["middleDashLength"] = 1, ["middleBreakLength"] = 1, ["middleBkgColor"] = 1,
	["middleLineColor"] = 1}
end

--stili, kas ir iekodeti compart atributa
function compartStyleAttribute()
	return {"id", "alignment", "adjustment", "textDirection", "shapeCode", "shapeStyle", "lineWidth", "dashLength", "breakLength", "adornment",
	"bkgColor", "lineColor", "width", "height", "xPos", "yPos", "isVisible", "breakAtSpace", "compactVisible", "fontCharSet", "fontPitch", "fontSize", "fontStyle", "fontColor", "fontTypeFace",
	"picture", "picStyle", "picPos", "picWidth", "picHeight"}
end

--stili, kas ir ierakstami compartStyle instance
function compartStyleInstance()
	return {["id"] = 1, ["alignment"] = 1, ["adjustment"] = 1, ["textDirection"] = 1,["lineWidth"] = 1, ["adornment"] = 1, ["lineColor"] = 1, ["isVisible"] = 1,
	["fontCharSet"] = 1, ["fontPitch"] = 1, ["fontSize"] = 1, ["fontStyle"] = 1,["fontColor"] = 1, ["fontTypeFace"] = 1, ["picture"] = 1, ["picStyle"] = 1,
	["picPos"] = 1, ["picWidth"] = 1, ["picHeight"] = 1, ["lineStartDirection"] = 1, ["lineEndDirection"] = 1, ["breakAtSpace"] = 1, ["compactVisible"] = 1}
end

--ieraksta stilu atributaa
function makeNodeStyleAttibuteValueFromInstance(newStyle)
	local shape = {"shapeCode", "shapeStyle", "lineWidth", "dashLength", "breakLength", "adornment", "bkgColor", "lineColor"}
	local picture = {"picture", "picStyle", "picPos",  "picWidth", "picHeight"}
	local style = "[["
	for i,v in pairs(shape) do
		style = style .. newStyle:attr(v) .. ";"
	end
	style = style .. "]["
	if newStyle:attr("picture")~="" then 
		for i,v in pairs(picture) do
			style = style .. newStyle:attr(v) .. ";"
		end
	else style = style .. ";"
	end
	style = style .. "]]"
	return style
end

function makeEdgeStyleAttibuteValueFromInstance(newStyle)
	local shape = {"shapeCode", "shapeStyle", "lineWidth", "dashLength", "breakLength", "adornment", "bkgColor", "lineColor"}
	local shape2 = {"ShapeCode", "ShapeStyle", "LineWidth", "DashLength", "BreakLength", "Adornment", "BkgColor", "LineColor"}
	local shape3 = {"ShapeCode", "ShapeStyle", "LineWidth", "TotalWidth", "TotalHeight", "Adornment", "BkgColor", "LineColor"}
	local style = "[["
	for i,v in pairs(shape) do
		if newStyle:attr(v)~=nil then
			style = style .. newStyle:attr(v) .. ";"
		else style = style .. "0;" end
	end
	style = style .. "]"
	style = style .. newStyle:attr("lineType") .. ";"
	style = style .. newStyle:attr("lineDirection") .. ";"
	style = style .. newStyle:attr("lineStartDirection") .. ";"
	style = style .. newStyle:attr("lineEndDirection") .. ";["
	for i,v in pairs(shape3) do
		if newStyle:attr("start" .. v)~=nil then
			style = style .. newStyle:attr("start" .. v) .. ";"
		else style = style .. "0;" end
	end
	style = style .. "]["
	for i,v in pairs(shape3) do
		if newStyle:attr("end" .. v)~=nil then
			style = style .. newStyle:attr("end" .. v) .. ";"
		else style = style .. "0;" end
	end
	style = style .. "]["
	for i,v in pairs(shape2) do
		if newStyle:attr("middle" .. v)~=nil then
			style = style .. newStyle:attr("middle" .. v) .. ";"
		else style = style .. "0;" end
	end
	style = style .. "]]"
	return style
end


--funkcija elementa stila uzstadisanai
-- element - elements, kam jauzstada stils
-- sourceType - stila uzstadisanas avots(Change-stilu definicijas maina profila vai skatijuma, ViewRemove-tika nomemts skatijums
--		ViewApply - tika pielietots skatijums, ChoiceItem-stilu maina no choiceItema)
-- sourceInformation - avots no kura ir atkariga stila uzstadisana(var but choiceItem veca vertiba vai View)
-- external - pazime, ka ir areja stilu uzstadisana
-- parameterTable - pazime, ka stils tiek uzstadits importa laika
function ElemStyleBySettings(element, sourceType, sourceInformation, external, parameterTable) 
	-- print("--------- START ElemStyleBySettings")
	graphDiagramEngine = require("lua_graphDiagram")
	
	owl_fields_specific2 = "OWLGrEd_UserFields.owl_fields_specific"
	
	--graph_diagram_style_utils.save_diagram_element_and_compartment_styles(dgr)
	
	--visi stili kuri ir japiekarto
	local elemStyles = lQuery(element):find("/elemType/elementStyleSetting[isDeleted != 1]"):map(function(objS)
		--izsaucam proceduru, kas noskaidro vai izpildas visi nosacijumi, lai pielietotu stilu
		local result

		local sep=lpeg.C(".")
		sep = styleMechanism.anywhere(sep)
		local res = lpeg.match(sep,lQuery(objS):attr("procCondition"))
		
		if res==nil then
	--	if string.find(lQuery(objS):attr("procCondition"), ".")==nil then 
			result = assert(loadstring('return ' .. owl_fields_specific2.. '.'..lQuery(objS):attr("procCondition")..'(...)'))(element, objS, parameterTable)
		else
			local reqTable = styleMechanism.split(lQuery(objS):attr("procCondition"), ".")
			local reqFunctionLen = string.len(reqTable[#reqTable])
			local req = string.sub(lQuery(objS):attr("procCondition"), 1, string.len(lQuery(objS):attr("procCondition"))-reqFunctionLen-1)
			require(req)
			result = assert(loadstring('return ' ..lQuery(objS):attr("procCondition")..'(...)'))(element, objS, parameterTable)
		end
		-- print("--------- procCondition", result)
		if result == true then
			return(objS)
		end
	end)

		--skatijumi, kas ir piekartoti diagramai kuraa ir padotais elements
		local viewW = lQuery(element):find("/graphDiagram/activeExtension"):map(function(obj)
			return obj
		end)
		--noklusetie skatijumi
		local defaultViews = lQuery("Extension[type='aa#Profile']/aa#subExtension"):map(function(obj)
			local l = 0
			obj:find("/aa#graphDiagram"):each(function(gd)
				if gd:id() == element:find("/graphDiagram"):id() then l = 1 end
			end)
			if lQuery("AA#View[name='" .. obj:attr("id") .. "']"):attr("isDefault") == "true" and l==0 then
				return obj
			end
		end)
		local view = lQuery.merge(viewW, defaultViews)
		-- print("--------- ADD VIEWS")
		--sakartojam stilus pec stipruma
		table.sort(elemStyles, function(x,y) return x:attr("strength") < y:attr("strength") end)
		-- print("--------- SORT STYLE SETTING")
		--sakartojam stilus pec view priaritatem
		local elemStyles2 = {}
		for i = #view,1,-1 do
			for j,b in pairs(elemStyles) do
				if tonumber(b:attr("strength")) == 3 and b:find("/extension"):id() == view[i]:id() then table.insert(elemStyles2, b) end
				if tonumber(b:attr("strength")) > 3 then break end
			end
		end
		for j,b in pairs(elemStyles) do
			if tonumber(b:attr("strength")) > 3 then table.insert(elemStyles2, b) end
		end
		-- print("--------- SORT STYLE SETTING by strength")
		------------------------------------------------------------------------------------------
		--tekosa stila nolasisana
		
		--atrodam nokluseto stilu, kas ir pirmais pie elementa tipa
		local defStyle = lQuery(element):find("/elemType/elemStyle"):first()

		--noskaidrot stila tipu (node, edge)
		local styleType
		lQuery("NodeStyle"):each(function(obj)
			if lQuery(obj):id() == lQuery(defStyle):id() then styleType = "NodeStyle" end
		end)
		lQuery("EdgeStyle"):each(function(obj)
			if lQuery(obj):id() == lQuery(defStyle):id() then styleType = "EdgeStyle" end
		end)
		-- print("--------- NodeStyle or EdgeStyle")
		
		
		--izveidijam junu stilu
		local newStyle = lQuery.create(styleType, {})
		local diagram = lQuery(element):find("/graphDiagram")
	--	if diagram:is_not_empty() and (graphDiagramEngine.IsOpenDiagram( diagram:id() ) == "open" or (parameterTable~=nil and parameterTable['import']=="true")) then 
			if styleType=="NodeStyle" then
				-- print("--------- NodeStyle")
				--ja elementu stilu ir pamainijujsi kada ne spraudna procedura
				if parameterTable~=nil and parameterTable['dependentStyle']=="true" then
					-- print("--------- NodeStyle 111")
					local elementStyleInstance = lQuery(element):find("/elemStyle"):first()
					local getAttributes = lQuery.model.property_list(styleType)
					for i,v in pairs(getAttributes) do
						lQuery(newStyle):attr(v, lQuery(elementStyleInstance):attr(v))
					end
				--ja elementam stils nav saglabats atributa style, tad jaunaja stila parrakstam nokluseto
				elseif element:attr("style") == "#" or element:attr("style") == ""  then
					-- print("--------- NodeStyle 222")
					local getAttributes = lQuery.model.property_list(styleType)
					for i,v in pairs(getAttributes) do
						lQuery(newStyle):attr(v, lQuery(defStyle):attr(v))
					end
					local elementDefaultStyle = element:find("/elemStyle"):first()
					if elementDefaultStyle:id() ~= defStyle:id() then
						getAttributes = lQuery.model.property_list(styleType)
						for i,v in pairs(getAttributes) do
							--ja stils newStyle instance ir vienads ar defStyle un elementDefaultStyle nav vienads ar defStyle
							if defStyle:attr(v) == newStyle:attr(v) and defStyle:attr(v) ~= elementDefaultStyle:attr(v) then 
								newStyle:attr(v, elementDefaultStyle:attr(v))
							end
						end
					end
				--ja elementam ir saglabats stils atributa style
				else
					-- print("--------- NodeStyle 333")
					--sadalam style atributa vertibas un ierakstam tas tabulaa
					local t = graph_diagram_style_utils.get_style_table(element)
					for i,v in pairs(t) do newStyle:attr(i, v) end
					--atrodam kostes augstumu un platumu no elementa location atributa
					local location = parseLocation(element:attr("location"))
					newStyle:attr("width", location[1])
					newStyle:attr("height", location[2])
				end
			elseif styleType=="EdgeStyle" then
				-- print("--------- EdgeStyle")
				--ja elementu stilu ir pamainijujsi kada ne spraudna procedura
				local role = element:find("/compartment:has(/compartType[id='Role'])/subCompartment:has(/compartType[id='Name'])"):attr("value")
				local invRole = element:find("/compartment:has(/compartType[id='InvRole'])/subCompartment:has(/compartType[id='Name'])"):attr("value")
				--if (parameterTable~=nil and parameterTable['dependentStyle']=="true") or role~="" or invRole~="" then
				if (parameterTable~=nil and parameterTable['dependentStyle']=="true")  then
					-- print("--------- EdgeStyle 111")
					local elementStyleInstance = lQuery(element):find("/elemStyle"):first()
					local getAttributes = lQuery.model.property_list(styleType)
					for i,v in pairs(getAttributes) do
						lQuery(newStyle):attr(v, lQuery(elementStyleInstance):attr(v))
					end
				--ja elementam stils nav saglabats atributa style, tad jaunaja stila parrakstam nokluseto
				elseif element:attr("style") == "#" or element:attr("style") == "" then
					-- print("--------- EdgeStyle 222")
					local getAttributes = lQuery.model.property_list(styleType)
					for i,v in pairs(getAttributes) do
						lQuery(newStyle):attr(v, lQuery(defStyle):attr(v))
					end
					local elementDefaultStyle = element:find("/elemStyle"):first()
					if elementDefaultStyle:id() ~= defStyle:id() then
						getAttributes = lQuery.model.property_list(styleType)
						for i,v in pairs(getAttributes) do
							--ja stils newStyle instance ir vienads ar defStyle un elementDefaultStyle nav vienads ar defStyle
							if defStyle:attr(v) == newStyle:attr(v) and defStyle:attr(v) ~= elementDefaultStyle:attr(v) then 
								newStyle:attr(v, elementDefaultStyle:attr(v))
							end
						end
					end
				--ja elementam ir saglabats stils atributa style
				else
					-- print("--------- EdgeStyle 333")
					--sadalam style atributa vertibas un ierakstam tas tabulaa
					local t = graph_diagram_style_utils.get_style_table(element)
					for i,v in pairs(t) do
						newStyle:attr(i, v)
					end
				end
			end
	--	else
	--	end
		if element:find("/elemType"):attr("id") == "HorizontalFork" and element:find("/compartment"):is_not_empty() and element:find("/compartment:has(/compartType[id='Fork Style'])"):attr("value")~="" then
			lQuery(newStyle):attr("shapeCode", lQuery("NodeStyle[id='" .. element:find("/compartment:has(/compartType[id='Fork Style'])"):attr("value") .. "']"):attr("shapeCode"))
		end
		
		--------------------------------------------------------------------------------------------
		-- sakam stila klasifikaciju
		local newStyleTableDelta = {}
		--ja ir bijusi areja stilu uzstadisana, vai profila, skatijuma stila maina
		if external == 1 or sourceType == "Change" then
			-- print("--------- TYPE = Change START")
			
			--atrodam visus dzestos stila uzstadijumus, tiem jaunajaa stila usliekam noklusetos
			local deletedElemStyles = lQuery(element):find("/elemType/elementStyleSetting[isDeleted = 1]"):map(function(obj)
				return(obj)
			end)
			--ja bija kads lietotaja uzlikts stils, tad tas diemzel pazudis
			for i,v in pairs(deletedElemStyles) do
				if v:attr("setting") == "shapeStyleNoBorder" or v:attr("setting") == "shapeStyleShadow" or v:attr("setting") == "shapeStyle3D"
				or v:attr("setting") == "shapeStyleMultiple" or v:attr("setting") == "shapeStyleNoBackground" or v:attr("setting") == "shapeStyleNotLinePen" then
					lQuery(newStyle):attr("shapeStyle", defStyle:attr("shapeStyle"))
					newStyleTableDelta["shapeStyle"] = defStyle:attr("shapeStyle")
				else
					lQuery(newStyle):attr(v:attr("setting"), defStyle:attr(v:attr("setting")))
					newStyleTableDelta[v:attr("setting")] = defStyle:attr(v:attr("setting"))
				end
			end
			if element:find("/elemType"):attr("id") == "HorizontalFork" and element:find("/compartment"):is_not_empty() and element:find("/compartment:has(/compartType[id='Fork Style'])"):attr("value")~="" then
				lQuery(newStyle):attr("shapeCode", element:find("/elemType/elemStyle[id='" .. element:find("/compartment:has(/compartType[id='Fork Style'])"):attr("value") .. "']"):attr("shapeCode"))
				newStyleTableDelta["shapeCode"] = element:find("/elemType/elemStyle[id='" .. element:find("/compartment:has(/compartType[id='Fork Style'])"):attr("value") .. "']"):attr("shapeCode")
			end
			
			--uzliekam jaunus stilus
			newStyleTableDelta = setNewElementStyleSetting(newStyleTableDelta, elemStyles2, newStyle, element)
			-- print("--------- TYPE = Change END")
		-- ja tika pielietots view, vai view Tika samainiti vietam, vienkarsi pasreizejam stilam uzlikt jaunus stilus
		elseif sourceType == "ViewApply" then
			-- print("--------- TYPE = ViewApply START")
			newStyleTableDelta = setNewElementStyleSetting(newStyleTableDelta,elemStyles2, newStyle, element)
			-- print("--------- TYPE = ViewApply END")
		--ja view tika noments, atrast tos stila uzstadijumus, kurus ietekmeja view un tiem uzlits noklusetas vertibas
		-- uzlikt jaunus stilus
		elseif sourceType == "ViewRemove" then
			-- print("--------- TYPE = ViewRemove START")
			
			local elemTypeId = element:find("/elemType"):id()
			--atradisim visus stila uzstadijumus, kurus ietekmeja nonemtais view
			--sourceInformation ir nonetais skatijums
			local removedViewElemStyles = sourceInformation:find("/elementStyleSetting"):filter(function(obj)
				return obj:find("/elemType"):id() == elemTypeId
			end)
			
			--uzliekam noklusetas vertibas
			removedViewElemStyles:each(function(obj)
				if obj:attr("setting") == "shapeStyleNoBorder" or obj:attr("setting") == "shapeStyleShadow" or obj:attr("setting") == "shapeStyle3D"
				or obj:attr("setting") == "shapeStyleMultiple" or obj:attr("setting") == "shapeStyleNoBackground" or obj:attr("setting") == "shapeStyleNotLinePen" then
					newStyle:attr("shapeStyle", defStyle:attr("shapeStyle"))
					newStyleTableDelta["shapeStyle"] = defStyle:attr("shapeStyle")
				--elseif obj:attr("setting") == "shapeCode" and element~=nil and element:find("/elemType"):attr("id") == "HorizontalFork" and element:find("/compartment:has(/compartType[id='Fork Style'])"):attr("value")~="" then
				
				else 
					newStyle:attr(obj:attr("setting"), defStyle:attr(obj:attr("setting")))
					newStyleTableDelta[obj:attr("setting")] = defStyle:attr(obj:attr("setting"))
				end
			end)
			
			--uzliekam jaunus stilus
			newStyleTableDelta = setNewElementStyleSetting(newStyleTableDelta, elemStyles2, newStyle, element)
			-- print("--------- TYPE = ViewRemove END")
		-- ja tika mainits choiceItems, visiem stiliem, ko ietekmeja veca vertiba uzlikt noklusetas vertibas, tiem ko ietekme jauna vertiba-jaunas
		elseif sourceType == "ChoiceItem" then
			-- print("--------- TYPE = ChoiceItem START")
			
			local elemTypeId = element:find("/elemType"):id()
			--sourceInformation - vecais choiceItem
			--atrodam visas stila instances, kas ir piesaistitas vecajam choiceItem
			choiceItemElemStyle = sourceInformation:find("/elementStyleSetting"):filter(function(obj)
				return obj:find("/elemType"):id() == elemTypeId
			end)
			--uzliekam noklusetas vertibas
			choiceItemElemStyle:each(function(obj)
				if obj:attr("setting") == "shapeStyleNoBorder" or obj:attr("setting") == "shapeStyleShadow" or obj:attr("setting") == "shapeStyle3D"
				or obj:attr("setting") == "shapeStyleMultiple" or obj:attr("setting") == "shapeStyleNoBackground" or obj:attr("setting") == "shapeStyleNotLinePen" then
					newStyle:attr("shapeStyle", defStyle:attr("shapeStyle"))
					newStyleTableDelta["shapeStyle"] = defStyle:attr("shapeStyle")
				else
					newStyle:attr(obj:attr("setting"), defStyle:attr(obj:attr("setting")))
					newStyleTableDelta[obj:attr("setting")] = defStyle:attr(obj:attr("setting"))
				end
			end)
			
			--uzliekam jaunus stilus
			newStyleTableDelta = setNewElementStyleSetting(newStyleTableDelta, elemStyles2, newStyle, element)
			-- print("--------- TYPE = ChoiceItem END")
		elseif sourceType == "ChangeExtra" then
			local elemTypeId = element:find("/elemType"):id()
			--sourceInformation - compartType no ka ir atkarigs
			--atrodam visas stila instances, kas ir piesaistitas vecajam choiceItem
			choiceItemElemStyle = sourceInformation:find("/dependingElementStyleSetting"):filter(function(obj)
				return obj:find("/elemType"):id() == elemTypeId
			end)
			--uzliekam noklusetas vertibas
			choiceItemElemStyle:each(function(obj)
				if obj:attr("setting") == "shapeStyleNoBorder" or obj:attr("setting") == "shapeStyleShadow" or obj:attr("setting") == "shapeStyle3D"
				or obj:attr("setting") == "shapeStyleMultiple" or obj:attr("setting") == "shapeStyleNoBackground" or obj:attr("setting") == "shapeStyleNotLinePen" then
					newStyle:attr("shapeStyle", defStyle:attr("shapeStyle"))
					newStyleTableDelta["shapeStyle"] = defStyle:attr("shapeStyle")
				else
					newStyle:attr(obj:attr("setting"), defStyle:attr(obj:attr("setting")))
					newStyleTableDelta[obj:attr("setting")] = defStyle:attr(obj:attr("setting"))
				end
			end)
			
			--uzliekam jaunus stilus
			newStyleTableDelta = setNewElementStyleSetting(newStyleTableDelta, elemStyles2, newStyle, element)
			-- print("--------- TYPE = ChoiceItem END")
		end
		
		--pielietojam stilu
		--ja stils tiek piekartots atvertai diagrammai, vai ari stili uzstadas no imports, tad ir jalieto stila parlinkisana
	--	if (graphDiagramEngine.IsOpenDiagram( diagram:id() ) == "open" or (parameterTable~=nil and parameterTable['import']=="true")) and ((parameterTable~=nil and parameterTable['copy']~="true") or parameterTable==nil) then 
		if parameterTable~=nil and parameterTable['copy']=="true" then
			-- print("--------- UPDATE STYLE 111 START")
			graph_diagram_style_utils.update_style_without_diagram_refresh(element, newStyleTableDelta)
			newStyle:delete()
			-- print("--------- UPDATE STYLE 111 END")
		-- else
		elseif ((diagram:is_not_empty() and graphDiagramEngine.IsOpenDiagram( diagram:id() ) == "open") or (parameterTable~=nil and parameterTable['import']=="true")) then 
			-- print("--------- UPDATE STYLE 222 START")
			if element:find("/elemStyle/choiceItem"):is_not_empty() then 
			-- elseif element:find("/elemStyle/elemType"):id() ~= element:find("/elemType"):id() then lQuery(element):find("/elemStyle"):delete()
			elseif element:find("/elemStyle/elemType"):is_empty() then lQuery(element):find("/elemStyle"):delete()
			-- elseif lQuery(element):find("/elemStyle"):id() ~= defStyle:id() then
				-- lQuery(element):find("/elemStyle"):delete()
			end
			element:remove_link("elemStyle")
			element:link("elemStyle",newStyle)
			-- print("--------- UPDATE STYLE 222 END")
		--citos gadijumos var lietot UpdateStyleCmd komandu
		else
			-- print("--------- UPDATE STYLE 333 START")
			graph_diagram_style_utils.update_style_without_diagram_refresh(element, newStyleTableDelta)
			newStyle:delete()
			-- print("--------- UPDATE STYLE 333 END")
		end
	-- print("--------- END ElemStyleBySettings")
end

--funkcija kompartmenta stila uzstadisanai
-- compartment - kompartments, kam jauzstada stils
-- sourceType - stila uzstadisanas avots(Change-stilu definicijas maina profila vai skatijuma, ViewRemove-tika nomemts skatijums
--		ViewApply - tika pielietots skatijums, ChoiceItem-stilu maina no choiceItema)
-- sourceInformation - avots no kura ir atkariga stila uzstadisana(var but choiceItem veca vertiba vai View)
-- external - pazime, ka ir areja stilu uzstadisana
-- parameterTable - pazime, ka stils tiek uzstadits importa laika
function CompartStyleBySetting(compartment, sourceType, sourceInformation, external, parameterTable)
	-- print("--------- START CompartStyleBySetting")
	if compartment:find("/parentCompartment"):is_empty() and compartment:find("/element"):is_empty() then return end
	owl_fields_specific2 = "OWLGrEd_UserFields.owl_fields_specific"
	-- atlasam stilus, kurus ir japiekarto

	local compartStyles = lQuery(compartment):find("/compartType/compartmentStyleSetting[isDeleted != 1]"):map(function(objS)
		local result
		
		local sep=lpeg.C(".")
		sep = styleMechanism.anywhere(sep)
		local res = lpeg.match(sep,lQuery(objS):attr("procCondition"))
		
		if res==nil then
	--	if string.find(lQuery(objS):attr("procCondition"), ".")==nil then 
			result = assert(loadstring('return ' .. owl_fields_specific2.. '.'..lQuery(objS):attr("procCondition")..'(...)'))(compartment, objS)
		else
			local reqTable = styleMechanism.split(lQuery(objS):attr("procCondition"), ".")
			local reqFunctionLen = string.len(reqTable[#reqTable])
			local req = string.sub(lQuery(objS):attr("procCondition"), 1, string.len(lQuery(objS):attr("procCondition"))-reqFunctionLen-1)
			require(req)
			result = assert(loadstring('return ' ..lQuery(objS):attr("procCondition")..'(...)'))(compartment, objS)
		end
		--local result = assert(loadstring('return ' .. owl_fields_specific2 .. '.'..lQuery(objS):attr("procCondition")..'(...)'))(compartment, objS)
		-- print("--------- procCondition", result)
		if result == true then
			return(objS)
		end
	end)

	--sakartojam stilus par stipruma
	table.sort(compartStyles, function(x,y) return x:attr("strength") < y:attr("strength") end)
	--atrodam elementu
	local element
	local compartment2 = compartment
	local l = 0
	while l == 0 do
		if compartment2:find("/element"):is_not_empty() then
			element = compartment2:find("/element")
			l=1
		else
			compartment2 = compartment2:find("/parentCompartment")
		end
	end
	--skatijumi, kas ir piekartoti pie diagramas, kur atrodas elements
	local view = lQuery(element):find("/graphDiagram/activeExtension"):map(function(obj)
		return obj
	end)
	--noklusetie skatijumi
	local defaultViews = lQuery("Extension[type='aa#View']"):map(function(obj)
		local l = 0
		obj:find("/aa#graphDiagram"):each(function(gd)
			if gd:id() == element:find("/graphDiagram"):id() then l = 1 end
		end)
		
		if lQuery("AA#View[name='" .. obj:attr("id") .. "']"):attr("isDefault") == "true" and l==0 then
			return obj
		end
	end)

	local view = lQuery.merge(view, defaultViews)
	-- print("--------- ADD VIEWS")
	--sakartojas stlu uzstadilumus pec skatijumu prioritatem	
	local compartStyles2 = {}
	for i = #view,1,-1 do
		for j,b in pairs(compartStyles) do
			if tonumber(b:attr("strength")) == 3 and b:find("/extension"):id() == view[i]:id() then table.insert(compartStyles2, b) end
			if tonumber(b:attr("strength")) > 3 then break end
		end
	end
	for j,b in pairs(compartStyles) do
		if tonumber(b:attr("strength")) > 3 then table.insert(compartStyles2, b) end
	end
	-- print("--------- SORT STYLE SETTING")
	------------------------------------------------------------------------------------------
	--tekosa stila nolasisana
	
	--noklusetais stils
	local defStyle = lQuery(compartment):find("/compartType/compartStyle"):first()

	--izveidot jauno stilu
	local newStyle = lQuery.create("CompartStyle")
	if compartment:attr("style") == "#" or compartment:attr("style") == "" then
		-- print("--------- CompartStyle 111")
		local getAttributes = lQuery.model.property_list("CompartStyle")
		for i,v in pairs(getAttributes) do
			lQuery(newStyle):attr(v, lQuery(defStyle):attr(v))
		end
	else
		-- print("--------- CompartStyle 222")
		--sadalam style atributa vertibas un ierakstam tas tabulaa
		local t = graph_diagram_style_utils.get_style_table(compartment)
		
		for i,v in pairs(t) do
			if i == "fontSize" then 
				local n, m
				m=tonumber(t[i])
				m = math.abs(m)
				n=(3*m-1)/4
				n=math.ceil(n)
				newStyle:attr(i, n)
			else
				newStyle:attr(i, v)
			end
		end

		newStyle:attr("caption", t["caption"])
		newStyle:attr("id", t["caption"])
		newStyle:attr("nr", 1)
	end
	
	----------------------------------------
	-- sakam stila klasifikaciju
	
	-- sakam stila klasifikaciju
	local newStyleTableDelta = {}
	
	--ja ir bijusi areja stilu uzstadisana, vai profila, skatijuma stila maina
	if external == 1 or sourceType == "Change" then
		-- print("--------- TYPE = Change START")
		--atrodam visus dzestos stila uzstadijumus, tiem jaunajaa stila usliekam noklusetos
		local deletedElemStyles = lQuery(compartment):find("/compartType/compartmentStyleSetting[isDeleted = 1]"):map(function(obj)
			return(obj)
		end)
		for i,v in pairs(deletedElemStyles) do
			if v:attr("setting") == "fontStyleBold" or v:attr("setting") == "fontStyleItalic" or v:attr("setting") == "fontStyleUnderline"
			or v:attr("setting") == "fontStyleStrikeout" then
				lQuery(newStyle):attr("fontStyle", defStyle:attr("fontStyle"))
				newStyleTableDelta["fontStyle"] = defStyle:attr("fontStyle")
			else
				lQuery(newStyle):attr(v:attr("setting"), defStyle:attr(v:attr("setting")))
				newStyleTableDelta[v:attr("setting")] = defStyle:attr(v:attr("setting"))
			end
		end
		--uzliekam jaunus stilus
		setNewCompartStyleSetting(compartStyles2, newStyle, newStyleTableDelta)
		-- print("--------- TYPE = Change END")
	-- ja tika pielietots view, vai viewi tka samainiti vietam, vienkarsi pasreizejam stilam uzlikt junus stilus
	elseif sourceType == "ViewApply" then
		-- print("--------- TYPE = ViewApply START")
		setNewCompartStyleSetting(compartStyles2, newStyle, newStyleTableDelta)
		-- print("--------- TYPE = ViewApply END")
	--ja view tika noments, atrast tos stila uzstadijumus, kurus ietekmeja view un tiem uzlits noklusetas vertibas
	-- uzlikt jaunus stilus
	elseif sourceType == "ViewRemove" then
		-- print("--------- TYPE = ViewRemove START")
		local compartTypeId = compartment:find("/compartType"):id()
		--atradisim visus stila uzstadijumus, kukus ietekmeja nonemtais view
		-- sourceInformation - skatijums, kas tika nonemts
		local removedViewCompartStyles = sourceInformation:find("/compartmentStyleSetting"):filter(function(obj)
			return obj:find("/compartType"):id() == compartTypeId
		end)

		--uzliekam noklusetas vertibas
		removedViewCompartStyles:each(function(obj)
			if obj:attr("setting") == "fontStyleBold" or obj:attr("setting") == "fontStyleItalic" or obj:attr("setting") == "fontStyleUnderline"
			or obj:attr("setting") == "fontStyleStrikeout" then
				removeFontStyleSetting(obj, newStyle, newStyleTableDelta)
			else
				lQuery(newStyle):attr(obj:attr("setting"), defStyle:attr(obj:attr("setting")))
				newStyleTableDelta[obj:attr("setting")] = defStyle:attr(obj:attr("setting"))
			end
		end)
		
		--uzliekam jaunus stilus
		setNewCompartStyleSetting(compartStyles2, newStyle, newStyleTableDelta)
		-- print("--------- TYPE = ViewRemove END")
	-- ja tika mainits choiceItems, visiem stiliem, ko ietekmeja veca vertiba uzlikt noklusetas vertibas, tiem ko ietekme jauna vertiba-jaunas
	elseif sourceType == "ChoiceItem" then
		-- print("--------- TYPE = ChoiceItem START")
		local compartTypeId = compartment:find("/compartType"):id()
		-- sourceInformation - veca choiceItem instance
		choiceItemCompartStyle = sourceInformation:find("/compartmentStyleSetting"):filter(function(obj)
			return obj:find("/compartType"):id() == compartTypeId
		end)
		--uzliekam noklusetas vertibas
		choiceItemCompartStyle:each(function(obj)
			if obj:attr("setting") == "fontStyleBold" or obj:attr("setting") == "fontStyleItalic" or obj:attr("setting") == "fontStyleUnderline"
			or obj:attr("setting") == "fontStyleStrikeout" then
				lQuery(newStyle):attr("fontStyle", defStyle:attr("fontStyle"))
				newStyleTableDelta["fontStyle"] = defStyle:attr("fontStyle")
			else
				lQuery(newStyle):attr(obj:attr("setting"), defStyle:attr(obj:attr("setting")))
				newStyleTableDelta[obj:attr("setting")] = defStyle:attr(obj:attr("setting"))
			end
		end)
		
		--uzliekam jaunus stilus
		setNewCompartStyleSetting(compartStyles2, newStyle, newStyleTableDelta)
		-- print("--------- TYPE = ChoiceItem END")
	elseif sourceType == "ChangeExtra" then
		-- print("--------- TYPE = ChoiceItem START")
		local compartTypeId = compartment:find("/compartType"):id()
		-- sourceInformation - veca choiceItem instance
		choiceItemCompartStyle = sourceInformation:find("/dependingCompartmentStyleSetting"):filter(function(obj)
			return obj:find("/compartType"):id() == compartTypeId
		end)
		--uzliekam noklusetas vertibas
		choiceItemCompartStyle:each(function(obj)
			if obj:attr("setting") == "fontStyleBold" or obj:attr("setting") == "fontStyleItalic" or obj:attr("setting") == "fontStyleUnderline"
			or obj:attr("setting") == "fontStyleStrikeout" then
				lQuery(newStyle):attr("fontStyle", defStyle:attr("fontStyle"))
				newStyleTableDelta[obj:attr("fontStyle")] = defStyle:attr("fontStyle")
			else
				lQuery(newStyle):attr(obj:attr("setting"), defStyle:attr(obj:attr("setting")))
				newStyleTableDelta[obj:attr("setting")] = defStyle:attr(obj:attr("setting"))
			end
		end)
		
		--uzliekam jaunus stilus
		setNewCompartStyleSetting(compartStyles2, newStyle, newStyleTableDelta)
		-- print("--------- TYPE = ChoiceItem END")
	end

	
	-- if parameterTable~=nil and parameterTable['copy']=="true" then
		-- graph_diagram_style_utils.update_style_without_diagram_refresh(compartment, newStyleTableDelta)
		-- newStyle:delete()
		
		-- local diagram = utilities.current_diagram()
		-- graph_diagram_style_utils.refresh_diagram(diagram)
	-- else
		-- izdzesam pasreiz piesaistito stilu, ja tas nav noklusetais
		if lQuery(compartment):find("/compartStyle"):id() ~= defStyle:id() then
			lQuery(compartment):find("/compartStyle"):delete()
		end
		
		--local newStyleTableDelta = {}
		-- newStyleTableDelta["fontColor"] = 233

		--pielietojam stilu
		local diagram = utilities.current_diagram()
		compartment:remove_link("compartStyle")
		compartment:link("compartStyle",newStyle)
		compartment:attr("style","#")
	-- end
	
	-- print("--------- END CompartStyleBySetting")
end

--noskaidro vai elementam ir japiekarto dotais stils no choiceItem (element-elements, elemStyleSetting-stila uzstadijums)
function setElemStyleByChoiceItem(element, elemStyleSetting, parameterTable)
	local elemType = element:find("/elemType"):attr("id")
	local result = false
	local compartment = lQuery(elemStyleSetting):find("/choiceItem/compartType/compartment"):filter(
		function(obj)
			if lQuery(obj):find("/element"):is_empty() then 
				return lQuery(obj):find("/parentCompartment/element"):id() == lQuery(element):id()
			else
				return lQuery(obj):find("/element"):id() == lQuery(element):id()
			end
		end)
	lQuery(compartment):each(function(obj)
		local compartValue = lQuery(obj):attr("value")
		lQuery(elemStyleSetting):find("/choiceItem"):each(function(objI)
			if compartValue == lQuery(objI):attr("value") then result = true end
		end)
	end)
	return result
end

--noskaidro vai kompartmentam ir japiekarto dotais tils no choiceItem (compartment-kompartments, compartStyleSetting-stila uzstadijums)
function setCompartStyleByChoiceItem(compartment, compartStyleSetting)
	local result = false
	-- local elemTypeAssociation = lQuery(compartment):find("/parentCompartment/element/elemType"):attr("id")
	-- local elemTypeClassObject = lQuery(compartment):find("/element/elemType"):attr("id")
	local compartmentElement
	local com = compartment
	local l = 0
	while l==0 do
		compartmentElement = com:find("/element")
		if compartmentElement:is_empty() then com = com:find("/parentCompartment")
		else l = 1 end
	end
	local subCompartment = lQuery(compartStyleSetting):find("/choiceItem/compartType/compartment"):filter(
		function(obj)
			local l = 0
			local objElement
			local com = obj
			while l==0 do
				
				objElement = com:find("/element")
				if objElement:is_empty() then com = com:find("/parentCompartment")
				else l = 1 end
			end
			return objElement:id() == compartmentElement:id()
		end)
	-- lQuery(subCompartment):each(function(obj)
			-- local compartValue = lQuery(obj):attr("value")
			-- lQuery(compartStyleSetting):find("/choiceItem"):each(function(objI)
				-- if compartValue == lQuery(objI):attr("value") then result = true end
			-- end)
		-- end)
		
		
	--uzstada sufiksus (dataCompartType-kompartmenta tips no kura ir atkariga sufiksa uzliksana, 
	--------------------dataCompartment-kompartments no kura ir atkariga sufiksa uzliksana,
	--------------------parsingCompartment-kompartment, kam jaustada sufikss)

	local dataCompartType = compartStyleSetting:find("/compartType")
	local choiceItemCompartType = compartStyleSetting:find("/choiceItem/compartType")
	local compartTypeMin = findCompartTypeMin(dataCompartType, choiceItemCompartType)
	--jadabu istais compartments
			
	local compartmentMinTop = findCompartment(compartment, compartTypeMin)
	local choiceItemCompartment = findChoiceItemCompartment(compartmentMinTop, choiceItemCompartType)
	
	if choiceItemCompartment~=nil and choiceItemCompartment:attr("value") == compartStyleSetting:find("/choiceItem"):attr("value") then result = true end

	-- if lQuery(compartment):find("/parentCompartment"):is_not_empty() and lQuery(compartment):find("/parentCompartment"):attr("isGroup")=="true" then 
		-- local element = lQuery(compartment):find("/parentCompartment")
		-- local subCompartment = lQuery(compartStyleSetting):find("/choiceItem/compartType/compartment"):filter(
			-- function(obj)
				-- return lQuery(obj):find("/parentCompartment"):id() == lQuery(element):id()
			-- end)
		-- lQuery(subCompartment):each(function(obj)
			-- local compartValue = lQuery(obj):attr("value")
			-- lQuery(compartStyleSetting):find("/choiceItem"):each(function(objI)
				-- if compartValue == lQuery(objI):attr("value") then result = true end
			-- end)
		-- end)
	-- elseif lQuery(compartment):find("/element"):is_not_empty() then
		-- local element = lQuery(compartment):find("/element")
		-- local subCompartment = lQuery(compartStyleSetting):find("/choiceItem/compartType/compartment"):filter(
			-- function(obj)
				-- return lQuery(obj):find("/element"):id() == lQuery(element):id()
			-- end)
		-- lQuery(subCompartment):each(function(obj)
			-- local compartValue = lQuery(obj):attr("value")
			-- lQuery(compartStyleSetting):find("/choiceItem"):each(function(objI)
				-- if compartValue == lQuery(objI):attr("value") then result = true end
			-- end)
		-- end)
	-- end
	return result
end

--noskaidro vai elementam ir japiekarto dotais stils no skatijuma (element-elements, elemStyleSetting-stila uzstadijums, parameterTable-tabula ar parametriem)
function setElemStyleByExtension(element, elemStyleSetting, parameterTable)
	local result = false
	local graphDiagram = element:find("/graphDiagram")
	local extension = elemStyleSetting:find("/extension")
	if extension:attr("id") == "Default" then result = true end
	graphDiagram:find("/activeExtension"):each(function(ext)
		if extension:id() == ext:id() and element:find("/elemType"):id() == elemStyleSetting:find("/elemType"):id() then result = true end
	end)
	local l = 0
	extension:find("/aa#graphDiagram"):each(function(gd)
		if gd:id() == element:find("/graphDiagram"):id() then l = 1 end
	end)
	if lQuery("AA#View[name='" .. extension:attr("id") .. "']"):attr("isDefault") == "true" and l then result = true end
	if parameterTable~=nil and parameterTable["import"] == "true" and elemStyleSetting:attr("setting")=="widthProc" then result = true end
	if (parameterTable==nil or parameterTable["import"] ~= "true") and elemStyleSetting:attr("setting")=="widthProc" then result = false end
	return result
end

function setElemStyleByExtensionAndChoiceItem(element, elemStyleSetting)
	local result = false
	local resultEx = false
	local resultCI = false
	
	local elemType = element:find("/elemType")
	
	local graphDiagram = element:find("/graphDiagram")
	local extension = elemStyleSetting:find("/extension")
	graphDiagram:find("/activeExtension"):each(function(ext)
		if extension:id() == ext:id() and elemType:id() == elemStyleSetting:find("/elemType"):id() then resultEx = true end
	end)
	
	local subCompartment = lQuery(elemStyleSetting):find("/choiceItem/compartType/compartment"):filter(
		function(obj)
			local l = 0
			local objElement
			local com = obj
			while l==0 do
				objElement = com:find("/element")
				if objElement:is_empty() then com = com:find("/parentCompartment")
				else l = 1 end
			end
			return objElement:id() == element:id()
		end)
	lQuery(subCompartment):each(function(obj)
			local compartValue = lQuery(obj):attr("value")
			lQuery(elemStyleSetting):find("/choiceItem"):each(function(objI)
				if compartValue == lQuery(objI):attr("value") then resultCI = true end
			end)
		end)

	if resultEx == true and resultCI == true then result = true end
	return result
end

--noskaidro vai kompartmentam  ir japiekarto stils no skatijuma un izveles vienuma (compartment-kompartments, compartStyleSetting-stila uzstadijums)
function setCompartStyleByExtensionAndChoiceItem(compartment, compartStyleSetting)
	local result = false
	local resultEx = false
	local resultCI = false
	--atrast elementu no compartmenta
	local compartment2 = compartment
	local compartType = compartment:find("/compartType")
	local element
	local l = 0
	while l == 0 do
		if compartment:find("/element"):is_not_empty() then
			element = compartment:find("/element")
			l=1
		else
			compartment = compartment:find("/parentCompartment")
		end
	end
	
	local graphDiagram = element:find("/graphDiagram")
	local extension = compartStyleSetting:find("/extension")
	graphDiagram:find("/activeExtension"):each(function(ext)
		if extension:id() == ext:id() and compartType:id() == compartStyleSetting:find("/compartType"):id() then resultEx = true end
	end)
	
	local subCompartment = lQuery(compartStyleSetting):find("/choiceItem/compartType/compartment"):filter(
		function(obj)
			local l = 0
			local objElement
			local com = obj
			while l==0 do
				
				objElement = com:find("/element")
				if objElement:is_empty() then com = com:find("/parentCompartment")
				else l = 1 end
			end
			return objElement:id() == element:id()
		end)
	-- lQuery(subCompartment):each(function(obj)
			-- local compartValue = lQuery(obj):attr("value")
			-- lQuery(compartStyleSetting):find("/choiceItem"):each(function(objI)
				-- if compartValue == lQuery(objI):attr("value") then resultCI = true end
			-- end)
		-- end)
	
	
	--------------------(dataCompartType-kompartmenta tips no kura ir atkariga sufiksa uzliksana, 
	--------------------dataCompartment-kompartments no kura ir atkariga sufiksa uzliksana,
	--------------------parsingCompartment-kompartment, kam jaustada sufikss)

	local dataCompartType = compartStyleSetting:find("/compartType")
	local choiceItemCompartType = compartStyleSetting:find("/choiceItem/compartType")
	local compartTypeMin = findCompartTypeMin(dataCompartType, choiceItemCompartType)
	--jadabu istais compartments

	local compartmentMinTop = findCompartment(compartment2, compartTypeMin)
	local choiceItemCompartment = findChoiceItemCompartment(compartmentMinTop, choiceItemCompartType)
	
	if choiceItemCompartment~=nil and choiceItemCompartment:attr("value") == compartStyleSetting:find("/choiceItem"):attr("value") then resultCI = true end

	if resultEx == true and resultCI == true then result = true end
	return result
end

--noskaidro vai kompartmentam  ir japiekarto stils no skatijuma (compartment-kompartments, compartStyleSetting-stila uzstadijums, compartType-kompartmenta tips)
function setCompartStyleByExtension(compartment, compartStyleSetting, compartType)
	local result = false
	if compartment~=nil and compartment~="" then 
		--atrast elementu no compartmenta
		if compartType==nil then compartType = compartment:find("/compartType") end
		local element
		local l = 0
		while l == 0 do
			if compartment:find("/element"):is_not_empty() then
				element = compartment:find("/element")
				l=1
			else
				compartment = compartment:find("/parentCompartment")
				if compartment:is_empty() then break end
			end
		end
		if element~=nil then 
			local graphDiagram = element:find("/graphDiagram")
			local extension = compartStyleSetting:find("/extension")
			graphDiagram:find("/activeExtension"):each(function(ext)
				if extension:id() == ext:id() and compartType:id() == compartStyleSetting:find("/compartType"):id() then result = true end
			end)
			local l = 0
			extension:find("/aa#graphDiagram"):each(function(gd)
				if gd:id() == element:find("/graphDiagram"):id() then l = 1 end
			end)
			if lQuery("AA#View[name='" .. extension:attr("id") .. "']"):attr("isDefault") == "true" and l==0 then result = true end
		end
	end
	return result
end

function setElemStyleByExtraStyle(element, elemStyleSetting, parameterTable)
	local result = false
	local resultEx = false
	local resultExtra = false
	
	local elemType = element:find("/elemType")
	
	local graphDiagram = element:find("/graphDiagram")
	local extension = elemStyleSetting:find("/extension")
	graphDiagram:find("/activeExtension"):each(function(ext)
		if extension:id() == ext:id() and elemType:id() == elemStyleSetting:find("/elemType"):id() then resultEx = true end
	end)

	resultExtra = true
	elemStyleSetting:find("/settingTag"):each(function(styleSetting)
		local dependingElementType2 = elemStyleSetting:find("/dependsOnCompartType")
		local dependingElementType
		local l = 0
		while l==0 do
			dependingElementType = dependingElementType2:find("/elemType")
			if dependingElementType:is_empty() then dependingElementType2 = dependingElementType2:find("/parentCompartType")
			else l = 1 end
		end
		if dependingElementType:attr("id") == elemType:attr("id") then 
			local subCompartment = styleSetting:find("/ref/compartment"):filter(
				function(obj)
					local l = 0
					local objElement
					local com = obj
					while l==0 do
						objElement = com:find("/element")
						if objElement:is_empty() then com = com:find("/parentCompartment")
						else l = 1 end
					end
					return objElement:id() == element:id()
				end)
			lQuery(subCompartment):each(function(obj)
				if styleSetting:attr("tagValue") == obj:attr(styleSetting:attr("tagName")) then
					--resultExtra = true
				else
					resultExtra = false
				end
			end)
		else
			resultExtra = false
			--atrast elementu no kura ir atkarigs stils
			local depElement = element:find("/eStart:has(/elemType[id='" .. dependingElementType:attr("id") .. "'])")
			depElement = depElement:add(element:find("/eEnd:has(/elemType[id='" .. dependingElementType:attr("id") .. "'])"))
			depElement = depElement:add(element:find("/end:has(/elemType[id='" .. dependingElementType:attr("id") .. "'])"))
			local depCompartment = styleSetting:find("/ref/compartment"):filter(
				function(obj)
					local c = 0
					local l = 0
					local objElement
					local com = obj
					while l==0 do
						objElement = com:find("/element")
						if objElement:is_empty() then com = com:find("/parentCompartment")
						else l = 1 end
					end
					depElement:each(function(dElem)
						if objElement:id() == dElem:id() then c = 1 end
					end)
					return c == 1
				end)
			lQuery(depCompartment):each(function(obj)
				if styleSetting:attr("tagValue") == obj:attr(styleSetting:attr("tagName")) then
					resultExtra = true
				else
					--resultExtra = false
				end
			end)
		end
	end)
	--resultExtra = resultSet
	if resultEx == true and resultExtra == true then result = true end
	return result
end

function setCompartStyleByExtraStyle(compartment, compartStyleSetting)
	
	local result = false
	local resultEx = false
	local resultExtra = false
	
	local compartment2 = compartment
	local compartType = compartment:find("/compartType")
	local element
	local l = 0
	while l == 0 do
		if compartment:find("/element"):is_not_empty() then
			element = compartment:find("/element")
			l=1
		else
			compartment = compartment:find("/parentCompartment")
		end
	end
	local elemType = element:find("/elemType")
	
	local graphDiagram = element:find("/graphDiagram")
	local extension = compartStyleSetting:find("/extension")
	graphDiagram:find("/activeExtension"):each(function(ext)
		if extension:id() == ext:id() and compartType:id() == compartStyleSetting:find("/compartType"):id() then resultEx = true end
	end)
	resultExtra = true
	compartStyleSetting:find("/settingTag"):each(function(styleSetting)
		local resultSet = true
		local dependingElementType2 = compartStyleSetting:find("/dependsOnCompartType")
		local dependingElementType
		local l = 0
		while l==0 do
			dependingElementType = dependingElementType2:find("/elemType")
			if dependingElementType:is_empty() then dependingElementType2 = dependingElementType2:find("/parentCompartType")
			else l = 1 end
		end
		if dependingElementType:attr("id") == elemType:attr("id") then 
			local subCompartment = styleSetting:find("/ref/compartment"):filter(
				function(obj)
					local l = 0
					local objElement
					local com = obj
					while l==0 do
						objElement = com:find("/element")
						if objElement:is_empty() then com = com:find("/parentCompartment")
						else l = 1 end
					end
					return objElement:id() == element:id()
				end)
				
			lQuery(subCompartment):each(function(obj)
				if styleSetting:attr("tagValue") == obj:attr(styleSetting:attr("tagName")) then
					--resultExtra = true
				else
					resultExtra = false
				end
			end)
		else
			resultExtra = false
			--atrast elementu no kura ir atkarigs stils
			local depElement = element:find("/eStart:has(/elemType[id='" .. dependingElementType:attr("id") .. "'])")
			depElement = depElement:add(element:find("/eEnd:has(/elemType[id='" .. dependingElementType:attr("id") .. "'])"))
			depElement = depElement:add(element:find("/end:has(/elemType[id='" .. dependingElementType:attr("id") .. "'])"))
			local depCompartment = styleSetting:find("/ref/compartment"):filter(
				function(obj)
					local c = 0
					local l = 0
					local objElement
					local com = obj
					while l==0 do
						objElement = com:find("/element")
						if objElement:is_empty() then com = com:find("/parentCompartment")
						else l = 1 end
					end
					depElement:each(function(dElem)
						if objElement:id() == dElem:id() then c = 1 end
					end)
					return c == 1
				end)
			lQuery(depCompartment):each(function(obj)
				if styleSetting:attr("tagValue") == obj:attr(styleSetting:attr("tagName")) then
					resultExtra = true
				else
					--resultExtra = false
				end
			end)
		end
	end)
	-- resultExtra = resultSet
	if resultEx == true and resultExtra == true then result = true end
	return result
end

function setCompartmStyleByExtraStyle(compartment, compartStyleSetting)
	local result = false
	return result
end

--parrekina stilus uz vertibu mainu, uzstada, gan noklusetos atilus, gan lietotaja definetus(compart-kompartments no kura ir atkarigs noklusetais stils)
function setDependentStyleSetting(compart)

	--tabula ar atkarigiem stiliem
	local dependentStylesTable = styleMechanism.dependentStylesTable()
	local compartType = compart:find("/compartType")
	--atrast celu lidz elementam
	local pathToElement = compartType:attr("id")
	local l = 0
	while l ~= 1 do
		local compartTypeDep = compartType:find("/parentCompartType")
		if compartTypeDep:is_empty() then compartTypeDep = compartType:find("/elemType") l=1 end
		compartType=compartTypeDep
		pathToElement = compartType:attr("id") .. "/" .. pathToElement
	end

	local dependentElemPath
	local transleteProcedure
	for i,v in pairs(dependentStylesTable) do
		if v[1] == pathToElement then dependentElemPath = v[2] transleteProcedure = v[3] end
	end
	local elem--lauks kuram ir translets

	local pathTable = styleMechanism.split(dependentElemPath, "/")
	
	for j,b in pairs(pathTable) do
		if j == 1 then elem = lQuery("ElemType[id='" .. b  .. "']")
		elseif j == 2 then elem = elem:find("/compartType[id='" .. b .. "']")
		else
			elem = elem:find("/subCompartType[id='" .. b .. "']")
		end
	end
	--izpildit proceduru, kas uzstada stulus
	assert(loadstring('return ' .. transleteProcedure ..'(...)'))(compart)

	--elements kuram tiek atverta ipasibu diagrama
	local element = compart
	l = 0
	while l ~= 1 do
		local compartTypeDep = element:find("/parentCompartment")
		if compartTypeDep:is_empty() then compartTypeDep = element:find("/element") l=1 end
		element=compartTypeDep
	end

	-- lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
		-- utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
	-- end)
	lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
		utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
	end)

	--izstadit lietotaja stilus
	local parameterTable = {}
	parameterTable["dependentStyle"] = "true"
	if elem:find("/elementStyleSetting"):is_not_empty() then ElemStyleBySettings(element, 0, 0, 1, parameterTable) end
	--utilities.quiet_execute_fn("OWL_CNL_specific.set_display_label", compart)
end

--paslepj lauku
function hide_for_OWL_Fields()
	return false
end
