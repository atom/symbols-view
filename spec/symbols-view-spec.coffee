path = require 'path'
{$} = require 'atom-space-pen-views'
fs = require 'fs-plus'
temp = require 'temp'
SymbolsView = require '../lib/symbols-view'
TagGenerator = require '../lib/tag-generator'

describe "SymbolsView", ->
  [symbolsView, activationPromise, editor, directory] = []

  getWorkspaceView = -> atom.views.getView(atom.workspace)
  getEditorView = -> atom.views.getView(atom.workspace.getActiveTextEditor())

  beforeEach ->
    spyOn(SymbolsView::, "setLoading").andCallThrough()

    atom.project.setPaths([
      temp.mkdirSync("other-dir-")
      temp.mkdirSync('atom-symbols-view-')
    ])

    directory = atom.project.getDirectories()[1]
    fs.copySync(path.join(__dirname, 'fixtures', 'js'), atom.project.getPaths()[1])

    activationPromise = atom.packages.activatePackage("symbols-view")
    jasmine.attachToDOM(getWorkspaceView())

  describe "when tags can be generated for a file", ->
    beforeEach ->
      waitsForPromise ->
        atom.workspace.open(directory.resolve('sample.js'))

    it "initially displays all JavaScript functions with line numbers", ->
      runs ->
        atom.commands.dispatch(getEditorView(), "symbols-view:toggle-file-symbols")

      waitsForPromise ->
        activationPromise

      runs ->
        symbolsView = $(getWorkspaceView()).find('.symbols-view').view()

      waitsFor "loading", ->
        symbolsView.setLoading.callCount > 1

      waitsFor ->
        symbolsView.list.children('li').length > 0

      runs ->
        expect(symbolsView.loading).toBeEmpty()
        expect($(getWorkspaceView()).find('.symbols-view')).toExist()
        expect(symbolsView.list.children('li').length).toBe 2
        expect(symbolsView.list.children('li:first').find('.primary-line')).toHaveText 'quicksort'
        expect(symbolsView.list.children('li:first').find('.secondary-line')).toHaveText 'Line 1'
        expect(symbolsView.list.children('li:last').find('.primary-line')).toHaveText 'quicksort.sort'
        expect(symbolsView.list.children('li:last').find('.secondary-line')).toHaveText 'Line 2'
        expect(symbolsView.error).not.toBeVisible()

    it "caches tags until the editor changes", ->
      runs ->
        editor = atom.workspace.getActiveTextEditor()
        atom.commands.dispatch(getEditorView(), "symbols-view:toggle-file-symbols")

      waitsForPromise ->
        activationPromise

      runs ->
        symbolsView = $(getWorkspaceView()).find('.symbols-view').view()

      waitsFor ->
        symbolsView.list.children('li').length > 0

      runs ->
        symbolsView.cancel()
        spyOn(symbolsView, 'generateTags').andCallThrough()
        atom.commands.dispatch(getEditorView(), "symbols-view:toggle-file-symbols")

      waitsFor ->
        symbolsView.list.children('li').length > 0

      runs ->
        expect(symbolsView.loading).toBeEmpty()
        expect(symbolsView.list.children('li').length).toBe 2
        expect(symbolsView.generateTags).not.toHaveBeenCalled()
        editor.save()
        symbolsView.cancel()
        atom.commands.dispatch(getEditorView(), "symbols-view:toggle-file-symbols")

      waitsFor ->
        symbolsView.list.children('li').length > 0

      runs ->
        expect(symbolsView.loading).toBeEmpty()
        expect(symbolsView.list.children('li').length).toBe 2
        expect(symbolsView.generateTags).toHaveBeenCalled()
        editor.destroy()
        expect(symbolsView.cachedTags).toEqual {}

    it "displays an error when no tags match text in mini-editor", ->
      runs ->
        atom.commands.dispatch(getEditorView(), "symbols-view:toggle-file-symbols")

      waitsForPromise ->
        activationPromise

      runs ->
        symbolsView = $(getWorkspaceView()).find('.symbols-view').view()

      waitsFor ->
        symbolsView.list.children('li').length > 0

      runs ->
        symbolsView.filterEditorView.setText("nothing will match this")
        window.advanceClock(symbolsView.inputThrottle)

        expect($(getWorkspaceView()).find('.symbols-view')).toExist()
        expect(symbolsView.list.children('li').length).toBe 0
        expect(symbolsView.error).toBeVisible()
        expect(symbolsView.error.text().length).toBeGreaterThan 0

        # Should remove error
        symbolsView.filterEditorView.setText("")
        window.advanceClock(symbolsView.inputThrottle)

        expect(symbolsView.list.children('li').length).toBe 2
        expect(symbolsView.error).not.toBeVisible()

    it "moves the cursor to the selected function", ->
      runs ->
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual [0, 0]
        expect($(getWorkspaceView()).find('.symbols-view')).not.toExist()
        atom.commands.dispatch(getEditorView(), "symbols-view:toggle-file-symbols")

      waitsFor ->
        $(getWorkspaceView()).find('.symbols-view').find('li').length

      runs ->
        $(getWorkspaceView()).find('.symbols-view').find('li:eq(1)').mousedown().mouseup()
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual [1, 2]

  describe "when tags can't be generated for a file", ->
    beforeEach ->
      waitsForPromise ->
        atom.workspace.open('sample.txt')

    it "shows an error message when no matching tags are found", ->
      runs ->
        atom.commands.dispatch(getEditorView(), "symbols-view:toggle-file-symbols")

      waitsForPromise ->
        activationPromise

      runs ->
        symbolsView = $(getWorkspaceView()).find('.symbols-view').view()

      waitsFor ->
        symbolsView.error.isVisible()

      runs ->
        expect(symbolsView).toExist()
        expect(symbolsView.list.children('li').length).toBe 0
        expect(symbolsView.error).toBeVisible()
        expect(symbolsView.error.text().length).toBeGreaterThan 0
        expect(symbolsView.loadingArea).not.toBeVisible()

  describe "TagGenerator", ->
    it "generates tags for all JavaScript functions", ->
      tags = []

      waitsForPromise ->
        sampleJsPath = directory.resolve('sample.js')
        new TagGenerator(sampleJsPath).generate().then (o) -> tags = o

      runs ->
        expect(tags.length).toBe 2
        expect(tags[0].name).toBe "quicksort"
        expect(tags[0].position.row).toBe 0
        expect(tags[1].name).toBe "quicksort.sort"
        expect(tags[1].position.row).toBe 1

    it "generates no tags for text file", ->
      tags = []

      waitsForPromise ->
        sampleJsPath = directory.resolve('sample.txt')
        new TagGenerator(sampleJsPath).generate().then (o) -> tags = o

      runs ->
        expect(tags.length).toBe 0

  describe "go to declaration", ->
    it "doesn't move the cursor when no declaration is found", ->
      waitsForPromise ->
        atom.workspace.open(directory.resolve("tagged.js"))

      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setCursorBufferPosition([0, 2])
        atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration')

      waitsForPromise ->
        activationPromise

      runs ->
        expect(editor.getCursorBufferPosition()).toEqual [0, 2]

    it "moves the cursor to the declaration when there is a single matching declaration", ->
      waitsForPromise ->
        atom.workspace.open(directory.resolve("tagged.js"))

      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setCursorBufferPosition([6, 24])
        spyOn(SymbolsView.prototype, "moveToPosition").andCallThrough()
        atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration')

      waitsFor ->
        SymbolsView::moveToPosition.callCount is 1

      runs ->
        expect(editor.getCursorBufferPosition()).toEqual [2, 0]

    it "displays matches when more than one exists and opens the selected match", ->
      waitsForPromise ->
        atom.workspace.open(directory.resolve("tagged.js"))

      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setCursorBufferPosition([8, 14])
        atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration')

      waitsFor ->
        $(getWorkspaceView()).find('.symbols-view').find('li').length > 0

      runs ->
        symbolsView = $(getWorkspaceView()).find('.symbols-view').view()
        expect(symbolsView.list.children('li').length).toBe 2
        expect(symbolsView).toBeVisible()
        spyOn(SymbolsView.prototype, "moveToPosition").andCallThrough()
        symbolsView.confirmed(symbolsView.items[0])

      waitsFor ->
        SymbolsView::moveToPosition.callCount is 1

      runs ->
        expect(atom.workspace.getActiveTextEditor().getPath()).toBe directory.resolve("tagged-duplicate.js")
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual [0, 4]

    it "moves the cursor to the declaration if the tags are numbered instead of patterned", ->
      atom.project.setPaths([temp.mkdirSync("atom-symbols-view-js-excmd-number-")])
      fs.copySync(path.join(__dirname, "fixtures", "js-excmd-number"), atom.project.getPaths()[0])

      waitsForPromise ->
        atom.workspace.open "sorry.js"

      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setCursorBufferPosition([9, 16])
        spyOn(SymbolsView.prototype, "moveToPosition").andCallThrough()
        atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration')

      waitsFor ->
        SymbolsView::moveToPosition.callCount is 1

      runs ->
        expect(editor.getCursorBufferPosition()).toEqual [6, 0]

    it "includes ? and ! characters in ruby symbols", ->
      atom.project.setPaths([temp.mkdirSync("atom-symbols-view-ruby-")])
      fs.copySync(path.join(__dirname, 'fixtures', 'ruby'), atom.project.getPaths()[0])

      waitsForPromise ->
        atom.packages.activatePackage('language-ruby')

      waitsForPromise ->
        atom.workspace.open 'file1.rb'

      runs ->
        spyOn(SymbolsView.prototype, "moveToPosition").andCallThrough()
        atom.workspace.getActiveTextEditor().setCursorBufferPosition([13, 4])
        atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration')

      waitsForPromise ->
        activationPromise

      waitsFor ->
        SymbolsView::moveToPosition.callCount is 1

      runs ->
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual [5, 2]
        SymbolsView::moveToPosition.reset()
        atom.workspace.getActiveTextEditor().setCursorBufferPosition([14, 2])
        atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration')

      waitsFor ->
        SymbolsView::moveToPosition.callCount is 1

      runs ->
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual [9, 2]
        SymbolsView::moveToPosition.reset()
        atom.workspace.getActiveTextEditor().setCursorBufferPosition([15, 5])
        atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration')

      waitsFor ->
        SymbolsView::moveToPosition.callCount is 1

      runs ->
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual [1, 2]

    describe "return from declaration", ->
      it "doesn't do anything when no go-to have been triggered", ->
        waitsForPromise ->
          atom.workspace.open(directory.resolve("tagged.js"))

        runs ->
          editor = atom.workspace.getActiveTextEditor()
          editor.setCursorBufferPosition([6, 0])
          atom.commands.dispatch(getEditorView(), 'symbols-view:return-from-declaration')

        waitsForPromise ->
          activationPromise

        runs ->
          expect(editor.getCursorBufferPosition()).toEqual [6, 0]

      it "returns to previous row and column", ->
        waitsForPromise ->
          atom.workspace.open(directory.resolve("tagged.js"))

        runs ->
          editor = atom.workspace.getActiveTextEditor()
          editor.setCursorBufferPosition([6, 24])
          spyOn(SymbolsView.prototype, "moveToPosition").andCallThrough()
          atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration')

        waitsForPromise ->
          activationPromise

        waitsFor ->
          SymbolsView::moveToPosition.callCount is 1

        runs ->
          expect(editor.getCursorBufferPosition()).toEqual [2, 0]
          atom.commands.dispatch(getEditorView(), 'symbols-view:return-from-declaration')

        waitsFor ->
          SymbolsView::moveToPosition.callCount is 2

        runs ->
          expect(editor.getCursorBufferPosition()).toEqual [6, 24]

    describe "when the tag is in a file that doesn't exist", ->
      it "doesn't display the tag", ->
        fs.removeSync(directory.resolve("tagged-duplicate.js"))

        waitsForPromise ->
          atom.workspace.open(directory.resolve("tagged.js"))

        runs ->
          editor = atom.workspace.getActiveTextEditor()
          editor.setCursorBufferPosition([8, 14])
          spyOn(SymbolsView.prototype, "moveToPosition").andCallThrough()
          atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration')

        waitsFor ->
          SymbolsView::moveToPosition.callCount is 1

        runs ->
          expect(editor.getCursorBufferPosition()).toEqual [8, 0]

  describe "project symbols", ->
    it "displays all tags", ->
      jasmine.unspy(window, 'setTimeout')

      waitsForPromise ->
        atom.workspace.open(directory.resolve("tagged.js"))

      runs ->
        expect($(getWorkspaceView()).find('.symbols-view')).not.toExist()
        atom.commands.dispatch(getWorkspaceView(), "symbols-view:toggle-project-symbols")

      waitsForPromise ->
        activationPromise

      runs ->
        symbolsView = $(getWorkspaceView()).find('.symbols-view').view()

      waitsFor "loading", ->
        symbolsView.setLoading.callCount > 1

      waitsFor ->
        symbolsView.list.children('li').length > 0

      runs ->
        directoryBasename = path.basename(directory.getPath())
        expect(symbolsView.loading).toBeEmpty()
        expect($(getWorkspaceView()).find('.symbols-view')).toExist()
        expect(symbolsView.list.children('li').length).toBe 4
        expect(symbolsView.list.children('li:first').find('.primary-line')).toHaveText 'callMeMaybe'
        expect(symbolsView.list.children('li:first').find('.secondary-line')).toHaveText path.join(directoryBasename, 'tagged.js')
        expect(symbolsView.list.children('li:last').find('.primary-line')).toHaveText 'thisIsCrazy'
        expect(symbolsView.list.children('li:last').find('.secondary-line')).toHaveText path.join(directoryBasename, 'tagged.js')
        expect(symbolsView.error).not.toBeVisible()
        atom.commands.dispatch(getWorkspaceView(), "symbols-view:toggle-project-symbols")

        fs.removeSync(directory.resolve('tags'))

      waitsFor ->
        symbolsView.reloadTags

      runs ->
        atom.commands.dispatch(getWorkspaceView(), "symbols-view:toggle-project-symbols")

      waitsFor ->
        symbolsView.error.text().length > 0

      runs ->
        expect(symbolsView.list.children('li').length).toBe 0

    describe "when there is only one project", ->
      beforeEach ->
        atom.project.setPaths([directory.getPath()])

      it "does not include the root directory's name when displaying the tag's filename", ->
        jasmine.unspy(window, 'setTimeout')

        waitsForPromise ->
          atom.workspace.open(directory.resolve("tagged.js"))

        runs ->
          expect($(getWorkspaceView()).find('.symbols-view')).not.toExist()
          atom.commands.dispatch(getWorkspaceView(), "symbols-view:toggle-project-symbols")

        waitsForPromise ->
          activationPromise

        runs ->
          symbolsView = $(getWorkspaceView()).find('.symbols-view').view()

        waitsFor ->
          symbolsView.list.children('li').length > 0

        runs ->
          expect(symbolsView.list.children('li:first').find('.primary-line')).toHaveText 'callMeMaybe'
          expect(symbolsView.list.children('li:first').find('.secondary-line')).toHaveText 'tagged.js'

    describe "when selecting a tag", ->
      describe "when the file doesn't exist", ->
        beforeEach ->
          fs.removeSync(directory.resolve("tagged.js"))

        it "doesn't open the editor", ->
          atom.commands.dispatch(getWorkspaceView(), "symbols-view:toggle-project-symbols")

          waitsForPromise ->
            activationPromise

          runs ->
            symbolsView = $(getWorkspaceView()).find('.symbols-view').view()

          waitsFor ->
            symbolsView.list.children('li').length > 0

          runs ->
            spyOn(atom.workspace, 'open').andCallThrough()
            symbolsView.list.children('li:first').mousedown().mouseup()
            expect(atom.workspace.open).not.toHaveBeenCalled()
            expect(symbolsView.error.text().length).toBeGreaterThan 0

  describe "when useEditorGrammarAsCtagsLanguage is set to true", ->
    it "uses the language associated with the editor's grammar", ->
      atom.config.set('symbols-view.useEditorGrammarAsCtagsLanguage', true)

      waitsForPromise ->
        atom.packages.activatePackage('language-javascript')

      waitsForPromise ->
        atom.workspace.open('sample.javascript')

      runs ->
        atom.workspace.getActiveTextEditor().setText("var test = function() {}")
        atom.workspace.getActiveTextEditor().save()
        atom.commands.dispatch(getEditorView(), "symbols-view:toggle-file-symbols")

      waitsForPromise ->
        activationPromise

      waitsFor ->
        $(getWorkspaceView()).find('.symbols-view').view().error.isVisible()

      runs ->
        atom.commands.dispatch(getEditorView(), "symbols-view:toggle-file-symbols")
        atom.workspace.getActiveTextEditor().setGrammar(atom.grammars.grammarForScopeName('source.js'))
        symbolsView.setLoading.reset()
        atom.commands.dispatch(getEditorView(), "symbols-view:toggle-file-symbols")
        symbolsView = $(getWorkspaceView()).find('.symbols-view').view()

      waitsFor "loading", ->
        symbolsView.setLoading.callCount > 1

      waitsFor ->
        symbolsView.list.children('li').length is 1

      runs ->
        expect(symbolsView.loading).toBeEmpty()
        expect($(getWorkspaceView()).find('.symbols-view')).toExist()
        expect(symbolsView.list.children('li:first').find('.primary-line')).toHaveText 'test'
        expect(symbolsView.list.children('li:first').find('.secondary-line')).toHaveText 'Line 1'

  describe "match highlighting", ->
    beforeEach ->
      waitsForPromise ->
        atom.workspace.open(directory.resolve('sample.js'))

    it "highlights an exact match", ->
      runs ->
        atom.commands.dispatch(getEditorView(), "symbols-view:toggle-file-symbols")

      waitsForPromise ->
        activationPromise

      runs ->
        symbolsView = $(getWorkspaceView()).find('.symbols-view').view()

      waitsFor ->
        symbolsView.list.children('li').length > 0

      runs ->
        symbolsView.filterEditorView.getModel().setText('quicksort')
        expect(symbolsView.filterEditorView.getModel().getText()).toBe 'quicksort'
        symbolsView.populateList()
        resultView = symbolsView.getSelectedItemView()

        matches = resultView.find('.character-match')
        expect(matches.length).toBe 1
        expect(matches.last().text()).toBe 'quicksort'

    it "highlights a partial match", ->
      runs ->
        atom.commands.dispatch(getEditorView(), "symbols-view:toggle-file-symbols")

      waitsForPromise ->
        activationPromise

      runs ->
        symbolsView = $(getWorkspaceView()).find('.symbols-view').view()

      waitsFor ->
        symbolsView.list.children('li').length > 0

      runs ->
        symbolsView.filterEditorView.getModel().setText('quick')
        symbolsView.populateList()
        resultView = symbolsView.getSelectedItemView()

        matches = resultView.find('.character-match')
        expect(matches.length).toBe 1
        expect(matches.last().text()).toBe 'quick'

    it "highlights multiple matches in the symbol name", ->
      runs ->
        atom.commands.dispatch(getEditorView(), "symbols-view:toggle-file-symbols")

      waitsForPromise ->
        activationPromise

      runs ->
        symbolsView = $(getWorkspaceView()).find('.symbols-view').view()

      waitsFor ->
        symbolsView.list.children('li').length > 0

      runs ->
        symbolsView.filterEditorView.getModel().setText('quicort')
        symbolsView.populateList()
        resultView = symbolsView.getSelectedItemView()

        matches = resultView.find('.character-match')
        expect(matches.length).toBe 2
        expect(matches.first().text()).toBe 'quic'
        expect(matches.last().text()).toBe 'ort'

  describe "quickjump to symbol", ->
    beforeEach ->
      waitsForPromise ->
        atom.workspace.open(directory.resolve('sample.js'))

    it "jumps to the selected function", ->
      runs ->
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual [0, 0]
        atom.commands.dispatch(getEditorView(), "symbols-view:toggle-file-symbols")

      waitsForPromise ->
        activationPromise

      runs ->
        symbolsView = $(getWorkspaceView()).find('.symbols-view').view()

      waitsFor ->
        symbolsView.list.children('li').length > 0

      runs ->
        symbolsView.selectNextItemView()
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual [1, 2]

    it "restores previous editor state on cancel", ->
      bufferRanges = [{start: {row: 0, column: 0}, end: {row: 0, column: 3}}]

      runs ->
        atom.workspace.getActiveTextEditor().setSelectedBufferRanges bufferRanges
        atom.commands.dispatch(getEditorView(), "symbols-view:toggle-file-symbols")

      waitsForPromise ->
        activationPromise

      runs ->
        symbolsView = $(getWorkspaceView()).find('.symbols-view').view()

      waitsFor ->
        symbolsView.list.children('li').length > 0

      runs ->
        symbolsView.selectNextItemView()
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual [1, 2]
        symbolsView.cancel()
        expect(atom.workspace.getActiveTextEditor().getSelectedBufferRanges()).toEqual bufferRanges
