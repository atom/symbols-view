path = require 'path'
{WorkspaceView} = require 'atom'
fs = require 'fs-plus'
temp = require 'temp'
SymbolsView = require '../lib/symbols-view'
TagGenerator = require '../lib/tag-generator'

describe "SymbolsView", ->
  [symbolsView, setItemsSpy, setErrorSpy, activationPromise] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.project.setPath(temp.mkdirSync('atom-symbols-view-'))
    fs.copySync(path.join(__dirname, 'fixtures'), atom.project.getPath())

    activationPromise = atom.packages.activatePackage("symbols-view")

    atom.workspaceView.attachToDom()
    setItemsSpy = spyOn(SymbolsView.prototype, 'setItems').andCallThrough()

  describe "when tags can be generated for a file", ->
    it "initially displays all JavaScript functions with line numbers", ->
      atom.workspaceView.openSync('sample.js')
      atom.workspaceView.getActiveView().trigger "symbols-view:toggle-file-symbols"

      waitsForPromise ->
        activationPromise

      runs ->
        symbolsView = atom.workspaceView.find('.symbols-view').view()
        expect(symbolsView.loading).toHaveText 'Generating symbols...'

      waitsFor ->
        setItemsSpy.callCount > 0

      runs ->
        expect(symbolsView.loading).toBeEmpty()
        expect(atom.workspaceView.find('.symbols-view')).toExist()
        expect(symbolsView.list.children('li').length).toBe 2
        expect(symbolsView.list.children('li:first').find('.primary-line')).toHaveText 'quicksort'
        expect(symbolsView.list.children('li:first').find('.secondary-line')).toHaveText 'Line 1'
        expect(symbolsView.list.children('li:last').find('.primary-line')).toHaveText 'quicksort.sort'
        expect(symbolsView.list.children('li:last').find('.secondary-line')).toHaveText 'Line 2'
        expect(symbolsView.error).not.toBeVisible()

    it "caches tags until the buffer changes", ->
      editor = atom.workspaceView.openSync('sample.js')
      atom.workspaceView.getActiveView().trigger "symbols-view:toggle-file-symbols"

      waitsForPromise ->
        activationPromise

      runs ->
        symbolsView = atom.workspaceView.find('.symbols-view').view()

      waitsFor ->
        setItemsSpy.callCount > 0

      runs ->
        setItemsSpy.reset()
        symbolsView.cancel()
        spyOn(symbolsView, 'generateTags').andCallThrough()
        atom.workspaceView.getActiveView().trigger "symbols-view:toggle-file-symbols"

      waitsFor ->
        setItemsSpy.callCount > 0

      runs ->
        expect(symbolsView.loading).toBeEmpty()
        expect(symbolsView.list.children('li').length).toBe 2
        expect(symbolsView.generateTags).not.toHaveBeenCalled()
        editor.getBuffer().emit 'saved'
        setItemsSpy.reset()
        symbolsView.cancel()
        atom.workspaceView.getActiveView().trigger "symbols-view:toggle-file-symbols"

      waitsFor ->
        setItemsSpy.callCount > 0

      runs ->
        expect(symbolsView.loading).toBeEmpty()
        expect(symbolsView.list.children('li').length).toBe 2
        expect(symbolsView.generateTags).toHaveBeenCalled()
        editor.destroy()
        expect(symbolsView.cachedTags).toEqual {}

    it "displays error when no tags match text in mini-editor", ->
      atom.workspaceView.openSync('sample.js')
      atom.workspaceView.getActiveView().trigger "symbols-view:toggle-file-symbols"

      waitsForPromise ->
        activationPromise

      runs ->
        symbolsView = atom.workspaceView.find('.symbols-view').view()

      waitsFor ->
        setItemsSpy.callCount > 0

      runs ->
        symbolsView.filterEditorView.setText("nothing will match this")
        window.advanceClock(symbolsView.inputThrottle)

        expect(atom.workspaceView.find('.symbols-view')).toExist()
        expect(symbolsView.list.children('li').length).toBe 0
        expect(symbolsView.error).toBeVisible()
        expect(symbolsView.error.text().length).toBeGreaterThan 0

        # Should remove error
        symbolsView.filterEditorView.setText("")
        window.advanceClock(symbolsView.inputThrottle)

        expect(symbolsView.list.children('li').length).toBe 2
        expect(symbolsView.error).not.toBeVisible()

  describe "when tags can't be generated for a file", ->
    it "shows an error message when no matching tags are found", ->
      atom.workspaceView.openSync('sample.txt')
      atom.workspaceView.getActiveView().trigger "symbols-view:toggle-file-symbols"

      waitsForPromise ->
        activationPromise

      runs ->
        symbolsView = atom.workspaceView.find('.symbols-view').view()
        setErrorSpy = spyOn(symbolsView, "setError").andCallThrough()

      waitsFor ->
        setErrorSpy.callCount > 0

      runs ->
        expect(symbolsView).toExist()
        expect(symbolsView.list.children('li').length).toBe 0
        expect(symbolsView.error).toBeVisible()
        expect(symbolsView.error.text().length).toBeGreaterThan 0
        expect(symbolsView.loadingArea).not.toBeVisible()

  it "moves the cursor to the selected function", ->
    tags = []

    waitsForPromise ->
      sampleJsPath = atom.project.resolve('sample.js')
      new TagGenerator(sampleJsPath).generate().then (o) -> tags = o

    runs ->
      atom.workspaceView.openSync('sample.js')
      expect(atom.workspaceView.getActivePaneItem().getCursorBufferPosition()).toEqual [0,0]
      expect(atom.workspaceView.find('.symbols-view')).not.toExist()
      symbolsView = SymbolsView.activate()
      symbolsView.setItems(tags)
      symbolsView.attach()
      expect(atom.workspaceView.find('.symbols-view')).toExist()
      symbolsView.confirmed(tags[1])
      expect(atom.workspaceView.getActivePaneItem().getCursorBufferPosition()).toEqual [1,2]

  describe "TagGenerator", ->
    it "generates tags for all JavaScript functions", ->
      tags = []

      waitsForPromise ->
        sampleJsPath = atom.project.resolve('sample.js')
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
        sampleJsPath = atom.project.resolve('sample.txt')
        new TagGenerator(sampleJsPath).generate().then (o) -> tags = o

      runs ->
        expect(tags.length).toBe 0

  describe "go to declaration", ->
    it "doesn't move the cursor when no declaration is found", ->
      atom.workspaceView.openSync("tagged.js")
      editor = atom.workspaceView.getActivePaneItem()
      editor.setCursorBufferPosition([0,2])
      atom.workspaceView.getActiveView().trigger 'symbols-view:go-to-declaration'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(editor.getCursorBufferPosition()).toEqual [0,2]

    it "moves the cursor to the declaration", ->
      atom.workspaceView.openSync("tagged.js")
      editor = atom.workspaceView.getActivePaneItem()
      editor.setCursorBufferPosition([6,24])
      spyOn(SymbolsView.prototype, "moveToPosition").andCallThrough()
      atom.workspaceView.getActiveView().trigger 'symbols-view:go-to-declaration'

      waitsForPromise ->
        activationPromise

      waitsFor ->
        SymbolsView.prototype.moveToPosition.callCount == 1

      runs ->
        expect(editor.getCursorBufferPosition()).toEqual [2,0]

    it "displays matches when more than one exists and opens the selected match", ->
      atom.workspaceView.openSync("tagged.js")
      editor = atom.workspaceView.getActivePaneItem()
      editor.setCursorBufferPosition([8,14])
      atom.workspaceView.getActiveView().trigger 'symbols-view:go-to-declaration'

      waitsForPromise ->
        activationPromise

      runs ->
        symbolsView = atom.workspaceView.find('.symbols-view').view()
        expect(symbolsView.list.children('li').length).toBe 2
        expect(symbolsView).toBeVisible()
        spyOn(SymbolsView.prototype, "moveToPosition").andCallThrough()
        symbolsView.confirmed(symbolsView.items[0])

      waitsFor ->
        SymbolsView.prototype.moveToPosition.callCount == 1

      runs ->
        expect(atom.workspaceView.getActivePaneItem().getPath()).toBe atom.project.resolve("tagged-duplicate.js")
        expect(atom.workspaceView.getActivePaneItem().getCursorBufferPosition()).toEqual [0,4]

    describe "when the tag is in a file that doesn't exist", ->
      it "doesn't display the tag", ->
        fs.removeSync(atom.project.resolve("tagged-duplicate.js"))
        atom.workspaceView.openSync("tagged.js")
        editor = atom.workspaceView.getActivePaneItem()
        editor.setCursorBufferPosition([8,14])
        atom.workspaceView.getActiveView().trigger 'symbols-view:go-to-declaration'

        waitsForPromise ->
          activationPromise

        runs ->
          symbolsView = atom.workspaceView.find('.symbols-view').view()
          expect(symbolsView.list.children('li').length).toBe 1
          expect(symbolsView.list.children('li:first').find('.primary-line')).toHaveText 'tagged.js'

  describe "project symbols", ->
    it "displays all tags", ->
      atom.workspaceView.openSync("tagged.js")
      expect(atom.workspaceView.find('.symbols-view')).not.toExist()
      atom.workspaceView.trigger "symbols-view:toggle-project-symbols"

      waitsForPromise ->
        activationPromise

      runs ->
        symbolsView = atom.workspaceView.find('.symbols-view').view()
        expect(symbolsView.loading).toHaveText 'Loading symbols...'

      waitsFor ->
        setItemsSpy.callCount > 0

      runs ->
        expect(symbolsView.loading).toBeEmpty()
        expect(atom.workspaceView.find('.symbols-view')).toExist()
        expect(symbolsView.list.children('li').length).toBe 4
        expect(symbolsView.list.children('li:first').find('.primary-line')).toHaveText 'callMeMaybe'
        expect(symbolsView.list.children('li:first').find('.secondary-line')).toHaveText 'tagged.js'
        expect(symbolsView.list.children('li:last').find('.primary-line')).toHaveText 'thisIsCrazy'
        expect(symbolsView.list.children('li:last').find('.secondary-line')).toHaveText 'tagged.js'
        expect(symbolsView.error).not.toBeVisible()

    describe "when selecting a tag", ->
      describe "when the file doesn't exist", ->
        beforeEach ->
          fs.removeSync(atom.project.resolve("tagged.js"))

        it "doesn't open the editor", ->
          atom.workspaceView.trigger "symbols-view:toggle-project-symbols"

          waitsForPromise ->
            activationPromise

          runs ->
            symbolsView = atom.workspaceView.find('.symbols-view').view()

          waitsFor ->
            setItemsSpy.callCount > 0

          runs ->
            spyOn(atom.workspaceView, 'open').andCallThrough()
            symbolsView.list.children('li:first').mousedown().mouseup()
            expect(atom.workspaceView.open).not.toHaveBeenCalled()
            expect(symbolsView.error.text().length).toBeGreaterThan 0
