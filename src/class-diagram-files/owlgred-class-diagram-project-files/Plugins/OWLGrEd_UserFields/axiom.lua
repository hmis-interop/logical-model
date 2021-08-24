module(..., package.seeall)
require("lua_tda")
tda_to_protege = require "tda_to_protege"
styleMechanism = require "OWLGrEd_UserFields.styleMechanism"

-- function axiom(diagram)
	-- local String = ""
	-- local tag = lQuery("Tag[key = 'owl_Fields_ImportSpec']"):each(function(obj)
		-- if obj:attr("value")~="" and obj:find("/choiceItem"):is_not_empty() then
			-- String = String .. "\n" .. gramarImport(obj:attr("value"), obj:find("/choiceItem"):attr("value"))
		-- elseif obj:attr("value")~="" then
			-- String = String .. "\n" .. gramarImport(obj:attr("value"), obj:find("/type"):attr("id"))
		-- end
	-- end)
	-- return axiom2(String, diagram)..String
-- end

--function axiom2(String, diagram)
--savac visas aksiomas prieks eksporta (diagram-eksportejama diagrama) (Class, Attribute, Association, Object)
function axiom(diagram)
	String = ""
	local tag = lQuery("Tag[key = 'owl_Field_axiom']"):each(function(obj)
		local compartment = lQuery(obj):find("/type/compartment")
		compartment:each(function(objCom)
			local replacementValue = objCom:attr("value")
			local compartType = objCom
			local l = 0
			while l==0 do
				if lQuery(compartType):find("/compartType/elemType"):is_not_empty() then --ja ir elements
					l=1
					if lQuery(compartType):find("/element/elemType"):attr("caption")== "Class" and lQuery(compartType):find("/element/graphDiagram"):id() == diagram:id() then
						local replacementSubject = lQuery(compartType):find("/element/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value")
						local namespace
						if lQuery(compartType):find("/element/compartment/subCompartment:has(/compartType[id='Namespace'])"):is_not_empty() then 
							namespace = lQuery(compartType):find("/element/compartment/subCompartment:has(/compartType[id='Namespace'])"):attr("value")
							if namespace~="" then replacementSubject = replacementSubject .. "{" .. namespace .. "}" end
						end
						if replacementSubject~="" and replacementValue~="" then
							String = String .. "\n" .. gramar(obj:attr("value"), replacementSubject, replacementValue, replacementSubject, "", "")
						end
					elseif lQuery(compartType):find("/element/graphDiagram"):id() == diagram:id() then
						if lQuery(compartType):find("/element/elemType"):attr("caption")== "Annotation" then
							replacementValue = string.sub(replacementValue, 2)
							local len = string.len(replacementValue)
							replacementValue = string.sub(replacementValue, 1, len-1)
							String = String .. "\n" .. gramar(obj:attr("value"), "", replacementValue, "", "", "") 
						else
							lQuery(compartType):find("/element/compartment:has(/compartType/subCompartType[id='Name'])"):each(function(objC)
								replacementSubject = lQuery(objC):attr("value")
								if replacementSubject~=""  and replacementValue~="" then
								
									String = String .. "\n" .. gramar(obj:attr("value"), replacementSubject, replacementValue, replacementSubject, "", "")
								end
							end)
						end
					end
				elseif lQuery(compartType):find("/parentCompartment/compartType"):attr("id") == "InvRole" or lQuery(compartType):find("/parentCompartment/compartType"):attr("id") == "Role" then
					l=1
					if lQuery(compartType):find("/parentCompartment/element/graphDiagram"):id() == diagram:id() then
						replacementSubject = lQuery(compartType):find("/parentCompartment/subCompartment/subCompartment:has(/compartType[id='Name'])"):attr("input") .. lQuery(compartType):find("/parentCompartment/subCompartment/subCompartment:has(/compartType[id='Namespace'])"):attr("input")
						local replacementDomain
						local replacementRange
						if lQuery(compartType):find("/parentCompartment/compartType"):attr("id") == "InvRole" then
							replacementDomain = compartType:find("/parentCompartment/element/end/compartment:has(/compartType[id='Name'])"):attr("value")
							replacementRange = compartType:find("/parentCompartment/element/start/compartment:has(/compartType[id='Name'])"):attr("value")
						else
							replacementDomain = compartType:find("/parentCompartment/element/start/compartment:has(/compartType[id='Name'])"):attr("value")
							replacementRange = compartType:find("/parentCompartment/element/end/compartment:has(/compartType[id='Name'])"):attr("value")
						end
						if replacementSubject~="" and replacementValue~="" then
							-- String = String .. "\n" .. gramar(obj:attr("value"), replacementSubject, replacementValue, "", replacementDomain, replacementRange)
							local isAllValuesFrom = compartType:find("/parentCompartment/subCompartment:has(/compartType[id='allValuesFrom'])"):attr("value")
							local result =  gramar(obj:attr("value"), replacementSubject, replacementValue, "", replacementDomain, replacementRange)
							if stringStarts(result,"AnnotationAssertion(") and isAllValuesFrom == "true" then 
								result = "AnnotationAssertion(Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> " .. repNamespace(replacementDomain) .. ")" .. string.sub(result, 21)
							end
							String = String .. "\n" .. result
						end
					end
				elseif lQuery(compartType):find("/parentCompartment/compartType"):attr("id") == "Attributes" then 
					l=1
					if lQuery(compartType):find("/parentCompartment/parentCompartment/element/graphDiagram"):id() == diagram:id() then
						replacementSubject = lQuery(compartType):find("/parentCompartment/subCompartment/subCompartment:has(/compartType[id='Name'])"):attr("value") 
						replacementObject = compartType:find("/parentCompartment/parentCompartment/element/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value") 
						local namespace
						if lQuery(compartType):find("/parentCompartment/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):is_not_empty() then
							namespace =  lQuery(compartType):find("/parentCompartment/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value")
							if namespace~="" then replacementSubject = replacementSubject .. "{" .. namespace .. "}" end
						end
						if replacementSubject~=""  and replacementValue~="" then
							-- String = String .. "\n" .. gramar(obj:attr("value"), replacementSubject, replacementValue, replacementObject, "", "")
							local isAllValuesFrom = compartType:find("/parentCompartment/subCompartment:has(/compartType[id='allValuesFrom'])"):attr("value")
							local result =  gramar(obj:attr("value"), replacementSubject, replacementValue, replacementObject, "", "")
							if stringStarts(result,"AnnotationAssertion(") and isAllValuesFrom == "true" then 
								result = "AnnotationAssertion(Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> " .. repNamespace(replacementObject) .. ")" .. string.sub(result, 21)
							end
							String = String .. "\n" .. result
						end
					end
				else compartType = lQuery(compartType):find("/parentCompartment")  end
			end
		end)
		if lQuery(obj):find("/choiceItem"):is_not_empty() then
			local ciValue =  lQuery(obj):find("/choiceItem"):attr("value")
			local ciCompartment = lQuery(obj):find("/choiceItem/compartType/compartment[value='" .. ciValue .. "']")
			ciCompartment:each(function(objCom)
				local compartType = objCom
				local replacementValue = objCom:attr("value")
				local l = 0
				while l==0 do
					if lQuery(compartType):find("/compartType/elemType"):is_not_empty() then 
						l=1
						if lQuery(compartType):find("/element/elemType"):attr("caption")== "Class" and lQuery(compartType):find("/element/graphDiagram"):id() == diagram:id() then
							local replacementSubject = lQuery(compartType):find("/element/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value") 
							local namespace
							if lQuery(compartType):find("/element/compartment/subCompartment:has(/compartType[id='Namespace'])"):is_not_empty() then 
								namespace =  lQuery(compartType):find("/element/compartment/subCompartment:has(/compartType[id='Namespace'])"):attr("value")
								if namespace~="" then replacementSubject = replacementSubject .. "{" .. namespace .. "}" end
							end
							if replacementSubject~="" and replacementValue~="" then
								String = String .. "\n" .. gramar(obj:attr("value"), replacementSubject, replacementValue, replacementSubject, replacementSubject, "")
							end
						elseif lQuery(compartType):find("/element/graphDiagram"):id() == diagram:id() then
							lQuery(compartType):find("/element/compartment:has(/compartType/subCompartType[id='Name'])"):each(function(objC)
								replacementSubject = lQuery(objC):attr("value")
								if replacementSubject~="" and replacementValue~="" then
									String = String .. "\n" .. gramar(obj:attr("value"), replacementSubject, replacementValue,  replacementSubject, replacementSubject, "")
								end
							end)
						end
					elseif lQuery(compartType):find("/parentCompartment/compartType"):attr("id") == "InvRole" or lQuery(compartType):find("/parentCompartment/compartType"):attr("id") == "Role" then
						l=1
						if lQuery(compartType):find("/parentCompartment/element/graphDiagram"):id() == diagram:id() then
							replacementSubject = lQuery(compartType):find("/parentCompartment/subCompartment/subCompartment:has(/compartType[id='Name'])"):attr("value") 
							local namespace
							if lQuery(compartType):find("/parentCompartment/subCompartment/subCompartment:has(/compartType[id='Namespace'])"):is_not_empty() then 
								namespace =  lQuery(compartType):find("/parentCompartment/subCompartment/subCompartment:has(/compartType[id='Namespace'])"):attr("value")
								if namespace~="" then replacementSubject = replacementSubject .. "{" .. namespace .. "}" end
							end
							
							local replacementDomain
							local replacementRange
							if lQuery(compartType):find("/parentCompartment/compartType"):attr("id") == "InvRole" then
								replacementDomain = compartType:find("/parentCompartment/element/end/compartment:has(/compartType[id='Name'])"):attr("value")
								replacementRange = compartType:find("/parentCompartment/element/start/compartment:has(/compartType[id='Name'])"):attr("value")
							else
								replacementDomain = compartType:find("/parentCompartment/element/start/compartment:has(/compartType[id='Name'])"):attr("value")
								replacementRange = compartType:find("/parentCompartment/element/end/compartment:has(/compartType[id='Name'])"):attr("value")
							end
							
							if replacementSubject~=""  and replacementValue~="" then
								-- String = String .. "\n" .. gramar(obj:attr("value"), replacementSubject, replacementValue, "", replacementDomain, replacementRange)
								local isAllValuesFrom = compartType:find("/parentCompartment/subCompartment:has(/compartType[id='allValuesFrom'])"):attr("value")
								local result =  gramar(obj:attr("value"), replacementSubject, replacementValue, "", replacementDomain, replacementRange)
								if stringStarts(result,"AnnotationAssertion(") and isAllValuesFrom == "true" then 
									result = "AnnotationAssertion(Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> " .. repNamespace(replacementDomain) .. ")" .. string.sub(result, 21)
								end
								String = String .. "\n" .. result
							end
						end
					elseif lQuery(compartType):find("/parentCompartment/compartType"):attr("id") == "Attributes" then 
						l=1
						if lQuery(compartType):find("/parentCompartment/parentCompartment/element/graphDiagram"):id() == diagram:id() then
							replacementSubject = lQuery(compartType):find("/parentCompartment/subCompartment/subCompartment:has(/compartType[id='Name'])"):attr("value")
							replacementObject = compartType:find("/parentCompartment/parentCompartment/element/compartment/subCompartment:has(/compartType[id='Name'])"):attr("value") 
							local namespace
							if lQuery(compartType):find("/parentCompartment/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):is_not_empty() then 
								namespace = lQuery(compartType):find("/parentCompartment/subCompartment:has(/compartType[id='Name'])/subCompartment:has(/compartType[id='Namespace'])"):attr("value")
							
								if namespace~="" then  replacementSubject = replacementSubject .. "{" .. namespace .. "}" end
							end
							if replacementSubject~="" and replacementValue~="" then
								-- String = String .. "\n" .. gramar(obj:attr("value"), replacementSubject, replacementValue, replacementObject, "", "")
								local isAllValuesFrom = compartType:find("/parentCompartment/subCompartment:has(/compartType[id='allValuesFrom'])"):attr("value")
								local result =  gramar(obj:attr("value"), replacementSubject, replacementValue, replacementObject, "", "")
								if stringStarts(result,"AnnotationAssertion(") and isAllValuesFrom == "true" then 
									result = "AnnotationAssertion(Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> " .. repNamespace(replacementObject) .. ")" .. string.sub(result, 21)
								end
								String = String .. "\n" .. result
							end
						end
					else compartType = lQuery(compartType):find("/parentCompartment") end
				end
			end)
		end
	end)
	-- local ontologyFragment = lQuery(diagram):find("/element/target"):each(function(obj)
		-- String = String ..  axiom2(String, obj)
	-- end)

	return String
end
function stringStarts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end
--[[function gramarImport(text, repSubject, repValue)

	local Space = lpeg.S(" \n\t") ^ 1
	local SpaceO = lpeg.S(" \n\t") ^ 0
	
	local Letter = lpeg.R("az") + lpeg.R("AZ") + lpeg.R("09") + lpeg.S("_/")
	local String = lpeg.C(Letter * (Letter) ^ 0)
	
	local colon = lpeg.C(":")
	local comma = lpeg.C(",")
	local open = lpeg.C("(")
	local close = lpeg.C(")")
	local openB = lpeg.C("{")
	local closeB = lpeg.C("}")
	local owlgred = lpeg.C("owlgred:")
	local value = lpeg.C("$value")--iespejam japieliek funkcija
	local subject = lpeg.C("$subject")--iespejam japieliek funkcija
	local concat = lpeg.C('$concat')
	local concatClose = lpeg.C('")')
	local quote = lpeg.C('"')
	
	local Exp, A, B, C, D, R = lpeg.V"Exp", lpeg.V"A", lpeg.V"B", lpeg.V"C", lpeg.V"D", lpeg.V"R"
	G = lpeg.P{ Exp,
		Exp = String * open * SpaceO * B * SpaceO * C * SpaceO * close;
		B = lpeg.Cs(String * open * ((owlgred * String)/repOwlgred) * SpaceO * D * close * SpaceO)^0 ;
		D = quote * String * quote + (subject/repSubject)/repQuotes;
		C = ((owlgred * String)/repOwlgred) * SpaceO * R * SpaceO * D;
		R = (colon * String)/repColon + (String * openB * String * closeB)/repB;
		-- R = (colon * String)/repColon2 + (String * openB * String * closeB)/repB;
	}
	
	local FunNamePat = lpeg.P(G)
	FunNamePat = lpeg.Cs((FunNamePat))

	return lpeg.match(FunNamePat, text) or "PPPPPP"
end--]]

--gramatika prieks lietotaja defineto lauku vertibu importa
function gramarImport2(text, repSubject)
	local Space = lpeg.S(" \n\t") ^ 1
	local SpaceO = lpeg.S(" \n\t") ^ 0
	
	local Letter = lpeg.R("az") + lpeg.R("AZ") + lpeg.R("09") + lpeg.S("_/")
	local String = lpeg.C(Letter * (Letter) ^ 0)
	
	local colon = lpeg.C(":")
	local comma = lpeg.C(",")
	local open = lpeg.C("(")
	local close = lpeg.C(")")
	local openB = lpeg.C("{")
	local closeB = lpeg.C("}")
	local owlgred = lpeg.C("owlgred:")
	local value = lpeg.C("$value")--iespejam japieliek funkcija
	local subject = lpeg.C("$subject")--iespejam japieliek funkcija
	local concat = lpeg.C('$concat')
	local concatClose = lpeg.C('")')
	local quote = lpeg.C('"')
	
	local Exp, A, B, C, D, R = lpeg.V"Exp", lpeg.V"A", lpeg.V"B", lpeg.V"C", lpeg.V"D", lpeg.V"R"
	G = lpeg.P{ Exp,
		Exp = String * open * SpaceO * B * SpaceO * C * SpaceO * close;
		B = lpeg.Cs(String * open * (((String * colon * String)/prefix) + (colon * String)) * SpaceO * D * close * SpaceO)^0 ;
		D = quote * String * quote + (subject/repSubject)/repQuotes;
		C = (((String * colon * String)/prefix) + (colon * String)) * SpaceO * R * SpaceO * D;
		-- R = (colon * String)/repColon + (String * openB * String * closeB)/repB;
		R = ((String * colon * String)/prefix) + (colon * String) + (String * openB * String * closeB)/repB;
	}
	
	local FunNamePat = lpeg.P(G)
	FunNamePat = lpeg.Cs((FunNamePat))
	return lpeg.match(FunNamePat, text) or ""
end

--gramatika prieks definetiem Prefiksiem(Namespace) prieks importa
function prefix(St, colon, field)
	-- local tag = lQuery("ToolType/tag[key='owl_Import_Prefixes']")
	-- --vajadzigs tableCapcure
	local Space = lpeg.S(" \n\t") ^ 1
	local pr = lpeg.P("Prefix(")
	local en = lpeg.P(")")
	local Letter = lpeg.R("az") + lpeg.R("AZ") + lpeg.R("09") + lpeg.S("_/:#.<>=")
	local String = lpeg.C(Letter * (Letter) ^ 0)
	local row = pr * String * en
	local p = lpeg.Ct(row * (Space * row)^0 )  -- make a table capture
	--local t = lpeg.match(p, tag:attr("value"))
	local tt = {}
	local colon2 = lpeg.P(":=")
	local Letter2 = lpeg.R("az") + lpeg.R("AZ") + lpeg.R("09") + lpeg.S("_/#.<>:-")
	local String2 = lpeg.C(Letter2 * (Letter2) ^ 0)
	local Letter3 = lpeg.R("az") + lpeg.R("AZ") + lpeg.R("09") + lpeg.S("_/#.<>")
	local String3 = lpeg.C(Letter3 * (Letter3) ^ 0)
	local String33 = lpeg.P(Letter3 * (Letter3) ^ 0)
	local pat = String3 * colon2 * String2-- * Space
	local pat2 = String33 * colon2 * String2-- * Space

	local t = lQuery("ToolType/tag[key='owl_NamespaceDef']"):map(function(obj)
		return obj:attr("value")
	end)
	for i,v in pairs(t) do  tt[lpeg.match(pat, v)] = lpeg.match(pat2, v) end
	local ret = tt[St]
	local len = string.len(ret)
	ret = string.sub(ret, 1, len-1) .. field .. ">"
	return ret
end

function repOwlgred(owlgred, String)
	return '<http://owlgred.lumii.lv/__plugins/fields/2011/1.0/owlgred#' .. String .. '>'
end

--gramatika prieks AxiomAnnotation aksiomu eksporta
function gramar(text, repSubject, repValue, repObject, repDomain, repRange)
	--local repObject = "JJJJJJJJJJJJJJJJJJJ"
	local Space = lpeg.S(" \n\t") ^ 1
	
	local Letter = lpeg.R("az") + lpeg.R("AZ") + lpeg.R("09") + lpeg.S("_/{}#-[]")
	local String = lpeg.C(Letter * (Letter) ^ 0)
	
	local LetterB = lpeg.R("az") + lpeg.R("AZ") + lpeg.S("{}")
	local StringB = lpeg.C(LetterB * (LetterB) ^ 0)
	
	local LetterAll = lpeg.R("az") + lpeg.R("AZ") + lpeg.S('"') + lpeg.S("'/")
	local StringAll = lpeg.C(LetterAll * (LetterAll) ^ 0)
	
	local Number = lpeg.R("09")
	local Numbers = lpeg.C((Number) ^ 1)
	
	local colon = lpeg.C(":")
	local comma = lpeg.C(",")
	local open = lpeg.C("(")
	local close = lpeg.C(")")
	local openB = lpeg.C("{")
	local closeB = lpeg.C("}")
	local value = lpeg.C("$value")
	local subject = lpeg.C("$subject")
	local object = lpeg.C("$object")
	local domain = lpeg.C("$domain")
	local range = lpeg.C("$range")
	local concatOpen = lpeg.C('$concat("')
	local concat = lpeg.C('$concat')
	local concatClose = lpeg.C('")')
	local quote = lpeg.C('"')
	
	local Exp, A, B, C, D, R, K, E, F, L = lpeg.V"Exp", lpeg.V"A", lpeg.V"B", lpeg.V"C", lpeg.V"D", lpeg.V"R", lpeg.V"K", lpeg.V"E", lpeg.V"F", lpeg.V"L"
	G = lpeg.P{ Exp,
		Exp = String * open * A * close;
		A = B + L + C + F + E;
		B = R * Space * K * Space * D;
		L = R * Space * D;
		K = ((subject/repSubject)/repNamespace) + String * colon *(subject/repSubject);
		R = (colon * String)/repColon + (String * colon * String) + (String * openB * String * closeB)/repB;
		D = ((concat * open * StringAll * comma * (value/repValue) * comma * StringAll * close)/repConcat) + ((value/repValue)/repQuotes) + quote * String * quote;
		C = ((subject/repSubject)/repNamespace) * Space * R;
		F = ((domain/repDomain)/repNamespace) * Space * String * open * Numbers * Space * ((subject/repSubject)/repNamespace) * (Space * ((range/repRange)/repNamespace) )^0 * close;
		E = ((object/repObject)/repNamespace) * Space * String * open * Numbers * Space * ((subject/repSubject)/repNamespace) * close
	}
	
	local FunNamePat = lpeg.P(G)
	FunNamePat = lpeg.Cs((FunNamePat))
	return lpeg.match(FunNamePat, text) or ""
end

function repColon2(val)
	return val .. ">"
end

function repQuotes(val)
	return '"' .. val .. '"'
end

function repB(a, b, c, d)
	return tda_to_protege.make_full_object_name(c, a)
end

function repColon(colon, str)
	return tda_to_protege.make_full_object_name(str, str)
end

function repNamespace(val)
	local openB = lpeg.C("{")
	local closeB = lpeg.C("}")
	local Letter = lpeg.R("az") + lpeg.R("AZ") + lpeg.R("09") + lpeg.S("_/")
	local String = lpeg.C(Letter * (Letter) ^ 0)
	local nameNameSpace = (String * (openB * String * closeB)^0)/repN
	nameNameSpace = lpeg.Cs((nameNameSpace))
	
	return lpeg.match(nameNameSpace, val)
end

function repN(str1, openB, str2, cloceB)
	if str2~=nil then
		return tda_to_protege.make_full_object_name(str2, str1)
	else
		return tda_to_protege.make_full_object_name(str1, str1)
	end
	return str1
end

function repStringB(str, openB, str2, closeB)
	return str2 .. ":" .. str
end

function repConcat(a, b, c, d, e, f, g, h)
	return c .. e .. g
end

function match_err(patt, str)
	return lpeg.match(patt, str) --or print("NOT")
end

--atlasa lietotaju defineto lauku semantiku prieks eksporta
function getAxiomAnnotation(compartment, argument)
	
	local ret = ""
	if compartment:is_not_empty() then
		--atrast visus tagus, kas ir piesaistiti pie dota elemType vai compartType
		local typee = compartment:find("/compartType")
		if typee:is_empty() then typee = compartment:find("/elemType") end
		local tags = typee:find("/axiomAnnotationTag[key='owl_Axiom_Annotation']"):each(function(tag)
			--jaatrod value(janoparse)
			local text = tag:attr("value")
			local valueCompartType = tag:find("/type")
			
			-- jaatrod compartmenta vertiba 
			
			if valueCompartType:is_not_empty() then--pie lauka
				local parent = compartment
				--atrast path
				if string.find(text, "Path") ~= nil then
					local ending = string.find(text, ")")
					local path = string.sub(text, 6, ending-1)
					if path ~= ".." then 
						pathTable = styleMechanism.split(path, "/")
						for i,v in pairs(pathTable) do 
							local parent2 = parent:find("/element")
							if parent2:is_empty() then parent2 = parent:find("/parentCompartment") end
							parent = parent2
						end
					end
				end

				if parent:find("/compartType/parentCompartType"):is_not_empty() and string.find(parent:find("/compartType/parentCompartType"):attr("id"), "CheckBoxFictitious") ~= nil then
					parent=parent:find("/parentCompartment")
				end
				if parent:find("/compartType/parentCompartType"):is_not_empty() and string.find(parent:find("/compartType/parentCompartType"):attr("id"), "AutoGeneratedGroup") ~= nil then
					parent=parent:find("/parentCompartment")
				end
				value = parent:find("/subCompartment:has(/compartType[caption='" .. valueCompartType:attr("caption") .. "'])")
				if value:is_empty() then value = parent:find("/compartment:has(/compartType[caption='" .. valueCompartType:attr("caption") .. "'])") end
				
				if value:is_empty() then value = parent:find("/compartment/subCompartment:has(/compartType[caption='" .. valueCompartType:attr("caption") .. "'])") end
				if value:is_empty() then value = parent:find("/subCompartment/subCompartment:has(/compartType[caption='" .. valueCompartType:attr("caption") .. "'])") end
				
				if  (compartment:find("/parentCompartment/compartType"):is_not_empty() and  compartment:find("/parentCompartment/compartType"):attr("id")=="AutoGeneratedGroupMultiplicity") then
					local mul = compartment:attr("value")
					if string.find(argument,"ExactCardinality")~=nil or string.find(argument,"Functional")~=nil or string.find(argument,"MinCardinality")~=nil then
						local start = string.find(mul, "(", 1, true)
						local fin = string.find(mul, ")")
						if start ~= nil and fin ~= nil and start==1 then
							local subject = valueCompartType:attr("id")
							if getAxiomsAnnotationType(text) == argument or argument==nil or getAxiomsAnnotationType(text)=="" then 
								ret = ret ..  'Annotation(' .. getAxioms(mul, subject, text ).. ')'
							end
						end
					elseif string.find(argument,"MaxCardinality")~=nil then
						local start = string.find(mul, "..%(")
						if start ~= nil  then
							local subject = valueCompartType:attr("id")
							if getAxiomsAnnotationType(text) == argument or argument==nil or getAxiomsAnnotationType(text)=="" then 
								ret = ret ..  'Annotation(' .. getAxioms(mul, subject, text ).. ')'
							end
						end
					end
				elseif (value:is_not_empty() and value~=nil and value:attr("value")~="") or (compartment:find("/parentCompartment/compartType"):is_not_empty() and  compartment:find("/parentCompartment/compartType"):attr("id")=="AutoGeneratedGroupMultiplicity") then 
					local subject = valueCompartType:attr("id")
					if getAxiomsAnnotationType(text) == argument or (argument==nil and getAxiomsAnnotationType(text)=="") or getAxiomsAnnotationType(text)=="" then 
						local val = value:attr("value")
						if value:is_empty() then val = " " end
						ret = ret ..  'Annotation(' .. getAxioms(val, subject, text ).. ')'
					end
				end
			else
				valueCompartType = tag:find("/choiceItem/compartType")--pie choiceItem
				local parent = compartment
				--atrast path
				if string.find(text, "Path") ~= nil then
					local ending = string.find(text, ")")
					local path = string.sub(text, 6, ending-1)
					if path ~= ".." then 
						pathTable = styleMechanism.split(path, "/")
						for i,v in pairs(pathTable) do 
							local parent2 = parent:find("/element")
							if parent2:is_empty() then parent2 = parent:find("/parentCompartment") end
							parent = parent2
						end
					end
				end
				
				if parent:find("/compartType/parentCompartType"):is_not_empty() and string.find(parent:find("/compartType/parentCompartType"):attr("id"), "CheckBoxFictitious") ~= nil then
					parent=parent:find("/parentCompartment")
				end
				if parent:find("/compartType/parentCompartType"):is_not_empty() and string.find(parent:find("/compartType/parentCompartType"):attr("id"), "AutoGeneratedGroup") ~= nil then
					parent=parent:find("/parentCompartment")
				end
				value = parent:find("/subCompartment:has(/compartType[caption='" .. valueCompartType:attr("caption") .. "'])")
				if value:is_empty() then value = parent:find("/compartment:has(/compartType[caption='" .. valueCompartType:attr("caption") .. "'])") end
				
				if value:is_empty() then value = parent:find("/compartment/subCompartment:has(/compartType[caption='" .. valueCompartType:attr("caption") .. "'])") end
				if value:is_empty() then value = parent:find("/subCompartment/subCompartment:has(/compartType[caption='" .. valueCompartType:attr("caption") .. "'])") end

				if value~=nil then
					local compartmentValue = value:attr("value")
					local choiceItemValue = tag:find("/choiceItem"):attr("value")
					if (compartmentValue==choiceItemValue) then 
						local subject = valueCompartType:attr("id")
						if getAxiomsAnnotationType(text) == argument or argument==nil or getAxiomsAnnotationType(text)=="" then 
							local val = value:attr("value")
							if value:is_empty() then val = " " end
							ret = ret ..  'Annotation(' .. getAxioms(val, subject, text ).. ')'
						end
					elseif (compartment:find("/parentCompartment/compartType"):is_not_empty() and  compartment:find("/parentCompartment/compartType"):attr("id")=="AutoGeneratedGroupMultiplicity") then
						local mul = compartment:attr("value")
						if string.find(argument,"ExactCardinality")~=nil or string.find(argument,"Functional")~=nil or string.find(argument,"MinCardinality")~=nil then
							local start = string.find(mul, "(", 1, true)
							local fin = string.find(mul, ")")
							if start ~= nil and fin ~= nil and start==1 then
								mul = string.sub(mul, start+1, fin-1)
							end
							if (mul==choiceItemValue) then 
								local subject = valueCompartType:attr("id")
								if getAxiomsAnnotationType(text) == argument or argument==nil or getAxiomsAnnotationType(text)=="" then 
									ret = ret ..  'Annotation(' .. getAxioms(mul, subject, text ).. ')'
								end
							end
						elseif string.find(argument,"MaxCardinality")~=nil then
							local start = string.find(mul, "..%(")
							if start ~= nil then
								mul = string.sub(mul, start+3)
							end
							local fin = string.find(mul, ")")
							if fin ~= nil then
								mul = string.sub(mul, 1,fin-1)
							end
							if (mul==choiceItemValue) then 
								local subject = valueCompartType:attr("id")
								if getAxiomsAnnotationType(text) == argument or argument==nil or getAxiomsAnnotationType(text)=="" then 
									ret = ret ..  'Annotation(' .. getAxioms(mul, subject, text ).. ')'
								end
							end
						end
					end
				end
			end
		end)
	end
	return ret
end

--gramatika prieks lietotaju defineto lauku semantikas eksporta
function getAxioms(valueT, subjectT, text)
	valueT = '"' .. valueT .. '"'
	local Space = lpeg.S(" \n\t") ^ 1
	local SpaceO = lpeg.S(" \n\t") ^ 0
	
	local Letter = lpeg.R("az") + lpeg.R("AZ") + lpeg.R("09") + lpeg.S("_/.")
	local String = lpeg.C(Letter * (Letter) ^ 0)
	
	local arrow = lpeg.C("<-")
	local colon = lpeg.C(":")
	local comma = lpeg.C(",")
	local open = lpeg.C("(")
	local close = lpeg.C(")")
	local openB = lpeg.C("{")
	local closeB = lpeg.C("}")
	local owlgred = lpeg.C("owlgred:")
	local value = lpeg.C("$value")
	local subject = lpeg.C("$subject")
	local concat = lpeg.C('$concat')
	local concatClose = lpeg.C('")')
	local quote = lpeg.C('"')
	local path= lpeg.C('Path')
	
	local Exp, A, B, C = lpeg.V"Exp", lpeg.V"A", lpeg.V"B", lpeg.V"C"
	G = lpeg.P{ Exp,
		Exp = (path * open * String * close)/"" * SpaceO * (A * arrow)^0/"" * SpaceO * B;
		A = open * String * close;
		B = (String^0 * colon * (String+subject/subjectT))/repNem * SpaceO * (value/valueT + quote * String * quote);
	}
	
	local FunNamePat = lpeg.P(G)
	FunNamePat = lpeg.Cs((FunNamePat))
	return lpeg.match(FunNamePat, text) or ""
end

--gramatika prieks anotaciju tipa atpazisanas
function getAxiomsAnnotationType(text)
	local Space = lpeg.S(" \n\t") ^ 1
	local SpaceO = lpeg.S(" \n\t") ^ 0
	
	local Letter = lpeg.R("az") + lpeg.R("AZ") + lpeg.R("09") + lpeg.S("_/.")
	local String = lpeg.C(Letter * (Letter) ^ 0)
	
	local arrow = lpeg.C("<-")
	local colon = lpeg.C(":")
	local comma = lpeg.C(",")
	local open = lpeg.C("(")
	local close = lpeg.C(")")
	local openB = lpeg.C("{")
	local closeB = lpeg.C("}")
	local owlgred = lpeg.C("owlgred:")
	local value = lpeg.C("$value")
	local subject = lpeg.C("$subject")
	local concat = lpeg.C('$concat')
	local concatClose = lpeg.C('")')
	local quote = lpeg.C('"')
	local path= lpeg.C('Path')
	
	local Exp, A, B, C = lpeg.V"Exp", lpeg.V"A", lpeg.V"B", lpeg.V"C"
	G = lpeg.P{ Exp,
		Exp = (path * open * String * close * SpaceO)/"" * (A * (arrow/""))^0 * (SpaceO * B/"");
		A = open/"" * String * (close/"");
		B = String^0 * colon * (String+subject) * SpaceO * (value + quote * String * quote);
	}
	
	local FunNamePat = lpeg.P(G)
	FunNamePat = lpeg.Cs((FunNamePat))
	return lpeg.match(FunNamePat, text) or ""
end

function repNem(a, b, c)
	if c==nil then
		return tda_to_protege.make_full_object_name(b, b)
	else
		return a..b..c
	end
end