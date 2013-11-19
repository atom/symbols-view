{fs, RootView} = require 'atom'
SymbolsView = require '../lib/symbols-view'
TagGenerator = require '../lib/tag-generator'

describe "SymbolsView", ->
  [symbolsView, setArraySpy] = []

  beforeEach ->
    window.rootView = new RootView
    atom.activatePackage("symbols-view")

    rootView.attachToDom()
    setArraySpy = spyOn(SymbolsView.prototype, 'setArray').andCallThrough()

    fs.writeFileSync(project.resolve('tagged.js'), fs.readFileSync(project.resolve('tagged-original.js')))
    fs.writeFileSync(project.resolve('tagged-duplicate.js'), fs.readFileSync(project.resolve('tagged-duplicate-original.js')))

  afterEach ->
    fs.removeSync(project.resolve('tagged.js'))
    fs.removeSync(project.resolve('tagged-duplicate.js'))
    setArraySpy.reset()

  describe "when tags can be generated for a file", ->
    it "initially displays all JavaScript functions with line numbers", ->
      rootView.openSync('sample.js')
      rootView.getActiveView().trigger "symbols-view:toggle-file-symbols"
      symbolsView = rootView.find('.symbols-view').view()
      expect(symbolsView.loading).toHaveText 'Generating symbols...'

      waitsFor ->
        setArraySpy.callCount > 0

      runs ->
        expect(symbolsView.loading).toBeEmpty()
        expect(rootView.find('.symbols-view')).toExist()
        expect(symbolsView.list.children('li').length).toBe 2
        expect(symbolsView.list.children('li:first').find('.primary-line')).toHaveText 'quicksort'
        expect(symbolsView.list.children('li:first').find('.secondary-line')).toHaveText 'Line 1'
        expect(symbolsView.list.children('li:last').find('.primary-line')).toHaveText 'quicksort.sort'
        expect(symbolsView.list.children('li:last').find('.secondary-line')).toHaveText 'Line 2'
        expect(symbolsView.error).not.toBeVisible()

    it "caches tags until the buffer changes", ->
      editSession = rootView.openSync('sample.js')
      rootView.getActiveView().trigger "symbols-view:toggle-file-symbols"
      symbolsView = rootView.find('.symbols-view').view()

      waitsFor ->
        setArraySpy.callCount > 0

      runs ->
        setArraySpy.reset()
        symbolsView.cancel()
        spyOn(symbolsView, 'generateTags').andCallThrough()
        rootView.getActiveView().trigger "symbols-view:toggle-file-symbols"

      waitsFor ->
        setArraySpy.callCount > 0

      runs ->
        expect(symbolsView.loading).toBeEmpty()
        expect(symbolsView.list.children('li').length).toBe 2
        expect(symbolsView.generateTags).not.toHaveBeenCalled()
        editSession.getBuffer().emit 'saved'
        setArraySpy.reset()
        symbolsView.cancel()
        rootView.getActiveView().trigger "symbols-view:toggle-file-symbols"

      waitsFor ->
        setArraySpy.callCount > 0

      runs ->
        expect(symbolsView.loading).toBeEmpty()
        expect(symbolsView.list.children('li').length).toBe 2
        expect(symbolsView.generateTags).toHaveBeenCalled()
        editSession.destroy()
        expect(symbolsView.cachedTags).toEqual {}

    it "displays error when no tags match text in mini-editor", ->
      rootView.openSync('sample.js')
      rootView.getActiveView().trigger "symbols-view:toggle-file-symbols"
      symbolsView = rootView.find('.symbols-view').view()

      waitsFor ->
        setArraySpy.callCount > 0

      runs ->
        symbolsView.miniEditor.setText("nothing will match this")
        window.advanceClock(symbolsView.inputThrottle)

        expect(rootView.find('.symbols-view')).toExist()
        expect(symbolsView.list.children('li').length).toBe 0
        expect(symbolsView.error).toBeVisible()
        expect(symbolsView.error.text().length).toBeGreaterThan 0

        # Should remove error
        symbolsView.miniEditor.setText("")
        window.advanceClock(symbolsView.inputThrottle)

        expect(symbolsView.list.children('li').length).toBe 2
        expect(symbolsView.error).not.toBeVisible()

  describe "when tags can't be generated for a file", ->
    it "shows an error message when no matching tags are found", ->
      rootView.openSync('sample.txt')
      rootView.getActiveView().trigger "symbols-view:toggle-file-symbols"
      symbolsView = rootView.find('.symbols-view').view()
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
      path = project.resolve('sample.js')
      new TagGenerator(path).generate().then (o) -> tags = o

    runs ->
      rootView.openSync('sample.js')
      expect(rootView.getActiveView().getCursorBufferPosition()).toEqual [0,0]
      expect(rootView.find('.symbols-view')).not.toExist()
      symbolsView = SymbolsView.activate()
      symbolsView.setArray(tags)
      symbolsView.attach()
      expect(rootView.find('.symbols-view')).toExist()
      symbolsView.confirmed(tags[1])
      expect(rootView.getActiveView().getCursorBufferPosition()).toEqual [1,2]

  describe "TagGenerator", ->
    it "generates tags for all JavaScript functions", ->
      tags = []

      waitsForPromise ->
        path = project.resolve('sample.js')
        new TagGenerator(path).generate().then (o) -> tags = o

      runs ->
        expect(tags.length).toBe 2
        expect(tags[0].name).toBe "quicksort"
        expect(tags[0].position.row).toBe 0
        expect(tags[1].name).toBe "quicksort.sort"
        expect(tags[1].position.row).toBe 1

    it "generates no tags for text file", ->
      tags = []

      waitsForPromise ->
        path = project.resolve('sample.txt')
        new TagGenerator(path).generate().then (o) -> tags = o

      runs ->
        expect(tags.length).toBe 0

  describe "go to declaration", ->
    it "doesn't move the cursor when no declaration is found", ->
      rootView.openSync("tagged.js")
      editor = rootView.getActiveView()
      editor.setCursorBufferPosition([0,2])
      editor.trigger 'symbols-view:go-to-declaration'
      expect(editor.getCursorBufferPosition()).toEqual [0,2]

    it "moves the cursor to the declaration", ->
      rootView.openSync("tagged.js")
      editor = rootView.getActiveView()
      editor.setCursorBufferPosition([6,24])
      spyOn(SymbolsView.prototype, "moveToPosition").andCallThrough()
      editor.trigger 'symbols-view:go-to-declaration'

      waitsFor ->
        SymbolsView.prototype.moveToPosition.callCount == 1

      runs ->
        expect(editor.getCursorBufferPosition()).toEqual [2,0]

    it "displays matches when more than one exists and opens the selected match", ->
      rootView.openSync("tagged.js")
      editor = rootView.getActiveView()
      editor.setCursorBufferPosition([8,14])
      editor.trigger 'symbols-view:go-to-declaration'

      symbolsView = rootView.find('.symbols-view').view()
      expect(symbolsView.list.children('li').length).toBe 2
      expect(symbolsView).toBeVisible()
      spyOn(SymbolsView.prototype, "moveToPosition").andCallThrough()
      symbolsView.confirmed(symbolsView.array[0])

      waitsFor ->
        SymbolsView.prototype.moveToPosition.callCount == 1

      runs ->
        expect(rootView.getActiveView().getPath()).toBe project.resolve("tagged-duplicate.js")
        expect(rootView.getActiveView().getCursorBufferPosition()).toEqual [0,4]

    describe "when the tag is in a file that doesn't exist", ->
      it "doesn't display the tag", ->
        fs.removeSync(project.resolve("tagged-duplicate.js"))
        rootView.openSync("tagged.js")
        editor = rootView.getActiveView()
        editor.setCursorBufferPosition([8,14])
        editor.trigger 'symbols-view:go-to-declaration'
        symbolsView = rootView.find('.symbols-view').view()
        expect(symbolsView.list.children('li').length).toBe 1
        expect(symbolsView.list.children('li:first').find('.primary-line')).toHaveText 'tagged.js'

  describe "project symbols", ->
    it "displays all tags", ->
      rootView.openSync("tagged.js")
      expect(rootView.find('.symbols-view')).not.toExist()
      rootView.trigger "symbols-view:toggle-project-symbols"
      symbolsView = rootView.find('.symbols-view').view()
      expect(symbolsView.loading).toHaveText 'Loading symbols...'

      waitsFor ->
        setArraySpy.callCount > 0

      runs ->
        expect(symbolsView.loading).toBeEmpty()
        expect(rootView.find('.symbols-view')).toExist()
        expect(symbolsView.list.children('li').length).toBe 4
        expect(symbolsView.list.children('li:first').find('.primary-line')).toHaveText 'callMeMaybe'
        expect(symbolsView.list.children('li:first').find('.secondary-line')).toHaveText 'tagged.js'
        expect(symbolsView.list.children('li:last').find('.primary-line')).toHaveText 'thisIsCrazy'
        expect(symbolsView.list.children('li:last').find('.secondary-line')).toHaveText 'tagged.js'
        expect(symbolsView.error).not.toBeVisible()

    describe "when selecting a tag", ->
      describe "when the file doesn't exist", ->
        beforeEach ->
          fs.removeSync(project.resolve("tagged.js"))

        it "doesn't open the editor", ->
          rootView.trigger "symbols-view:toggle-project-symbols"
          symbolsView = rootView.find('.symbols-view').view()

          waitsFor ->
            setArraySpy.callCount > 0

          runs ->
            spyOn(rootView, 'open').andCallThrough()
            symbolsView.list.children('li:first').mousedown().mouseup()
            expect(rootView.open).not.toHaveBeenCalled()
            expect(symbolsView.error.text().length).toBeGreaterThan 0
