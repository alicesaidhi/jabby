local component = require(script.Parent.Parent.util.component)

type Can<T> = T | () -> T
return component(function(p: {
	-- textfield properties
	text: Can<string>?,
	placeholder: Can<string>?,
	multiline: Can<number>?,
	monospace: Can<boolean>?,

	-- error state properties
	error: Can<boolean>,
	helper_text: Can<string>,

	-- events
	oninput: ((text: string) -> ())?,
	enter: ((text: string) -> ())?,
	focuslost: ((text: string, enter: boolean) -> ())?,

})

end)