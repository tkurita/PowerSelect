global keyText
global InsertionContainer

on select_in_Finder(target_items)
	--log "start select_in_Finder"
	tell InsertionContainer
		if (not is_in_window()) or (not is_determined_by_selection()) or (is_closed_folder()) then
			tell application "Finder"
				select target_items
			end tell
			return
		end if
	end tell
	
	using terms from application "Finder"
		if view_type() of InsertionContainer is not list view then
			tell application "Finder"
				select target_items
			end tell
			return
		end if
	end using terms from
	
	tell application "Finder"
		set selection to target_items
		set toolbar_visible to toolbar visible of Finder window 1
	end tell
	
	tell application "System Events" to tell (application process "Finder"'s window 1 whose description is "standard window")
		if toolbar_visible then
			set t to splitter group 1
		else
			set t to it
		end if
		
		tell scroll area -1 of t
			tell outline 1
				set outline_properties to properties of it
				set header_h to item 2 of (get size of group 1)
				set content_size_v to (item 2 of size of outline_properties)
				-- window が zoomed であるかどうかで、4 pixel だけ値が変わる。zoomed の時は、余白(4pixel）だけ増える
				-- header をのぞいたサイズ
				set content_pos_v to (item 2 of position of outline_properties) -- header の内側から
				set pos_list to position of rows where it is selected -- 画面の上（menubar を含む)から測った上辺の位置
				set item_h to item 2 of (get size of first row)
				if class of item 1 of pos_list is list then
					set pos_list to item 1 of pos_list
					set item_h to (item 2 of last item of pos_list) + item_h
				end if
				set item_pos_t to ((item 2 of pos_list) - content_pos_v)
				set item_pos_b to item_pos_t + item_h
			end tell
			
			set scroll_properties to properties of it
			set sbar_h to item 2 of (get size of scroll bar 2)
			set scroll_size_v to ((item 2 of size of scroll_properties) - header_h - sbar_h) -- header をのぞいたサイズ
			set scroll_pos_v to ((item 2 of position of scroll_properties) + header_h) -- header の内側からのサイズ
			set current_t to scroll_pos_v - content_pos_v
			set current_b to current_t + scroll_size_v
			set hidden_v to content_size_v - scroll_size_v
			(*
		- item_pos_t : 表示すべき領域の先頭位置
		- item_pos_b : 
		- item_h : 表示すべき領域の高さ
		- hidden_v : 表示できない領域の高さ
		- scroll_size_v : 表示できる領域の高さ
		- current_t : 現在表示している outline の領域 top
		- current_b : 現在表示している outline の領域 bottom
		*)
			
			if hidden_v is 0 then return
			if (current_t is less than or equal to item_pos_t) and (item_pos_b is less than or equal to current_b) then return
			if (item_h > scroll_size_v) or (item_pos_b > current_b) then
				-- align with last item
				set scroll_ratio to (item_pos_t + (item_h - scroll_size_v)) / hidden_v
			else
				-- align with first item
				set scroll_ratio to item_pos_t / hidden_v
			end if
			--log scroll_ratio
			set value of scroll bar 1 to scroll_ratio
		end tell
	end tell
end select_in_Finder

script FilterActionBase
	
	on make_for_location(a_location)
		script FilterActionBaseCore
			property _container : a_location
			property _itemList : missing value
			property _attributeList : {}
		end script
	end make_for_location
	
	on count_items()
		return length of my _attributeList
	end count_items
	
	on attribute_list()
		return my _attributeList
	end attribute_list
	
	on all_items()
		return my _itemList
	end all_items
	
	on target_container()
		return my _container
	end target_container
	
	on is_found()
		return (my _itemList is not missing value)
	end is_found
	
	on isFound()
		return (my _itemList is not missing value)
	end isFound
	
	on GetNameAndKindList()
		--log "start GetNameAndKindList"
		if my _itemList is {} then
			set a_message to localized string "NoItemsFound"
			set my _attributeList to {{|name|:a_message, |kind|:""}}
			set my _itemList to missing value
		else
			repeat with ith from 1 to length of my _itemList
				--log ith
				set theItem to item ith of my _itemList
				tell application "Finder"
					set end of my _attributeList to {|name|:name of theItem, |kind|:kind of theItem}
				end tell
			end repeat
		end if
		--log "end GetNameAndKindList"
	end GetNameAndKindList
	
	on selectItem(numList)
		if my _itemList is missing value then
			return false
		end if
		
		set target_items to {}
		repeat with theNum in numList
			set end of target_items to item theNum of my _itemList
		end repeat
		select_in_Finder(target_items)
		return true
	end selectItem
	
	on selectAll()
		--log itemList
		select_in_Finder(my _itemList)
	end selectAll
	
	on GetItemList()
		set my _itemList to doFilterAction()
		GetNameAndKindList()
	end GetItemList
	
	on doFilterAction()
		return {}
	end doFilterAction
end script


on do(a_location, a_mode)
	--log "start do in FilterActionMaker"
	--log a_location
	set filter_action_base to make_for_location(a_location) of FilterActionBase
	
	if a_mode is 1 then
		script ContainFilter
			property parent : filter_action_base
			on doFilterAction()
				tell application "Finder"
					return every item of my _container whose name contains keyText
				end tell
			end doFilterAction
		end script
		
	else if a_mode is 2 then
		script NotContainFilter
			property parent : filter_action_base
			on doFilterAction()
				tell application "Finder"
					return every item of my _container whose name does not contain keyText
				end tell
			end doFilterAction
		end script
		
	else if a_mode is 4 then
		script StartWithFilter
			property parent : filter_action_base
			on doFilterAction()
				tell application "Finder"
					return every item of my _container whose name starts with keyText
				end tell
			end doFilterAction
		end script
		
	else if a_mode is 5 then
		script NotStartWithFilter
			property parent : filter_action_base
			on doFilterAction()
				tell application "Finder"
					return every item of my _container whose name does not start with keyText
				end tell
			end doFilterAction
		end script
		
	else if a_mode is 7 then
		script EndWithFilter
			property parent : filter_action_base
			on doFilterAction()
				tell application "Finder"
					return every item of my _container whose name ends with keyText
				end tell
			end doFilterAction
		end script
		
	else if a_mode is 8 then
		script NotEndWithFilter
			property parent : filter_action_base
			on doFilterAction()
				tell application "Finder"
					return every item of my _container whose name does not end with keyText
				end tell
			end doFilterAction
		end script
		
	else
		script InvalidFilter
			on GetNameAndKindList()
				my GetItemList()
			end GetNameAndKindList
			on GetItemList()
				set theMessage to localized string "InternalError"
				error theMessage number -128
			end GetItemList
		end script
	end if
	
	return the result
end do
