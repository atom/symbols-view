{BufferedProcess, Point} = require 'atom'
Q = require 'q'
path = require 'path'

module.exports =
class TagGenerator
  constructor: (@path, @scopeName) ->

  parseTagLine: (line) ->
    sections = line.split('\t')
    if sections.length > 3
      position: new Point(parseInt(sections[2]) - 1)
      name: sections[0]
    else
      null

  getLanguage: ->
    return 'Cson' if path.extname(@path) is '.cson'

    switch @scopeName
      when 'source.c'        then 'C'
      when 'source.c++'      then 'C++'
      when 'source.clojure'  then 'Lisp'
      when 'source.coffee'   then 'CoffeeScript'
      when 'source.css'      then 'Css'
      when 'source.css.less' then 'Css'
      when 'source.css.scss' then 'Css'
      when 'source.gfm'      then 'Markdown'
      when 'source.go'       then 'Go'
      when 'source.java'     then 'Java'
      when 'source.js'       then 'JavaScript'
      when 'source.json'     then 'Json'
      when 'source.makefile' then 'Make'
      when 'source.objc'     then 'C'
      when 'source.objc++'   then 'C++'
      when 'source.ruby'     then 'Ruby'
      when 'source.sass'     then 'CSS'
      when 'text.html'       then 'Html'
      when 'text.html.php'   then 'Php'

  generate: ->
    deferred = Q.defer()
    tags = []
    command = path.resolve(__dirname, '..', 'vendor', "ctags-#{process.platform}")
    defaultCtagsFile = require.resolve('./.ctags')
    args = ["--options=#{defaultCtagsFile}", '--fields=+KS']

    if atom.config.get('symbols-view.useEditorGrammarAsCtagsLanguage')
      if language = @getLanguage()
        args.push("--language-force=#{language}")

    args.push('-nf', '-', @path)

    stdout = (lines) =>
      for line in lines.split('\n')
        tag = @parseTagLine(line)
        tags.push(tag) if tag
    exit = ->
      deferred.resolve(tags)

    new BufferedProcess({command, args, stdout, exit})

    deferred.promise
