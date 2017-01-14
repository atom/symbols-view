import {CompositeDisposable} from 'atom';
import SymbolsView from './symbols-view';
import TagGenerator from './tag-generator';
import {match} from 'fuzzaldrin';

// TODO: remove references to logical display buffer when it is released.

export default class FileView extends SymbolsView {
  constructor(stack) {
    super(stack);
    this.cachedTags = {};

    this.editorsSubscription = atom.workspace.observeTextEditors(editor => {
      const removeFromCache = () => {
        delete this.cachedTags[editor.getPath()];
      };
      const editorSubscriptions = new CompositeDisposable();
      editorSubscriptions.add(editor.onDidChangeGrammar(removeFromCache));
      editorSubscriptions.add(editor.onDidSave(removeFromCache));
      editorSubscriptions.add(editor.onDidChangePath(removeFromCache));
      editorSubscriptions.add(editor.getBuffer().onDidReload(removeFromCache));
      editorSubscriptions.add(editor.getBuffer().onDidDestroy(removeFromCache));
      editor.onDidDestroy(() => {
        editorSubscriptions.dispose();
      });
    });
  }

  destroy() {
    this.editorsSubscription.dispose();
    super.destroy();
  }

  elementForItem(item) {
    // Style matched characters in search results
    item.matches = match(item.name, this.selectListView.getQuery());
    const primaryContent = this.highlightMatches(item);

    const li = document.createElement('li');
    li.classList.add('two-lines');

    const primaryLine = document.createElement('div');
    primaryLine.classList.add('primary-line');
    primaryLine.innerHTML = primaryContent;
    li.appendChild(primaryLine);

    const secondaryLine = document.createElement('div');
    secondaryLine.classList.add('secondary-line');
    secondaryLine.textContent = `Line ${item.position.row + 1}`;
    li.appendChild(secondaryLine);

    return li;
  }

  selectItemView(...args) {
    super.selectItemView(...args);
    if (atom.config.get('symbols-view.quickJumpToFileSymbol')) {
      const item = this.getSelectedItem();
      if (item != null) {
        this.openTag(item);
      }
    }
  }

  cancel() {
    super.cancel();
    const editor = this.getEditor();
    if (this.initialState && editor) {
      this.deserializeEditorState(editor, this.initialState);
    }
    this.initialState = null;
  }

  async toggle() {
    if (this.panel) {
      this.cancel();
      return;
    }
    const filePath = this.getPath();
    if (filePath) {
      const editor = this.getEditor();
      if (atom.config.get('symbols-view.quickJumpToFileSymbol') && editor) {
        this.initialState = this.serializeEditorState(editor);
      }
      this.populate(filePath);
      await this.selectListView.update();
      this.attach();
    }
  }

  serializeEditorState(editor) {
    let scrollTop;
    const editorElement = atom.views.getView(editor);
    if (editorElement.logicalDisplayBuffer) {
      scrollTop = editorElement.getScrollTop();
    } else {
      scrollTop = editor.getScrollTop();
    }

    return {
      bufferRanges: editor.getSelectedBufferRanges(),
      scrollTop,
    };
  }

  deserializeEditorState(editor, {bufferRanges, scrollTop}) {
    const editorElement = atom.views.getView(editor);

    editor.setSelectedBufferRanges(bufferRanges);
    if (editorElement.logicalDisplayBuffer) {
      return editorElement.setScrollTop(scrollTop);
    } else {
      return editor.setScrollTop(scrollTop);
    }
  }

  getEditor() {
    return atom.workspace.getActiveTextEditor();
  }

  getPath() {
    const editor = this.getEditor();
    if (editor) {
      return editor.getPath();
    }
    return undefined;
  }

  getScopeName() {
    const editor = this.getEditor();
    if (editor) {
      const grammar = editor.getGrammar();
      if (grammar) {
        return grammar.scopeName;
      }
    }
    return undefined;
  }

  populate(filePath) {
    const tags = this.cachedTags[filePath];
    const list = this.selectListView.refs.items;
    if (list && list.childNodes.length > 0) {
      list.innerHTML = '';
    }
    this.setLoading('Generating symbols\u2026');
    if (tags) {
      this.setMaxItems(Infinity);
      this.setItems(tags);
    } else {
      this.generateTags(filePath);
    }
  }

  generateTags(filePath) {
    return new TagGenerator(filePath, this.getScopeName()).generate().then(tags => {
      this.cachedTags[filePath] = tags;
      this.setMaxItems(Infinity);
      this.setItems(tags);
    });
  }
}
