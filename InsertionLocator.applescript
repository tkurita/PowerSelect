property InsertionLocator : module
property XList : module
property loader : boot (module loader of application (get "PowerSelectLib")) for me

on init()
	InsertionLocator's set_allow_closed_folder(false)
end init

property _ : init()

on run
	--return missing value
	(*
	set a_result to InsertionLocator's do()
	if a_result is not missing value then
		set a_result to POSIX path of a_result
	end if
	return a_result
	*)
	return make
end run

on select_in_Finder(target_items)
	script to_fileref
		on do(an_item)
			return POSIX file an_item
		end do
	end script
	
	set target_items to XList's make_with(target_items)'s map_as_list(to_fileref)
	tell my _locator
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
		if my _locator's view_type() is not list view then
			tell application "Finder"
				select target_items
			end tell
			return true
		end if
	end using terms from
	set a_window to my _locator's target_window()
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
				if (count (scroll bars)) > 1 then
					set sbar_h to item 2 of (get size of scroll bar 2)
				else
					set sbar_h to 0
				end if
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

on insertion_path()
	set my _insertion_path to my _locator's do()
	set a_result to my _insertion_path
	if a_result is not missing value then
		set a_result to a_result's POSIX path
	end if
	return a_result
end insertion_path

on make
	set self to me
	script
		property parent : self
		property _locator : make InsertionLocator
		property _insertion_path : missing value
	end script
	return result
end make