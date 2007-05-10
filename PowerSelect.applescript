(*== Script Modules *)
property InsertionContainer : load("InsertionContainer") of application (get "PowerSelectLib")
property FilterActionMaker : missing value
property DefaultValueManager : missing value

(*== GUI items *)
property _searchComboBox : missing value
property _candidateTable : missing value
property mainWindow : missing value
property appController : missing value
property _targetLocationLabel : missing value

(*== parameters *)
property keyText : missing value
property _filterAction : missing value
property ComboBoxHistory : missing value
property searchTextHistoryObj : missing value

on initialize()
	InsertionContainer's set_allow_closed_folder(false)
end initialize

property _init : initialize()

on GetFilterResult(a_mode)
	--log "start to set filter script obj"
	
	set a_location to do() of InsertionContainer
	if a_location is missing value then
		set a_message to localized string "InvalidLocation"
		
		script ErrorMsgObj
			on count_items()
				return 0
			end count_items
			
			on is_found()
				return false
			end is_found
			
			on target_container()
				return a_message
			end target_container
			
			on setup_pathes()
				call method "clearSearchResult"
			end setup_pathes
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
		
		tell my _filterAction
			if (is_found()) and (length of all_items() is 1) then
				selectAll() of my _filterAction
				quit
				return
			end if
		end tell
		
		set theDrawer to drawer "CandidateDrawer" of mainWindow
		
		set contents of contents of my _targetLocationLabel to target_container() of my _filterAction
		my _filterAction's setup_pathes()
		if state of theDrawer is drawer closed then
			tell theDrawer to open drawer
		else
			setupDrawer(theDrawer)
		end if
		
		addValue(keyText) of searchTextHistoryObj
	else if theName is "CancelButton" then
		close mainWindow
		--quit
	else if theName is "SelectButton" then
		--set selectNumList to selected rows of table view "CandidateTable" of scroll view "CandidateTable" of drawer "CandidateDrawer" of mainWindow
		if (select_table_selection() of my _filterAction) then
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
	
	if theName is "SearchText" then
		set searchTextHistoryObj to makeObj("SearchTextHistory", {}) of ComboBoxHistory
		setComboBox(theObject) of searchTextHistoryObj
		
		registControl(a reference to contents of contents of theObject, theName, "") of DefaultValueManager
		set _searchComboBox to theObject
		
	else if theName is "ModePopup" then
		registControl(a reference to contents of contents of theObject, theName, 0) of DefaultValueManager
		
	else if theName is "TargetLocationLabel" then
		set my _targetLocationLabel to theObject
		
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
	end if
	--log "end will close"
end will close

on double clicked theObject
	if (select_table_selection() of _filterAction) then
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
		set tableHeight to theRowHeight * ((call method "countResultRows" of appController) + 1)
		
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
			set enabled of button "SelectAllButton" to true
		else
			set enabled of button "SelectAllButton" to false
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
	return false
end should close

on will finish launching theObject
	set appController to call method "delegate"
end will finish launching

on mouse up theObject event theEvent
	set a_name to name of theObject
	if a_name is "LocationBox" then
		if click count of theEvent > 1 then
			set a_location to target_container() of my _filterAction
			tell application "Finder"
				try
					open a_location
				end try
			end tell
		end if
	end if
end mouse up
