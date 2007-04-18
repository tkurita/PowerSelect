property controlList : {}

on registControl(theControl, theDefaultKey, theDefaultValue)
	set theValue to readDefaultValue(theDefaultKey, theDefaultValue)
	set contents of theControl to theValue
	
	script ControlValueObj
		property targetControlValue : theControl
		property defaultKey : theDefaultKey
		property currentValue : theValue
		
		on writeDefaults()
			set currentValue to contents of targetControlValue
			set contents of default entry defaultKey of user defaults to currentValue
		end writeDefaults
	end script
	
	set end of controlList to ControlValueObj
	return ControlValueObj
end registControl

on writeAllDefaults()
	repeat with theItem in controlList
		writeDefaults() of theItem
	end repeat
end writeAllDefaults

on readDefaultValue(entryName, defaultValue)
	tell user defaults
		if exists default entry entryName then
			return contents of default entry entryName
		else
			make new default entry at end of default entries with properties {name:entryName, contents:defaultValue}
			return defaultValue
		end if
	end tell
end readDefaultValue