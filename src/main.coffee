$.level = 1

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
offsetX = 0
offsetY = 0
saveFolder = null
nameCounter = 0
structures = []
fileNames = {} # ファイル名重複対策
fileNameCounter = 0 # ファイル名重複対策

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

hideLayerWithoutSelf = (layer) ->
	parent = layer.parent
	if parent and parent.layers # 親の子（自分も含めて兄弟要素）を一度全部隠す
		for sub in parent.layers
			if sub.visible
				sub.name += "__v__"
				sub.visible = off
		hideLayerWithoutSelf parent
	layer.visible = on # 自分だけ表示させる
	layer.name = layer.name.replace /__v__$/i, ''

showLayer = (layer) ->
	parent = layer.parent
	if parent and parent.layers
		for sub in parent.layers
			if /__v__$/i.test sub.name
				sub.visible = on
				sub.name = sub.name.replace /__v__$/i, ''
		showLayer parent

# 抽出
extract = (layer, mix, extFlag) ->
	name = layer.name
	# 拡張子の分離
	if ext = name.match /(\.(?:jpe?g|gif|png))$/i
		ext = ext[0]
		name = name.replace ext, ''
	ext = '.' + extFlag if extFlag
	unless mix
		# 自分以外を隠す
		hideLayerWithoutSelf layer
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
	if ext is '.jpeg' or ext is '.jpg'
		url = saveJPEG name, dir
	else if ext is '.gif'
		url = saveGIF name, dir
	else
		url = savePNG name, dir
	newDoc.close SaveOptions.DONOTSAVECHANGES
	data = metrics
	data.name = name
	data.url = url
	structures.push data
	unless mix
		# 表示状態を元に戻す
		showLayer layer
	return

# アウトプット
output = (layers, ext, mix) ->
	for layer in layers
		alert layer.name
		# 表示状態であり、フォルダレイヤーであれば再帰する
		if layer.typename is 'LayerSet' and layer.visible
			output layer.layers, mix, ext
		# スマートオブジェクト化対象のレイヤーをスマートオブジェクト化して抽出する
		else if layer.visible and layer.kind isnt LayerKind.SMARTOBJECT and /^o:/.test(layer.name)
			do ->
				newLayer = cloneLayer layer
				toSmartObject newLayer
				layer.visible = off
				newLayer = newLayer.replace /^o:/, ''
				extract newLayer, mix, ext
		# スマートオブジェクトであり、且つ表示状態であれば抽出する
		else if layer.visible and layer.kind is LayerKind.SMARTOBJECT
			extract layer, mix, ext
	return

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
	# カンバスサイズをメモ
	originalWidth = activeDocument.width
	originalHeight = activeDocument.height
	currentWidth = originalWidth
	currentHeight = originalHeight
	# フォルダインスタンス
	saveFolder = new Folder saveFolderPath
	# レイヤーの取得
	layers = activeDocument.layers
	# **画像の出力** レイヤーの数だけ再帰
	output layers, ext, mix
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
	alert 'Complete!!\nお待たせしました。終了です。'
	return

# ## 入力ダイアログの表示
input = ->
	$dialog = new DialogUI 'PSD to HTML', 700, 430, null, ->
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
