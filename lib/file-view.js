'use babel'

import { $$ } from 'atom-space-pen-views'
import { CompositeDisposable } from 'atom'
import SymbolsView from './symbols-view'
import TagGenerator from './tag-generator'
import { match } from 'fuzzaldrin'

// TODO: remove references to logical display buffer when it is released.

export default class FileView extends SymbolsView {
  initialize () {
    super.initialize(...arguments)

    this.cachedTags = {}

    this.editorsSubscription = atom.workspace.observeTextEditors(editor => {
      const removeFromCache = () => {
        delete this.cachedTags[editor.getPath()]
      }
      const editorSubscriptions = new CompositeDisposable()
      editorSubscriptions.add(editor.onDidChangeGrammar(removeFromCache))
      editorSubscriptions.add(editor.onDidSave(removeFromCache))
      editorSubscriptions.add(editor.onDidChangePath(removeFromCache))
      editorSubscriptions.add(editor.getBuffer().onDidReload(removeFromCache))
      editorSubscriptions.add(editor.getBuffer().onDidDestroy(removeFromCache))
      editor.onDidDestroy(() => {
        editorSubscriptions.dispose()
      })
    })
  }

  destroy () {
    this.editorsSubscription.dispose()
    super.destroy(...arguments)
  }

  viewForItem ({position, name}) {
    // Style matched characters in search results
    const matches = match(name, this.getFilterQuery())

    return $$(function () {
      return this.li({class: 'two-lines'}, () => {
        this.div({class: 'primary-line'}, () => FileView.highlightMatches(this, name, matches))
        return this.div(`Line ${position.row + 1}`, {class: 'secondary-line'})
      })
    })
  }

  selectItemView () {
    super.selectItemView(...arguments)
    if (atom.config.get('symbols-view.quickJumpToFileSymbol')) {
      const item = this.getSelectedItem()
      if (item != null) {
        this.openTag(item)
      }
    }
  }

  cancelled () {
    super.cancelled(...arguments)
    const editor = this.getEditor()
    if (this.initialState && editor) {
      this.deserializeEditorState(editor, this.initialState)
    }
    this.initialState = null
  }

  toggle () {
    if (this.panel.isVisible()) {
      this.cancel()
    }
    const filePath = this.getPath()
    if (filePath) {
      const editor = this.getEditor()
      if (atom.config.get('symbols-view.quickJumpToFileSymbol') && editor) {
        this.initialState = this.serializeEditorState(editor)
      }
      this.populate(filePath)
      this.attach()
    }
  }

  serializeEditorState (editor) {
    let scrollTop
    const editorElement = atom.views.getView(editor)
    if (editorElement.logicalDisplayBuffer) {
      scrollTop = editorElement.getScrollTop()
    } else {
      scrollTop = editor.getScrollTop()
    }

    return {
      bufferRanges: editor.getSelectedBufferRanges(),
      scrollTop
    }
  }

  deserializeEditorState (editor, {bufferRanges, scrollTop}) {
    const editorElement = atom.views.getView(editor)

    editor.setSelectedBufferRanges(bufferRanges)
    if (editorElement.logicalDisplayBuffer) {
      return editorElement.setScrollTop(scrollTop)
    } else {
      return editor.setScrollTop(scrollTop)
    }
  }

  getEditor () {
    return atom.workspace.getActiveTextEditor()
  }

  getPath () {
    if (this.getEditor()) {
      return this.getEditor().getPath()
    }
    return undefined
  }

  getScopeName () {
    if (this.getEditor() && this.getEditor().getGrammar()) {
      return this.getEditor().getGrammar().scopeName
    }
    return undefined
  }

  populate (filePath) {
    const tags = this.cachedTags[filePath]
    this.list.empty()
    this.setLoading('Generating symbols\u2026')
    if (tags) {
      this.setMaxItems(Infinity)
      this.setItems(tags)
    } else {
      this.generateTags(filePath)
    }
  }

  generateTags (filePath) {
    return new TagGenerator(filePath, this.getScopeName()).generate().then((tags) => {
      this.cachedTags[filePath] = tags
      this.setMaxItems(Infinity)
      this.setItems(tags)
    })
  }
}
