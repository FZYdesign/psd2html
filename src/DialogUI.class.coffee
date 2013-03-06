class DialogUI extends WindowUI
	constructor: (@name, @width, @height, options, callback) ->
		super 'dialog', @name, @width, @height, options, callback
