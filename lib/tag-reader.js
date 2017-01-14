import {Task} from 'atom';
import ctags from 'ctags';
import async from 'async';
import getTagsFile from './get-tags-file';
import _ from 'underscore-plus';

const handlerPath = require.resolve('./load-tags-handler');

const wordAtCursor = (text, cursorIndex, wordSeparator, noStripBefore) => {
  const beforeCursor = text.slice(0, cursorIndex);
  const afterCursor = text.slice(cursorIndex);
  const beforeCursorWordBegins = noStripBefore ? 0 : beforeCursor.lastIndexOf(wordSeparator) + 1;
  let afterCursorWordEnds = afterCursor.indexOf(wordSeparator);
  if (afterCursorWordEnds === -1) {
    afterCursorWordEnds = afterCursor.length;
  }
  return beforeCursor.slice(beforeCursorWordBegins) + afterCursor.slice(0, afterCursorWordEnds);
};

export default {
  find(editor, callback) {
    let symbol = editor.getSelectedText();
    const symbols = [];

    if (symbol) {
      symbols.push(symbol);
    }

    if (!symbols.length) {
      let nonWordCharacters;
      const cursor = editor.getLastCursor();
      const cursorPosition = cursor.getBufferPosition();
      const scope = cursor.getScopeDescriptor();
      const rubyScopes = scope.getScopesArray().filter(s => /^source\.ruby($|\.)/.test(s));

      const wordRegExp = rubyScopes.length ?
        (nonWordCharacters = atom.config.get('editor.nonWordCharacters', {scope}),
        // Allow special handling for fully-qualified ruby constants
        nonWordCharacters = nonWordCharacters.replace(/:/g, ''),
        new RegExp(`[^\\s${_.escapeRegExp(nonWordCharacters)}]+([!?]|\\s*=>?)?|[<=>]+`, 'g'))
      :
        cursor.wordRegExp();

      const addSymbol = s => {
        if (rubyScopes.length) {
          // Normalize assignment syntax
          if (/\s+=?$/.test(s)) { symbols.push(s.replace(/\s+=$/, '=')); }
          // Strip away assignment & hashrocket syntax
          symbols.push(s.replace(/\s+=>?$/, ''));
        } else {
          symbols.push(s);
        }
      };

      // Can't use `getCurrentWordBufferRange` here because we want to select
      // the last match of the potential 2 matches under cursor.
      editor.scanInBufferRange(wordRegExp, cursor.getCurrentLineBufferRange(), ({range, match}) => {
        if (range.containsPoint(cursorPosition)) {
          symbol = match[0];
          if (rubyScopes.length && symbol.indexOf(':') > -1) {
            const cursorWithinSymbol = cursorPosition.column - range.start.column;
            // Add fully-qualified ruby constant up until the cursor position
            addSymbol(wordAtCursor(symbol, cursorWithinSymbol, ':', true));
            // Additionally, also look up the bare word under cursor
            addSymbol(wordAtCursor(symbol, cursorWithinSymbol, ':'));
          } else {
            addSymbol(symbol);
          }
        }
      });
    }

    if (!symbols.length) {
      process.nextTick(() => {
        callback(null, []);
      });
    }

    async.map(atom.project.getPaths(), (projectPath, done) => {
      const tagsFile = getTagsFile(projectPath);
      let foundTags = [];
      let foundErr = null;
      const detectCallback = () => {
        done(foundErr, foundTags);
      };
      if (!tagsFile) {
        return detectCallback();
      }
        // Find the first symbol in the list that matches a tag
      return async.detectSeries(symbols, (s, doneDetect) => {
        ctags.findTags(tagsFile, s, (err, t) => {
          let tags = t;
          if (!tags) {
            tags = [];
          }
          if (err) {
            foundErr = err;
            doneDetect(false);
          } else if (tags.length) {
            for (const tag of Array.from(tags)) {
              tag.directory = projectPath;
            }
            foundTags = tags;
            doneDetect(true);
          } else {
            doneDetect(false);
          }
        });
      }, detectCallback);
    }, (err, foundTags) => {
      callback(err, _.flatten(foundTags));
    });
  },

  getAllTags(callback) {
    const projectTags = [];
    const task = Task.once(handlerPath, atom.project.getPaths(), () => callback(projectTags));
    task.on('tags', tags => {
      projectTags.push(...tags);
    });
    return task;
  },
};
