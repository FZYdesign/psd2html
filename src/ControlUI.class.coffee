class ControlUI
	constructor: (@$window, @type, @width = 100, @height = 20, @left = 0, @top = 0, options = []) ->
		@window = @$window.window
		@context = @window.add.apply @window, [@type, [@left, @top, @width + @left, @height + @top]].concat options
	close: (value) ->
		@window.close value
	val: (getValue) ->
		switch @type
			when 'edittext', 'statictext'
				type = 'text'
			else
				type = 'value'
		if getValue?
			@context[type] = value = getValue.toString()
		else
			value = @context[type]
		value
	on: (event, callback) ->
		event = event.toLowerCase().replace(/^on/i, '').replace /^./, (character) ->
			character.toUpperCase()
		self = @
		@context['on' + event] = =>
			callback.apply self, arguments
		@
