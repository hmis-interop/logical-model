require("lQuery")
local configurator = require("configurator.configurator")
local utils = require "plugin_mechanism.utils"
local completeMetamodelUserFields = require "OWLGrEd_UserFields.completeMetamodel"
local d = require("dialog_utilities")

local path
local picturePath

if tda.isWeb then 
	path = tda.FindPath(tda.GetToolPath() .. "/AllPlugins", "OWLGrEd_Schema") .. "/"
	picturePath = tda.GetToolPath().. "/web-root/Pictures/"
else
	path = tda.GetProjectPath() .. "\\Plugins\\OWLGrEd_Schema\\"
	picturePath = tda.GetProjectPath() .. "\\Pictures\\"
end	

utils.copy(path .. "export.bmp",
           picturePath .. "OWLGrEd_Schema_export.bmp")
		   
-- lQuery.model.add_class("OWL_PP#ExportParameter")
-- lQuery.model.add_property("OWL_PP#ExportParameter", "pName")
-- lQuery.model.add_property("OWL_PP#ExportParameter", "pValue")
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

--[[
local project_dgr_type = lQuery("GraphDiagramType[id=projectDiagram]")
-- local owl_dgr_type = lQuery("GraphDiagramType[id=OWL]")-----------------------------------------------------

-- get or create toolbar type
local toolbarType = project_dgr_type:find("/toolbarType")
if toolbarType:is_empty() then
  toolbarType = lQuery.create("ToolbarType", {graphDiagramType = project_dgr_type})
end


local view_manager_toolbar_el = lQuery.create("ToolbarElementType", {
		  toolbarType = toolbarType,
		  id = "SchemaExportParameters",
		  caption = "Ontology export preferences",
		  picture = "OWLGrEd_Schema_export.bmp",
		  procedureName = "OWLGrEd_Schema.schema.exportParametersForm"
		})	
-- refresh project diagram toolbar
configurator.make_toolbar(project_dgr_type)

lQuery.create("PopUpElementType", {id="Export Configuration", caption="Ontology Export Options", nr=6, visibility=true, procedureName="OWLGrEd_Schema.schema.exportParametersForm"})
		:link("popUpDiagramType", lQuery("GraphDiagramType[id='projectDiagram']/rClickEmpty"))
--]]
local pathConfiguration = path .. "AutoLoadConfiguration"
completeMetamodelUserFields.loadAutoLoadContextType(pathConfiguration)

--ieladet profilu
local pathContextType = path .. "AutoLoad"
completeMetamodelUserFields.loadAutoLoadProfiles(pathContextType)

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

lQuery("ElemType[id='Attribute']/compartType[id='Name']"):link("translet", lQuery.create("Translet", {extensionPoint = "procGetPrefix", procedureName = "OWLGrEd_Schema.schema.setPrefixeNameAttribute"}))

-- SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'][/localRange == 'true'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
-- SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'][/localRange == 'true'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))

lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
AnnotationAssertion([/schemaAssertion == 'true' || /schemaAssertion == ' '][/Type/Type:$isEmpty != true][/Type/Type != 'Thing'][/../../Name != ''] Annotation(<http://lumii.lv/2018/1.0/owlc#target> /Type:$getTypeExpression(/Type /Namespace)) <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr)
AnnotationAssertion([/schemaAssertion == 'true' || /schemaAssertion == ' '][/Type/Type:$isEmpty == true || /Type/Type == 'Thing'][/../../Name != ''] <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr)
ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/domainAndRange == 'true' || /domainAndRange == ' ' || /domainAndRange == '!'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
DataPropertyRange([/Type:$isEmpty != true][$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/domainAndRange == 'true' || /domainAndRange == ' ' || /domainAndRange == '!'] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))]])

lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value",[[AnnotationAssertion([/../../schemaAssertion == 'true' || /../../schemaAssertion == ' ']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../schemaAssertion != 'true'][/../../schemaAssertion != ' '] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

-- SubClassOf([/../localRange == 'true'] $getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))
lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../domainAndRange == 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
SubClassOf($getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))
AnnotationAssertion([/../schemaAssertion == 'true'][$getClassName(/end) != 'Thing'][$getClassName(/start) != ''] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/end))) <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/start))
AnnotationAssertion([/../schemaAssertion == 'true'][$getClassName(/end) == 'Thing' || $getClassName(/end) == ''][$getClassName(/start) != ''] <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/start))]])

-- SubClassOf([/../localRange == 'true'] $getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))
lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../domainAndRange == 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
InverseObjectProperties([/../../Role/domainAndRange == 'true'][/../domainAndRange == 'true']$getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
AnnotationAssertion([/../../Role/domainAndRange != 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#source> $getClassExpr(/start)) Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start)) <http://lumii.lv/2018/1.0/owlc#isInverse> $getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
AnnotationAssertion([/../domainAndRange != 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#source> $getClassExpr(/start)) Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start)) <http://lumii.lv/2018/1.0/owlc#isInverse> $getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
SubClassOf($getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))
AnnotationAssertion([/../schemaAssertion == 'true'][$getClassName(/start) != 'Thing'][$getClassName(/end) != ''] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start))) <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/end))
AnnotationAssertion([/../schemaAssertion == 'true'][$getClassName(/start) == 'Thing' || $getClassName(/start) == ''][$getClassName(/end) != ''] <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/end))]])

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

-- SubClassOf([/localRange == 'true'] $getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
-- SubClassOf([/localRange == 'true'] $getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
-------------------------------------------------------------------------
lQuery("ElemType[id='Attribute']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(DataProperty(/Name:$getUri(/Name /Namespace)))
DataPropertyRange([/domainAndRange == 'true'] /Name:$getUri(/Name /Namespace) $getDataTypeExpression)
SubClassOf($getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf($getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
AnnotationAssertion([/schemaAssertion == 'true'] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getDataTypeExpression)) <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr(/end))
AnnotationAssertion([/schemaAssertion == 'true'] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getDataTypeExpression)) <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr(/start))]])

lQuery("ElemType[id='Attribute']/compartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr(/end))) ?([/../../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
---------------------------------------------

lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='hiddenCompartment']"):attr("shouldBeIncluded", "OWLGrEd_Schema.schema.hideField")
lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='hiddenCompartment']/propertyRow"):attr("shouldBeIncluded", "OWLGrEd_Schema.schema.hideField")

lQuery.create("PropertyEventHandler", {eventType = 'onOpen', procedureName='OWLGrEd_Schema.schema.onAttributeOpen'}):link("propertyElement", lQuery("PropertyDiagram[id='Attributes']"))
lQuery.create("PropertyEventHandler", {eventType = 'onOpen', procedureName='OWLGrEd_Schema.schema.disablePropertiesOnOpen'}):link("propertyElement", lQuery("PropertyDiagram[id='Association']"))
lQuery.create("PropertyEventHandler", {eventType = 'onOpen', procedureName='OWLGrEd_Schema.schema.onAttributeLinkOpen'}):link("propertyElement", lQuery("PropertyDiagram[id='Attribute']"))

lQuery.create("Translet", {extensionPoint = 'procDecompose', procedureName = 'OWLGrEd_Schema.schema.schemaGrammar'}):link("type", lQuery("CompartType[id='Attributes']"))
return true
-- return false, error_string