'use strict'

# ## Constants
NAMESPACE = 'psd2html'
VERSION = '1.1.0'

# ## Alias
global = @
Math = global.Math
setTimeout = global.setTimeout
clearTimeout = global.clearTimeout
setInterval = global.setInterval
clearInterval = global.clearInterval
isNaN = global.isNaN

# ## Variables

# ## Functions

# ### Debug Function
# #### ハッシュの出力用（再帰なし）
varDump = (obj) ->
	_rlt = []
	for own _key of obj
		try
			_val = obj[_key]
			unless _val instanceof Function then _rlt.push _key + ': ' + _val
		catch error
	alert _rlt.join '\n'

# ### Utility Function
# #### 数値処理拡張
Number::fillZero = (n) ->
	zeros = new Array n + 1 - @toString(10).length
	zeros.join('0') + @

# ### Layer Function

# #### 全レイヤーを選択
selectAllLayers = ->
	ref = new ActionReference()
	ref.putEnumerated charIDToTypeID('Lyr '), charIDToTypeID('Ordn'), charIDToTypeID('Trgt')
	desc = new ActionDescriptor()
	desc.putReference charIDToTypeID('null'), ref
	executeAction stringIDToTypeID('selectAllLayers'), desc, DialogModes.NO
	return

# #### レイヤーのコピー
cloneLayer = (layer, removeCOPYText) ->
	removeCOPY = (layer) ->
		layer.name = layer.name.replace /\s+のコピー(?:\s+\d+)?$/, ''
		if layer.layers
			for child in layer.layers
				removeCOPY child
	newLayer = layer.duplicate()
	removeCOPY newLayer if removeCOPYText
	activeDocument.activeLayer = newLayer
	newLayer

# #### スマートオブジェクトに変更
toSmartObject = (layer) ->
	if layer?
		activeDocument.activeLayer = layer
	executeAction stringIDToTypeID('newPlacedLayer'), undefined, DialogModes.NO
	activeDocument.activeLayer

# #### テキストの抽出
getText = (layer = activeDocument.layers[0]) ->
	text = []
	extructText = (layer) ->
		if layer.layers
			for child in layer.layers
				extructText child
		else if layer.kind is LayerKind.TEXT
			text.push layer.textItem.contents

# ### FileSystem Function

# #### Revert
# 復帰 (前回の保存時に戻す。)
revert = ->
	executeAction charIDToTypeID('Rvrt'), undefined, DialogModes.NO

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

# ### Output Function
outputCSS = (structures) ->
	cssText = []
	for layer, i in structures
		z = i * 10
		className = layer.url.replace(/\//g, '_').replace /\.[a-z]+$/i, ''
		text =
			"""
			.#{className} \{
				overflow: hidden;
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
	htmlTags = []
	for layer, i in structures
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
		</haed>
		<body>

		$

		</body>
		</html>
	"""
	htmlFile = new File saveFolder + '/' + 'index.html'
	htmlFile.open 'w'
	htmlFile.encoding = 'utf-8'
	htmlFile.write html.replace '$', htmlTags.join '\n'
	htmlFile.close()
	return

outputJSON = (structures) ->
	outputText = []
	for layer, i in structures
		z = i * 10
		className = layer.url.replace(/\//g, '_').replace /\.[a-z]+$/i, ''
		text = """
			\{
				"name": "#{layer.name}",
				"className": "#{className}",
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

outputLESS = (structures) ->
	cssText = []
	for layer, i in structures
		z = i * 10
		className = layer.url.replace(/\//g, '_').replace /\.[a-z]+$/i, ''
		text =
			"""
			.#{className} \{
				overflow: hidden;
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
	lessFile = new File saveFolder + '/' + 'position.less'
	lessFile.open 'w'
	lessFile.encoding = 'utf-8'
	lessFile.write cssText.join '\n'
	lessFile.close()
	scssFile = new File saveFolder + '/' + '_position.scss'
	lessFile.copy scssFile
	cssText = []
	for layer, i in structures
		z = i * 10
		className = layer.url.replace(/\//g, '_').replace /\.[a-z]+$/i, ''
		text =
			"""
			.#{className}
				overflow: hidden
				position: absolute
				top: #{layer.y}px
				left: #{layer.x}px
				z-index: #{z}
				width: #{layer.width}px
				height: #{layer.height}px
				background: url(#{layer.url}) no-repeat scroll 0 0
			"""
		cssText.push text
	sassFile = new File saveFolder + '/' + '_position.sass'
	sassFile.open 'w'
	sassFile.encoding = 'utf-8'
	sassFile.write cssText.join '\n'
	sassFile.close()
	return

outputJQUERY = (structures) ->
	jsvText = []
	jsjText = []
	for layer, i in structures
		z = i * 10
		className = layer.url.replace(/\//g, '_').replace /\.[a-z]+$/i, ''
		variableName = className.replace /_([a-z])/g, ($0, $1) -> $1.toUpperCase()
		vtext = "$#{variableName}"
		jsvText.push vtext
		jtext = "$#{variableName} = $('.#{className}')"
		jsjText.push jtext
	jsFile = new File saveFolder + '/' + 'position.js'
	jsFile.open 'w'
	jsFile.encoding = 'utf-8'
	jsFile.writeln 'var\n\t' + jsvText.join(',\n\t') + ';\n\n'
	jsFile.write jsjText.join(';\n') + ';'
	jsFile.close()
	cfvText = []
	cfjText = []
	for layer, i in structures
		z = i * 10
		className = layer.url.replace(/\//g, '_').replace /\.[a-z]+$/i, ''
		variableName = className.replace /_([a-z])/g, ($0, $1) -> $1.toUpperCase()
		vtext = "$#{variableName}"
		cfvText.push vtext
		jtext = "$#{variableName} = $ '.#{className}'"
		cfjText.push jtext
	cfFile = new File saveFolder + '/' + 'position.coffee'
	cfFile.open 'w'
	cfFile.encoding = 'utf-8'
	cfFile.writeln cfvText.join(' =\n') + ' = undefined\n\n'
	cfFile.write cfjText.join '\n'
	cfFile.close()
	return