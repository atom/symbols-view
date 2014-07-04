
module.exports =
ProviderClass: (Provider, Suggestion, ctagsCache)  ->
  options = { partialMatch: true }
  basepath = atom.project.getPath()+"/"
  class CtagsProvider extends Provider
    buildSuggestions: ->
      console.error("buildSuggestions")

      selection = @editor.getSelection()
      prefix = @prefixOfSelection selection

      # No prefix? Don't autocomplete!
      return unless prefix.length

      matches = ctagsCache.findTags prefix, options

      suggestions = (new Suggestion(this, word: i.name, label: i.pattern, prefix: prefix) for i in matches)

      # No suggestions? Don't autocomplete!
      return unless suggestions.length

      # Now we're ready - display the suggestions
      return suggestions

  return CtagsProvider
