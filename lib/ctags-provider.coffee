
module.exports =
ProviderClass: (Provider, Suggestion, ctagsCache)  ->
  #maxItems = autocomplete-plus:SimpleSelectListView.maxItems
  options = { partialMatch: true, maxItems: 10 }
  basepath = atom.project.getPath()+"/"

  class CtagsProvider extends Provider
    buildSuggestions: ->

      selection = @editor.getSelection()
      prefix = @prefixOfSelection selection

      options.partialMatch = true
      if not prefix.length
        #here to show pre symbol tag pattern
        selectionRange = selection.getBufferRange()
        selectionRange = selectionRange.add([0, -1])
        prefix = @prefixOfSelection { getBufferRange: ()-> selectionRange }
        options.partialMatch = false

      # No prefix? Don't autocomplete!
      return unless prefix.length

      matches = ctagsCache.findTags prefix, options

      suggestions = []
      if options.partialMatch
        output = {}
        k = 0
        while k < matches.length
          v = matches[k++]
          continue if output[v.name]
          output[v.name] = v
          suggestions.push new Suggestion(this, word: v.name, prefix: prefix)
        if suggestions.length == 1 and suggestions[0].word == prefix
          return []
      else
        for i in matches
          suggestions.push new Suggestion(this, word: i.name, prefix: prefix, label: i.pattern)

      # No suggestions? Don't autocomplete!
      return unless suggestions.length

      # Now we're ready - display the suggestions
      return suggestions

  return CtagsProvider
