property InsertionContainer : load("InsertionContainer") of application (get "PowerSelectLib")
property FilterActionMaker : missing value
property DefaultValueManager : missing value

property CandidateDataSource : missing value
property mainWindow : missing value
property ComboBoxHistory : missing value
property searchTextHistoryObj : missing value

(*== GUI items *)
property _searchComboBox : missing value
property _candidateTable : missing value

(*== parameters *)
property keyText : missing value
property _filterAction : missing value

on initialize()
	--InsertionContainer's respect_icon_view(true)
end initialize

property _ : initialize()

on GetFilterResult(a_mode)
	--log "start to set filter script obj"
	
	set a_location to do() of InsertionContainer
	if a_location is missing value then
		set a_message to localized string "InvalidLocation"
		script ErrorMsgObj
			property _attributeList : {{|name|:a_message, |kind|:""}}
			property _itemList : missing value
			
			on count_items()
				return length of my _attributeList
			end count_items
			
			on attribute_list()
				return my _attributeList
			end attribute_list
			
			on is_found()
				return (my _itemList is not missing value)
			end is_found
		end script
		
		return ErrorMsgObj
	end if
	
	set filter_action to do(a_location, a_mode) of FilterActionMaker
	GetItemList() of filter_action
	
	return filter_action
end GetFilterResult

on clicked theObject
	set theName to name of theObject
	
	if theName is "SearchButton" then
		tell mainWindow
			set keyText to contents of combo box "SearchText"
			set a_mode to (contents of popup button "ModePopup") + 1
		end tell
		--log "filter mode:" & filterMode
		
		set my _filterAction to GetFilterResult(a_mode)
		--log "success GetFilterResult"
		
		tell my _filterAction
			if (is_found()) and (length of all_items() is 1) then
				selectAll() of my _filterAction
				quit
				return
			end if
		end tell
		
		set theDrawer to drawer "CandidateDrawer" of mainWindow
		
		if state of theDrawer is drawer closed then
			append CandidateDataSource with (my _filterAction's attribute_list())
			set contents of text field "TargetLocationLabel" of theDrawer to target_container() of my _filterAction
			tell theDrawer to open drawer
		else
			delete (every data row of CandidateDataSource)
			append CandidateDataSource with (my _filterAction's attribute_list())
			setupDrawer(theDrawer)
		end if
		
		addValue(keyText) of searchTextHistoryObj
	else if theName is "CancelButton" then
		close mainWindow
		--quit
	else if theName is "SelectButton" then
		set selectNumList to selected rows of table view "CandidateTable" of scroll view "CandidateTable" of drawer "CandidateDrawer" of mainWindow
		if (selectItem(selectNumList) of my _filterAction) then
			quit
		end if
	else if theName is "SelectAllButton" then
		selectAll() of _filterAction
		quit
	end if
	
end clicked

on import_script(scriptName)
	tell main bundle
		set scriptPath to path for script scriptName extension "scpt"
	end tell
	return load script POSIX file scriptPath
end import_script

on will open theObject
	set theName to name of theObject
	
	if theName is "MainWindow" then
		set mainWindow to theObject
		
		set ComboBoxHistory to import_script("ComboBoxHistory")
		set DefaultValueManager to import_script("DefaultValueManager")
		set FilterActionMaker to import_script("FilterActionMaker")
		
		set windowPosition to registControl(a reference to position of theObject, "WindowPosition", {0, 0}) of DefaultValueManager
		if currentValue of windowPosition is {0, 0} then
			center theObject
		end if
	end if
end will open

on awake from nib theObject
	set theName to name of theObject
	
	if theName is "CandidateDataSource" then
		set CandidateDataSource to theObject
		tell theObject
			make new data column at the end of the data columns with properties {name:"name"}
			make new data column at the end of the data columns with properties {name:"kind"}
		end tell
		
	else if theName is "SearchText" then
		set searchTextHistoryObj to makeObj("SearchTextHistory", {}) of ComboBoxHistory
		setComboBox(theObject) of searchTextHistoryObj
		
		registControl(a reference to contents of contents of theObject, theName, "") of DefaultValueManager
		set _searchComboBox to theObject
		
	else if theName is "ModePopup" then
		registControl(a reference to contents of contents of theObject, theName, 0) of DefaultValueManager
		
	end if
end awake from nib

on will close theObject
	--log "start will close"
	set theName to name of theObject
	
	if theName is "CandidateDrawer" then
		tell theObject
			set {drawerWidth, drawerHeight} to minimum content size as list
			--log "minimum height:" & drawerHeight
			set content size to {drawerWidth, drawerHeight}
		end tell
		delete (every data row of CandidateDataSource)
	end if
	--log "end will close"
end will close

on double clicked theObject
	set selectNum to selected rows of theObject
	--log selectNum
	if (selectItem(selectNum) of _filterAction) then
		quit
	end if
end double clicked

on will resize theObject proposed size proposedSize
	--log "will resize"
	return content size of theObject
end will resize

on setupDrawer(theDrawer)
	--log "start setupDrawer"
	tell theDrawer
		call method "setNextKeyView:" of scroll view "CandidateTable" with parameter _searchComboBox
		set theRowHeight to row height of table view "CandidateTable" of scroll view "CandidateTable"
		set tableHeight to theRowHeight * ((count_items() of my _filterAction) + 1)
		
		--set theRowHeight to theRowHeight + 4
		set theViewRect to visible document rect of scroll view "CandidateTable"
		set scrollViewHeight to (item 4 of theViewRect) - (item 2 of theViewRect)
		
		set heightDiff to tableHeight - scrollViewHeight
		set {drawerWidth, drawerHeight} to content size as list
		--log "height difference:" & heightDiff
		
		set drawerHeight to drawerHeight + heightDiff
		--log "drawerHeight:" & drawerHeight
		
		set {maxWidth, maxHeight} to maximum content size of theDrawer
		--log "maxHeight : " & maxHeight
		
		if drawerHeight > maxHeight then
			set drawerHeight to maxHeight
		end if
		set content size to {drawerWidth, drawerHeight}
		
		if _filterAction's is_found() then
			set enabled of button "SelectAllButton" to false
		else
			set enabled of button "SelectAllButton" to true
		end if
		set enabled of button "SelectButton" to false
	end tell
end setupDrawer

on opened theObject
	set theName to name of theObject
	
	if theName is "CandidateDrawer" then
		setupDrawer(theObject)
	end if
end opened

on will quit theObject
	--log "will quit"
	writeDefaults() of searchTextHistoryObj
	writeAllDefaults() of DefaultValueManager
end will quit

on should select row theObject row theRow
	if is_found() of my _filterAction then
		set enabled of button "SelectButton" of drawer "CandidateDrawer" of mainWindow to true
		return true
	else
		return false
	end if
end should select row

on should close theObject -- "MainWindow" Only
	try -- if drawer is not opend, error occur.
		tell mainWindow
			tell drawer "CandidateDrawer" to close drawer
		end tell
	end try
	hide theObject
	--quit
	call method "terminate:"
	return false
end should close
