$.level = 0

# ## Global Settings
# 単位をピクセルに
preferences.rulerUnits = Units.PIXELS;

# ## Global Variables
originalWidth = 0
originalHeight = 0
currentWidth = 0
currentHeight = 0
boundsOffsetX = 0
boundsOffsetY = 0
pageWidth = 0
offsetX = 0
offsetY = 0
saveFolder = null
nameCounter = 0
structures = []
fileNames = {} # ファイル名重複対策
fileNameCounter = 0 # ファイル名重複対策
startTime = 0

# ## Functions
getLayerPath = (layer) ->
	path = []
	getLayerName = (layer) ->
		path.push layer.name
		if layer.parent
			getLayerName layer.parent
		return
	getLayerName layer
	path.shift()
	path.pop()
	path.pop()
	path.reverse()
	encodeURI '/' + path.join '/'

# 閉じる
close = (showDialog = false) ->
	if showDialog
		unless confirm '閉じてよろしいですか?'
			return
	activeDocument.close(SaveOptions.DONOTSAVECHANGES);
	return

getBounds = (layer) ->
	bounds = layer.bounds
	return {
		x: parseInt bounds[0], 10
		y: parseInt bounds[1], 10
		x2: parseInt bounds[2], 10
		y2: parseInt bounds[3], 10
	}

enlargeForSelect = (layer) ->
	bounds = getBounds layer
	if bounds.x < 0
		currentWidth -= bounds.x
		boundsOffsetX += bounds.x
		activeDocument.resizeCanvas currentWidth, currentHeight, AnchorPosition.TOPRIGHT
	if bounds.y < 0
		currentHeight -= bounds.y
		boundsOffsetY += bounds.y
		activeDocument.resizeCanvas currentWidth, currentHeight, AnchorPosition.BOTTOMLEFT
	if bounds.x2 > currentWidth + boundsOffsetX
		currentWidth += bounds.x2 + boundsOffsetX
		activeDocument.resizeCanvas currentWidth, currentHeight, AnchorPosition.TOPLEFT
	if bounds.y2 > currentHeight + boundsOffsetY
		currentHeight += bounds.y2 + boundsOffsetY
		activeDocument.resizeCanvas currentWidth, currentHeight, AnchorPosition.TOPLEFT
	return bounds

restoreDimension = ->
	activeDocument.resizeCanvas originalWidth - boundsOffsetX, originalHeight - boundsOffsetY, AnchorPosition.TOPLEFT
	activeDocument.resizeCanvas originalWidth, originalHeight, AnchorPosition.BOTTOMRIGHT

isSelect = ->
	flag = true
	_level = $.level
	$.level = 0
	try
		activeDocument.selection.translate(0, 0)
	catch e
		$.level = _level
		return flag = false
	finally
		$.level = _level
		return flag
	return

copy = (layer) ->
	bounds = enlargeForSelect layer
	activeDocument.selection.select [
		[bounds.x,     bounds.y]
		[bounds.x + 1, bounds.y]
		[bounds.x + 1, bounds.y + 1]
		[bounds.x,     bounds.y + 1]
	]
	fillTransparent = false
	unless isSelect()
		black = new SolidColor
		black.model = ColorModel.RGB
		black.red = 0
		black.green = 0
		black.blue = 0
		dot = activeDocument.artLayers.add()
		activeDocument.activeLayer = dot
		activeDocument.selection.fill black, ColorBlendMode.NORMAL, 100, false
		fillTransparent = true
	activeDocument.selection.deselect()
	selectAllLayers()
	activeDocument.selection.select [
		[bounds.x,  bounds.y]
		[bounds.x2, bounds.y]
		[bounds.x2, bounds.y2]
		[bounds.x,  bounds.y2]
	]
	if dot
		dot.visible = off
	activeDocument.selection.copy true
	activeDocument.selection.deselect()
	activeDocument.activeLayer = layer
	if dot
		dot.remove()
	dot = null
	fillTransparent

paste = (doc, fillTransparent) ->
	doc.paste()
	layer = activeDocument.activeLayer
	layer.translate -layer.bounds[0], -layer.bounds[1]
	if fillTransparent
		activeDocument.selection.select [
			[0, 0]
			[1, 0]
			[1, 1]
			[0, 1]
		]
		activeDocument.selection.clear()
	activeDocument.selection.deselect();
	doc = null
	return

getMetrics = (layer) ->
	bounds = getBounds layer
	return {
		x: bounds.x + boundsOffsetX + offsetX
		y: bounds.y + boundsOffsetY + offsetY
		width: bounds.x2 - bounds.x
		height: bounds.y2 - bounds.y
	}

createDocument = (width, height, name) ->
	return documents.add(width, height, 72, name, NewDocumentMode.RGB, DocumentFill.TRANSPARENT);

# 抽出
extract = (layer, extFlag, originalText = []) ->
	name = layer.name
	# 拡張子の分離
	if ext = name.match /(\.(?:jpe?g|gif|png))$/i
		ext = ext[0]
		name = name.replace ext, ''
	ext = '.' + extFlag if extFlag
	dir = getLayerPath layer
	name = name.replace(/^[0-9]/, 'image$0').replace(/[^a-z0-9_\.:-]/gi, '')
	if name is 'image'
		name = 'image_' + nameCounter++
	if fileNames[dir + name]
		name += fileNameCounter++
	fileNames[dir + name] = on
	fillTransparent = copy layer
	metrics = getMetrics layer
	newDoc = createDocument metrics.width, metrics.height, layer.name
	paste newDoc, fillTransparent
	switch ext
		when '.jpg', 'jpeg'
			url = saveJPEG name, dir
		when '.gif'
			url = saveGIF name, dir
		else
			url = savePNG name, dir
	newDoc.close SaveOptions.DONOTSAVECHANGES
	data = metrics
	data.name = name
	data.url = url
	data.text = originalText
	structures.push data
	return

# アウトプット
output = (layers, ext) ->
	for layer in layers
		layer.visible = on
		# なにもしないレイヤー
		if /^_:/.test(layer.name)
			layer.visible = off
			continue
		# フォルダレイヤーであり、スマートオブジェクト化対象外の場合は子レイヤーを再帰処理する
		else if layer.layers and not /^o:/.test(layer.name)
			output layer.layers, ext
			app.purge(PurgeTarget.ALLCACHES);
			$.gc()
		# スマートオブジェクト化対象のレイヤーをスマートオブジェクト化して抽出する
		else
			do ->
				newLayer = cloneLayer layer
				# hideIgnoreLayers newLayer
				newLayer = toSmartObject newLayer
				newLayer.name = newLayer.name.replace /^o:/, ''
				originalText = getText layer
				extract newLayer, ext, originalText
				newLayer.remove()
				newLayer = null
				app.purge(PurgeTarget.ALLCACHES);
				$.gc()
		layer.visible = off
	return

# ## 全レイヤーを非表示にする
hideAllLayers = (layers, parentIsSmartObject) ->
	if layers
		for layer in layers
			# 親レイヤーがスマートオブジェクト対象
			if parentIsSmartObject
				if /^_:/.test(layer.name)
					layer.visible = off
			else
				# 非表示
				$.writeln layer.name
				$.writeln layer.layer
				$.writeln '* * *'
				layer.visible = off
			# 再帰（フォルダレイヤー且つスマートオブジェクト化対象外→スマートオブジェクト化対象の中身は表示のまま）
			isSmartObject = not /^o:/.test(layer.name) or parentIsSmartObject
			hideAllLayers layer.layers, isSmartObject

# ## exec
#
# 実行
#
# @param {Number} typeFlag 出力タイプ
# @param {String} ext 拡張子  
# @param {String} saveFolderPath 出力パス  
# @param {Boolean} mix 背景を含めるかどうか
#
exec = (typeFlag, ext, saveFolderPath = '~/', mix = false) ->
	# タイマースタート
	startTime = new Date()
	# カンバスサイズをメモ
	originalWidth = activeDocument.width
	originalHeight = activeDocument.height
	currentWidth = originalWidth
	currentHeight = originalHeight
	# フォルダインスタンス
	saveFolder = new Folder saveFolderPath
	# 全レイヤーを非表示にする
	hideAllLayers activeDocument.layers
	# **画像の出力** レイヤーの数だけ再帰
	output activeDocument.layers, ext
	# ### カンバスサイズをもとに戻す
	restoreDimension()
	# **ここまでが画像の出力**
	# * * *
	# 取得したレイヤーを逆にする
	structures.reverse()
	# ### 出力タイプにより出力
	FLAG_CSS = 1
	FLAG_JSON = 2
	FLAG_LESS = 4
	FLAG_JQUERY = 8
	FLAG_JSFL = 16
	if typeFlag & FLAG_CSS
		outputCSS structures
	if typeFlag & FLAG_LESS
		outputLESS structures
	if typeFlag & FLAG_JQUERY
		outputJQUERY structures
	if typeFlag & FLAG_JSON
		outputJSON structures
	# ### 完了
	endTime = (new Date) - startTime
	period = do ->
		endTimeDate = new Date

	if confirm 'Complete!!\nお待たせしました。終了です。\nレイヤーの状態を元に戻しますか?'
		revert()
	return

# ## 入力ダイアログの表示
input = ->
	$dialog = new DialogUI 'PSD to HTML', 700, 480, null, ->
		@addText '書き出しフォルダ', 120, 20, 10, 50
		$saveFolder = @addTextbox 540, 20, 60, 70
		$saveFolder.val activeDocument.path + '/' + activeDocument.name.replace(/\.[a-z0-9_]+$/i, '') + '/'
		@addButton '選択', 80, 20, 610, 70,
			click: ->
				saveFolder = Folder.selectDialog '保存先のフォルダを選択してください'
				$saveFolder.val decodeURI saveFolder.getRelativeURI '/' if saveFolder
		@addText '書き出し形式', 120, 20, 10, 160
		$types = []
		$types.push @addCheckbox 'HTML＆CSS', 140, 20, 10+140*0, 190
		$types.push @addCheckbox 'JSON', 140, 20, 10+140*1, 190
		$types.push @addCheckbox 'LESS＆SASS', 140, 20, 10+140*2, 190
		$types.push @addCheckbox 'jQuery', 140, 20, 10+140*3, 190
		$types.push @addCheckbox 'JSFL', 140, 20, 10+140*4, 190
		@addText 'オプション', 120, 20, 10, 230
		$mix = @addCheckbox '背景やバウンディングボックスの範囲に入るオブジェクトも含めて書きだす。', 600, 20, 10, 260
		$png = @addRadio '全ての画像を強制的にPNGで書き出す。', 600, 20, 10, 290
		$gif = @addRadio '全ての画像を強制的にGIFで書き出す。', 600, 20, 10, 320
		@addText 'ドキュメントの原点のオフセットX', 300, 20, 10, 350
		$offsetX = @addTextbox 40, 20, 190, 350
		$offsetX.val 0
		@addText 'px', 300, 20, 235, 350
		@addText 'ドキュメントの原点のオフセットY', 300, 20, 310, 350
		$offsetY = @addTextbox 40, 20, 490, 350
		$offsetY.val 0
		@addText 'px', 300, 20, 535, 350
		@addText 'ページの幅', 300, 20, 10, 380
		$pageWidth = @addTextbox 40, 20, 190, 380
		$pageWidth.val 0
		@addText 'px', 300, 20, 235, 380
		@ok ->
			saveFolderPath = encodeURI $saveFolder.val()
			typeFlag = 0
			for $type, i in $types
				if $type.val()
					typeFlag += Math.pow 2, i
			ext = 'png' if $png.val()
			ext = 'gif' if $gif.val()
			offsetX = parseInt($offsetX.val(), 10) * -1 or 0
			offsetY = parseInt($offsetY.val(), 10) * -1 or 0
			pageWidth = parseInt($pageWidth.val(), 10) or 0
			@close()
			exec typeFlag, ext, saveFolderPath, $mix.val() # 実行

if documents.length
	savable = yes
	_level = $.level
	$.level = 0
	try
		activeDocument.path
	catch err
		alert '保存してください\nこのドキュメントは一度も保存されていません。\nドキュメントを保存後に再実行してください。'
		savable = no
	$.level = _level
	if savable
		if activeDocument.saved
			input()
		else
			if confirm 'ドキュメントが保存されていません。\n保存しますか？'
				activeDocument.save()
			input()
else
	alert 'ドキュメントが開かれていません\n対象のドキュメントが開かれていません。'
