'use babel';

import path from 'path';
import { Point } from 'atom';
import { $$, SelectListView } from 'atom-space-pen-views';
import fs from 'fs-plus';
import { match } from 'fuzzaldrin';

export default class SymbolsView extends SelectListView {
  static highlightMatches(context, name, matches, offsetIndex) {
    if (!offsetIndex) {
      offsetIndex = 0;
    }
    let lastIndex = 0;
    let matchedChars = []; // Build up a set of matched chars to be more semantic

    for (let matchIndex of Array.from(matches)) {
      matchIndex -= offsetIndex;
      if (matchIndex < 0) {
        // If marking up the basename, omit name matches
        continue;
      }
      const unmatched = name.substring(lastIndex, matchIndex);
      if (unmatched) {
        if (matchedChars.length) {
          context.span(matchedChars.join(''), {class: 'character-match'});
        }
        matchedChars = [];
        context.text(unmatched);
      }
      matchedChars.push(name[matchIndex]);
      lastIndex = matchIndex + 1;
    }

    if (matchedChars.length) {
      context.span(matchedChars.join(''), {class: 'character-match'});
    }

    // Remaining characters are plain text
    return context.text(name.substring(lastIndex));
  }

  initialize(stack) {
    this.stack = stack;
    super.initialize(...arguments);
    this.panel = atom.workspace.addModalPanel({item: this, visible: false});
    this.addClass('symbols-view');
  }

  destroy() {
    this.cancel();
    this.panel.destroy();
  }

  getFilterKey() { return 'name'; }

  viewForItem({position, name, file, directory}) {
    // Style matched characters in search results
    const matches = match(name, this.getFilterQuery());

    if (atom.project.getPaths().length > 1) {
      file = path.join(path.basename(directory), file);
    }

    return $$(() => {
      return this.li({class: 'two-lines'}, () => {
        if (position) {
          this.div(`${name}:${position.row + 1}`, {class: 'primary-line'});
        } else {
          this.div({class: 'primary-line'}, () => SymbolsView.highlightMatches(this, name, matches));
        }
        return this.div(file, {class: 'secondary-line'});
      }
      );
    });
  }

  getEmptyMessage(itemCount) {
    if (itemCount === 0) {
      return 'No symbols found';
    } else {
      return super.getEmptyMessage(...arguments);
    }
  }

  cancelled() {
    return this.panel.hide();
  }

  confirmed(tag) {
    if (tag.file && !fs.isFileSync(path.join(tag.directory, tag.file))) {
      this.setError('Selected file does not exist');
      return setTimeout(() => this.setError(), 2000);
    } else {
      this.cancel();
      return this.openTag(tag);
    }
  }

  openTag(tag) {
    let editor, previous;
    if (editor = atom.workspace.getActiveTextEditor()) {
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
    if (!beginningOfLine) {
      beginningOfLine = true;
    }
    const editor = atom.workspace.getActiveTextEditor();
    if (editor) {
      editor.scrollToBufferPosition(position, {center: true});
      editor.setCursorBufferPosition(position);
      if (beginningOfLine) {
        editor.moveToFirstCharacterOfLine();
      }
    }
  }

  attach() {
    this.storeFocusedElement();
    this.panel.show();
    this.focusFilterEditor();
  }

  getTagLine(tag) {
    // Remove leading /^ and trailing $/
    let pattern = tag.pattern;
    if (pattern) {
      pattern = pattern.replace(/(^^\/\^)|(\$\/$)/g, '').trim();
    } else {
      return null;
    }

    const file = path.join(tag.directory, tag.file);
    if (!fs.isFileSync(file)) {
      return null;
    }
    const iterable = fs.readFileSync(file, 'utf8').split('\n');
    for (let index = 0; index < iterable.length; index++) {
      let line = iterable[index];
      if (pattern === line.trim()) {
        return new Point(index, 0);
      }
    }
    return null;
  }
}
