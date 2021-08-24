module(..., package.seeall)

require "lpeg"

function aaa()
return true
end

--nolasa compartment stilus no style atributa vertibas (styleAttibute-style atributa tekstuala vertiba)
function createCompartStyleFromAttribute(styleAttibute)
	local newStyle = lQuery.create("CompartStyle")
	
	--sadalam style atributa vertibas un ierakstam tas tabulaa
	local styleValues = parseCompartStyle(styleAttibute)
	
	--stilu vienumu nosaukumi, kas ir iekodeti style atributaa
	local attributeStyles = compartStyleAttribute()
	
	--stilu vienumu nosaukumi, kas ir ierakstami compartStyle instance
	local compartStyles = compartStyleInstance()
	
	for i,v in pairs(attributeStyles) do
		--ierakstam stila vienumu instance, ja tajaa tad vienums eksiste
		if compartStyles[v] ~= "" then 
			--burtu izmers tiek atkodets atseviski
			if v == "fontSize" then 
				local n, m
				m=tonumber(styleValues[i])
				m = math.abs(m)
				n=(3*m-1)/4
				n=math.ceil(n)
				newStyle:attr(v, n)
			else
				newStyle:attr(v, styleValues[i])
			end
		end
	end
	newStyle:attr("caption", styleValues[1])
	newStyle:attr("nr", 1)
	return newStyle
end

--nolasa node stilus no style atributa vertibas (styleAttibute-style atributa tekstuala vertiba)
function createNodeStyleFromAttribute(styleAttibute)
	local newStyle = lQuery.create("NodeStyle")
	
	--sadalam style atributa vertibas un ierakstam tas tabulaa
	local styleValues = parseNodeStyle(styleAttibute)
	
	--stilu vienumu nosaukumi, kas ir iekodeti style atributa
	local attributeStyles = nodeStyleAttribute()
	
	--stilu vienumu nosaukumi, kas ir ierakstami nodeStyle instance
	local nodeStyle = nodeStyleInstance()
	
	for i,v in pairs(attributeStyles) do
		--ierakstam stila vienumu instance
		if nodeStyle[v] ~= "" then newStyle:attr(v, styleValues[i]) end
	end
	--atrodam kostes augstumu un platumu no elementa location atributa
	local location = parseLocation(element:attr("location"))
	newStyle:attr("width", location[1])
	newStyle:attr("height", location[2])
	
	return newStyle
end

--nolasa nede stilus no style atributa vertibas (styleAttibute-style atributa tekstuala vertiba)
function createEdgeStyleFromAttribute(styleAttibute)
	local newStyle = lQuery.create("EdgeStyle")
	
	--sadalam style atributa vertibas un ierakstam tas tabulaa
	local styleValues = parseEdgeStyle(styleAttibute)
	
	--stilu vienumu nosaukumi, kas ir iekodeti style atributa
	local attributeStyles = edgeStyleAttribute()
	
	--stilu vienumu nosaukumi, kas ir ierakstami edgeStyle instance
	local edgeStyle = edgeStyleInstance()
	
	for i,v in pairs(attributeStyles) do
		--ierakstam stila vienumu instance
		if edgeStyle[v] ~= nil then  newStyle:attr(v, styleValues[i]) end
	end
	
	return newStyle
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
	"lineType", "lineDirection", "startShapeCode", "startShapeStyle", "startLineWidth", "startTotalWidth", "startTotalHeight", "startAdornment", "startBkgColor", "startLineColor",
	"endShapeCode", "endShapeStyle", "endLineWidth", "endTotalWidth", "endTotalHeight", "endAdornment", "endBkgColor", "endLineColor",
	"middleShapeCode", "middleShapeStyle", "middleLineWidth", "middleDashLength", "middleBreakLength", "middleAdornment", "middleBkgColor", "middleLineColor"}
end

--stili, kas ir ierakstami edgeStyle instance
function edgeStyleInstance()
	return {["shapeCode"] = 1, ["shapeStyle"] = 1, ["lineWidth"] = 1, ["dashLength"] = 1,["breakLength"] = 1, ["bkgColor"] = 1, ["lineColor"] = 1, ["lineType"] = 1,
	["lineDirection"] = 1, ["startShapeCode"] = 1, ["startLineWidth"] = 1,["startTotalWidth"] = 1, ["startTotalHeight"] = 1, ["startBkgColor"] = 1,
	["startLineColor"] = 1, ["endShapeCode"] = 1, ["endLineWidth"] = 1,["endTotalWidth"] = 1, ["endTotalHeight"] = 1, ["endBkgColor"] = 1, 
	["endLineColor"] = 1, ["middleShapeCode"] = 1, ["middleLineWidth"] = 1,["middleDashLength"] = 1, ["middleBreakLength"] = 1, ["middleBkgColor"] = 1,
	["middleLineColor"] = 1}
end

--stili, kas ir iekodeti compart atributa
function compartStyleAttribute()
	return {"id", "alignment", "adjustment", "textDirection", "shapeCode", "shapeStyle", "lineWidth", "dashLength", "breakLength", "adornment",
	"bkgColor", "lineColor", "width", "height", "xPos", "yPos", "isVisible", "fontCharSet", "fontPitch", "fontSize", "fontStyle", "fontColor", "fontTypeFace",
	"picture", "picStyle", "picPos", "picWidth", "picHeight"}
end

--stili, kas ir ierakstami compartStyle instance
function compartStyleInstance()
	return {["id"] = 1, ["alignment"] = 1, ["adjustment"] = 1, ["textDirection"] = 1,["lineWidth"] = 1, ["adornment"] = 1, ["lineColor"] = 1, ["isVisible"] = 1,
	["fontCharSet"] = 1, ["fontPitch"] = 1, ["fontSize"] = 1, ["fontStyle"] = 1,["fontColor"] = 1, ["fontTypeFace"] = 1, ["picture"] = 1, ["picStyle"] = 1,
	["picPos"] = 1, ["picWidth"] = 1, ["picHeight"] = 1}
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

-- atkodejam node width un height vertibas (text-style atributa vertiba)
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
	
	local Exp, EdgeStyle, Shape = lpeg.V"Exp", lpeg.V"NodeStyle", lpeg.V"Shape"
	G = lpeg.P{Exp,
		Exp = open * EdgeStyle * close + a;
		NodeStyle = open * Shape * close * String * separater * String * separater * open * Shape * close * open * Shape * close * open * Shape * close;
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
			String * separater * String * separater * String * separater * String * separater * String * separater * open * Shape * close * 
			open * Picture * close;
		Shape = String * separater * (String * separater) ^ 0;
		Picture = String * separater * (String * separater) ^ 0 + separater;
	}
	
	local FunNamePat = lpeg.P(lpeg.Ct(G))
	local t = lpeg.match(FunNamePat, text)
	return t
end 
