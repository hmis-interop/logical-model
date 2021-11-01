require("lQuery")
require "core"
local plugin_name = "OWLGrEd_Schema"

local path

if tda.isWeb then 
	path = tda.FindPath(tda.GetToolPath() .. "/AllPlugins", "OWLGrEd_Schema") .. "/"
else
	path = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_Schema\\"
end

local plugin_info_path = path .. "info.lua"
local f = io.open(plugin_info_path, "r")
local info = loadstring("return" .. f:read("*a"))()
f:close()
local plugin_version = info.version
local current_version = lQuery("Plugin[id='".. plugin_name .."']"):attr("version")

current_version = tonumber(string.sub(current_version, 3))
plugin_version = string.sub(plugin_version, 3)


if current_version < 2 then
	
	lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'][/noSchema != 'true'][/noSchema != '!'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'][/noSchema != 'true'][/noSchema != '!'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
AnnotationAssertion([/noSchema != 'true'][/noSchema != '!'] <http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr)
ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
DataPropertyRange([/Type:$isEmpty != true][$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))]])

	-- lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value",[[AnnotationAssertion([/../../allValuesFrom == 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
-- AnnotationAssertion([/../../allValuesFrom == '+']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
-- AnnotationAssertion([/../../allValuesFrom != 'true'][/../../allValuesFrom != '+'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

	lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
SubClassOf([/../noSchema != 'true'] $getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))
AnnotationAssertion([/../noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> $getUri(/Name /Namespace) $getClassExpr(/start))]])

	lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
InverseObjectProperties($getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
SubClassOf([/../noSchema != 'true'] $getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))
AnnotationAssertion([/../noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> $getUri(/Name /Namespace) $getClassExpr(/end))]])

	-- lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../allValuesFrom == 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
	-- lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../allValuesFrom == 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/end))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
end

if current_version < 3 then
	lQuery.create("OWL_PP#ExportParameter", {pName = 'explicitSubProperties', pValue = 'true'})
	lQuery.create("OWL_PP#ExportParameter", {pName = 'enableInversePropertyResoning', pValue = 'false'})
	lQuery.create("OWL_PP#ExportParameter", {pName = 'extendByInitialChainProperties', pValue = 'false'})
	lQuery.create("OWL_PP#ExportParameter", {pName = 'existentialAssertions', pValue = 'false'})
	lQuery("OWL_PP#ExportParameter[pName='schemaExtension']"):attr("pValue", 'Weak schema assertion')
	
	lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value",[[AnnotationAssertion([/../../noSchema != 'true'][/../../noSchema != '+']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../noSchema == 'true'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../noSchema == '+'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

	lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
	lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/end))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

end

if current_version < 4 then
	lQuery.create("PropertyEventHandler", {eventType = 'onOpen', procedureName='OWLGrEd_Schema.schema.onAttributeOpen'}):link("propertyElement", lQuery("PropertyDiagram[id='Attributes']"))
	lQuery.create("PropertyEventHandler", {eventType = 'onOpen', procedureName='OWLGrEd_Schema.schema.disablePropertiesOnOpen'}):link("propertyElement", lQuery("PropertyDiagram[id='Association']"))
end

if current_version < 5 then
	local completeMetamodelUserFields = require "OWLGrEd_UserFields.completeMetamodel"
	
	local pathConfiguration = path .. "AutoLoadConfiguration"
	completeMetamodelUserFields.loadAutoLoadContextType(pathConfiguration)
	
	local pathContextType = path .. "AutoLoadAttributes"
	completeMetamodelUserFields.loadAutoLoadProfiles(pathContextType)
	
	lQuery("CompartType[id='allValuesFrom']"):attr("caption", "Schema Only (no domain assertion)")
	lQuery("PropertyRow[id='allValuesFrom']"):attr("caption", "Schema Only (no domain assertion)")

	lQuery("CompartType[id='noSchema']"):attr("caption", "No schema (domain only)")
	lQuery("PropertyRow[id='noSchema']"):attr("caption", "No schema (domain only)")
	
	lQuery("ElemType[id='Attribute']/compartType[id='Name']"):link("translet", lQuery.create("Translet", {extensionPoint = "procGetPrefix", procedureName = "OWLGrEd_Schema.schema.setPrefixesPlusAttribute"}))

	lQuery.create("PropertyEventHandler", {eventType = 'onOpen', procedureName='OWLGrEd_Schema.schema.onAttributeLinkOpen'}):link("propertyElement", lQuery("PropertyDiagram[id='Attribute']"))

	lQuery("ElemType[id='Attribute']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(DataProperty(/Name:$getUri(/Name /Namespace)))
DataPropertyRange([/allValuesFrom != 'true'] /Name:$getUri(/Name /Namespace) $getDataTypeExpression)
SubClassOf([/noSchema != 'true'] $getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf([/noSchema != 'true'] $getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
AnnotationAssertion([/noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr(/end))
AnnotationAssertion([/noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr(/start))]])

	lQuery("ElemType[id='Attribute']/compartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/end))) ?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

end

if current_version < 6 then
	if lQuery("OWL_PP#ExportParameter[pName='schemaExtension']"):attr("pValue") ~= "Weak schema closure" and lQuery("OWL_PP#ExportParameter[pName='schemaExtension']"):attr("pValue") ~= "Strict schema closure" and lQuery("OWL_PP#ExportParameter[pName='schemaExtension']"):attr("pValue") ~= "Standard (non-shema) ontology only" then
		lQuery("OWL_PP#ExportParameter[pName='schemaExtension']"):attr("pValue", 'Weak schema closure')
		
		
		if lQuery("OWL_PP#ExportParameter[pName = 'includeSchemaAssertionsInAnnotationForm']"):attr("pValue") == "true" then
			lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'][/noSchema != 'true'][/noSchema != '!'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'][/noSchema != 'true'][/noSchema != '!'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
AnnotationAssertion([/noSchema != 'true'][/noSchema != '!'] <http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr)
ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
DataPropertyRange([/Type:$isEmpty != true][$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))]])

			lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value",[[AnnotationAssertion([/../../noSchema != 'true'][/../../noSchema != '+']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../noSchema == 'true'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../noSchema == '+'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

			lQuery("ElemType[id='Attribute']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(DataProperty(/Name:$getUri(/Name /Namespace)))
DataPropertyRange([/allValuesFrom != 'true'] /Name:$getUri(/Name /Namespace) $getDataTypeExpression)
SubClassOf([/noSchema != 'true'] $getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf([/noSchema != 'true'] $getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
AnnotationAssertion([/noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr(/end))
AnnotationAssertion([/noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> /Name:$getUri(/Name /Namespace) $getClassExpr(/start))]])

			lQuery("ElemType[id='Attribute']/compartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/end))) ?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../noSchema == 'true'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../noSchema == '+'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

			lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
SubClassOf([/../noSchema != 'true'] $getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))
AnnotationAssertion([/../noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> $getUri(/Name /Namespace) $getClassExpr(/start))]])

			lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
InverseObjectProperties($getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
SubClassOf([/../noSchema != 'true'] $getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))
AnnotationAssertion([/../noSchema != 'true']<http://lumii.lv/2011/1.0/owlgred#schema> $getUri(/Name /Namespace) $getClassExpr(/end))]])

			lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
			lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../noSchema != 'true']Annotation(<http://lumii.lv/2011/1.0/owlgred#Context> $getClassExpr(/end))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

	else
			lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'][/noSchema != 'true'][/noSchema != '!'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'][/noSchema != 'true'][/noSchema != '!'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
DataPropertyRange([/Type:$isEmpty != true][$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/allValuesFrom != 'true'][/allValuesFrom != '+'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))]])

			lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value",[[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

			lQuery("ElemType[id='Attribute']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(DataProperty(/Name:$getUri(/Name /Namespace)))
DataPropertyRange([/allValuesFrom != 'true'] /Name:$getUri(/Name /Namespace) $getDataTypeExpression)
SubClassOf([/noSchema != 'true'] $getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf([/noSchema != 'true'] $getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))]])

			lQuery("ElemType[id='Attribute']/compartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
		
			lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
SubClassOf([/../noSchema != 'true'] $getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))]])

			lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../allValuesFrom != 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
InverseObjectProperties($getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
SubClassOf([/../noSchema != 'true'] $getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))]])

			lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
			lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
		end
	end
end
	
if current_version < 7 then
    lQuery.create("PopUpElementType", {id="Export Configuration", caption="Export Configuration", nr=6, visibility=true, procedureName="OWLGrEd_Schema.schema.exportParametersForm"})
		:link("popUpDiagramType", lQuery("GraphDiagramType[id='OWL']/rClickEmpty"))
		
	--Rename profile
	lQuery("AA#Profile[name='Schema']"):attr("name", "Schema_old")
	lQuery("Extension[id='Schema']"):attr("id", "Schema_old")
	
	--add new profile
	local completeMetamodelUserFields = require "OWLGrEd_UserFields.completeMetamodel"
	local syncProfile = require "OWLGrEd_UserFields.syncProfile"
	local profileMechanism = require "OWLGrEd_UserFields.profileMechanism"

	local pathContextType

	if tda.isWeb then 
		pathContextType = path .. "AutoLoad/Schema.txt"
	else
		pathContextType = path .. "AutoLoad\\Schema.txt"
	end
	
	completeMetamodelUserFields.loadAutoLoadProfile(pathContextType)
	
	--copy information to new fields
	--role/invRole
	lQuery("ElemType[id='Association']/compartType/compartment"):each(function(role)
		local name = role:find("/subCompartment:has(/compartType[id='Name'])")
		
		if name:attr("value") ~= nil and name:attr("value") ~= "" then
		
			local noSchema = role:find("/subCompartment:has(/compartType[id='noSchema'])"):attr("value")
			local allValuesFrom = role:find("/subCompartment:has(/compartType[id='allValuesFrom'])"):attr("value")
			
			core.create_missing_compartment(role, role:find("/compartType"), role:find("/compartType/subCompartType[id='schemaAssertion']"))
			core.create_missing_compartment(role, role:find("/compartType"), role:find("/compartType/subCompartType[id='domainAndRange']"))
			core.create_missing_compartment(role, role:find("/compartType"), role:find("/compartType/subCompartType[id='localRange']"))
				
			local schemaAssertion = role:find("/subCompartment:has(/compartType[id='schemaAssertion'])")
			local domainAndRange = role:find("/subCompartment:has(/compartType[id='domainAndRange'])")
			local localRange = role:find("/subCompartment:has(/compartType[id='localRange'])")
			-- print(noSchema, allValuesFrom, role:find("/subCompartment:has(/compartType[id='Name'])"):attr("value"))
			if noSchema == "true" or noSchema == "!" then 
				domainAndRange:attr("value", "true")
				core.update_compartment_input_from_value(domainAndRange)
			end
			if allValuesFrom == "true" or allValuesFrom == "+" then 
				schemaAssertion:attr("value", "true")
				core.update_compartment_input_from_value(schemaAssertion)
				localRange:attr("value", "true")
				core.update_compartment_input_from_value(localRange)
			end
			if allValuesFrom ~= "true" and  allValuesFrom ~= "+" and noSchema ~= "true" and noSchema ~= "!" then 
				schemaAssertion:attr("value", "true")
				core.update_compartment_input_from_value(schemaAssertion)
				domainAndRange:attr("value", "true")
				core.update_compartment_input_from_value(domainAndRange)
			end
				
			local result = ""
			if schemaAssertion:attr("value") ~= "true" then result = "!"
			elseif domainAndRange:attr("value") ~= "true" then 
				result = "+"
				if localRange:attr("value") ~= "true" then result = "++" end
			end
		
			name:attr("input", result .. name:attr("value"))
			utilities.refresh_element(name, utilities.current_diagram())
		end
	end)
	--attributes
	lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/compartment"):each(function(attribute)
		local noSchema = attribute:find("/subCompartment:has(/compartType[id='noSchema'])"):attr("value")
		local allValuesFrom = attribute:find("/subCompartment:has(/compartType[id='allValuesFrom'])"):attr("value")
		
		core.create_missing_compartment(attribute, attribute:find("/compartType"), attribute:find("/compartType/subCompartType[id='schemaAssertion']"))
		core.create_missing_compartment(attribute, attribute:find("/compartType"), attribute:find("/compartType/subCompartType[id='domainAndRange']"))
		core.create_missing_compartment(attribute, attribute:find("/compartType"), attribute:find("/compartType/subCompartType[id='localRange']"))
			
		local schemaAssertion = attribute:find("/subCompartment:has(/compartType[id='schemaAssertion'])")
		local domainAndRange = attribute:find("/subCompartment:has(/compartType[id='domainAndRange'])")
		local localRange = attribute:find("/subCompartment:has(/compartType[id='localRange'])")

		-- print(noSchema, allValuesFrom, attribute:find("/subCompartment:has(/compartType[id='Name'])"):attr("value"))
		if noSchema == "true" or noSchema == "!" then 
			domainAndRange:attr("value", "true")
			core.update_compartment_input_from_value(domainAndRange)
		end
		if allValuesFrom == "true" or allValuesFrom == "+" then 
			schemaAssertion:attr("value", "true")
			core.update_compartment_input_from_value(schemaAssertion)
			localRange:attr("value", "true")
			core.update_compartment_input_from_value(localRange)
		end
		if allValuesFrom ~= "true" and  allValuesFrom ~= "+" and noSchema ~= "true" and noSchema ~= "!" then 
			schemaAssertion:attr("value", "true")
			core.update_compartment_input_from_value(schemaAssertion)
			domainAndRange:attr("value", "true")
			core.update_compartment_input_from_value(domainAndRange)
		end
		
		local result = false
		if (schemaAssertion:attr("value") == "true" or schemaAssertion:attr("value") == " ") 
		and (domainAndRange:attr("value") ~= "true" and domainAndRange:attr("value") ~= "!" and domainAndRange:attr("value") ~= " ")
		and (localRange:attr("value")~="true" and localRange:attr("value")~="true")then result = "+" end
		
		core.create_missing_compartment(attribute, attribute:find("/compartType"), attribute:find("/compartType/subCompartType[id='hiddenCompartment']"))
		local hiddenCompartment = attribute:find("/subCompartment:has(/compartType[id='hiddenCompartment'])")
		hiddenCompartment:attr("value", result)
		core.update_compartment_input_from_value(hiddenCompartment)
	end)
	
	--attribute
	lQuery("ElemType[id='Attribute']/element"):each(function(attribute)
		local noSchema = attribute:find("/compartment:has(/compartType[id='noSchema'])"):attr("value")
		local allValuesFrom = attribute:find("/compartment:has(/compartType[id='allValuesFrom'])"):attr("value")
		
		core.create_missing_compartment(attribute, attribute:find("/compartType"), attribute:find("/elemType/compartType[id='schemaAssertion']"))
		core.create_missing_compartment(attribute, attribute:find("/compartType"), attribute:find("/elemType/compartType[id='domainAndRange']"))
		core.create_missing_compartment(attribute, attribute:find("/compartType"), attribute:find("/elemType/compartType[id='localRange']"))
			
		local schemaAssertion = attribute:find("/compartment:has(/compartType[id='schemaAssertion'])")
		local domainAndRange = attribute:find("/compartment:has(/compartType[id='domainAndRange'])")
		local localRange = attribute:find("/compartment:has(/compartType[id='localRange'])")
		
		if noSchema == "true" or noSchema == "!" then 
			domainAndRange:attr("value", "true")
			core.update_compartment_input_from_value(domainAndRange)
		end
		if allValuesFrom == "true" or allValuesFrom == "+" then 
			schemaAssertion:attr("value", "true")
			core.update_compartment_input_from_value(schemaAssertion)
			localRange:attr("value", "true")
			core.update_compartment_input_from_value(localRange)
		end
		if allValuesFrom ~= "true" and  allValuesFrom ~= "+" and noSchema ~= "true" and noSchema ~= "!" then 
			schemaAssertion:attr("value", "true")
			core.update_compartment_input_from_value(schemaAssertion)
			domainAndRange:attr("value", "true")
			core.update_compartment_input_from_value(domainAndRange)
		end
	end)
	
	--delete old fields
	local profileName = "Schema_old"
	local profile = lQuery("AA#Profile[name = '" .. profileName .. "']")
	--izdzest AA# Dalu
	lQuery(profile):find("/field"):each(function(obj)
		profileMechanism.deleteField(obj)
	end)
	--saglabajam stilus
	lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
		utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
	end)
	--palaist sinhronizaciju
	syncProfile.syncProfile(profileName)
	-- viewMechanism.deleteViewFromProfile(profileName)
	--izdzest profilu, extension
	lQuery(profile):delete()
	lQuery("Extension[id='" .. profileName .. "'][type='aa#Profile']"):delete()
	
	--delete old fields
	local profileName = "Schema_Attribute"
	local profile = lQuery("AA#Profile[name = '" .. profileName .. "']")
	--izdzest AA# Dalu
	lQuery(profile):find("/field"):each(function(obj)
		profileMechanism.deleteField(obj)
	end)
	--saglabajam stilus
	lQuery("GraphDiagram:has(/graphDiagramType[id='OWL'])"):each(function(diagram)
		utilities.execute_cmd("SaveDgrCmd", {graphDiagram = diagram})
	end)
	--palaist sinhronizaciju
	syncProfile.syncProfile(profileName)
	-- viewMechanism.deleteViewFromProfile(profileName)
	--izdzest profilu, extension
	lQuery(profile):delete()
	lQuery("Extension[id='" .. profileName .. "'][type='aa#Profile']"):delete()

	lQuery("ElemType[id='Class']/compartType[id='ASFictitiousAttributes']/compartment"):each(function(attribute)
		attribute:find("/subCompartment"):each(function(attrib)
		    core.update_compartment_value_from_subcompartments(attrib)
		end)
		core.update_compartment_value_from_subcompartments(attribute)
	end)
	
	lQuery.create("OWL_PP#ExportParameter", {pName = 'computePropertyRangeClosure', pValue = 'true'})
	
	lQuery("CompartType[id='schemaAssertion']"):attr("caption", "Schema assertion")
	lQuery("PropertyRow[id='schemaAssertion']"):attr("caption", "Schema assertion")

	lQuery("CompartType[id='domainAndRange']"):attr("caption", "Domain and Range")
	lQuery("PropertyRow[id='domainAndRange']"):attr("caption", "Domain and Range")

	lQuery("CompartType[id='localRange']"):attr("caption", "Local range (all values from)")
	lQuery("PropertyRow[id='localRange']"):attr("caption", "Local range (all values from)")
	
	
	lQuery("ElemType[id='Association']/compartType[id = 'Role']/subCompartType[id='Name']/translet[extensionPoint = 'procGetPrefix']"):delete()
	lQuery("ElemType[id='Association']/compartType[id = 'InvRole']/subCompartType[id='Name']/translet[extensionPoint = 'procGetPrefix']"):delete()
	lQuery("ElemType[id='Association']/compartType[id = 'Role']/subCompartType[id='Name']"):link("translet", lQuery.create("Translet", {extensionPoint = "procGetPrefix", procedureName = "OWLGrEd_Schema.schema.setPrefixNameRole"}))
	lQuery("ElemType[id='Association']/compartType[id = 'InvRole']/subCompartType[id='Name']"):link("translet", lQuery.create("Translet", {extensionPoint = "procGetPrefix", procedureName = "OWLGrEd_Schema.schema.setPrefixNameRole"}))

	lQuery("ElemType[id='Attribute']/compartType[id='Name']/translet[extensionPoint = 'procGetPrefix']"):delete()
	lQuery("ElemType[id='Attribute']/compartType[id='Name']"):link("translet", lQuery.create("Translet", {extensionPoint = "procGetPrefix", procedureName = "OWLGrEd_Schema.schema.setPrefixeNameAttribute"}))
	
	lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='hiddenCompartment']"):attr("shouldBeIncluded", "OWLGrEd_Schema.schema.hideField")
	lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='hiddenCompartment']/propertyRow"):attr("shouldBeIncluded", "OWLGrEd_Schema.schema.hideField")
	
	lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
AnnotationAssertion([/schemaAssertion == 'true'][/Type/Type:$isEmpty != true] Annotation(<http://lumii.lv/2018/1.0/owlc#target> /Type:$getTypeExpression(/Type /Namespace)) <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr)
AnnotationAssertion([/schemaAssertion == ' '][/Type/Type:$isEmpty != true] Annotation(<http://lumii.lv/2018/1.0/owlc#target> /Type:$getTypeExpression(/Type /Namespace)) <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr)
AnnotationAssertion([/schemaAssertion == 'true'][/Type/Type:$isEmpty == true] <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr)
AnnotationAssertion([/schemaAssertion == ' '][/Type/Type:$isEmpty == true] <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr)
ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/domainAndRange == 'true'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/domainAndRange == ' '] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/domainAndRange == '!'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
DataPropertyRange([/Type:$isEmpty != true][$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/domainAndRange == 'true'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
DataPropertyRange([/Type:$isEmpty != true][$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/domainAndRange == '!'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
DataPropertyRange([/Type:$isEmpty != true][$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/domainAndRange == ' '] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))]])

lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value",[[AnnotationAssertion([/../../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../schemaAssertion == ' ']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../schemaAssertion != 'true'][/../../schemaAssertion != ' '] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../domainAndRange == 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
SubClassOf($getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))
AnnotationAssertion([/../schemaAssertion == 'true'] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/end))) <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/start))]])

lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../domainAndRange == 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
InverseObjectProperties([/../../Role/domainAndRange == 'true'][/../domainAndRange == 'true']$getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
AnnotationAssertion([/../../Role/domainAndRange != 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#source> $getClassExpr(/start)) Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start)) <http://lumii.lv/2018/1.0/owlc#isInverse> $getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
AnnotationAssertion([/../domainAndRange != 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#source> $getClassExpr(/start)) Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start)) <http://lumii.lv/2018/1.0/owlc#isInverse> $getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
SubClassOf($getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))
AnnotationAssertion([/../schemaAssertion == 'true'] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start))) <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/end))]])

lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr(/end))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])


if lQuery("Plugin[id='DefaultOrder']"):is_not_empty() and lQuery("Plugin[id='DefaultOrder']"):attr("status") == "loaded" then
	if lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):size() == 0 then
		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']"):link("tag", lQuery.create("Tag",{key = 'ExportAxiom', value = ""}))
	end
	if lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):size() == 0 then
		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']"):link("tag", lQuery.create("Tag",{key = 'ExportAxiom', value = ""}))
	end
	lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr(/start))) <http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])
	lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr(/end))) <http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])

	lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']/tag[key = 'owl_Field_axiom']"):delete()
	lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']/tag[key = 'owl_Field_axiom']"):delete()

end

lQuery("ElemType[id='Attribute']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(DataProperty(/Name:$getUri(/Name /Namespace)))
DataPropertyRange([/domainAndRange == 'true'] /Name:$getUri(/Name /Namespace) $getDataTypeExpression)
SubClassOf($getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf($getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
AnnotationAssertion([/schemaAssertion == 'true'] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getDataTypeExpression)) <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr(/end))
AnnotationAssertion([/schemaAssertion == 'true'] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getDataTypeExpression)) <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr(/start))]])

lQuery("ElemType[id='Attribute']/compartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr(/end))) ?([/../../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

end

if current_version < 8 then
lQuery("PopUpElementType[id='Export Configuration']"):attr("caption", "Ontology Export Options")
end

if current_version < 9 then
    lQuery.create("Translet", {extensionPoint = 'procDecompose', procedureName = 'OWLGrEd_Schema.schema.schemaGrammar'}):link("type", lQuery("CompartType[id='Attributes']"))
	lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type/Type /isObjectAttribute) != 'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) != 'ObjectProperty'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
AnnotationAssertion([/schemaAssertion == 'true' || /schemaAssertion == ' '][/Type/Type:$isEmpty != true] Annotation(<http://lumii.lv/2018/1.0/owlc#target> /Type:$getTypeExpression(/Type /Namespace)) <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr)
AnnotationAssertion([/schemaAssertion == 'true' || /schemaAssertion == ' '][/Type/Type:$isEmpty == true] <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr)
ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/domainAndRange == 'true' || /domainAndRange == ' ' || /domainAndRange == '!'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
DataPropertyRange([/Type:$isEmpty != true][$getAttributeType(/Type /isObjectAttribute) != 'ObjectProperty'][/domainAndRange == 'true' || /domainAndRange == ' ' || /domainAndRange == '!'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))]])

lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value",[[AnnotationAssertion([/../../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../schemaAssertion == ' ']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../schemaAssertion != 'true'][/../../schemaAssertion != ' '] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

end

if current_version < 10 then
    lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
AnnotationAssertion([/schemaAssertion == 'true' || /schemaAssertion == ' '][/Type/Type:$isEmpty != true][/Type/Type != 'Thing'] Annotation(<http://lumii.lv/2018/1.0/owlc#target> /Type:$getTypeExpression(/Type /Namespace)) <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr)
AnnotationAssertion([/schemaAssertion == 'true' || /schemaAssertion == ' '][/Type/Type:$isEmpty == true || /Type/Type == 'Thing'] <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr)
ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/domainAndRange == 'true' || /domainAndRange == ' ' || /domainAndRange == '!'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
DataPropertyRange([/Type:$isEmpty != true][$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/domainAndRange == 'true' || /domainAndRange == ' ' || /domainAndRange == '!'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))]])


	lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../domainAndRange == 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
SubClassOf($getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))
AnnotationAssertion([/../schemaAssertion == 'true'][$getClassName(/end) != 'Thing'] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/end))) <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/start))
AnnotationAssertion([/../schemaAssertion == 'true'][$getClassName(/end) == 'Thing' || $getClassName(/end) == ''] <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/start))]])

lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../domainAndRange == 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
InverseObjectProperties([/../../Role/domainAndRange == 'true'][/../domainAndRange == 'true']$getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
AnnotationAssertion([/../../Role/domainAndRange != 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#source> $getClassExpr(/start)) Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start)) <http://lumii.lv/2018/1.0/owlc#isInverse> $getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
AnnotationAssertion([/../domainAndRange != 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#source> $getClassExpr(/start)) Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start)) <http://lumii.lv/2018/1.0/owlc#isInverse> $getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
SubClassOf($getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))
AnnotationAssertion([/../schemaAssertion == 'true'][$getClassName(/start) != 'Thing'] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start))) <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/end))
AnnotationAssertion([/../schemaAssertion == 'true'][$getClassName(/start) == 'Thing' || $getClassName(/start) == ''] <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/end))]])

end

if current_version < 11 then
	local configurator = require("configurator.configurator")
	lQuery("ToolbarElementType[id=SchemaExportParameters]"):delete()
	-- refresh project diagram
	configurator.make_toolbar(lQuery("GraphDiagramType[id=projectDiagram]"))
	configurator.make_toolbar(lQuery("GraphDiagramType[id=OWL]"))
	lQuery("PopUpElementType[id='Export Configuration']"):delete()
	
	local checkBox = lQuery("OWL_PP#ExportParameterRow[type = 'checkBox']")
	local radioButton = lQuery("OWL_PP#ExportParameterRow[type = 'radioButton']")

	local tab = lQuery.create("OWL_PP#ExportParameterTab", {caption = "Schema", source = "OWLGrEd_Schema"})

	local schemaExportType = lQuery.create("OWL_PP#ExportParameterGroupBox", {caption = "Schema export type", topMargin = 0, leftMargin = 0}):link("tab", tab)
	local schemaExtension = lQuery.create("OWL_PP#ExportParameter", {pName = 'schemaExtension', pValue = 'Weak schema closure', caption = "", procedure = "lua.OWLGrEd_Schema.schema.saveRadioButtonParameter()", topMargin = 5})
	:link("groupBox",schemaExportType)
	:link("row",radioButton)

		lQuery.create("OWL_PP#ExportParameterValueOption", {value = "Weak schema closure"}):link("parameter", schemaExtension)
		lQuery.create("OWL_PP#ExportParameterValueOption", {value = "Strict schema closure"}):link("parameter", schemaExtension)
		lQuery.create("OWL_PP#ExportParameterValueOption", {value = "Standard (non-shema) ontology only"}):link("parameter", schemaExtension)

	lQuery.create("OWL_PP#ExportParameter", {pName = 'computePropertyRangeClosure', pValue = 'true', caption = "Compute property range closure", procedure = "lua.OWLGrEd_Schema.schema.saveCheckBoxParameter()", topMargin = 10})
	:link("groupBox",schemaExportType)
	:link("row",checkBox)

	lQuery.create("OWL_PP#ExportParameter", {pName = 'includeSchemaAssertionsInAnnotationForm', pValue = 'true', caption = "Include schema assertions in annotation form", procedure = "lua.OWLGrEd_Schema.schema.saveCheckBoxParameter()", topMargin = 10})
	:link("groupBox",schemaExportType)
	:link("row",checkBox)


	local schemaClosureExtensions = lQuery.create("OWL_PP#ExportParameterGroupBox", {caption = "Schema closure extensions", topMargin = 10, leftMargin = 0}):link("tab", tab)
	lQuery.create("OWL_PP#ExportParameter", {pName = 'explicitSubProperties', pValue = 'true', caption = "Explicit sub-properties", procedure = "lua.OWLGrEd_Schema.schema.saveCheckBoxParameter()", topMargin = 5, leftMargin = 0})
	:link("groupBox",schemaClosureExtensions)
	:link("row",checkBox)

	lQuery.create("OWL_PP#ExportParameter", {pName = 'enableInversePropertyResoning', pValue = 'false', caption = "Enable inverse property reasoning", procedure = "lua.OWLGrEd_Schema.schema.saveCheckBoxParameter()", leftMargin = 30})
	:link("groupBox",schemaClosureExtensions)
	:link("row",checkBox)

	lQuery.create("OWL_PP#ExportParameter", {pName = 'extendByInitialChainProperties', pValue = 'false', caption = "Extend by initial chain properties", procedure = "lua.OWLGrEd_Schema.schema.saveCheckBoxParameter()", leftMargin = 30})
	:link("groupBox",schemaClosureExtensions)
	:link("row",checkBox)

	lQuery.create("OWL_PP#ExportParameter", {pName = 'existentialAssertions', pValue = 'false', caption = "Existential assertions (some values from, min cardinality, has values ..)", procedure = "lua.OWLGrEd_Schema.schema.saveCheckBoxParameter()", topMargin = 10, leftMargin = 0})
	:link("groupBox",schemaClosureExtensions)
	:link("row",checkBox)
end

if current_version < 12 then
	lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../domainAndRange == 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
SubClassOf($getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))
AnnotationAssertion([/../schemaAssertion == 'true'][$getClassName(/end) != 'Thing'][$getClassName(/start) != ''] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/end))) <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/start))
AnnotationAssertion([/../schemaAssertion == 'true'][$getClassName(/end) == 'Thing' || $getClassName(/end) == ''][$getClassName(/start) != ''] <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/start))]])

	lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../domainAndRange == 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
InverseObjectProperties([/../../Role/domainAndRange == 'true'][/../domainAndRange == 'true']$getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
AnnotationAssertion([/../../Role/domainAndRange != 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#source> $getClassExpr(/start)) Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start)) <http://lumii.lv/2018/1.0/owlc#isInverse> $getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
AnnotationAssertion([/../domainAndRange != 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#source> $getClassExpr(/start)) Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start)) <http://lumii.lv/2018/1.0/owlc#isInverse> $getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
SubClassOf($getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))
AnnotationAssertion([/../schemaAssertion == 'true'][$getClassName(/start) != 'Thing'][$getClassName(/end) != ''] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start))) <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/end))
AnnotationAssertion([/../schemaAssertion == 'true'][$getClassName(/start) == 'Thing' || $getClassName(/start) == ''][$getClassName(/end) != ''] <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/end))]])

	lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
AnnotationAssertion([/schemaAssertion == 'true' || /schemaAssertion == ' '][/Type/Type:$isEmpty != true][/Type/Type != 'Thing'][/../../Name/Name != ''] Annotation(<http://lumii.lv/2018/1.0/owlc#target> /Type:$getTypeExpression(/Type /Namespace)) <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr)
AnnotationAssertion([/schemaAssertion == 'true' || /schemaAssertion == ' '][/Type/Type:$isEmpty == true || /Type/Type == 'Thing'][/../../Name/Name != ''] <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr)
ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/domainAndRange == 'true' || /domainAndRange == ' ' || /domainAndRange == '!'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
DataPropertyRange([/Type:$isEmpty != true][$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/domainAndRange == 'true' || /domainAndRange == ' ' || /domainAndRange == '!'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))]])

end
	
return true
-- return false, error_string