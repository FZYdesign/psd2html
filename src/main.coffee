$.level = 1

# ## Global Settings
# 単位をピクセルに
preferences.rulerUnits = Units.PIXELS;

# ## Global Variables
originalWidth = 0
originalHeight = 0
currentWidth = 0
currentHeight = 0
offsetX = 0
offsetY = 0
saveFolder = null
nameCounter = 0
structures = []
fileNames = {} # ファイル名重複対策
fileNameCounter = 0 # ファイル名重複対策

# ## Utility Function
# ### 数値処理拡張
Number::fillZero = (n) ->
  zeros = new Array n + 1 - @toString(10).length
  zeros.join('0') + @

# ## Debug Function
# ### ハッシュの出力用（再帰なし）
varDump = (obj) ->
	_rlt = []
	for own _key of obj
		try
			_val = obj[_key]
			unless _val instanceof Function then _rlt.push _key + ': ' + _val
		catch error
	alert _rlt.join '\n'

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

# 保存
saveJPEG = (fileName, dir = '', quality = 80) ->
	folder = new Folder saveFolder + dir + '/'
	unless folder.exists
		folder.create()
	filePath = folder + '/' + fileName + '.jpg'
	file = new File filePath
	jpegOpt = new JPEGSaveOptions()
	jpegOpt.embedColorProfile = false
	jpegOpt.quality = parseInt(12 * (quality / 100), 10)
	jpegOpt.formatOptions = FormatOptions.OPTIMIZEDBASELINE
	jpegOpt.scans = 3
	jpegOpt.matte = MatteType.NONE
	activeDocument.saveAs file, jpegOpt, true, Extension.LOWERCASE
	file.getRelativeURI saveFolder

saveGIF = (fileName, dir = '') ->
	folder = new Folder saveFolder + dir + '/'
	unless folder.exists
		folder.create()
	filePath = folder + '/' + fileName + '.gif'
	file = new File filePath
	gifOpt = new GIFSaveOptions()
	gifOpt.colors = 32
	gifOpt.dither = Dither.NONE
	gifOpt.interlacted = on
	gifOpt.matte = MatteType.WHITE
	gifOpt.palette = Palette.EXACT
	gifOpt.preserveExactColors = off
	gifOpt.transparency = on
	activeDocument.saveAs file, gifOpt, on, Extension.LOWERCASE
	file.getRelativeURI saveFolder

savePNG = (fileName, dir = '') ->
	folder = new Folder saveFolder + dir + '/'
	unless folder.exists
		folder.create()
	filePath = folder + '/' + fileName + '.png'
	file = new File filePath
	pngOpt = new PNGSaveOptions
	pngOpt.interlaced = off
	activeDocument.saveAs file, pngOpt, on, Extension.LOWERCASE
	file.getRelativeURI saveFolder

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
		offsetX += bounds.x
		activeDocument.resizeCanvas currentWidth, currentHeight, AnchorPosition.TOPRIGHT
	if bounds.y < 0
		currentHeight -= bounds.y
		offsetY += bounds.y
		activeDocument.resizeCanvas currentWidth, currentHeight, AnchorPosition.BOTTOMLEFT
	if bounds.x2 > currentWidth + offsetX
		currentWidth += bounds.x2 + offsetX
		activeDocument.resizeCanvas currentWidth, currentHeight, AnchorPosition.TOPLEFT
	if bounds.y2 > currentHeight + offsetY
		currentHeight += bounds.y2 + offsetY
		activeDocument.resizeCanvas currentWidth, currentHeight, AnchorPosition.TOPLEFT
	return bounds

restoreDimension = ->
	activeDocument.resizeCanvas originalWidth - offsetX, originalHeight - offsetY, AnchorPosition.TOPLEFT
	activeDocument.resizeCanvas originalWidth, originalHeight, AnchorPosition.BOTTOMRIGHT

selectAllLayers = ->
	ref = new ActionReference()
	ref.putEnumerated charIDToTypeID('Lyr '), charIDToTypeID('Ordn'), charIDToTypeID('Trgt')
	desc = new ActionDescriptor()
	desc.putReference charIDToTypeID('null'), ref
	executeAction stringIDToTypeID('selectAllLayers'), desc, DialogModes.NO
	return

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
	$.gc()

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
	$.gc()
	return

getMetrics = (layer) ->
	bounds = getBounds layer
	return {
		x: bounds.x + offsetX
		y: bounds.y + offsetY
		width: bounds.x2 - bounds.x
		height: bounds.y2 - bounds.y
	}

createDocument = (width, height, name) ->
	return documents.add(width, height, 72, name, NewDocumentMode.RGB, DocumentFill.TRANSPARENT);

outputCSS = (structures) ->
	cssText = []
	for layer, i in structures
		# z = 10000 - i * 10
		z = i * 10
		className = layer.url.replace(/\//g, '_').replace /\.[a-z]+$/i, ''
		text =
			"""
			.#{className} \{
				position: absolute;
				top: #{layer.y}px;
				left: #{layer.x}px;
				z-index: #{z};
				width: #{layer.width}px;
				height: #{layer.height}px;
				background: url(#{layer.url}) no-repeat scroll 0 0;
			\}
			"""
		cssText.push text
	cssFile = new File saveFolder + '/' + 'style.css'
	cssFile.open 'w'
	cssFile.encoding = 'utf-8'
	cssFile.write cssText.join '\n'
	cssFile.close()

	cssText = null
	cssFile = null
	$.gc()

	htmlTags = []
	for layer, i in structures
		# z = 10000 - i * 10
		z = i * 10
		className = layer.url.replace(/\//g, '_').replace /\.[a-z]+$/i, ''
		text = """
			<div class="#{className}">
				<!-- <img class="#{className}" src="#{layer.url}" alt="#{layer.name}" width="#{layer.width}" height="#{layer.height}"> -->
				<!-- <div class="#{className}" data-src="#{layer.url}" data-width="#{layer.width}" data-height="#{layer.height}" data-x="#{layer.x}" data-y="#{layer.y}" data-z="#{z}">#{layer.name}</div> -->
			</div>
		"""
		htmlTags.push text
	html = """
		<!doctype html>
		<html>
		<head>
			<meta charset="utf-8">
			<link rel="stylesheet" href="style.css">
		$
		</haed>
		<body>
		</body>
		</html>
	"""
	htmlFile = new File saveFolder + '/' + 'index.html'
	htmlFile.open 'w'
	htmlFile.encoding = 'utf-8'
	htmlFile.write html.replace '$', htmlTags.join '\n'
	htmlFile.close()

	htmlTags = null
	html = null
	htmlFile = null
	$.gc()

	return

outputLESS = (structures) ->
	alert 'LESSはまだつくってない'
	return

outputJSON = (structures) ->
	outputText = []
	for layer, i in structures
		z = 10000 - i * 10
		text = """
			\{
				"name": "#{layer.name}",
				"className": "#{layer.name}",
				"x": #{layer.x},
				"y": #{layer.y},
				"z": #{z},
				"width": #{layer.width},
				"height": #{layer.height},
				"url": "#{layer.url}"
			\}
		"""
		outputText.push text
	outputFile = new File saveFolder + '/' + 'structures.json'
	outputFile.open 'w'
	outputFile.encoding = 'utf-8'
	outputFile.write '[' + outputText.join(',\n') + ']'
	outputFile.close()

	return

hideLayerWithoutSelf = (layer) ->
	layer.visible = on
	parent = layer.parent
	if parent and parent.layers
		for sub in parent.layers
			sub._v = sub.visible
			sub.visible = off
		hideLayerWithoutSelf parent

showLayer = (layer) ->
	parent = layer.parent
	if parent and parent.layers
		for sub in parent.layers
			$.writeln sub._v
			sub.visible = sub._v
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

	parent = null
	sub = null
	uncle = null
	$.gc()

	return

# アウトプット
output = (layers, mix, ext) ->
	for layer in layers
		# 表示状態であり、フォルダレイヤーであれば再帰する
		if layer.typename is 'LayerSet' and layer.visible
			output layer.layers, mix, ext
		else
			# スマートオブジェクトであり、且つ表示状態であれば抽出する
			if layer.visible and layer.kind is LayerKind.SMARTOBJECT
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
	output layers, mix, ext

	# ### カンバスサイズをもとに戻す
	restoreDimension()

	# ### ガーベッジコレクション
	fileNames = null
	layers = null
	$.gc()

	# **ここまでが画像の出力**
	# * * *

	# 取得したレイヤーを逆にする
	structures.reverse()

	# ### 出力タイプにより出力
	FLAG_CSS = 1
	FLAG_LESS = 2
	FLAG_JSON = 4
	if typeFlag & FLAG_CSS
		outputCSS structures
	if typeFlag & FLAG_JSON
		outputJSON structures

	# ### ガーベッジコレクション
	structures = null
	saveFolder = null
	$.gc()

	# ### 完了
	alert 'Complete!!'

	return

# ## 入力ダイアログの表示
$dialog = new DialogUI 'PSD to PNG', 700, 400, null, ->
	@addText '書き出しフォルダ', 120, 20, 10, 50
	$saveFolder = @addTextbox 540, 20, 60, 70
	$saveFolder.val activeDocument.path + '/'
	@addButton '選択', 80, 20, 610, 70,
		click: ->
			saveFolder = Folder.selectDialog '保存先のフォルダを選択してください'
			$saveFolder.val decodeURI saveFolder.getRelativeURI '/' if saveFolder
	@addText '書き出し形式', 120, 20, 10, 160
	$types = []
	$types.push @addCheckbox 'HTML&CSS', 220, 20, 10, 190
	$types.push @addCheckbox 'LESS', 220, 20, 230, 190
	$types.push @addCheckbox 'JSON', 220, 20, 450, 190
	@addText 'オプション', 120, 20, 10, 230
	$mix = @addCheckbox '背景やバウンディングボックスの範囲に入るオブジェクトも含めて書きだす。', 600, 20, 10, 260
	$png = @addRadio '全ての画像を強制的にPNGで書き出す。', 600, 20, 10, 290
	$gif = @addRadio '全ての画像を強制的にGIFで書き出す。', 600, 20, 10, 320
	@ok ->
		saveFolderPath = encodeURI $saveFolder.val()
		typeFlag = 0
		for $type, i in $types
			if $type.val()
				typeFlag += Math.pow 2, i
		ext = 'png' if $png.val()
		ext = 'gif' if $gif.val()
		@close()
		exec typeFlag, ext, saveFolderPath, $mix.val() # 実行




