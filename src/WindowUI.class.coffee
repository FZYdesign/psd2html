class WindowUI
	constructor: (@type, @name = 'ダイアログボックス', @width = 100, @height = 100, options, callback) ->
		@window = new Window @type, @name, [0, 0, @width, @height], options
		@window.center()
		@controls = []
		@onOK = ->
		@onCancel = ->
		BUTTON_WIDTH = 100
		BUTTON_HEIGHT = 20
		BUTTON_MARGIN = 10
		@addButton 'OK', BUTTON_WIDTH, BUTTON_HEIGHT, @width - BUTTON_WIDTH - BUTTON_MARGIN, @height - BUTTON_HEIGHT - BUTTON_MARGIN,
			click: ->
				@$window.onOK.apply @, arguments
		@addButton 'キャンセル', BUTTON_WIDTH, BUTTON_HEIGHT, @width - BUTTON_WIDTH - BUTTON_MARGIN - BUTTON_WIDTH - BUTTON_MARGIN, @height - BUTTON_HEIGHT - BUTTON_MARGIN,
			click: ->
				@$window.onCancel.apply @, arguments
				@close()
		stop = callback?.call @
		unless stop is false
			@show()
	close: (value) ->
		@window.close value
	show: ->
		@window.show()
		@
	hide: ->
		@window.hide()
		@
	center: ->
		@window.center()
		@
	addControl: (type, width, height, left, top, options, events) ->
		$ctrl = new ControlUI @, type, width, height, left, top, options
		if events?
			for own event, callback of events
				$ctrl.on event, callback
		@controls.push $ctrl
		$ctrl
	addText: (text = '', width, height, left, top, events) ->
		@addControl 'statictext', width, height, left, top + 2, [text], events
	addTextbox: (width, height, left, top, defaultText = '', events) ->
		@addControl 'edittext', width, height, left, top, [defaultText], events
	addButton: (label, width, height, left, top, events) ->
		@addControl 'button', width, height, left, top, [label], events
	addRadio: (label, width, height, left, top, events) ->
		@addControl 'radiobutton', width, height, left, top, [label], events
	addCheckbox: (label, width, height, left, top, events) ->
		@addControl 'checkbox', width, height, left, top, [label], events
	ok: (callback = ->) ->
		@onOK = callback
		@
	cancel: (callback = ->) ->
		@onCancel = callback
		@
