'use strict'

# ## Constants
NAMESPACE = 'psd2html'
VERSION = '1.0.0'

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
# ### 別名で保存

newSave = ->
	desc3 = new ActionDescriptor()
	desc4 = new ActionDescriptor()
	desc4.putBoolean( stringIDToTypeID( "maximizeCompatibility" ), true )
	desc3.putObject( charIDToTypeID( "As  " ), charIDToTypeID( "Pht3" ), desc4 )
	# desc3.putPath( charIDToTypeID( "In  " ), new File( "/Users/hanada/Desktop" ) )
	# desc3.putBoolean( charIDToTypeID( "LwCs" ), true )
	executeAction( charIDToTypeID( "save" ), desc3, DialogModes.NO )