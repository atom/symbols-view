{SelectListView} = require 'atom-space-pen-views'

# This is a shim to be used until the views are switched to use Etch
# space-pen is incompatible with ES6
module.exports =
class BaseSymbolsView extends SelectListView
