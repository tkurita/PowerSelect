global keyText
global InsertionLocator
global mainWindow
global appController
global XList

on select_in_Finder(target_items)
	script to_fileref
		on do(an_item)
			return POSIX file an_item
		end do
	end script
	
	set target_items to target_items's map_as_list(to_fileref)
	tell InsertionLocator
		--log is_location_in_window()
		--log is_determined_by_selection()
		--log is_closed_folder()
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
			--log "target_window is closerd"
			select target_items
			return true
		end try
		
		set w_index to index of a_window
		set nwin_f to count windows
		set selection to target_items
	end tell
	
	tell application "System Events"
		set nwin_ax to count windows of application process "Finder"
		(* In leopard (comfirmed in 10.5.5), floting windows of Finder are ignored in window indexes.
	Therefor indexes of window is not same between Finder and SystemEvents *)
		set w_index to w_index - (nwin_f - nwin_ax)
		
		tell (application process "Finder"'s window w_index)
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
					set row_h to item 2 of (get size of first row)
					if class of item 1 of pos_list is list then
						-- leopard : always list of positions
						-- tiger : when multiple items are selected, list of positions
						set item_pos_t to item 2 of first item of pos_list
						set item_pos_b to (item 2 of last item of pos_list) + row_h
						set item_h to item_pos_b - item_pos_t
					else
						-- tiger : when only one item is selected, open position is retuened
						set item_pos_t to item 2 of pos_list
						set item_pos_b to item_pos_t + row_h
						set item_h to row_h
					end if
					set item_pos_t to (item_pos_t - content_pos_v)
					set item_pos_b to (item_pos_b - content_pos_v)
				end tell
				set scroll_properties to properties of it
				set sbar_h to item 2 of (get size of scroll bar 2)
				set scroll_size_v to ((item 2 of size of scroll_properties) - header_h - sbar_h) -- header をのぞいたサイズ
				set scroll_pos_v to ((item 2 of position of scroll_properties) + header_h) -- header の内側からのサイズ
				set current_t to scroll_pos_v - content_pos_v
				set current_b to current_t + scroll_size_v
				set hidden_v to content_size_v - scroll_size_v
				(*
		log "item_pos_t : 表示すべき領域の先頭位置 : " & item_pos_t
		log "item_pos_b : " & item_pos_b
		log "item_h : 表示すべき領域の高さ : " & item_h
		log "hidden_v : 表示できない領域の高さ : " & hidden_v
		log "scroll_size_v : 表示できる領域の高さ :" & scroll_size_v
		log "current_t : 現在表示している outline の領域 top : " & current_t
		log "current_b : 現在表示している outline の領域 bottom : " & current_b
		*)
				if hidden_v is 0 then return true
				if (current_t is less than or equal to item_pos_t) and (item_pos_b is less than or equal to current_b) then
					return true
				end if
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
	end tell
	-- log "end of select_in_Finder"
	return true
end select_in_Finder


on make_for_location(a_location)
	script FilterActionBaseCore
		property _container : a_location
		property _itemList : missing value
	end script
end make_for_location

on count_items()
	return my _itemList's item_counts()
end count_items

on all_items()
	return my _itemList's list_ref()
end all_items

on target_container()
	return my _container
end target_container

on is_found()
	return (my _itemList's item_counts() is not 0)
end is_found

on setup_pathes()
	set path_list to {}
	set path_list to my _itemList's list_ref()
	call method "setSearchResult:" of appController with parameter path_list
	--return path_list
end setup_pathes

on select_table_selection()
	if not is_found() then
		return false
	end if
	set path_list to call method "tableSelection"
	set target_items to XList's make_with(path_list)
	return select_in_Finder(target_items)
end select_table_selection

on select_all()
	select_in_Finder(my _itemList)
end select_all

on store_search_result()
	set my _itemList to XList's make_with(do_search())
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
				return call method "searchAtDirectory:withString:withMethod:" of appController with parameters {my _container, keyText, "nameContain:"}
			end do_search
		end script
		
	else if a_mode is 2 then
		script NotContainFilter
			property parent : filter_action_base
			on do_search()
				return call method "searchAtDirectory:withString:withMethod:" of appController with parameters {my _container, keyText, "nameNotContain:"}
			end do_search
		end script
		
	else if a_mode is 4 then
		script StartWithFilter
			property parent : filter_action_base
			on do_search()
				return call method "searchAtDirectory:withString:withMethod:" of appController with parameters {my _container, keyText, "nameHasPrefix:"}
			end do_search
		end script
		
	else if a_mode is 5 then
		script NotStartWithFilter
			property parent : filter_action_base
			on do_search()
				return call method "searchAtDirectory:withString:withMethod:" of appController with parameters {my _container, keyText, "nameNotHasPrefix:"}
			end do_search
		end script
		
	else if a_mode is 7 then
		script EndWithFilter
			property parent : filter_action_base
			on do_search()
				return call method "searchAtDirectory:withString:withMethod:" of appController with parameters {my _container, keyText, "nameHasSuffix:"}
			end do_search
		end script
		
	else if a_mode is 8 then
		script NotEndWithFilter
			property parent : filter_action_base
			on do_search()
				return call method "searchAtDirectory:withString:withMethod:" of appController with parameters {my _container, keyText, "nameNotHasSuffix:"}
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
