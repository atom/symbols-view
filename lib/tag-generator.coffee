{BufferedProcess, Point} = require 'atom'
Q = require 'q'
path = require 'path'

TAG_LINE = "line:"
TAG_LINE_LENGTH = TAG_LINE.length
fs = null

module.exports =
class TagGenerator
  constructor: (@path, @scopeName, @cmdArgs) ->

  parseTagLine: (line) ->
    sections = line.split(/\t+/)
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

  read: ->
    deferred = Q.defer()
    tags = []

    fs = require "fs" if not fs
    fs.readFile @path, 'utf-8', (err, lines) =>
      if not err
        lines = lines.replace(/\\\\/g, "\\")
        lines = lines.replace(/\\\//g, "/")
        lines = lines.split('\n')
        if lines[lines.length-1] == ""
          lines.pop()

        err = []
        for line in lines
          continue if line.indexOf('!_TAG_') == 0
          tag = @parseTagLine(line)
          if tag
            tags.push(tag)
          else
            err.push "failed to parseTagLine: @#{line}@"

        error "please create a new issue:<br> path: #{@path} <br>" + err.join("<br>") if err.length > 0
      else
        error err

      deferred.resolve(tags)

    deferred.promise

  generate: ->
    deferred = Q.defer()
    tags = []
    command = path.resolve(__dirname, '..', 'vendor', "ctags-#{process.platform}")
    defaultCtagsFile = require.resolve('./.ctags')

    args = []
    args.push @cmdArgs... if @cmdArgs

    args.push("--options=#{defaultCtagsFile}", '--fields=+KSn')

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

      err = []
      for line in lines
        tag = @parseTagLine(line)
        if tag
          tags.push(tag)
        else
          err.push "failed to parseTagLine: @#{line}@"
      error "please create a new issue:<br> command: @#{command} #{args.join(' ')}@" + err.join("<br>") if err.length > 0
    stderr = (lines) ->
      console.warn  """command: @#{command} #{args.join(' ')}@
      err: @#{lines}@"""

    exit = ->
      clearTimeout(t)
      deferred.resolve(tags)

    childProcess = new BufferedProcess({command, args, stdout, stderr, exit})

    timeout = atom.config.get('atom-ctags.buildTimeout')
    t = setTimeout =>
      childProcess.kill()
      error """
      stoped: Build more than #{timeout} seconds, check if #{@path} contain too many file.<br>
              Suggest that add CmdArgs at atom-ctags package setting, example:<br>
                  --exclude=some/path --exclude=some/other"""
    ,timeout

    deferred.promise

PlainMessageView = null
panel = null
error= (message, className) ->
    if not panel
      {MessagePanelView, PlainMessageView} = require "atom-message-panel"
      panel = new MessagePanelView title: "Atom Ctags"

    panel.attach()
    panel.add new PlainMessageView
      message: message
      className: className || "text-error"
      raw: true
