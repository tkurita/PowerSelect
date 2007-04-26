property InsertionContainer : load("InsertionContainer") of application (get "PowerSelectLib")
property CandidateDataSource : missing value
property keyText : missing value
property filterMode : missing value
property FilterAction : missing value
property mainWindow : missing value
property ComboBoxHistory : missing value
property searchTextHistoryObj : missing value
property DefaultValueManager : missing value
property _searchComboBox : missing value
property _candidateTable : missing value

on initialize()
	--InsertionContainer's respect_icon_view(true)
end initialize

property _ : initialize()

on GetFilterAction(theLocation)
	script FilterdLists
		property theContainer : theLocation
		property itemList : missing value
		property namekindList : {}
		
		on target_container()
			return my theContainer
		end target_container
		
		on isFound()
			return (itemList is not missing value)
		end isFound
		
		on GetNameAndKindList()
			--log "start GetNameAndKindList"
			if itemList is {} then
				set theMessage to localized string "NoItemsFound"
				set namekindList to {{|name|:theMessage, |kind|:""}}
				set itemList to missing value
			else
				repeat with ith from 1 to length of itemList
					--log ith
					set theItem to item ith of itemList
					tell application "Finder"
						set end of namekindList to {|name|:name of theItem, |kind|:kind of theItem}
					end tell
				end repeat
			end if
			--log "end GetNameAndKindList"
		end GetNameAndKindList
		
		on selectItem(numList)
			if itemList is missing value then
				return false
			end if
			
			set targetList to {}
			repeat with theNum in numList
				set end of targetList to item theNum of itemList
			end repeat
			tell application "Finder"
				select targetList
			end tell
			
			return true
		end selectItem
		
		on selectAll()
			--log itemList
			tell application "Finder"
				select itemList
			end tell
		end selectAll
		
		on GetItemList()
			set itemList to doFilterAction()
			GetNameAndKindList()
		end GetItemList
		
		on doFilterAction()
			return {}
		end doFilterAction
	end script
	
	script ContainFilter
		property parent : FilterdLists
		on doFilterAction()
			--log "start GetItemList"
			tell application "Finder"
				return every item of my theContainer whose name contains keyText
			end tell
			--log "end GetItemList"
		end doFilterAction
	end script
	
	script NotContainFilter
		property parent : FilterdLists
		on doFilterAction()
			tell application "Finder"
				return every item of my theContainer whose name does not contain keyText
			end tell
		end doFilterAction
	end script
	
	script StartWithFilter
		property parent : FilterdLists
		on doFilterAction()
			tell application "Finder"
				return every item of my theContainer whose name starts with keyText
			end tell
		end doFilterAction
	end script
	
	script NotStartWithFilter
		property parent : FilterdLists
		on doFilterAction()
			tell application "Finder"
				return every item of my theContainer whose name does not start with keyText
			end tell
		end doFilterAction
	end script
	
	script EndWithFilter
		property parent : FilterdLists
		on doFilterAction()
			tell application "Finder"
				return every item of my theContainer whose name ends with keyText
			end tell
		end doFilterAction
	end script
	
	script NotEndWithFilter
		property parent : FilterdLists
		on doFilterAction()
			tell application "Finder"
				return every item of my theContainer whose name does not end with keyText
			end tell
		end doFilterAction
	end script
	
	script InvalidFilter
		on GetNameAndKindList(itemList)
			my GetItemList()
		end GetNameAndKindList
		on GetItemList()
			set theMessage to localized string "InternalError"
			error theMessage number -128
		end GetItemList
	end script
	
	return item filterMode of {ContainFilter, NotContainFilter, InvalidFilter, StartWithFilter, NotStartWithFilter, InvalidFilter, EndWithFilter, NotEndWithFilter}
	
end GetFilterAction

on GetFilterResult()
	
	local theFilterAction
	local tmpList
	
	script ErrorMsgObj
		property namekindList : missing value
		property itemList : missing value
	end script
	
	--log "start to set filter script obj"
	
	set theLocation to do() of InsertionContainer
	if theLocation is missing value then
		set theMessage to localized string "InvalidLocation"
		set namekindList of ErrorMsgObj to {{|name|:"Selected Location is invalid.", |kind|:""}}
		return ErrorMsgObj
	end if
	--log "before GetFilterAction"
	set theFilterAction to GetFilterAction(theLocation)
	--log "success GetFilterAction"
	--get list of matched item
	GetItemList() of theFilterAction
	
	return theFilterAction
end GetFilterResult

on clicked theObject
	set theName to name of theObject
	
	if theName is "SearchButton" then
		tell mainWindow
			set keyText to contents of combo box "SearchText"
			set filterMode to (contents of popup button "ModePopup") + 1
		end tell
		--log "filter mode:" & filterMode
		
		set FilterAction to GetFilterResult()
		--log "success GetFilterResult"
		
		if (itemList of FilterAction is not missing value) and (length of itemList of FilterAction is 1) then
			selectAll() of FilterAction
			quit
			return
		end if
		
		set theDrawer to drawer "CandidateDrawer" of mainWindow
		
		if state of theDrawer is drawer closed then
			append CandidateDataSource with namekindList of FilterAction
			set contents of text field "TargetLocationLabel" of theDrawer to target_container() of FilterAction
			tell theDrawer to open drawer
		else
			delete (every data row of CandidateDataSource)
			append CandidateDataSource with namekindList of FilterAction
			setupDrawer(theDrawer)
		end if
		
		addValue(keyText) of searchTextHistoryObj
	else if theName is "CancelButton" then
		(*
		tell mainWindow
			tell drawer "CandidateDrawer" to close drawer
		end tell
		*)
		close mainWindow
		--quit
	else if theName is "SelectButton" then
		set selectNumList to selected rows of table view "CandidateTable" of scroll view "CandidateTable" of drawer "CandidateDrawer" of mainWindow
		if (selectItem(selectNumList) of FilterAction) then
			quit
		end if
	else if theName is "SelectAllButton" then
		selectAll() of FilterAction
		quit
	end if
	
end clicked

on importScript(scriptName)
	tell main bundle
		set scriptPath to path for script scriptName extension "scpt"
	end tell
	return load script POSIX file scriptPath
end importScript

on will open theObject
	set theName to name of theObject
	
	if theName is "MainWindow" then
		set mainWindow to theObject
		
		set ComboBoxHistory to importScript("ComboBoxHistory")
		
		set DefaultValueManager to importScript("DefaultValueManager")
		
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
		
	end if
	--log "end will close"
end will close

on double clicked theObject
	set selectNum to selected rows of theObject
	--log selectNum
	if (selectItem(selectNum) of FilterAction) then
		quit
	end if
end double clicked

on will resize theObject proposed size proposedSize
	tell theObject to close drawer
end will resize

on setupDrawer(theDrawer)
	log "start setupDrawer"
	tell theDrawer
		call method "setNextKeyView:" of scroll view "CandidateTable" with parameter _searchComboBox
		set theRowHeight to row height of table view "CandidateTable" of scroll view "CandidateTable"
		set tableHeight to theRowHeight * ((length of namekindList of FilterAction) + 1)
		
		--set theRowHeight to theRowHeight + 2
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
		
		if itemList of FilterAction is missing value then
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
	if isFound() of FilterAction then
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
