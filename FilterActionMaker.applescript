global keyText
global InsertionLocator
global mainWindow
global appController

on select_in_Finder(target_items)
	--log "start select_in_Finder"
	tell InsertionLocator
		if (not is_location_in_window()) or (not is_determined_by_selection()) or (is_closed_folder()) then
			tell application "Finder"
				select target_items
			end tell
			return true
		end if
	end tell
	
	using terms from application "Finder"
		if view_type() of InsertionLocator is not list view then
			tell application "Finder"
				select target_items
			end tell
			return true
		end if
	end using terms from
	
	set a_window to target_window() of InsertionLocator
	tell application "Finder"
		try
			set toolbar_visible to toolbar visible of a_window
		on error
			-- when target_window is closerd
			select target_items
			return true
		end try
		
		set w_index to index of a_window
		set selection to target_items
	end tell
	
	--tell application "System Events" to tell (application process "Finder"'s window 1 whose description is "standard window")
	tell application "System Events" to tell (application process "Finder"'s window w_index)
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
					set item_h to (item 2 of pos_list) + item_h
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
	--log "end of select_in_Finder"
	return true
end select_in_Finder


on make_for_location(a_location)
	script FilterActionBaseCore
		property _container : a_location
		property _itemList : missing value
	end script
end make_for_location

on count_items()
	return length of my _itemList
end count_items

on all_items()
	return my _itemList
end all_items

on target_container()
	return my _container
end target_container

on is_found()
	return (my _itemList is not {})
end is_found

on setup_pathes()
	set path_list to {}
	repeat with an_item in my _itemList
		set end of path_list to POSIX path of (an_item as alias)
	end repeat
	call method "setSearchResult:" of appController with parameter path_list
	--return path_list
end setup_pathes

on select_table_selection()
	if not is_found() then
		return false
	end if
	set path_list to call method "tableSelection"
	set target_items to {}
	repeat with a_path in path_list
		set end of target_items to (POSIX file a_path)
	end repeat
	return select_in_Finder(target_items)
end select_table_selection

on select_all()
	select_in_Finder(my _itemList)
end select_all

on store_search_result()
	set my _itemList to do_search()
end store_search_result

on do_search()
	return {}
end do_search

on do(a_location, a_mode)
	--log "start do in FilterActionMaker"
	--log a_location
	set filter_action_base to make_for_location(a_location)
	
	if a_mode is 1 then
		script ContainFilter
			property parent : filter_action_base
			on do_search()
				tell application "Finder"
					return every item of my _container whose name contains keyText
				end tell
			end do_search
		end script
		
	else if a_mode is 2 then
		script NotContainFilter
			property parent : filter_action_base
			on do_search()
				tell application "Finder"
					return every item of my _container whose name does not contain keyText
				end tell
			end do_search
		end script
		
	else if a_mode is 4 then
		script StartWithFilter
			property parent : filter_action_base
			on do_search()
				tell application "Finder"
					return every item of my _container whose name starts with keyText
				end tell
			end do_search
		end script
		
	else if a_mode is 5 then
		script NotStartWithFilter
			property parent : filter_action_base
			on do_search()
				tell application "Finder"
					return every item of my _container whose name does not start with keyText
				end tell
			end do_search
		end script
		
	else if a_mode is 7 then
		script EndWithFilter
			property parent : filter_action_base
			on do_search()
				tell application "Finder"
					return every item of my _container whose name ends with keyText
				end tell
			end do_search
		end script
		
	else if a_mode is 8 then
		script NotEndWithFilter
			property parent : filter_action_base
			on do_search()
				tell application "Finder"
					return every item of my _container whose name does not end with keyText
				end tell
			end do_search
		end script
		
	else
		script InvalidFilter
			on do_search()
				set a_message to localized string "InternalError"
				error a_message number -128
			end do_search
			
		end script
	end if
	
	return the result
end do
