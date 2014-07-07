{BufferedProcess, Point} = require 'atom'
Q = require 'q'
path = require 'path'

TAG_LINE = "line:"
TAG_LINE_LENGTH = TAG_LINE.length

module.exports =
class TagGenerator
  constructor: (@path, @scopeName) ->

  parseTagLine: (line) ->
    sections = line.split("\t")
    if sections.length > 3
      tag = {
        name: sections.shift()
        file: sections.shift()
      }

      i = sections.length - 1

      while i >= 0
        row = sections[i]
        if row.indexOf(TAG_LINE) == 0
          row = row.substr(TAG_LINE_LENGTH) - 1
          break
        else
          row = -1
        --i

      pattern = sections.join("\t")

      #match /^ and trailing $/;
      tag.pattern = pattern.match(/^\/\^(.*)(\$\/;")/)?[1]
      if not tag.pattern
        tag.pattern = pattern.match(/^\/\^(.*)(\/;")/)?[1]

      if tag.pattern
        tag.position = new Point(row, tag.pattern.indexOf(tag.name))
      else
        return null
      return tag
    else
      return null

  getLanguage: ->
    return 'Cson' if path.extname(@path) in ['.cson', '.gyp']

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
      when 'source.python'   then 'Python'
      when 'source.ruby'     then 'Ruby'
      when 'source.sass'     then 'Sass'
      when 'source.yaml'     then 'Yaml'
      when 'text.html'       then 'Html'
      when 'text.html.php'   then 'Php'

  generate: ->
    deferred = Q.defer()
    tags = []
    command = path.resolve(__dirname, '..', 'vendor', "ctags-#{process.platform}")
    args = ['--fields=+KSn']

    if atom.config.get('atom-ctags.useEditorGrammarAsCtagsLanguage')
      if language = @getLanguage()
        args.push("--language-force=#{language}")

    args.push('-R', '-f', '-', @path)

    stdout = (lines) =>
      lines = lines.replace(/\\\\/g, "\\")
      lines = lines.replace(/\\\//g, "/")

      lines = lines.split('\n')
      if lines[lines.length-1] == ""
        lines.pop()

      for line in lines
        tag = @parseTagLine(line)
        if tag
          tags.push(tag)
        else
          console.error """
          [atom-ctags:TagGenerator] please create a new issue:
             failed to parseTagLine, @#{line}@
             command: @#{command} #{args.join(' ')}@
          """
    stderr = (lines) =>
      console.error """
      [atom-ctags:TagGenerator]
       please create a new issue:
         failed to excute command: @#{command} #{args.join(' ')}@
         lines: @#{lines}@
      """

    exit = ->
      clearTimeout(t)
      deferred.resolve(tags)

    childProcess = new BufferedProcess({command, args, stdout, stderr, exit})

    t = setTimeout =>
      childProcess.kill()
      console.error "[atom-ctags:TagGenerator] stoped. Build more than 5 seconds, check if #{@path} contain too many file"
    , 5000

    deferred.promise
