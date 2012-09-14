property InsertionLocator : module
property loader : boot (module loader of application (get "PowerSelectLib")) for me

on init()
	InsertionLocator's set_allow_closed_folder(false)
end init

property _ : init()

on run
	--return missing value
	set a_result to InsertionLocator's do()
	if a_result is not missing value then
		set a_result to POSIX path of a_result
	end if
	return a_result
end run