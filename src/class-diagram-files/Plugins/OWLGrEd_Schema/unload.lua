require("lQuery")
local utils = require "plugin_mechanism.utils"
local configurator = require("configurator.configurator")
syncProfile = require "OWLGrEd_UserFields.syncProfile"
profileMechanism = require "OWLGrEd_UserFields.profileMechanism"
viewMechanism = require "OWLGrEd_UserFields.viewMechanism"


local profileName = "Schema"
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

local contextType = lQuery("AA#ContextType[type='Attribute']")
contextType:delete()

lQuery("ElemType[id='Association']/compartType[id = 'Role']/subCompartType[id='Name']/translet[extensionPoint = 'procGetPrefix']"):delete()
lQuery("ElemType[id='Association']/compartType[id = 'InvRole']/subCompartType[id='Name']/translet[extensionPoint = 'procGetPrefix']"):delete()
lQuery("ElemType[id='Attribute']/compartType[id='Name']/translet[extensionPoint = 'procGetPrefix']"):delete()


lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
ObjectPropertyDomain([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'] /Name:$getUri(/Name /Namespace) $getDomainOrRange)
DataPropertyDomain([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace) $getDomainOrRange)]])

lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType[id='Type']/tag[key = 'ExportAxiom']"):attr("value",[[ObjectPropertyRange([$getAttributeType(/Type /../isObjectAttribute) == 'ObjectProperty'] /../Name:$getUri(/Name /Namespace) $getTypeExpression(/Type /Namespace))
DataPropertyRange([$getAttributeType(/Type /../isObjectAttribute) == 'DataProperty'] /../Name:$getUri(/Name /Namespace) $getTypeExpression(/Type /Namespace))]])

lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value",[[AnnotationAssertion($getUri(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyDomain( $getUri(/Name /Namespace) $getDomainOrRange(/start))
ObjectPropertyRange( $getUri(/Name /Namespace) $getDomainOrRange(/end))]])

lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyDomain($getUri(/Name /Namespace) $getDomainOrRange(/end))
ObjectPropertyRange($getUri(/Name /Namespace) $getDomainOrRange(/start))
InverseObjectProperties($getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))]])

lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getUri(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getUri(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

lQuery("ElemType[id='Attribute']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(DataProperty(/Name:$getUri(/Name /Namespace)))
DataPropertyDomain(/Name:$getUri(/Name /Namespace) $getClassExpr(/end))
DataPropertyDomain(/Name:$getUri(/Name /Namespace) $getClassExpr(/start))
DataPropertyRange(/Name:$getUri(/Name  /Namespace) $getDataTypeExpression)]])

lQuery("ElemType[id='Attribute']/compartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

if lQuery("Plugin[id='DefaultOrder']"):is_not_empty() and lQuery("Plugin[id='DefaultOrder']"):attr("status") == "loaded" then
	lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']"):link("tag", lQuery.create("Tag",{key = 'owl_Field_axiom', value = "AnnotationAssertion(owlgred:posInTable $subject $value)"}))
	lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']"):link("tag", lQuery.create("Tag",{key = 'owl_Field_axiom', value = "AnnotationAssertion(owlgred:posInTable $subject $value)"}))

	lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):delete()
	lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):delete()

end

--lQuery("ToolbarElementType[id=SchemaExportParameters]"):delete()
-- refresh project diagram
-- configurator.make_toolbar(lQuery("GraphDiagramType[id=projectDiagram]"))
-- configurator.make_toolbar(lQuery("GraphDiagramType[id=OWL]"))

-- lQuery("OWL_PP#ExportParameter"):delete()
-- lQuery.model.delete_class("OWL_PP#ExportParameter")

lQuery("GraphDiagramType[id='OWL']/graphDiagram/element:has(/elemType[id='Class'])/compartment:has(/compartType[id='ASFictitiousAttributes'])/subCompartment/subCompartment:has(/compartType[id='Name'])"):each(function(name)
    core.update_compartment_input_from_value(name)
end)

lQuery("GraphDiagramType[id='OWL']/graphDiagram/element:has(/elemType[id='Association'])/compartment/subCompartment:has(/compartType[id='Name'])"):each(function(name)
    core.update_compartment_input_from_value(name)
end)

utilities.enqued_cmd("OkCmd", {graphDiagram = lQuery("GraphDiagramType[id='OWL']/graphDiagram")})

lQuery("PropertyEventHandler[procedureName='OWLGrEd_Schema.schema.onAttributeOpen']"):delete()
lQuery("PropertyEventHandler[procedureName='OWLGrEd_Schema.schema.disablePropertiesOnOpen']"):delete()
lQuery("PropertyEventHandler[procedureName='OWLGrEd_Schema.schema.onAttributeLinkOpen']"):delete()

-- lQuery("PopUpElementType[id='Export Configuration']"):delete()
lQuery("Translet[procedureName='OWLGrEd_Schema.schema.schemaGrammar']"):delete()

return true
-- return false, error_string