import { Task } from 'atom';
import ctags from 'ctags';
import async from 'async';
import getTagsFile from './get-tags-file';
import _ from 'underscore-plus';

let handlerPath = require.resolve('./load-tags-handler');

let wordAtCursor = function(text, cursorIndex, wordSeparator, noStripBefore) {
  let beforeCursor = text.slice(0, cursorIndex);
  let afterCursor = text.slice(cursorIndex);
  let beforeCursorWordBegins = noStripBefore ? 0 : beforeCursor.lastIndexOf(wordSeparator) + 1;
  let afterCursorWordEnds = afterCursor.indexOf(wordSeparator);
  if (afterCursorWordEnds === -1) { afterCursorWordEnds = afterCursor.length; }
  return beforeCursor.slice(beforeCursorWordBegins) + afterCursor.slice(0, afterCursorWordEnds);
};

export default {
  find(editor, callback) {
    let symbol;
    let symbols = [];

    if (symbol = editor.getSelectedText()) {
      symbols.push(symbol);
    }

    if (!symbols.length) {
      let nonWordCharacters;
      let cursor = editor.getLastCursor();
      let cursorPosition = cursor.getBufferPosition();
      let scope = cursor.getScopeDescriptor();
      let rubyScopes = scope.getScopesArray().filter(s => /^source\.ruby($|\.)/.test(s));

      let wordRegExp = rubyScopes.length ?
        (nonWordCharacters = atom.config.get('editor.nonWordCharacters', {scope}),
        // Allow special handling for fully-qualified ruby constants
        nonWordCharacters = nonWordCharacters.replace(/:/g, ''),
        new RegExp(`[^\\s${_.escapeRegExp(nonWordCharacters)}]+([!?]|\\s*=>?)?|[<=>]+`, 'g'))
      :
        cursor.wordRegExp();

      let addSymbol = function(symbol) {
        if (rubyScopes.length) {
          // Normalize assignment syntax
          if (/\s+=?$/.test(symbol)) { symbols.push(symbol.replace(/\s+=$/, '=')); }
          // Strip away assignment & hashrocket syntax
          return symbols.push(symbol.replace(/\s+=>?$/, ''));
        } else {
          return symbols.push(symbol);
        }
      };

      // Can't use `getCurrentWordBufferRange` here because we want to select
      // the last match of the potential 2 matches under cursor.
      editor.scanInBufferRange(wordRegExp, cursor.getCurrentLineBufferRange(), function({range, match}) {
        if (range.containsPoint(cursorPosition)) {
          symbol = match[0];
          if (rubyScopes.length && symbol.indexOf(':') > -1) {
            let cursorWithinSymbol = cursorPosition.column - range.start.column;
            // Add fully-qualified ruby constant up until the cursor position
            addSymbol(wordAtCursor(symbol, cursorWithinSymbol, ':', true));
            // Additionally, also look up the bare word under cursor
            return addSymbol(wordAtCursor(symbol, cursorWithinSymbol, ':'));
          } else {
            return addSymbol(symbol);
          }
        }
        return null;
      });
    }

    if (!symbols.length) {
      return process.nextTick(() => callback(null, []));
    }

    return async.map(
      atom.project.getPaths(),
      function(projectPath, done) {
        let tagsFile = getTagsFile(projectPath);
        let foundTags = [];
        let foundErr = null;
        let detectCallback = () => done(foundErr, foundTags);
        if (tagsFile == null) { return detectCallback(); }
        // Find the first symbol in the list that matches a tag
        return async.detectSeries(symbols,
          (symbol, doneDetect) =>
            ctags.findTags(tagsFile, symbol, function(err, tags) {
              if (tags == null) { tags = []; }
              if (err) {
                foundErr = err;
                return doneDetect(false);
              } else if (tags.length) {
                for (let tag of Array.from(tags)) { tag.directory = projectPath; }
                foundTags = tags;
                return doneDetect(true);
              } else {
                return doneDetect(false);
              }
            })
          ,
          detectCallback);
      },
      (err, foundTags) => callback(err, _.flatten(foundTags)));
  },

  getAllTags(callback) {
    let projectTags = [];
    let task = Task.once(handlerPath, atom.project.getPaths(), () => callback(projectTags));
    task.on('tags', tags => projectTags.push(...tags));
    return task;
  },
};
