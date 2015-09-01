{BufferedProcess, Point} = require 'atom'
Q = require 'q'
path = require 'path'

module.exports =
class TagGenerator
  constructor: (@path, @scopeName) ->

  getPackageRoot: ->
    packageRoot = path.resolve(__dirname, '..')
    {resourcePath} = atom.getLoadSettings()
    if path.extname(resourcePath) is '.asar'
      if packageRoot.indexOf(resourcePath) is 0
        packageRoot = path.join("#{resourcePath}.unpacked", 'node_modules', 'symbols-view')
    packageRoot

  parseTagLine: (line) ->
    sections = line.split('\t')
    if sections.length > 3
      position: new Point(parseInt(sections[2]) - 1)
      name: sections[0]
    else
      null

  getLanguage: ->
    return 'Cson' if path.extname(@path) in ['.cson', '.gyp']

    switch @scopeName
      when 'source.c'        then 'C'
      when 'source.cpp'      then 'C++'
      when 'source.clojure'  then 'Lisp'
      when 'source.capnp'    then 'Capnp'
      when 'source.coffee'   then 'CoffeeScript'
      when 'source.css'      then 'Css'
      when 'source.css.less' then 'Css'
      when 'source.css.scss' then 'Css'
      when 'source.elixir'   then 'Elixir'
      when 'source.fountain' then 'Fountain'
      when 'source.gfm'      then 'Markdown'
      when 'source.go'       then 'Go'
      when 'source.java'     then 'Java'
      when 'source.js'       then 'JavaScript'
      when 'source.js.jsx'   then 'JavaScript'
      when 'source.jsx'      then 'JavaScript'
      when 'source.json'     then 'Json'
      when 'source.julia'    then 'Julia'
      when 'source.makefile' then 'Make'
      when 'source.objc'     then 'C'
      when 'source.objcpp'   then 'C++'
      when 'source.python'   then 'Python'
      when 'source.ruby'     then 'Ruby'
      when 'source.sass'     then 'Sass'
      when 'source.yaml'     then 'Yaml'
      when 'text.html'       then 'Html'
      when 'text.html.php'   then 'Php'

  generate: ->
    deferred = Q.defer()
    tags = {}
    packageRoot = @getPackageRoot()
    command = path.join(packageRoot, 'vendor', "ctags-#{process.platform}")
    defaultCtagsFile = path.join(packageRoot, 'lib', 'ctags-config')
    args = ["--options=#{defaultCtagsFile}", '--fields=+KS']

    if atom.config.get('symbols-view.useEditorGrammarAsCtagsLanguage')
      if language = @getLanguage()
        args.push("--language-force=#{language}")

    args.push('-nf', '-', @path)

    stdout = (lines) =>
      for line in lines.split('\n')
        if tag = @parseTagLine(line)
          tags[tag.position.row] ?= tag
    stderr = ->
    exit = ->
      tags = (tag for row, tag of tags)
      deferred.resolve(tags)

    new BufferedProcess({command, args, stdout, stderr, exit})

    deferred.promise
