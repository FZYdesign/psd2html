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

# #### スマートオブジェクトに変更
toSmartObject = (layer) ->
	if layer?
		activeDocument.activeLayer = layer
	executeAction stringIDToTypeID('newPlacedLayer'), undefined, DialogModes.NO
	layer

# ### FileSystem Function
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