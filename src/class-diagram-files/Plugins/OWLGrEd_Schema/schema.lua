module(..., package.seeall)

local MP = require("ManchesterParser")
require "core"

--ROLE
function setPrefixFromSchemaAssertionRole(compartment, oldValue)
	local name = compartment:find("/parentCompartment/subCompartment:has(/compartType[id='Name'])")
	local compartment = compartment:filter(function(obj)
		return obj:find("/compartType"):attr("id") == "schemaAssertion"
	end)
	local owl_fields_specific = require("OWLGrEd_UserFields.owl_fields_specific")
	local prefixResult =  owl_fields_specific.setAllPrefixesView(name:find("/compartType"), name, nil)
	if compartment:attr("value") == "false" then 
		local parentCompartment = compartment:find("/parentCompartment")
		local domainAndRange = parentCompartment:find("/subCompartment:has(/compartType[id='domainAndRange'])")
		domainAndRange:attr("value", "true")
		core.update_compartment_input_from_value(domainAndRange)
		
		local localRange = parentCompartment:find("/subCompartment:has(/compartType[id='localRange'])")
		localRange:attr("value", "false")
		core.update_compartment_input_from_value(localRange)
		
		domainAndRange:find("/component"):attr("checked", "true")
		if domainAndRange:find("/component"):is_not_empty() then
			local cmd = utilities.create_command("D#Command", {info = "Refresh"})
			domainAndRange:find("/component"):link("command", cmd)
			utilities.execute_cmd_obj(cmd)
		end
		
		localRange:find("/component"):attr("checked", "false")
		if localRange:find("/component"):is_not_empty() then
			local cmd = utilities.create_command("D#Command", {info = "Refresh"})
			localRange:find("/component"):link("command", cmd)
			utilities.execute_cmd_obj(cmd)
		end
		
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='localRange'])/component"), false)
		
		name:attr("input", "!" .. prefixResult.. name:attr("value"))
	else
		local domainAndRange = compartment:find("/parentCompartment/subCompartment:has(/compartType[id='domainAndRange'])"):attr("value")
		local localRange = compartment:find("/parentCompartment/subCompartment:has(/compartType[id='localRange'])"):attr("value")
		local result = ""
		
		if domainAndRange == "false" then 
			result = "+"
			if localRange == "false" then result = "++" end
		end
		
		name:attr("input", result .. prefixResult ..  name:attr("value"))	
	end
	
	--------------------------------------
	--TO DO disableEnableProperty
	--------------------------------------
end

function setPrefixFromDomainAndRangeRole(compartment, oldValue)
	local name = compartment:find("/parentCompartment/subCompartment:has(/compartType[id='Name'])")
	
	local compartment = compartment:filter(function(obj)
		return obj:find("/compartType"):attr("id") == "domainAndRange"
	end)
	local owl_fields_specific = require("OWLGrEd_UserFields.owl_fields_specific")
	local prefixResult =  owl_fields_specific.setAllPrefixesView(name:find("/compartType"), name, nil)
	if compartment:attr("value") == "true" then 
		local parentCompartment = compartment:find("/parentCompartment")
		local localRange = parentCompartment:find("/subCompartment:has(/compartType[id='localRange'])")
		localRange:attr("value", "false")
		core.update_compartment_input_from_value(localRange)
		
		localRange:find("/component"):attr("checked", "false")
		if localRange:find("/component"):is_not_empty() then
			local cmd = utilities.create_command("D#Command", {info = "Refresh"})
			localRange:find("/component"):link("command", cmd)
			utilities.execute_cmd_obj(cmd)
		end
		
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='localRange'])/component"), false)
		
		local result = ""
		local schemaAssertion = parentCompartment:find("/subCompartment:has(/compartType[id='schemaAssertion'])"):attr("value")
		
		if schemaAssertion == "false" then result = "!" end
		
		if name ~= nil and name:attr("value") ~= "" then name:attr("input", result .. prefixResult.. name:attr("value")) end
	else
		local parentCompartment = compartment:find("/parentCompartment")
		
		local schemaAssertion = parentCompartment:find("/subCompartment:has(/compartType[id='schemaAssertion'])")
		schemaAssertion:attr("value", "true")
		core.update_compartment_input_from_value(schemaAssertion)
		
		schemaAssertion:find("/component"):attr("checked", "true")
		if schemaAssertion:find("/component"):is_not_empty() then
			local cmd = utilities.create_command("D#Command", {info = "Refresh"})
			schemaAssertion:find("/component"):link("command", cmd)
			utilities.execute_cmd_obj(cmd)
		end
		
		local localRange = parentCompartment:find("/subCompartment:has(/compartType[id='localRange'])")
		localRange:attr("value", "true")
		core.update_compartment_input_from_value(localRange)
		
		localRange:find("/component"):attr("checked", "true")
		if localRange:find("/component"):is_not_empty() then
			local cmd = utilities.create_command("D#Command", {info = "Refresh"})
			localRange:find("/component"):link("command", cmd)
			utilities.execute_cmd_obj(cmd)
		end
		
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='localRange'])/component"), true)
		
		local result = ""

		if schemaAssertion:attr("value") == "false" then result = "!"
		else
			result = "+"
			if localRange:attr("value") == "false" then result = "++" end
		end
		
		if name ~= nil and name:attr("value") ~= "" then name:attr("input", result .. prefixResult.. name:attr("value")) end
	end
	utilities.refresh_element(name, utilities.current_diagram())
	
	-- local compartType = compartment:find("/parentCompartment/compartType"):attr("id")
	-- if compartType == "Role" then compartType = "InvRole"
	-- else compartType = "Role" end
	-- local inverseCompartment = compartment:find("/parentCompartment/element/compartment:has(/compartType[id='".. compartType .."'])")
	-- print(inverseCompartment:size(), compartType)
-- setPrefixFromDomainAndRangeRole(inverseCompartment, oldValue)
end

function setPrefixFromLocalRangeRole(compartment, oldValue)
	local name = compartment:find("/parentCompartment/subCompartment:has(/compartType[id='Name'])")
	
	local owl_fields_specific = require("OWLGrEd_UserFields.owl_fields_specific")
	local prefixResult =  owl_fields_specific.setAllPrefixesView(name:find("/compartType"), name, nil)
	
	local schemaAssertion = compartment:find("/parentCompartment/subCompartment:has(/compartType[id='schemaAssertion'])"):attr("value")
	local domainAndRange = compartment:find("/parentCompartment/subCompartment:has(/compartType[id='domainAndRange'])"):attr("value")
	local localRange = compartment:attr("value")

	local result = ""
	if schemaAssertion == "false" then result = "!"
	elseif domainAndRange == "false" then 
		result = "+"
		if localRange == "false" then result = "++" end
	end
	
	name:attr("input", result ..prefixResult.. name:attr("value"))
	utilities.refresh_element(name, utilities.current_diagram())
end

function setPrefixNameRole(dataCompartType, dataCompartment, parsingCompartment)
	local result = ""
	if dataCompartment~=nil then
		local schemaAssertion = dataCompartment:find("/parentCompartment/subCompartment:has(/compartType[id='schemaAssertion'])"):attr("value")
		local domainAndRange = dataCompartment:find("/parentCompartment/subCompartment:has(/compartType[id='domainAndRange'])"):attr("value")
		local localRange = dataCompartment:find("/parentCompartment/subCompartment:has(/compartType[id='localRange'])"):attr("value")
		
		-- if schemaAssertion == "false" then result = "!"
		-- elseif domainAndRange == "false" then 
			-- result = "+"
			-- if localRange == "false" then result = "++" end
		-- end
		if schemaAssertion ~= "true" then result = "!"
		elseif domainAndRange ~= "true" then 
			result = "+"
			if localRange ~= "true" then result = "++" end
		end
	end
	
	local owl_fields_specific = require("OWLGrEd_UserFields.owl_fields_specific")
	result = result .. owl_fields_specific.setAllPrefixesView(dataCompartType, dataCompartment, parsingCompartment)
	
	return result
end
--ROLE

--ATTRIBUTE
function setPrefixFromSchemaAssertionAttribute(compartment, oldValue)
	local name = compartment:find("/element/compartment:has(/compartType[id='Name'])")
	
	local compartment = compartment:filter(function(obj)
		return obj:find("/compartType"):attr("id") == "schemaAssertion"
	end)
	
	if compartment:attr("value") == "false" then 
		local parentCompartment = compartment:find("/element")
		local domainAndRange = parentCompartment:find("/compartment:has(/compartType[id='domainAndRange'])")
		domainAndRange:attr("value", "true")
		core.update_compartment_input_from_value(domainAndRange)
		
		local localRange = parentCompartment:find("/compartment:has(/compartType[id='localRange'])")
		localRange:attr("value", "false")
		core.update_compartment_input_from_value(localRange)
		
		domainAndRange:find("/component"):attr("checked", "true")
		if domainAndRange:find("/component"):is_not_empty() then
			local cmd = utilities.create_command("D#Command", {info = "Refresh"})
			domainAndRange:find("/component"):link("command", cmd)
			utilities.execute_cmd_obj(cmd)
		end
		
		localRange:find("/component"):attr("checked", "false")
		if localRange:find("/component"):is_not_empty() then
			local cmd = utilities.create_command("D#Command", {info = "Refresh"})
			localRange:find("/component"):link("command", cmd)
			utilities.execute_cmd_obj(cmd)
		end
		
		disableEnableProperty(parentCompartment:find("/compartment:has(/compartType[id='localRange'])/component"), false)
		
		name:attr("input", "!" .. name:attr("value"))
	else
		local domainAndRange = compartment:find("/element/subCompartment:has(/compartType[id='domainAndRange'])"):attr("value")
		local localRange = compartment:find("/element/subCompartment:has(/compartType[id='localRange'])"):attr("value")
		local result = ""
		
		if domainAndRange == "false" then 
			result = "+"
			if localRange == "false" then result = "++" end
		end
		
		name:attr("input", result .. name:attr("value"))	
	end
	
	--------------------------------------
	--TO DO disableEnableProperty
	--------------------------------------
end

function setPrefixFromDomainAndRangeAttribute(compartment, oldValue)
	local name = compartment:find("/element/compartment:has(/compartType[id='Name'])")
	
	local compartment = compartment:filter(function(obj)
		return obj:find("/compartType"):attr("id") == "domainAndRange"
	end)
	
	if compartment:attr("value") == "true" then 
		local parentCompartment = compartment:find("/element")
		local localRange = parentCompartment:find("/compartment:has(/compartType[id='localRange'])")
		localRange:attr("value", "false")
		core.update_compartment_input_from_value(localRange)
		
		localRange:find("/component"):attr("checked", "false")
		if localRange:find("/component"):is_not_empty() then
			local cmd = utilities.create_command("D#Command", {info = "Refresh"})
			localRange:find("/component"):link("command", cmd)
			utilities.execute_cmd_obj(cmd)
		end
		
		disableEnableProperty(parentCompartment:find("/compartment:has(/compartType[id='localRange'])/component"), false)
		
		local result = ""
		local schemaAssertion = parentCompartment:find("/compartment:has(/compartType[id='schemaAssertion'])"):attr("value")
		
		if schemaAssertion == "false" then result = "!" end
		
		name:attr("input", result .. name:attr("value"))
	else
		local parentCompartment = compartment:find("/element")
		
		local schemaAssertion = parentCompartment:find("/compartment:has(/compartType[id='schemaAssertion'])")
		schemaAssertion:attr("value", "true")
		core.update_compartment_input_from_value(schemaAssertion)
		
		schemaAssertion:find("/component"):attr("checked", "true")
		if schemaAssertion:find("/component"):is_not_empty() then
			local cmd = utilities.create_command("D#Command", {info = "Refresh"})
			schemaAssertion:find("/component"):link("command", cmd)
			utilities.execute_cmd_obj(cmd)
		end
		
		local localRange = parentCompartment:find("/compartment:has(/compartType[id='localRange'])")
		localRange:attr("value", "true")
		core.update_compartment_input_from_value(localRange)
		
		localRange:find("/component"):attr("checked", "true")
		if localRange:find("/component"):is_not_empty() then
			local cmd = utilities.create_command("D#Command", {info = "Refresh"})
			localRange:find("/component"):link("command", cmd)
			utilities.execute_cmd_obj(cmd)
		end

		disableEnableProperty(parentCompartment:find("/compartment:has(/compartType[id='localRange'])/component"), true)
		
		local result = ""

		if schemaAssertion:attr("value") == "false" then result = "!"
		else
			result = "+"
			if localRange:attr("value") == "false" then result = "++" end
		end
		
		name:attr("input", result .. name:attr("value"))
	end
	utilities.refresh_element(name, utilities.current_diagram())
end

function setPrefixFromLocalRangeAttribute(compartment, oldValue)
	local name = compartment:find("/element/compartment:has(/compartType[id='Name'])")
		
	local schemaAssertion = compartment:find("/element/compartment:has(/compartType[id='schemaAssertion'])"):attr("value")
	local domainAndRange = compartment:find("/element/compartment:has(/compartType[id='domainAndRange'])"):attr("value")
	local localRange = compartment:attr("value")

	local result = ""
	if schemaAssertion == "false" then result = "!"
	elseif domainAndRange == "false" then 
		result = "+"
		if localRange == "false" then result = "++" end
	end
	
	name:attr("input", result .. name:attr("value"))
	utilities.refresh_element(name, utilities.current_diagram())
end

function setPrefixeNameAttribute(dataCompartType, dataCompartment, parsingCompartment)
	local result = ""
	if dataCompartment~=nil then
		local schemaAssertion = dataCompartment:find("/element/compartment:has(/compartType[id='schemaAssertion'])"):attr("value")
		local domainAndRange = dataCompartment:find("/element/compartment:has(/compartType[id='domainAndRange'])"):attr("value")
		local localRange = dataCompartment:find("/element/compartment:has(/compartType[id='localRange'])"):attr("value")
		
		if schemaAssertion == "false" then result = "!"
		elseif domainAndRange == "false" then 
			result = "+"
			if localRange == "false" then result = "++" end
		end
	end
	return result
end

--ATTRIBUTE

--ATTRIBUTES
function setPrefixFromSchemaAssertionAttributes(compartment, oldValue)
	local compartment = compartment:filter(function(obj)
		return obj:find("/compartType"):attr("id") == "schemaAssertion"
	end)
	
	local parentCompartment = compartment:find("/parentCompartment")
	local domainAndRange = parentCompartment:find("/subCompartment:has(/compartType[id='domainAndRange'])")

	if compartment:attr("value") == "false" or (compartment:attr("value") ~= "true" and compartment:attr("value") ~= " ") then 
		local parentCompartment = compartment:find("/parentCompartment")
		local domainAndRange = parentCompartment:find("/subCompartment:has(/compartType[id='domainAndRange'])")
		if domainAndRange:attr("value") ~= "true" then
			domainAndRange:attr("value", "true")
			core.update_compartment_input_from_value(domainAndRange)
			
			domainAndRange:find("/component"):attr("checked", "true")
			if domainAndRange:find("/component"):is_not_empty() then
				local cmd = utilities.create_command("D#Command", {info = "Refresh"})
				domainAndRange:find("/component"):link("command", cmd)
				utilities.execute_cmd_obj(cmd)
			end
			
			disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='localRange'])/component"), false)
		
		end
		
		local localRange = parentCompartment:find("/subCompartment:has(/compartType[id='localRange'])")
		if localRange:attr("value") ~= "false" or (localRange:attr("value") ~= "true" or localRange:attr("value") ~= "+") then
			localRange:attr("value", "false")
			core.update_compartment_input_from_value(localRange)
			localRange:find("/component"):attr("checked", "false")
			if localRange:find("/component"):is_not_empty() then
				local cmd = utilities.create_command("D#Command", {info = "Refresh"})
				localRange:find("/component"):link("command", cmd)
				utilities.execute_cmd_obj(cmd)
			end
		end
		
		-- core.create_missing_compartment(parentCompartment, parentCompartment:find("/compartType"), parentCompartment:find("/compartType/subCompartType[id='hiddenCompartment']"))
		local hiddenCompartment = parentCompartment:find("/subCompartment:has(/compartType[id='hiddenCompartment'])")
		
		if hiddenCompartment:attr("value") ~= "false" then
			hiddenCompartment:attr("value", "false")
			core.update_compartment_input_from_value(hiddenCompartment)
			-- if hiddenCompartment:find("/component"):is_not_empty() then
				-- local cmd = utilities.create_command("D#Command", {info = "Refresh"})
				-- hiddenCompartment:find("/component"):link("command", cmd)
				-- utilities.execute_cmd_obj(cmd)
			-- end
		end
		-- name:attr("input", "!" .. name:attr("value"))
		
		-- parentCompartment:find("/form/component"):each(function(com)
			-- if com:attr("id") == "IsFunctional" or com:attr("id") == "EquivalentProperties" or com:attr("id") == "SuperProperties(<)" or com:attr("id") == "DisjointProperties(<>)" then
				-- com:attr("enabled", false)
				-- local cmd = utilities.create_command("D#Command", {info = "Refresh"})
				-- com:link("command", cmd)
				-- utilities.execute_cmd_obj(cmd)
				-- com:find("/component"):each(function(obj)
					-- obj:attr("enabled", false)
					-- local cmd = utilities.create_command("D#Command", {info = "Refresh"})
					-- obj:link("command", cmd)
					-- utilities.execute_cmd_obj(cmd)
					-- obj:find("/component"):each(function(obj2)
						-- obj2:attr("enabled", false)
						-- local cmd = utilities.create_command("D#Command", {info = "Refresh"})
						-- obj2:link("command", cmd)
						-- utilities.execute_cmd_obj(cmd)
					-- end)
				-- end)
			-- end
			
		-- end)
		
		-- if parentCompartment:find("/subCompartment:has(/compartType[id='IsFunctional'])"):size() > 0 or
		-- parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousEquivalentProperties'])/subCompartment"):size() > 0 or
		-- parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousDisjointProperties'])/subCompartment"):size() > 0 or
		-- parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousSuperProperties'])/subCompartment"):size() > 0 then
			-- deleteCompartmentsForm("- IsFunctional\n- EquivalentProperties\n- DisjointProperties\n- SuperProperties")
		-- end
		
		
		-- if parentCompartment:find("/subCompartment:has(/compartType[id='IsFunctional'])"):size() > 0 and  parentCompartment:find("/subCompartment:has(/compartType[id='IsFunctional'])"):attr("value") == "true" then
			-- local isFunc = parentCompartment:find("/subCompartment:has(/compartType[id='IsFunctional'])"):attr("value", "false")
			-- core.update_compartment_input_from_value(isFunc)
			-- isFunc:find("/component"):attr("checked", "false")
		-- end
		-- if parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousEquivalentProperties'])/subCompartment"):size() > 0 then   
			-- deleteCompartment(parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousEquivalentProperties'])/subCompartment"))
			-- parentCompartment:find("/subCompartment:has(/compartType[id='EquivalentProperties'])"):attr("value", "")
			-- core.update_compartment_input_from_value(parentCompartment:find("/subCompartment:has(/compartType[id='EquivalentProperties'])"))
			-- parentCompartment:find("/form/component[id='EquivalentProperties']/component[id='field']"):attr("text", "")
		-- end
		-- if parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousDisjointProperties'])/subCompartment"):size() > 0 then   
		    -- deleteCompartment(parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousDisjointProperties'])/subCompartment"))
			-- parentCompartment:find("/subCompartment:has(/compartType[id='DisjointProperties'])"):attr("value", "")
			-- core.update_compartment_input_from_value(parentCompartment:find("/subCompartment:has(/compartType[id='DisjointProperties'])"))
			-- parentCompartment:find("/form/component[id='DisjointProperties']/component[id='field']"):attr("text", "")
		-- end
		-- if parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousSuperProperties'])/subCompartment"):size() > 0 then   
		    -- deleteCompartment(parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousSuperProperties'])/subCompartment"))
			-- parentCompartment:find("/subCompartment:has(/compartType[id='SuperProperties'])"):attr("value", "")
			-- core.update_compartment_input_from_value(parentCompartment:find("/subCompartment:has(/compartType[id='SuperProperties'])"))
			-- parentCompartment:find("/form/component[id='SuperProperties']/component[id='field']"):attr("text", "")
		-- end
		
		-- name:attr("input", "+" .. name:attr("value"))
	else
		local parentCompartment = compartment:find("/parentCompartment")
		local schemaAssertion = parentCompartment:find("/subCompartment:has(/compartType[id='schemaAssertion'])"):attr("value")
		local domainAndRange = parentCompartment:find("/subCompartment:has(/compartType[id='domainAndRange'])"):attr("value")
		local localRange = parentCompartment:find("/subCompartment:has(/compartType[id='localRange'])"):attr("value")
		
		local result = "false"
		if (schemaAssertion == "true" or schemaAssertion == " ") 
		and (domainAndRange ~= "true" and domainAndRange ~= "!" and domainAndRange ~= " ") 
		and (localRange ~= "true" and localRange ~= "+") then result = "true" end

		local domainAndRange = parentCompartment:find("/subCompartment:has(/compartType[id='domainAndRange'])")
		if domainAndRange:attr("value") == "true" or domainAndRange:attr("value") == "!" or domainAndRange:attr("value") == " " then
			domainAndRange:attr("value", "true")
			core.update_compartment_input_from_value(domainAndRange)
		end
		
		
		
		-- core.create_missing_compartment(parentCompartment, parentCompartment:find("/compartType"), parentCompartment:find("/compartType/subCompartType[id='hiddenCompartment']"))
		local hiddenCompartment = parentCompartment:find("/subCompartment:has(/compartType[id='hiddenCompartment'])")
		if hiddenCompartment:attr("value") ~= result then
			hiddenCompartment:attr("value", result)
			core.update_compartment_input_from_value(hiddenCompartment)
			-- if hiddenCompartment:find("/component"):is_not_empty() then
				-- local cmd = utilities.create_command("D#Command", {info = "Refresh"})
				-- hiddenCompartment:find("/component"):link("command", cmd)
				-- utilities.execute_cmd_obj(cmd)
			-- end
		end
		-- name:attr("input", name:attr("value"))
		-- local parentCompartment = compartment:find("/parentCompartment")
		-- parentCompartment:find("/form/component"):each(function(com)
			-- if com:attr("id") == "IsFunctional" or com:attr("id") == "EquivalentProperties" or com:attr("id") == "SuperProperties(<)" or com:attr("id") == "DisjointProperties(<>)" then
				-- com:attr("enabled", true)
				-- local cmd = utilities.create_command("D#Command", {info = "Refresh"})
				-- com:link("command", cmd)
				-- utilities.execute_cmd_obj(cmd)
				
				-- com:find("/component"):each(function(obj)
					-- obj:attr("enabled", true)
					-- local cmd = utilities.create_command("D#Command", {info = "Refresh"})
					-- obj:link("command", cmd)
					-- utilities.execute_cmd_obj(cmd)
					
					-- obj:find("/component"):each(function(obj2)
						-- obj2:attr("enabled", true)
						-- local cmd = utilities.create_command("D#Command", {info = "Refresh"})
						-- obj2:link("command", cmd)
						-- utilities.execute_cmd_obj(cmd)
					-- end)
				-- end)
			-- end
		-- end)
	end
end

function setPrefixFromFromDomainAndRangeAttributes(compartment, oldValue)

	local compartment = compartment:filter(function(obj)
		return obj:find("/compartType"):attr("id") == "domainAndRange"
	end)

	if compartment:attr("value") == "true" or compartment:attr("value") == "!" or compartment:attr("value") == " " then 
		local parentCompartment = compartment:find("/parentCompartment")
		local localRange = parentCompartment:find("/subCompartment:has(/compartType[id='localRange'])")
		
		if localRange:attr("value") ~= "false" then
			localRange:attr("value", "false")
			core.update_compartment_input_from_value(localRange)
			
			localRange:find("/component"):attr("checked", "false")
			if localRange:find("/component"):is_not_empty() then
				local cmd = utilities.create_command("D#Command", {info = "Refresh"})
				localRange:find("/component"):link("command", cmd)
				utilities.execute_cmd_obj(cmd)
			end
			
			disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='localRange'])/component"), false)
		end
		

	else
		local parentCompartment = compartment:find("/parentCompartment")
		
		local schemaAssertion = parentCompartment:find("/subCompartment:has(/compartType[id='schemaAssertion'])")
		
		if schemaAssertion:attr("value") ~= "true" then
			schemaAssertion:attr("value", "true")
			core.update_compartment_input_from_value(schemaAssertion)
			
			schemaAssertion:find("/component"):attr("checked", "true")
			if schemaAssertion:find("/component"):is_not_empty() then
				local cmd = utilities.create_command("D#Command", {info = "Refresh"})
				schemaAssertion:find("/component"):link("command", cmd)
				utilities.execute_cmd_obj(cmd)
			end
		end
		
		local localRange = parentCompartment:find("/subCompartment:has(/compartType[id='localRange'])")
		if localRange:attr("value") ~= "true" then
			localRange:attr("value", "true")
			core.update_compartment_input_from_value(localRange)
			
			localRange:find("/component"):attr("checked", "true")
			if localRange:find("/component"):is_not_empty() then
				local cmd = utilities.create_command("D#Command", {info = "Refresh"})
				localRange:find("/component"):link("command", cmd)
				utilities.execute_cmd_obj(cmd)
			end
			
			disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='localRange'])/component"), true)
		end
	end
		
	local parentCompartment = compartment:find("/parentCompartment")
	local schemaAssertion = parentCompartment:find("/subCompartment:has(/compartType[id='schemaAssertion'])"):attr("value")
	local domainAndRange = parentCompartment:find("/subCompartment:has(/compartType[id='domainAndRange'])"):attr("value")
	local localRange = parentCompartment:find("/subCompartment:has(/compartType[id='localRange'])"):attr("value")
	
	local result = false
	if (schemaAssertion == "true" or schemaAssertion == " ") 
	and (domainAndRange ~= "true" and domainAndRange ~= "!" and domainAndRange ~= " ") 
	and (localRange ~= "true" and localRange ~= "+") then result = "true" end
	
	-- core.create_missing_compartment(parentCompartment, parentCompartment:find("/compartType"), parentCompartment:find("/compartType/subCompartType[id='hiddenCompartment']"))
	local hiddenCompartment = parentCompartment:find("/subCompartment:has(/compartType[id='hiddenCompartment'])")
	if hiddenCompartment:attr("value") ~= result then
		hiddenCompartment:attr("value", result)
		core.update_compartment_input_from_value(hiddenCompartment)
		-- if hiddenCompartment:find("/component"):is_not_empty() then
			-- local cmd = utilities.create_command("D#Command", {info = "Refresh"})
			-- hiddenCompartment:find("/component"):link("command", cmd)
			-- utilities.execute_cmd_obj(cmd)
		-- end
	end
end

function setPrefixFromLocalRangeAttributes(compartment, oldValue)

	local parentCompartment = compartment:find("/parentCompartment")
	local schemaAssertion = parentCompartment:find("/subCompartment:has(/compartType[id='schemaAssertion'])"):attr("value")
	local domainAndRange = parentCompartment:find("/subCompartment:has(/compartType[id='domainAndRange'])"):attr("value")
	local localRange = parentCompartment:find("/subCompartment:has(/compartType[id='localRange'])"):attr("value")
	
	local result = false
	if (schemaAssertion == "true" or schemaAssertion == " ") 
	and (domainAndRange ~= "true" and domainAndRange ~= "!" and domainAndRange ~= " ") 
	and (localRange ~= "true" and localRange ~= "+") then result = "true" end
	
	-- core.create_missing_compartment(parentCompartment, parentCompartment:find("/compartType"), parentCompartment:find("/compartType/subCompartType[id='hiddenCompartment']"))
	local hiddenCompartment = parentCompartment:find("/subCompartment:has(/compartType[id='hiddenCompartment'])")
	hiddenCompartment:attr("value", result)
	
	hiddenCompartment = hiddenCompartment:first()
	core.update_compartment_input_from_value(hiddenCompartment)
	-- if hiddenCompartment:find("/component"):is_not_empty() then
		-- local cmd = utilities.create_command("D#Command", {info = "Refresh"})
		-- hiddenCompartment:find("/component"):link("command", cmd)
		-- utilities.execute_cmd_obj(cmd)
	-- end
end

--ATTRIBUTES

function hideField()
	return false
end
---------------------------------------------------------------------------------

function setPrefixesPlusFromAllFaluesFromDataProperty(compartment, oldValue)

	local compartment = compartment:filter(function(obj)
		return obj:find("/compartType"):attr("id") == "allValuesFrom"
	end)
	
	if compartment:attr("value") == "true" then 
		local parentCompartment = compartment:find("/parentCompartment")
		local noSchema = parentCompartment:find("/subCompartment:has(/compartType[id='noSchema'])")
		noSchema:attr("value", "false")
		core.update_compartment_input_from_value(noSchema)
		
		noSchema:find("/component"):attr("checked", "false")
		if noSchema:find("/component"):is_not_empty() then
			local cmd = utilities.create_command("D#Command", {info = "Refresh"})
			noSchema:find("/component"):link("command", cmd)
			utilities.execute_cmd_obj(cmd)
		end
		
		
		
		parentCompartment:find("/form/component"):each(function(com)
			if com:attr("id") == "IsFunctional" or com:attr("id") == "EquivalentProperties" or com:attr("id") == "SuperProperties(<)" or com:attr("id") == "DisjointProperties(<>)" then
				com:attr("enabled", false)
				local cmd = utilities.create_command("D#Command", {info = "Refresh"})
				com:link("command", cmd)
				utilities.execute_cmd_obj(cmd)
				com:find("/component"):each(function(obj)
					obj:attr("enabled", false)
					local cmd = utilities.create_command("D#Command", {info = "Refresh"})
					obj:link("command", cmd)
					utilities.execute_cmd_obj(cmd)
					obj:find("/component"):each(function(obj2)
						obj2:attr("enabled", false)
						local cmd = utilities.create_command("D#Command", {info = "Refresh"})
						obj2:link("command", cmd)
						utilities.execute_cmd_obj(cmd)
					end)
				end)
			end
			
		end)
		
		if parentCompartment:find("/subCompartment:has(/compartType[id='IsFunctional'])"):size() > 0 or
		parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousEquivalentProperties'])/subCompartment"):size() > 0 or
		parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousDisjointProperties'])/subCompartment"):size() > 0 or
		parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousSuperProperties'])/subCompartment"):size() > 0 then
			deleteCompartmentsForm("- IsFunctional\n- EquivalentProperties\n- DisjointProperties\n- SuperProperties")
		end
		
		
		if parentCompartment:find("/subCompartment:has(/compartType[id='IsFunctional'])"):size() > 0 and  parentCompartment:find("/subCompartment:has(/compartType[id='IsFunctional'])"):attr("value") == "true" then
			local isFunc = parentCompartment:find("/subCompartment:has(/compartType[id='IsFunctional'])"):attr("value", "false")
			core.update_compartment_input_from_value(isFunc)
			isFunc:find("/component"):attr("checked", "false")
		end
		if parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousEquivalentProperties'])/subCompartment"):size() > 0 then   
			deleteCompartment(parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousEquivalentProperties'])/subCompartment"))
			parentCompartment:find("/subCompartment:has(/compartType[id='EquivalentProperties'])"):attr("value", "")
			core.update_compartment_input_from_value(parentCompartment:find("/subCompartment:has(/compartType[id='EquivalentProperties'])"))
			parentCompartment:find("/form/component[id='EquivalentProperties']/component[id='field']"):attr("text", "")
		end
		if parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousDisjointProperties'])/subCompartment"):size() > 0 then   
		    deleteCompartment(parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousDisjointProperties'])/subCompartment"))
			parentCompartment:find("/subCompartment:has(/compartType[id='DisjointProperties'])"):attr("value", "")
			core.update_compartment_input_from_value(parentCompartment:find("/subCompartment:has(/compartType[id='DisjointProperties'])"))
			parentCompartment:find("/form/component[id='DisjointProperties']/component[id='field']"):attr("text", "")
		end
		if parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousSuperProperties'])/subCompartment"):size() > 0 then   
		    deleteCompartment(parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousSuperProperties'])/subCompartment"))
			parentCompartment:find("/subCompartment:has(/compartType[id='SuperProperties'])"):attr("value", "")
			core.update_compartment_input_from_value(parentCompartment:find("/subCompartment:has(/compartType[id='SuperProperties'])"))
			parentCompartment:find("/form/component[id='SuperProperties']/component[id='field']"):attr("text", "")
		end
		
		-- name:attr("input", "+" .. name:attr("value"))
	else
		-- name:attr("input", name:attr("value"))
		local parentCompartment = compartment:find("/parentCompartment")
		parentCompartment:find("/form/component"):each(function(com)
			if com:attr("id") == "IsFunctional" or com:attr("id") == "EquivalentProperties" or com:attr("id") == "SuperProperties(<)" or com:attr("id") == "DisjointProperties(<>)" then
				com:attr("enabled", true)
				local cmd = utilities.create_command("D#Command", {info = "Refresh"})
				com:link("command", cmd)
				utilities.execute_cmd_obj(cmd)
				
				com:find("/component"):each(function(obj)
					obj:attr("enabled", true)
					local cmd = utilities.create_command("D#Command", {info = "Refresh"})
					obj:link("command", cmd)
					utilities.execute_cmd_obj(cmd)
					
					obj:find("/component"):each(function(obj2)
						obj2:attr("enabled", true)
						local cmd = utilities.create_command("D#Command", {info = "Refresh"})
						obj2:link("command", cmd)
						utilities.execute_cmd_obj(cmd)
					end)
				end)
			end
		end)
	end

	-- utilities.refresh_element(name, utilities.current_diagram())
end



function setContainerNameVisible(compartment,oldValue)
	local containerName= compartment:find("/element/compartment:has(/compartType[id='Name'])")
	if compartment:attr("value") == "true" then
		containerName:link("compartStyle",containerName:find("/compartType/compartStyle[id='NameInvisible']"))
	else
		containerName:link("compartStyle",containerName:find("/compartType/compartStyle[id='Name']"))
	end
end

function setUniqueContainerName(form)
	local name = form:find("/presentationElement/compartment:has(/compartType[id='Name'])")
	if name:attr("value") == nil or name:attr("value") == "" then
		local containerName = "Container_"
		local count = 1
		while lQuery("ElemType[id='Container']/element/compartment:has(/compartType[id='Name'])[value='" .. containerName .. count .. "']"):is_not_empty() do
			count = count + 1
		end
		name:attr("value", containerName .. count)
		name:attr("input", containerName .. count)
		utilities.refresh_element(form:find("/presentationElement"), utilities.current_diagram())
	end
end


function deleteCheckBoxCompartment(compartType, parentCompartment)
	local isFunc = parentCompartment:find("/subCompartment:has(/compartType[id='"..compartType.."'])")
	if isFunc:attr("value") == "true" then
		isFunc:attr("value", "false")
		core.update_compartment_input_from_value(isFunc)
		isFunc:find("/component"):attr("checked", "false")
		local cmd = utilities.create_command("D#Command", {info = "Refresh"})
		isFunc:link("command", cmd)
		utilities.execute_cmd_obj(cmd)
	end
end



function setPrefixesPlusFromAllFaluesFrom(compartment, oldValue)
	local name = compartment:find("/parentCompartment/subCompartment:has(/compartType[id='Name'])")
	local compartment = compartment:filter(function(obj)
		return obj:find("/compartType"):attr("id") == "allValuesFrom"
	end)
	
	if compartment:attr("value") == "true" then 
		local parentCompartment = compartment:find("/parentCompartment")
		local noSchema = parentCompartment:find("/subCompartment:has(/compartType[id='noSchema'])")
		noSchema:attr("value", "false")
		core.update_compartment_input_from_value(noSchema)
		
		noSchema:find("/component"):attr("checked", "false")
		if noSchema:find("/component"):is_not_empty() then
			local cmd = utilities.create_command("D#Command", {info = "Refresh"})
			noSchema:find("/component"):link("command", cmd)
			utilities.execute_cmd_obj(cmd)
		end
		
		name:attr("input", "+" .. name:attr("value"))
		-- parentCompartment:find("/subCompartment"):each(function(obj)
			-- print(obj:find("/compartType"):attr("id"), obj:attr("value"))
		-- end)
		
		
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Functional'])/component"), false)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='InverseFunctional'])/component"), false)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Symmetric'])/component"), false)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Asymmetric'])/component"), false)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Reflexive'])/component"), false)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Irreflexive'])/component"), false)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Transitive'])/component"), false)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='SuperProperties'])/subCompartment/component"), false)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='DisjointProperties'])/subCompartment/component"), false)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='PropertyChains'])/subCompartment/component"), false)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='EquivalentProperties'])/subCompartment/component"), false)
		
		
		if parentCompartment:find("/subCompartment:has(/compartType[id='Functional'])"):attr("value") == "true" or
		parentCompartment:find("/subCompartment:has(/compartType[id='InverseFunctional'])"):attr("value") == "true" or
		parentCompartment:find("/subCompartment:has(/compartType[id='Symmetric'])"):attr("value") == "true" or
		parentCompartment:find("/subCompartment:has(/compartType[id='Asymmetric'])"):attr("value") == "true" or
		parentCompartment:find("/subCompartment:has(/compartType[id='Reflexive'])"):attr("value") == "true" or
		parentCompartment:find("/subCompartment:has(/compartType[id='Irreflexive'])"):attr("value") == "true" or
		parentCompartment:find("/subCompartment:has(/compartType[id='Transitive'])"):attr("value") == "true" or
		parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousEquivalentProperties'])/subCompartment"):size() > 0 or
		parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousDisjointProperties'])/subCompartment"):size() > 0 or
		parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousPropertyChains'])/subCompartment"):size() > 0 or
		parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousSuperProperties'])/subCompartment"):size() > 0 then
			deleteCompartmentsForm("- Functional\n- InverseFunctional\n- Symmetric\n- Asymmetric\n- Irreflexive\n- Reflexive\n- Transitive\n- EquivalentProperties\n- DisjointProperties\n- SuperProperties\n- PropertyChains")
			
			deleteCheckBoxCompartment('Functional', parentCompartment)
			deleteCheckBoxCompartment('InverseFunctional', parentCompartment)
			deleteCheckBoxCompartment('Symmetric', parentCompartment)
			deleteCheckBoxCompartment('Asymmetric', parentCompartment)
			deleteCheckBoxCompartment('Irreflexive', parentCompartment)
			deleteCheckBoxCompartment('Reflexive', parentCompartment)
			deleteCheckBoxCompartment('Transitive', parentCompartment)
			
			if parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousEquivalentProperties'])/subCompartment"):size() > 0 then   
				deleteCompartment(parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousEquivalentProperties'])/subCompartment"))
				parentCompartment:find("/subCompartment:has(/compartType[id='EquivalentProperties'])"):attr("value", "")
				core.update_compartment_input_from_value(parentCompartment:find("/subCompartment:has(/compartType[id='EquivalentProperties'])"))
				parentCompartment:find("/form/component[id='EquivalentProperties']/component[id='field']"):attr("text", "")
			end
			if parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousDisjointProperties'])/subCompartment"):size() > 0 then   
				deleteCompartment(parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousDisjointProperties'])/subCompartment"))
				parentCompartment:find("/subCompartment:has(/compartType[id='DisjointProperties'])"):attr("value", "")
				core.update_compartment_input_from_value(parentCompartment:find("/subCompartment:has(/compartType[id='DisjointProperties'])"))
				parentCompartment:find("/form/component[id='DisjointProperties']/component[id='field']"):attr("text", "")
			end
			if parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousSuperProperties'])/subCompartment"):size() > 0 then   
				deleteCompartment(parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousSuperProperties'])/subCompartment"))
				parentCompartment:find("/subCompartment:has(/compartType[id='SuperProperties'])"):attr("value", "")
				core.update_compartment_input_from_value(parentCompartment:find("/subCompartment:has(/compartType[id='SuperProperties'])"))
				parentCompartment:find("/form/component[id='SuperProperties']/component[id='field']"):attr("text", "")
			end
			if parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousPropertyChains'])/subCompartment"):size() > 0 then   
				deleteCompartment(parentCompartment:find("/subCompartment/subCompartment:has(/compartType[id='ASFictitiousPropertyChains'])/subCompartment"))
				parentCompartment:find("/subCompartment:has(/compartType[id='PropertyChains'])"):attr("value", "")
				core.update_compartment_input_from_value(parentCompartment:find("/subCompartment:has(/compartType[id='PropertyChains'])"))
				parentCompartment:find("/form/component[id='PropertyChains']/component[id='field']"):attr("text", "")
			end
		end
		
	else
		name:attr("input", name:attr("value"))
		
		local parentCompartment = compartment:find("/parentCompartment")
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Functional'])/component"), true)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='InverseFunctional'])/component"), true)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Symmetric'])/component"), true)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Asymmetric'])/component"), true)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Reflexive'])/component"), true)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Irreflexive'])/component"), true)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='Transitive'])/component"), true)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='SuperProperties'])/subCompartment/component"), true)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='DisjointProperties'])/subCompartment/component"), true)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='PropertyChains'])/subCompartment/component"), true)
		disableEnableProperty(parentCompartment:find("/subCompartment:has(/compartType[id='EquivalentProperties'])/subCompartment/component"), true)
	end
	utilities.refresh_element(name, utilities.current_diagram())
end

function setPrefixesPlusFromAllFaluesFromAttribute(compartment, oldValue)
	local name = compartment:find("/element/compartment:has(/compartType[id='Name'])")
	local compartment = compartment:filter(function(obj)
		return obj:find("/compartType"):attr("id") == "allValuesFrom"
	end)
	
	if compartment:attr("value") == "true" then 
		local parentCompartment = compartment:find("/element")
		local noSchema = parentCompartment:find("/compartment:has(/compartType[id='noSchema'])")
		noSchema:attr("value", "false")
		core.update_compartment_input_from_value(noSchema)
		
		noSchema:find("/component"):attr("checked", "false")
		if noSchema:find("/component"):is_not_empty() then
			local cmd = utilities.create_command("D#Command", {info = "Refresh"})
			noSchema:find("/component"):link("command", cmd)
			utilities.execute_cmd_obj(cmd)
		end
		
		name:attr("input", "+" .. name:attr("value"))

		disableEnableProperty(parentCompartment:find("/compartment:has(/compartType[id='IsFunctional'])/component"), false)
		disableEnableProperty(parentCompartment:find("/compartment:has(/compartType[id='SuperProperties'])/subCompartment/component"), false)
		disableEnableProperty(parentCompartment:find("/compartment:has(/compartType[id='DisjointProperties'])/subCompartment/component"), false)
		disableEnableProperty(parentCompartment:find("/compartment:has(/compartType[id='EquivalentProperties'])/subCompartment/component"), false)
		
		
		if parentCompartment:find("/compartment:has(/compartType[id='IsFunctional'])"):attr("value") == "true" or
		parentCompartment:find("/compartment/subCompartment:has(/compartType[id='ASFictitiousEquivalentProperties'])/subCompartment"):size() > 0 or
		parentCompartment:find("/compartment/subCompartment:has(/compartType[id='ASFictitiousDisjointProperties'])/subCompartment"):size() > 0 or
		parentCompartment:find("/compartment/subCompartment:has(/compartType[id='ASFictitiousSuperProperties'])/subCompartment"):size() > 0 then
			deleteCompartmentsForm("- IsFunctional\n- EquivalentProperties\n- DisjointProperties\n- SuperProperties\n- PropertyChains")
			
			deleteCheckBoxCompartment('IsFunctional', parentCompartment)
			
			if parentCompartment:find("/compartment/subCompartment:has(/compartType[id='ASFictitiousEquivalentProperties'])/subCompartment"):size() > 0 then   
				deleteCompartment(parentCompartment:find("/compartment/subCompartment:has(/compartType[id='ASFictitiousEquivalentProperties'])/subCompartment"))
				parentCompartment:find("/compartment:has(/compartType[id='EquivalentProperties'])"):attr("value", "")
				core.update_compartment_input_from_value(parentCompartment:find("/compartment:has(/compartType[id='EquivalentProperties'])"))
				parentCompartment:find("/form/component[id='EquivalentProperties']/component[id='field']"):attr("text", "")
			end
			if parentCompartment:find("/compartment/subCompartment:has(/compartType[id='ASFictitiousDisjointProperties'])/subCompartment"):size() > 0 then   
				deleteCompartment(parentCompartment:find("/compartment/subCompartment:has(/compartType[id='ASFictitiousDisjointProperties'])/subCompartment"))
				parentCompartment:find("/compartment:has(/compartType[id='DisjointProperties'])"):attr("value", "")
				core.update_compartment_input_from_value(parentCompartment:find("/compartment:has(/compartType[id='DisjointProperties'])"))
				parentCompartment:find("/form/component[id='DisjointProperties']/component[id='field']"):attr("text", "")
			end
			if parentCompartment:find("/compartment/subCompartment:has(/compartType[id='ASFictitiousSuperProperties'])/subCompartment"):size() > 0 then   
				deleteCompartment(parentCompartment:find("/compartment/subCompartment:has(/compartType[id='ASFictitiousSuperProperties'])/subCompartment"))
				parentCompartment:find("/compartment:has(/compartType[id='SuperProperties'])"):attr("value", "")
				core.update_compartment_input_from_value(parentCompartment:find("/compartment:has(/compartType[id='SuperProperties'])"))
				parentCompartment:find("/form/component[id='SuperProperties']/component[id='field']"):attr("text", "")
			end
		end
		
	else
		name:attr("input", name:attr("value"))
		
		local parentCompartment = compartment:find("/element")
		disableEnableProperty(parentCompartment:find("/compartment:has(/compartType[id='IsFunctional'])/component"), true)
		disableEnableProperty(parentCompartment:find("/compartment:has(/compartType[id='SuperProperties'])/subCompartment/component"), true)
		disableEnableProperty(parentCompartment:find("/compartment:has(/compartType[id='DisjointProperties'])/subCompartment/component"), true)
		disableEnableProperty(parentCompartment:find("/compartment:has(/compartType[id='EquivalentProperties'])/subCompartment/component"), true)
	end
	utilities.refresh_element(name, utilities.current_diagram())
end


function disableEnableProperty(obj, value)
	obj:attr("enabled", value)
	local cmd = utilities.create_command("D#Command", {info = "Refresh"})
	obj:link("command", cmd)
	utilities.execute_cmd_obj(cmd)
	obj:find("/container/component"):each(function(com)
		com:attr("enabled", value)
		local cmd = utilities.create_command("D#Command", {info = "Refresh"})
		com:link("command", cmd)
		utilities.execute_cmd_obj(cmd)
	end)
end



function onAttributeOpen(form)
	local attribute = form:find("/presentationElement")
	if attribute:find("/subCompartment"):size() == 0 then
		core.create_missing_compartment(attribute, attribute:find("/compartType"), attribute:find("/compartType/subCompartType[id='schemaAssertion']"))
		core.create_missing_compartment(attribute, attribute:find("/compartType"), attribute:find("/compartType/subCompartType[id='domainAndRange']"))
		core.create_missing_compartment(attribute, attribute:find("/compartType"), attribute:find("/compartType/subCompartType[id='localRange']"))
		core.create_missing_compartment(attribute, attribute:find("/compartType"), attribute:find("/compartType/subCompartType[id='hiddenCompartment']"))
		local schemaAssertion = attribute:find("/subCompartment:has(/compartType[id='schemaAssertion'])")
		local domainAndRange = attribute:find("/subCompartment:has(/compartType[id='domainAndRange'])")
		local localRange = attribute:find("/subCompartment:has(/compartType[id='localRange'])")
		
		schemaAssertion:attr("value", "true")
		domainAndRange:attr("value", "true")
		
		core.update_compartment_input_from_value(schemaAssertion)
		core.update_compartment_input_from_value(domainAndRange)
		core.update_compartment_input_from_value(localRange)

		schemaAssertion:link("component", form:find("/component[id='schemaAssertion']/component/component[id='field']"))
		schemaAssertion:find("/component"):attr("checked", "true")
		domainAndRange:link("component", form:find("/component[id='domainAndRange']/component/component[id='field']"))
		domainAndRange:find("/component"):attr("checked", "true")
		localRange:link("component", form:find("/component[id='localRange']/component/component[id='field']"))
		-- localRange:find("/component"):attr("checked", "false")	
	end
	local domainAndRange = attribute:find("/subCompartment:has(/compartType[id='domainAndRange'])")
	if domainAndRange:attr("value") == "true" or domainAndRange:attr("value") == "!" or domainAndRange:attr("value") == " " then
		form:find("/component[id='localRange']"):each(function(com)
			com:attr("enabled", false)
			com:find("/component"):each(function(obj)
				obj:attr("enabled", false)
				obj:find("/component"):each(function(obj2)
					obj2:attr("enabled", false)
				end)
			end)
		end)
	end
	-- local attribute = form:find("/presentationElement")
	-- local allValuesFrom = attribute:find("/subCompartment:has(/compartType[id='allValuesFrom'])")

	-- if allValuesFrom:size() > 0 and allValuesFrom:attr("value") == "true" then
		-- form:find("/component"):each(function(com)
			-- if com:attr("id") == "IsFunctional" or com:attr("id") == "EquivalentProperties" or com:attr("id") == "SuperProperties(<)" or com:attr("id") == "DisjointProperties(<>)" then
				-- com:attr("enabled", false)

				-- com:find("/component"):each(function(obj)
					-- obj:attr("enabled", false)

					-- obj:find("/component"):each(function(obj2)
						-- obj2:attr("enabled", false)
					-- end)
				-- end)
			-- end
		-- end)
	-- end

end

function disablePropertiesOnOpen(form)
	if form:find("/component[id='TabContainer']/component[caption='Direct']/component/component/component/compartment:has(/compartType[id='domainAndRange'])"):attr("value") == "true" then
		form:find("/component[id='TabContainer']/component[caption='Direct']/component/component/component"):each(function(com)
				local compartType = com:find("/compartment/compartType"):attr("id")
				if compartType == "localRange" then
					com:attr("enabled", false)
				end
		end)
	end
	if form:find("/component[id='TabContainer']/component[caption='Inverse']/component/component/component/compartment:has(/compartType[id='domainAndRange'])"):attr("value") == "true" then
		form:find("/component[id='TabContainer']/component[caption='Inverse']/component/component/component"):each(function(com)
				local compartType = com:find("/compartment/compartType"):attr("id")
				if compartType == "localRange" then
					com:attr("enabled", false)
				end
		end)
	end
	-- if form:find("/component[id='TabContainer']/component[caption='Direct']/component/component/component/compartment:has(/compartType[id='allValuesFrom'])"):attr("value") == "true" then
		-- form:find("/component[id='TabContainer']/component[caption='Direct']/component"):each(function(com)
			-- local compartType = com:attr("id")
			-- if compartType == "EquivalentProperties(=)" or compartType == "SuperProperties(<)" or compartType == "DisjointProperties(<>)" or compartType == "PropertyChains" then 
				-- com:attr("enabled", false)
				-- com:find("/component/component"):each(function(obj)
					-- obj:attr("enabled", false)
				-- end)
			-- end
			-- com:find("/component/component"):each(function(obj)
				-- local compartType = obj:find("/compartment/compartType"):attr("id")
				-- if compartType == "Transitive" or compartType == "Irreflexive" or compartType == "Reflexive" or compartType == "Asymmetric" or compartType == "Symmetric" or compartType == "InverseFunctional" or compartType == "Functional" then
					-- obj:attr("enabled", false)
				-- end
			-- end)
		-- end)
	-- end
	-- if form:find("/component[id='TabContainer']/component[caption='Inverse']/component/component/component/compartment:has(/compartType[id='allValuesFrom'])"):attr("value") == "true" then
		-- form:find("/component[id='TabContainer']/component[caption='Inverse']/component"):each(function(com)
			-- local compartType = com:attr("id")
			-- if compartType == "EquivalentProperties(=)" or compartType == "SuperProperties(<)" or compartType == "DisjointProperties(<>)" or compartType == "PropertyChains" then 
				-- com:attr("enabled", false)
				-- com:find("/component/component"):each(function(obj)
					-- obj:attr("enabled", false)
				-- end)
			-- end
			-- com:find("/component/component"):each(function(obj)
				-- local compartType = obj:find("/compartment/compartType"):attr("id")
				-- if compartType == "Transitive" or compartType == "Irreflexive" or compartType == "Reflexive" or compartType == "Asymmetric" or compartType == "Symmetric" or compartType == "InverseFunctional" or compartType == "Functional" then
					-- obj:attr("enabled", false)
				-- end
			-- end)
		-- end)
	-- end
end

function onAttributeLinkOpen(form)
	local attribute = form:find("/presentationElement")
	
	local domainAndRange = attribute:find("/compartment:has(/compartType[id='domainAndRange'])")
	if domainAndRange:attr("value") == "true" then
		form:find("/component[id='localRange']"):each(function(com)
			com:attr("enabled", false)
			com:find("/component"):each(function(obj)
				obj:attr("enabled", false)
				obj:find("/component"):each(function(obj2)
					obj2:attr("enabled", false)
				end)
			end)
		end)
	end
	
	-- local allValuesFrom = attribute:find("/compartment:has(/compartType[id='allValuesFrom'])")

	-- if allValuesFrom:size() > 0 and allValuesFrom:attr("value") == "true" then
		-- form:find("/component"):each(function(com)
			-- if com:attr("id") == "IsFunctional" or com:attr("id") == "EquivalentProperties" or com:attr("id") == "SuperProperties" or com:attr("id") == "DisjointProperties" then
				-- com:attr("enabled", false)

				-- com:find("/component"):each(function(obj)
					-- obj:attr("enabled", false)

					-- obj:find("/component"):each(function(obj2)
						-- obj2:attr("enabled", false)
					-- end)
				-- end)
			-- end
		-- end)
	-- end
end


function deleteCompartment(compartment)
  local parent_compartment = compartment:find("/parentCompartment")
  
  deleteSubCompartments(compartment)
  
  if not parent_compartment:is_empty() then
    core.update_compartment_value_from_subcompartments(parent_compartment)
  end
end

function deleteSubCompartments(compartment)
	compartment:find("/subCompartment"):each(function(com)
		deleteSubCompartments(com)
	end)
	compartment:delete()
end

function deleteCompartmentsForm(text)
	local close_button = lQuery.create("D#Button", {
    caption = "Close"
    ,eventHandler = utilities.d_handler("Click", "lua_engine", "lua.OWLGrEd_Schema.schema.closeDeleteCompartment()")
  })
  
  local form = lQuery.create("D#Form", {
    id = "deteleCompartments"
    ,caption = "Warning"
    ,buttonClickOnClose = false
    ,cancelButton = close_button
    ,defaultButton = close_button
    ,eventHandler = utilities.d_handler("Close", "lua_engine", "lua.OWLGrEd_Schema.schema.closeDeleteCompartment()")
    ,minimumWidth = 300
    ,maximumWidth = 300
    ,prefferedWidth = 300
	,component = {
		lQuery.create("D#VerticalBox",{
			id = "HorizontalAllForms"
			
			,component = {
				lQuery.create("D#VerticalBox", {
					horizontalAlignment = -1
					,component = {
						lQuery.create("D#Label", {caption = "The following properties will be deleted:"})
						,lQuery.create("D#Label", {caption = text})
					}
				})
			}})
		,lQuery.create("D#HorizontalBox", {
			horizontalAlignment = 1
			,component = {close_button}
		})
    }
  })
  dialog_utilities.show_form(form)
end

function closeDeleteCompartment()
	lQuery("D#Event"):delete()
	utilities.close_form("deteleCompartments")

end

function selectRadioButtonValue(id, caption)	
	local pValue = lQuery("OWL_PP#ExportParameter[pName = '" .. id .. "']"):attr("pValue")
	if caption == pValue then return true else return false end
end

function saveRadioButtonParameter()
	local radioButton = lQuery("D#Event/source"):last()
	local radioButtonCaption = radioButton:attr("caption")
	local radioButtonId = radioButton:attr("id")
	local pValue = lQuery("OWL_PP#ExportParameter[pName = '" .. radioButtonId .. "']")
	pValue:attr("pValue", radioButtonCaption)
	setExportAxioms()
end

function saveCheckBoxParameter()
	local checkBox = lQuery("D#Event/source"):last()
	local checkedId = checkBox:attr("id")
	local checked = checkBox:attr("checked")
	local pValue = lQuery("OWL_PP#ExportParameter[pName = '" .. checkedId .. "']")
	pValue:attr("pValue", checked)
	setExportAxioms()
end

function setExportAxioms()
	-- context = false, Standard (non-shema) ontology only
	if lQuery("OWL_PP#ExportParameter[pName = 'includeSchemaAssertionsInAnnotationForm']"):attr("pValue") == "false" and lQuery("OWL_PP#ExportParameter[pName = 'schemaExtension']"):attr("pValue") == "Standard (non-shema) ontology only" then

		local SubClassOf = [[SubClassOf([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/localRange == 'true' || /localRange == '+'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/localRange == 'true' || /localRange == '+'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))]]
		if lQuery("OWL_PP#ExportParameter[pName = 'computePropertyRangeClosure']"):attr("pValue") == "true" then
			SubClassOf = [[SubClassOf([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))]]
		end
		lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
ObjectPropertyDomain([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/domainAndRange == 'true' || /domainAndRange == '!' || /domainAndRange == ' '] /Name:$getUri(/Name /Namespace) $getDomainOrRange)
DataPropertyDomain([$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/domainAndRange == 'true' || /domainAndRange == '!' || /domainAndRange == ' '] /Name:$getUri(/Name /Namespace) $getDomainOrRange)
ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/domainAndRange == 'true' || /domainAndRange == '!' || /domainAndRange == ' '] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
DataPropertyRange([/Type:$isEmpty != true][$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/domainAndRange == 'true' || /domainAndRange == '!' || /domainAndRange == ' '] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
]] .. SubClassOf)


		lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value",[[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		SubClassOf = [[SubClassOf([/localRange == 'true'] $getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf([/localRange == 'true'] $getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))]]
		if lQuery("OWL_PP#ExportParameter[pName = 'computePropertyRangeClosure']"):attr("pValue") == "true" then
			SubClassOf = [[SubClassOf($getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf($getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))]]
		end
		
		lQuery("ElemType[id='Attribute']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(DataProperty(/Name:$getUri(/Name /Namespace)))
DataPropertyDomain([/domainAndRange == 'true']/Name:$getUri(/Name /Namespace) $getClassExpr(/end))
DataPropertyDomain([/domainAndRange == 'true']/Name:$getUri(/Name /Namespace) $getClassExpr(/start))
DataPropertyRange([/domainAndRange == 'true'] /Name:$getUri(/Name /Namespace) $getDataTypeExpression)
AnnotationAssertion([/schemaAssertion == 'true'] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getDataTypeExpression)) <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr(/end))
AnnotationAssertion([/schemaAssertion == 'true'] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getDataTypeExpression)) <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr(/start))
]] .. SubClassOf)

		lQuery("ElemType[id='Attribute']/compartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		SubClassOf = [[SubClassOf([/../localRange == 'true'] $getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))]]
		if lQuery("OWL_PP#ExportParameter[pName = 'computePropertyRangeClosure']"):attr("pValue") == "true" then
			SubClassOf = [[SubClassOf($getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))]]
		end
		
		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyDomain([/../domainAndRange == 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
ObjectPropertyRange([/../domainAndRange == 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
]] .. SubClassOf)

		local SubClassOf = [[SubClassOf([/../localRange == 'true'] $getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))]]
		if lQuery("OWL_PP#ExportParameter[pName = 'computePropertyRangeClosure']"):attr("pValue") == "true" then
			SubClassOf = [[SubClassOf($getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))]]
		end

		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyDomain([/../domainAndRange == 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
ObjectPropertyRange([/../domainAndRange == 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
InverseObjectProperties([/../../Role/domainAndRange == 'true'][/../domainAndRange == 'true']$getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
AnnotationAssertion([/../../Role/domainAndRange != 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#source> $getClassExpr(/start)) Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start)) <http://lumii.lv/2018/1.0/owlc#isInverse> $getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
AnnotationAssertion([/../domainAndRange != 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#source> $getClassExpr(/start)) Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start)) <http://lumii.lv/2018/1.0/owlc#isInverse> $getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
]] .. SubClassOf)


		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		if lQuery("Plugin[id='DefaultOrder']"):is_not_empty() and lQuery("Plugin[id='DefaultOrder']"):attr("status") == "loaded" then
			lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(<http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])
			lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(<http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])
		end
	-- context = true, Standard (non-shema) ontology only
	elseif lQuery("OWL_PP#ExportParameter[pName = 'includeSchemaAssertionsInAnnotationForm']"):attr("pValue") == "true" and lQuery("OWL_PP#ExportParameter[pName = 'schemaExtension']"):attr("pValue") == "Standard (non-shema) ontology only" then

		local SubClassOf = [[SubClassOf([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/localRange == 'true' || /localRange == '+'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))]]
		if lQuery("OWL_PP#ExportParameter[pName = 'computePropertyRangeClosure']"):attr("pValue") == "true" then
			SubClassOf = [[SubClassOf([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))]]
		end
	
		lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
AnnotationAssertion([/schemaAssertion == 'true' || /schemaAssertion == ' '][/Type/Type:$isEmpty != true][/Type/Type != 'Thing'][/../../Name/Name != ''] Annotation(<http://lumii.lv/2018/1.0/owlc#target> /Type:$getTypeExpression(/Type /Namespace)) <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr)
AnnotationAssertion([/schemaAssertion == 'true' || /schemaAssertion == ' '][/Type/Type:$isEmpty == true || /Type/Type == 'Thing'][/../../Name/Name != ''] <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr)
ObjectPropertyDomain([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/domainAndRange == 'true' || /domainAndRange == '!' || /domainAndRange == ' '] /Name:$getUri(/Name /Namespace) $getDomainOrRange)
DataPropertyDomain([$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/domainAndRange == 'true' || /domainAndRange == '!' || /domainAndRange == ' '] /Name:$getUri(/Name /Namespace) $getDomainOrRange)
ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/domainAndRange == 'true' || /domainAndRange == '!' || /domainAndRange == ' '] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
]].. SubClassOf)


		lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value",[[AnnotationAssertion([/../../schemaAssertion == 'true' || /../../schemaAssertion == ' ']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../schemaAssertion != 'true'][/../../schemaAssertion != ' '] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		SubClassOf = [[SubClassOf([/localRange == 'true'] $getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf([/localRange == 'true'] $getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))]]
		if lQuery("OWL_PP#ExportParameter[pName = 'computePropertyRangeClosure']"):attr("pValue") == "true" then
			SubClassOf = [[SubClassOf($getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf($getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))]]
		end

		lQuery("ElemType[id='Attribute']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(DataProperty(/Name:$getUri(/Name /Namespace)))
DataPropertyDomain([/domainAndRange == 'true']/Name:$getUri(/Name /Namespace) $getClassExpr(/end))
DataPropertyDomain([/domainAndRange == 'true']/Name:$getUri(/Name /Namespace) $getClassExpr(/start))
DataPropertyRange([/domainAndRange == 'true'] /Name:$getUri(/Name /Namespace) $getDataTypeExpression)
AnnotationAssertion([/schemaAssertion == 'true'] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getDataTypeExpression)) <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr(/end))
AnnotationAssertion([/schemaAssertion == 'true'] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getDataTypeExpression)) <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr(/start))
]].. SubClassOf)

		lQuery("ElemType[id='Attribute']/compartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr(/end))) ?([/../../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../schemaAssertion != 'true'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		SubClassOf = [[SubClassOf([/../localRange == 'true'] $getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))]]
		if lQuery("OWL_PP#ExportParameter[pName = 'computePropertyRangeClosure']"):attr("pValue") == "true" then
			SubClassOf = [[SubClassOf($getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))]]
		end

		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyDomain([/../domainAndRange == 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
ObjectPropertyRange([/../domainAndRange == 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
AnnotationAssertion([/../schemaAssertion == 'true'][$getClassName(/end) != 'Thing'][$getClassName(/start) != ''] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/end))) <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/start))
AnnotationAssertion([/../schemaAssertion == 'true'][$getClassName(/end) == 'Thing' || $getClassName(/end) == ''][$getClassName(/start) != ''] <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/start))
]].. SubClassOf)

		SubClassOf = [[SubClassOf([/../localRange == 'true'] $getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))]]
		if lQuery("OWL_PP#ExportParameter[pName = 'computePropertyRangeClosure']"):attr("pValue") == "true" then
			SubClassOf = [[SubClassOf($getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))]]
		end

		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyDomain([/../domainAndRange == 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
ObjectPropertyRange([/../domainAndRange == 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
InverseObjectProperties([/../../Role/domainAndRange == 'true'][/../domainAndRange == 'true']$getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
AnnotationAssertion([/../../Role/domainAndRange != 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#source> $getClassExpr(/start)) Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start)) <http://lumii.lv/2018/1.0/owlc#isInverse> $getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
AnnotationAssertion([/../domainAndRange != 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#source> $getClassExpr(/start)) Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start)) <http://lumii.lv/2018/1.0/owlc#isInverse> $getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
AnnotationAssertion([/../schemaAssertion == 'true'][$getClassName(/start) != 'Thing'][$getClassName(/end) != ''] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start))) <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/end))
AnnotationAssertion([/../schemaAssertion == 'true'][$getClassName(/start) == 'Thing' || $getClassName(/start) == ''][$getClassName(/end) != ''] <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/end))
]].. SubClassOf)


		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr(/end))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		if lQuery("Plugin[id='DefaultOrder']"):is_not_empty() and lQuery("Plugin[id='DefaultOrder']"):attr("status") == "loaded" then
			lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr(/start))) <http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])
			lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr(/end))) <http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])
		end
	-- context = true, !Standard (non-shema) ontology only	
	elseif lQuery("OWL_PP#ExportParameter[pName = 'includeSchemaAssertionsInAnnotationForm']"):attr("pValue") == "true" and lQuery("OWL_PP#ExportParameter[pName = 'schemaExtension']"):attr("pValue") ~= "Standard (non-shema) ontology only" then
		local SubClassOf = [[SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'][/localRange == 'true' || /localRange == '+'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'][/localRange == 'true' || /localRange == '+'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))]]
		if lQuery("OWL_PP#ExportParameter[pName = 'computePropertyRangeClosure']"):attr("pValue") == "true" then
			SubClassOf = [[SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))]]
		end
		
		lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
AnnotationAssertion([/schemaAssertion == 'true' || /schemaAssertion == ' '][/Type/Type:$isEmpty != true][/Type/Type != 'Thing'][/../../Name/Name != ''] Annotation(<http://lumii.lv/2018/1.0/owlc#target> /Type:$getTypeExpression(/Type /Namespace)) <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr)
AnnotationAssertion([/schemaAssertion == 'true' || /schemaAssertion == ' '][/Type/Type:$isEmpty == true || /Type/Type == 'Thing'][/../../Name/Name != ''] <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr)
ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/domainAndRange == 'true' || /domainAndRange == '!' || /domainAndRange == ' '] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
DataPropertyRange([/Type:$isEmpty != true][$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/domainAndRange == 'true' || /domainAndRange == '!' || /domainAndRange == ' '] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
]].. SubClassOf)

		lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value",[[AnnotationAssertion([/../../schemaAssertion == 'true' || /../../schemaAssertion == ' ']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../schemaAssertion != 'true'][/../../schemaAssertion != ' '] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		SubClassOf = [[SubClassOf([/localRange == 'true'] $getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf([/localRange == 'true'] $getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))]]
		if lQuery("OWL_PP#ExportParameter[pName = 'computePropertyRangeClosure']"):attr("pValue") == "true" then
			SubClassOf = [[SubClassOf($getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf($getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))]]
		end

		lQuery("ElemType[id='Attribute']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(DataProperty(/Name:$getUri(/Name /Namespace)))
DataPropertyRange([/domainAndRange == 'true'] /Name:$getUri(/Name /Namespace) $getDataTypeExpression)
AnnotationAssertion([/schemaAssertion == 'true'] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getDataTypeExpression)) <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr(/end))
AnnotationAssertion([/schemaAssertion == 'true'] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getDataTypeExpression)) <http://lumii.lv/2018/1.0/owlc#source> /Name:$getUri(/Name /Namespace) $getClassExpr(/start))
]].. SubClassOf)

		lQuery("ElemType[id='Attribute']/compartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr(/end))) ?([/../../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))
AnnotationAssertion([/../../schemaAssertion != 'true'] $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		SubClassOf = [[SubClassOf([/../localRange == 'true'] $getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))]]
		if lQuery("OWL_PP#ExportParameter[pName = 'computePropertyRangeClosure']"):attr("pValue") == "true" then
			SubClassOf = [[SubClassOf($getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))]]
		end

		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../domainAndRange == 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
AnnotationAssertion([/../schemaAssertion == 'true'][$getClassName(/end) != 'Thing'][$getClassName(/start) != ''] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/end))) <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/start))
AnnotationAssertion([/../schemaAssertion == 'true'][$getClassName(/end) == 'Thing' || $getClassName(/end) == ''][$getClassName(/start) != ''] <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/start))
]].. SubClassOf)

		SubClassOf = [[SubClassOf([/../localRange == 'true'] $getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))]]
		if lQuery("OWL_PP#ExportParameter[pName = 'computePropertyRangeClosure']"):attr("pValue") == "true" then
			SubClassOf = [[SubClassOf($getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))]]
		end

		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../domainAndRange == 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
InverseObjectProperties([/../../Role/domainAndRange == 'true'][/../domainAndRange == 'true']$getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
AnnotationAssertion([/../../Role/domainAndRange != 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#source> $getClassExpr(/start)) Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start)) <http://lumii.lv/2018/1.0/owlc#isInverse> $getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
AnnotationAssertion([/../domainAndRange != 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#source> $getClassExpr(/start)) Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start)) <http://lumii.lv/2018/1.0/owlc#isInverse> $getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
AnnotationAssertion([/../schemaAssertion == 'true'][$getClassName(/start) != 'Thing'][$getClassName(/end) != ''] ?(Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start))) <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/end))
AnnotationAssertion([/../schemaAssertion == 'true'][$getClassName(/start) == 'Thing' || $getClassName(/start) == ''][$getClassName(/end) != ''] <http://lumii.lv/2018/1.0/owlc#source> $getUri(/Name /Namespace) $getClassExpr(/end))
]].. SubClassOf)

		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr(/start))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr(/end))) $getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		if lQuery("Plugin[id='DefaultOrder']"):is_not_empty() and lQuery("Plugin[id='DefaultOrder']"):attr("status") == "loaded" then
			lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr(/start))) <http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])
			lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(?([/../schemaAssertion == 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#context> $getClassExpr(/end))) <http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])
		end
	-- context = false, !Standard (non-shema) ontology only	
	elseif lQuery("OWL_PP#ExportParameter[pName = 'includeSchemaAssertionsInAnnotationForm']"):attr("pValue") == "false" and lQuery("OWL_PP#ExportParameter[pName = 'schemaExtension']"):attr("pValue") ~= "Standard (non-shema) ontology only" then
		local SubClassOf = [[SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'][/localRange == 'true' || /localRange == '+'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'][/localRange == 'true' || /localRange == '+'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))]]
		if lQuery("OWL_PP#ExportParameter[pName = 'computePropertyRangeClosure']"):attr("pValue") == "true" then
			SubClassOf = [[SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'ObjectProperty'][/Type/Type:$isEmpty != true] $getClassExpr ObjectAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))
SubClassOf([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'][/Type/Type:$isEmpty != true] $getClassExpr DataAllValuesFrom(/Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace)))]]
		end
		
		lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(ObjectProperty([$getAttributeType(/Type/Type /isObjectAttribute) ==  'ObjectProperty'] /Name:$getUri(/Name /Namespace)))
Declaration(DataProperty([$getAttributeType(/Type/Type /isObjectAttribute) == 'DataProperty'] /Name:$getUri(/Name /Namespace)))
]] .. SubClassOf ..
[[ObjectPropertyRange([$getAttributeType(/Type /isObjectAttribute) == 'ObjectProperty'][/domainAndRange == 'true' || /domainAndRange == '!' || /domainAndRange == ' '] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))
DataPropertyRange([/Type:$isEmpty != true][$getAttributeType(/Type /isObjectAttribute) == 'DataProperty'][/domainAndRange == 'true' || /domainAndRange == '!' || /domainAndRange == ' '] /Name:$getUri(/Name /Namespace) /Type:$getTypeExpression(/Type /Namespace))]])

		lQuery("ElemType[id='Class']/compartType/subCompartType[id='Attributes']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value",[[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		SubClassOf = [[SubClassOf([/localRange == 'true'] $getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf([/localRange == 'true'] $getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))]]
		if lQuery("OWL_PP#ExportParameter[pName = 'computePropertyRangeClosure']"):attr("pValue") == "true" then
			SubClassOf = [[SubClassOf($getClassExpr(/end) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))
SubClassOf($getClassExpr(/start) DataAllValuesFrom(/Name:$getUri(/Name /Namespace) $getDataTypeExpression))]]
		end
		
		lQuery("ElemType[id='Attribute']/tag[key = 'ExportAxiom']"):attr("value", [[Declaration(DataProperty(/Name:$getUri(/Name /Namespace)))
DataPropertyRange([/domainAndRange == 'true'] /Name:$getUri(/Name /Namespace) $getDataTypeExpression)
]].. SubClassOf)

		lQuery("ElemType[id='Attribute']/compartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
		
		SubClassOf = [[SubClassOf([/../localRange == 'true'] $getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))]]
		if lQuery("OWL_PP#ExportParameter[pName = 'computePropertyRangeClosure']"):attr("pValue") == "true" then
			SubClassOf = [[SubClassOf($getClassExpr(/start) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/end)))]]
		end
		
		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../domainAndRange == 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/end))
]].. SubClassOf)

		SubClassOf = [[SubClassOf([/../localRange == 'true'] $getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))]]
		if lQuery("OWL_PP#ExportParameter[pName = 'computePropertyRangeClosure']"):attr("pValue") == "true" then
			SubClassOf = [[SubClassOf($getClassExpr(/end) ObjectAllValuesFrom($getUri(/Name /Namespace) $getClassExpr(/start)))]]
		end

		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='Name']/tag[key = 'ExportAxiom']"):attr("value",[[Declaration(ObjectProperty($getUri(/Name /Namespace)))
ObjectPropertyRange([/../domainAndRange == 'true'] $getUri(/Name /Namespace) $getDomainOrRange(/start))
InverseObjectProperties([/../../Role/domainAndRange == 'true'][/../domainAndRange == 'true']$getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
AnnotationAssertion([/../../Role/domainAndRange != 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#source> $getClassExpr(/start)) Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start)) <http://lumii.lv/2018/1.0/owlc#isInverse> $getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
AnnotationAssertion([/../domainAndRange != 'true']Annotation(<http://lumii.lv/2018/1.0/owlc#source> $getClassExpr(/start)) Annotation(<http://lumii.lv/2018/1.0/owlc#target> $getClassExpr(/start)) <http://lumii.lv/2018/1.0/owlc#isInverse> $getUri(/Name /Namespace) /../../Role/Name:$getUri(/Name /Namespace))
]].. SubClassOf)

		lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])
		lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType/subCompartType[id='Annotation']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion($getAnnotationProperty(/AnnotationType /Namespace) /../../Name:$getUri(/Name /Namespace) "$value(/ValueLanguage/Value)" ?(@$value(/ValueLanguage/Language)))]])

		
		if lQuery("Plugin[id='DefaultOrder']"):is_not_empty() and lQuery("Plugin[id='DefaultOrder']"):attr("status") == "loaded" then
			lQuery("ElemType[id='Association']/compartType[id='Role']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(<http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])
			lQuery("ElemType[id='Association']/compartType[id='InvRole']/subCompartType[id='posInTable']/tag[key = 'ExportAxiom']"):attr("value", [[AnnotationAssertion(<http://lumii.lv/2011/1.0/owlgred#posInTable> /../Name:$getUri(/Name /Namespace) "$value")]])
		end
	end
end

function schemaGrammar(compartment)

	local additional_clauses = {}
	local generated_grammer = make_compart_grammer(compartment:find("/compartType"), compartment, "?", additional_clauses, true)
	local grammer = string.format("%s%s", generated_grammer, table.concat(additional_clauses))

	local clauses = [[
	(
										(
											{:schemaAssertion: '' -> " " :}
											{:hiddenCompartment: '' -> "++" :}
											"++"
										) /
										(
											{:schemaAssertion: '' -> " " :}
											{:localRange: '' -> "+" :}
											"+"
										)/
										(
											{:domainAndRange: '' -> "!" :}
											"!"
										)/
										(
											{:schemaAssertion: '' -> " " :}
											{:domainAndRange: '' -> " " :}
											""
										)
									)
]] .. grammer

-- print(clauses)

	return clauses
end

function make_compart_grammer(compart_type, compart, is_optional, additional_clauses, root)
	local delimiter = compart_type:attr("concatStyle") or ""
	delimiter = string.format("{('%s')}?", delimiter)
	local sub_comparts = compart_type:find("/subCompartType")
	local size = sub_comparts:size()
	local i = 0
	local grammer = ""
	sub_comparts:each(function(sub_compart_type)
		if sub_compart_type:attr("id") ~= "schemaAssertion" and sub_compart_type:attr("id") ~= "domainAndRange" and sub_compart_type:attr("id") ~= "localRange" and sub_compart_type:attr("id") ~= "hiddenCompartment" then
			local new_grammer = ""
			local id = sub_compart_type:attr("id")
			i = i + 1
			local sub_sub_comparts = sub_compart_type:find("/subCompartType")
			local sub_compart_id = sub_compart_type:attr("id")
			local prefix, suffix = core.get_prefix_suffix(sub_compart_type, nil, compart)
			prefix = core.recalculate_pattern(prefix)
			suffix = core.recalculate_pattern(suffix)
			local pattern, pattern_clauses = core.get_pattern(sub_compart_type, suffix)
			if prefix ~= "" then
				prefix = "'" .. prefix .. "'"
			end
			if suffix ~= "" then
				suffix = "'" .. suffix .. "'"
			end
			if i > 1 and i <= size then
				local tmp_optional = is_optional
				if sub_sub_comparts:is_not_empty() then
					
					local sub_compart_delimiter = sub_compart_type:attr("concatStyle")
					sub_compart_delimiter = core.recalculate_pattern(sub_compart_delimiter)
					if sub_compart_delimiter ~= "" then
						sub_compart_delimiter = "'" .. sub_compart_delimiter .. "'"
					end		
					
					local start, finish = string.find(sub_compart_id, "ASFictitious")
					if  start == 1 and finish == 12 then
						local sub_compart_pattern = make_compart_grammer(sub_compart_type, compart, "?", additional_clauses, true)
						new_grammer = delimiter .. " (" .. prefix .. " {:" .. sub_compart_id .. ": ("
											.. sub_compart_pattern .. " -> {} "
											.. "(" .. sub_compart_delimiter .. " " .. sub_compart_pattern .. " -> {})*  "
											--.. ") -> {} :} " .. suffix .. ")" .. "  \n"
											.. ") -> {} :} " .. suffix .. ")"  .. tmp_optional .. " \n"

											--.. delimiter .. sub_compart_pattern .. " -> {} :} " .. suffix .. ")? " .. "-> {} "
					else
						local sub_compart_pattern = make_compart_grammer(sub_compart_type, compart, is_optional, additional_clauses)
						new_grammer = delimiter .. " (" .. prefix .. " {:" .. sub_compart_id .. ": ("
											.. sub_compart_pattern .. ") "
											.. " -> {} :} " .. suffix .. ")" .. tmp_optional .. " \n"
					end
				else
					new_grammer = delimiter .. " (" .. prefix .. " {:" .. sub_compart_id .. ": " .. pattern .. " :} " .. suffix .. ")" .. tmp_optional .. " \n"		
					table.insert(additional_clauses, pattern_clauses)							

				end
			else
				local tmp_optional = is_optional
				if sub_sub_comparts:size() == 1 then
					tmp_optional = "?"
				else
					tmp_optional = ""

				end
				if sub_sub_comparts:is_not_empty() then
					local sub_compart_delimiter = sub_compart_type:attr("concatStyle")
					if sub_compart_delimiter ~= "" then
						sub_compart_delimiter = "'" .. sub_compart_delimiter .. "'"
					end

					local start, finish = string.find(sub_compart_id, "ASFictitious")
					if start == 1 and finish == 12 then
						local sub_compart_pattern = make_compart_grammer(sub_compart_type, compart, "?", additional_clauses, true)
						new_grammer = "(" .. prefix .. " {:" .. sub_compart_id ..  ": ("
										.. sub_compart_pattern .. " -> {} "
										.. "(" .. sub_compart_delimiter .. " " .. sub_compart_pattern .. " -> {})*  "
										.. ") -> {} :}" .. suffix .. ")" .. tmp_optional .. " \n"

					else
						local sub_compart_pattern = make_compart_grammer(sub_compart_type, compart, is_optional, additional_clauses)
						new_grammer = "(" .. prefix .. " {:" .. sub_compart_id ..  ": (" .. sub_compart_pattern .. ") -> {} :} " .. suffix .. ")" .. tmp_optional .. " \n"	
					end
				else
					new_grammer = "(" .. prefix .. " {:" .. sub_compart_id ..  ": " .. pattern .. " :} " .. suffix .. ")" .. tmp_optional .. " \n"
					table.insert(additional_clauses, pattern_clauses)									
				end
			end
		
			grammer = grammer .. new_grammer
		end
	end)
	return grammer
end