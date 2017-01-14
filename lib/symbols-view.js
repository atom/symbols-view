/** @babel */
/** @jsx etch.dom */

import path from 'path';
import {Point} from 'atom';
import SelectListView from 'atom-select-list';
import fs from 'fs-plus';
import match from 'fuzzaldrin';

export default class SymbolsView {
  constructor(stack) {
    this.stack = stack;

    this.selectListView = new SelectListView({
      itemsClassList: ['mark-active'],
      items: [],
      emptyMessage: 'No symbols found',
      filterKeyForItem: () => { return 'name'; },
      elementForItem: item => { return this.elementForItem(item); },
      didCancelSelection: () => { this.cancel(); },
      didConfirmSelection: tag => { this.confirmed(tag); },
    });
    this.selectListView.element.classList.add('symbols-view');
  }

  elementForItem(item) {
    let primaryContent;
    if (item.position) {
      primaryContent = item.name + ':' + (item.position + 1);
    } else {
      // Style matched characters in search results
      item.matches = match(name, this.selectListView.getQuery());
      primaryContent = this.highlightMatches(item);
    }

    if (atom.project.getPaths().length > 1) {
      item.file = path.join(path.basename(item.directory), item.file);
    }

    const li = document.createElement('li');
    li.classList.add('two-lines');

    const primaryLine = document.createElement('div');
    primaryLine.classList.add('primary-line');
    primaryLine.innerHTML = primaryContent;
    li.appendChild(primaryLine);

    const secondaryLine = document.createElement('div');
    secondaryLine.classList.add('secondary-line');
    secondaryLine.textContent = item.file;
    li.appendChild(secondaryLine);

    return li;
  }

  highlightMatches({name, matches}, offsetIndex = 0) {
    let lastIndex = 0;
    let matchedChars = []; // Build up a set of matched chars to be more semantic
    let context = '';
    for (let matchIndex of Array.from(matches)) {
      matchIndex -= offsetIndex;
      if (matchIndex < 0) {
        continue; // If marking up the basename, omit name matches
      }
      const unmatched = name.substring(lastIndex, matchIndex);
      if (unmatched) {
        if (matchedChars.length) {
          context = context + '<span class="character-match">' + matchedChars.join('') + '</span>';
        }
        matchedChars = [];
        context += unmatched;
      }
      matchedChars.push(name[matchIndex]);
      lastIndex = matchIndex + 1;
    }

    if (matchedChars.length) {
      context = context + '<span class="character-match">' + matchedChars.join('') + '</span>';
    }

    context += name.substring(lastIndex);

    // Remaining characters are plain text
    return context;
  }

  setItems(items) {
    if (this.selectListView) {
      this.selectListView.update({items, infoMessage: undefined});
    }
  }

  setMaxItems(max) {
    this.selectListView.update({maxResults: max});
  }

  setError(message) {
    if (message && message.length) {
      this.selectListView.props.errorMessage = message;
    } else {
      delete this.selectListView.props.errorMessage;
    }
    this.selectListView.update();
  }

  setLoading(message = '') {
    if (message && message.length) {
      this.selectListView.props.infoMessage = message;
    } else {
      delete this.selectListView.props.infoMessage;
    }
    this.selectListView.update();
  }

  async toggle() {
    if (this.panel) {
      this.cancel();
    } else {
      await this.selectListView.update();
      this.attach();
    }
  }

  attach() {
    this.previouslyFocusedElement = document.activeElement;
    if (!this.panel) {
      this.panel = atom.workspace.addModalPanel({item: this.selectListView});
    }
    this.selectListView.focus();
    this.selectListView.reset();
  }

  cancel() {
    this.setItems([]);
    if (this.panel) {
      this.panel.destroy();
    }
    this.panel = null;
    if (this.previouslyFocusedElement) {
      this.previouslyFocusedElement.focus();
      this.previouslyFocusedElement = null;
    }
  }

  dispose() {
    this.destroy();
  }

  destroy() {
    this.cancel();
    if (this.selectListView) {
      this.selectListView.destroy();
    }
    this.selectListView = null;
  }

  confirmed(tag) {
    if (tag.file && !fs.isFileSync(path.join(tag.directory, tag.file))) {
      this.setError('Selected file does not exist');
      setTimeout(() => {
        this.setError();
      }, 2000);
    } else {
      this.cancel();
      this.openTag(tag);
    }
  }

  openTag(tag) {
    const editor = atom.workspace.getActiveTextEditor();
    let previous;
    if (editor) {
      previous = {
        editorId: editor.id,
        position: editor.getCursorBufferPosition(),
        file: editor.getURI(),
      };
    }

    let {position} = tag;
    if (!position) {
      position = this.getTagLine(tag);
    }
    if (tag.file) {
      atom.workspace.open(path.join(tag.directory, tag.file)).then(() => {
        if (position) {
          this.moveToPosition(position);
        }
      });
    } else if (position && !(previous.position.isEqual(position))) {
      this.moveToPosition(position);
    }

    this.stack.push(previous);
  }

  moveToPosition(position, beginningOfLine) {
    const editor = atom.workspace.getActiveTextEditor();
    if (editor) {
      editor.scrollToBufferPosition(position, {center: true});
      editor.setCursorBufferPosition(position);
      if (beginningOfLine || beginningOfLine == null) {
        editor.moveToFirstCharacterOfLine();
      }
    }
  }

  getTagLine(tag) {
    // Remove leading /^ and trailing $/
    if (!tag || !tag.pattern) {
      return undefined;
    }
    const pattern = tag.pattern.replace(/(^^\/\^)|(\$\/$)/g, '').trim();

    if (!pattern) {
      return undefined;
    }
    const file = path.join(tag.directory, tag.file);
    if (!fs.isFileSync(file)) {
      return undefined;
    }
    const iterable = fs.readFileSync(file, 'utf8').split('\n');
    for (let index = 0; index < iterable.length; index++) {
      const line = iterable[index];
      if (pattern === line.trim()) {
        return new Point(index, 0);
      }
    }
    return undefined;
  }
}
