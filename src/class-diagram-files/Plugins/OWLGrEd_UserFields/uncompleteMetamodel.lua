module(..., package.seeall)

require("lua_tda")
require "lpeg"
require "core"
deleteExtension = require "OWLGrEd_UserFields.deleteExtension"
styleMechanism = require "OWLGrEd_UserFields.styleMechanism"

function uncompleteMetamodel()
--print("uncomplete STARTED")

--jaizdzes visus izveidotus laukus
--jaatrod visas Extension instances, kas ir piesaistitas pie Extension[extensionType='Plugin']

lQuery("Extension[type='Plugin']/aa#subExtension"):each(function(obj)
	lQuery(obj):find("/type"):each(function(objCT)
		deleteExtension.deleteCompartType(objCT)
	end)
end)

lQuery("Extension[type='aa#View']"):delete()
lQuery("Extension[type='Plugin']/aa#subExtension/aa#subExtension"):delete()
lQuery("Extension[type='Plugin']/aa#subExtension"):delete()

--atjaunojam IsComposition
lQuery("CompartType[caption='IsComposition']"):attr("shouldBeIncluded", "")
lQuery("CompartType[caption='IsComposition']/propertyRow"):attr("shouldBeIncluded", "")

--izdzest specifiskos transletus
lQuery("Translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDependentStyle']"):delete()
lQuery("Translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setStyleSetting']"):delete()
lQuery("Translet[procedureName = 'OWLGrEd_UserFields.axiom.getAxiomAnnotation]"):delete()
lQuery("Translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setIsHidden]"):delete()
lQuery("Translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setSuffix]"):delete()
lQuery("Translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setPrefix]"):delete()
lQuery("Translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setAllSuffixesView]"):delete()
lQuery("Translet[procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setAllPrefixesView]"):delete()
lQuery("Translet[extensionPoint='RecalculateStylesInImport'][procedureName='OWLGrEd_UserFields.owl_fields_specific.setImportStyles']"):delete()

lQuery("Extension[type='Plugin']"):delete()
lQuery.model.delete_link("Extension", "aa#owner")
lQuery.model.delete_link("Extension", "activeExtension")
lQuery.model.delete_link("Extension", "aa#notDefault")

lQuery("AA#Profile"):delete()
lQuery("AA#Field"):delete()
lQuery("AA#ContextType"):delete()
lQuery("AA#Tag"):delete()
lQuery("AA#TransletTask"):delete()
lQuery("AA#Translet"):delete()
lQuery("AA#View"):delete()
lQuery("AA#ChoiceItem"):delete()
lQuery("AA#ViewStyleSetting"):delete()
lQuery("AA#FieldStyleSetting"):delete()
lQuery("AA#Dependency"):delete()
lQuery("AA#RowType"):delete()
lQuery("AA#StyleSetting"):delete()
lQuery("AA#CompartStyleItem"):delete()
lQuery("AA#ElemStyleItem"):delete()
lQuery("AA#NodeStyleItem"):delete()
lQuery("AA#EdgeStyleItem"):delete()
lQuery("AA#AnyElemStyleItem"):delete()
lQuery("ElementStyleSetting"):delete()
lQuery("CompartmentStyleSetting"):delete()
lQuery("AA#TagType"):delete()
lQuery("AA#Configuration"):delete()

lQuery.model.delete_link("ElementStyleSetting", "elemType")
lQuery.model.delete_link("ElementStyleSetting", "choiceItem")
lQuery.model.delete_link("ElementStyleSetting", "extension")
lQuery.model.delete_link("CompartmentStyleSetting", "compartType")
lQuery.model.delete_link("CompartmentStyleSetting", "choiceItem")
lQuery.model.delete_link("CompartmentStyleSetting", "extension")
lQuery.model.delete_link("CompartType", "aa#mirror")
lQuery.model.delete_link("Type", "axiomAnnotationTag")

--delete completed metamodel
lQuery.model.delete_class("AA#Profile")
lQuery.model.delete_class("AA#Field")
lQuery.model.delete_class("AA#ContextType")
lQuery.model.delete_class("AA#Tag")
lQuery.model.delete_class("AA#Translet")
lQuery.model.delete_class("AA#TransletTask")
lQuery.model.delete_class("AA#View")
lQuery.model.delete_class("AA#ChoiceItem")
lQuery.model.delete_class("AA#ViewStyleSetting")
lQuery.model.delete_class("AA#FieldStyleSetting")
lQuery.model.delete_class("AA#Dependency")
lQuery.model.delete_class("AA#RowType")
lQuery.model.delete_class("AA#StyleSetting")
lQuery.model.delete_class("AA#CompartStyleItem")
lQuery.model.delete_class("AA#ElemStyleItem")
lQuery.model.delete_class("AA#NodeStyleItem")
lQuery.model.delete_class("AA#EdgeStyleItem")
lQuery.model.delete_class("AA#AnyElemStyleItem")
lQuery.model.delete_class("ElementStyleSetting")
lQuery.model.delete_class("CompartmentStyleSetting")
lQuery.model.delete_class("AA#TagType")
lQuery.model.delete_class("AA#Configuration")

lQuery("Tag[key = 'owlgred_export']"):delete()
lQuery("Tag[key = 'owl_NamespaceDef']"):delete()
lQuery("Tag[key = 'owl_Annotation_Import']"):delete()
lQuery("Tag[key = 'owl_Import_Prefixes']"):delete()

local dependentStylesTable = styleMechanism.dependentStylesTable()
for i,v in pairs(dependentStylesTable) do
	local pathTable = styleMechanism.split(v[1], "/")
	local elem--lauks kuram ir translets
	for j,b in pairs(pathTable) do
		if j == 1 then elem = lQuery("ElemType[id='" .. b  .. "']")
		elseif j == 2 then elem = elem:find("/compartType[id='" .. b .. "']")
		else
			elem = elem:find("/subCompartType[id='" .. b .. "']")
		end
	end
	elem:find("/translet[extensionPoint='procFieldEntered']"):attr("procedureName", v[3])
end

lQuery("Translet[extensionPoint = 'procNewElement'][procedureName = 'OWLGrEd_UserFields.owl_fields_specific.setDefaultStyle']"):delete()
lQuery("Translet[extensionPoint = 'procCopied'][procedureName = 'OWLGrEd_UserFields.owl_fields_specific.styleCode']"):delete()

lQuery("PopUpElementType[id='Style Palette']"):delete()
lQuery("PopUpElementType[id='Manage Plug-ins]"):delete()
	

--print("uncompele ENDED")	
end
