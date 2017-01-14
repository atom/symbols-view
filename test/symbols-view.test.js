import sinon from 'sinon';
import path from 'path';
import fs from 'fs-plus';
import temp from 'temp';
import etch from 'etch';
import until from 'test-until';
import {expect} from 'chai';
import SymbolsViewPackage from '../lib/symbols-view-package';

describe('SymbolsView', () => {
  let [symbolsViewPackage, directory] = [];

  beforeEach(() => {
    temp.track();
    atom.project.setPaths([
      temp.mkdirSync('other-dir-'),
      temp.mkdirSync('atom-symbols-view-'),
    ]);

    directory = atom.project.getDirectories()[1];
    fs.copySync(path.join(__dirname, 'fixtures', 'js'), atom.project.getPaths()[1]);
    symbolsViewPackage = new SymbolsViewPackage();
  });

  afterEach(() => {
    if (symbolsViewPackage) {
      symbolsViewPackage.deactivate();
    }
    symbolsViewPackage = null;
    directory = null;
    atom.reset();
  });

  describe('when tags can be generated for a file', () => {
    let [fileView] = [];
    beforeEach(async () => {
      await atom.workspace.open(directory.resolve('sample.js'));
      await symbolsViewPackage.activate();
      fileView = symbolsViewPackage.createFileView();
      sinon.spy(fileView, 'setItems');
      sinon.spy(fileView, 'generateTags');
    });

    afterEach(() => {
      if (fileView) {
        fileView.setItems.restore();
        fileView.generateTags.restore();
        fileView.dispose();
      }
      fileView = null;
    });

    it('initially displays all JavaScript functions with line numbers', async () => {
      await fileView.toggle();
      await until('the items have been displayed', () => {
        return fileView.setItems.callCount === 1;
      });
      await until('the element exists', () => {
        return fileView.selectListView.element.getElementsByTagName('li').length > 1;
      });
      expect(fileView.selectListView.items.length).to.equal(2);

      const item1 = fileView.selectListView.element.getElementsByTagName('li')[0].getElementsByTagName('div');
      expect(item1[0].innerText).to.equal('quicksort');
      expect(item1[1].innerText).to.equal('Line 1');
      const item2 = fileView.selectListView.element.getElementsByTagName('li')[1].getElementsByTagName('div');
      expect(item2[0].innerText).to.equal('quicksort.sort');
      expect(item2[1].innerText).to.equal('Line 2');
    });

    it('caches tags until the editor changes', async () => {
      await fileView.toggle();
      await until('the items have been displayed', () => {
        return fileView.setItems.callCount === 1;
      });
      await until('the element exists', () => {
        return fileView.selectListView.element.getElementsByTagName('li').length > 1;
      });
      expect(fileView.selectListView.items.length).to.equal(2);
      expect(fileView.generateTags.callCount === 1);
      await fileView.toggle();
      await until('the panel is destroyed', () => {
        return fileView.panel === null;
      });
      expect(fileView.selectListView.items.length).to.equal(0);
      await fileView.toggle();
      expect(fileView.selectListView.items.length).to.equal(2);
      expect(fileView.generateTags.callCount === 1);
      atom.workspace.getActiveTextEditor().save();
      await fileView.toggle();
      await until('the panel is destroyed', () => {
        return fileView.panel === null;
      });
      expect(fileView.selectListView.items.length).to.equal(0);
      await fileView.toggle();
      await until('the panel is created', () => {
        return fileView.panel !== null;
      });
      expect(fileView.generateTags.callCount === 1);
      atom.workspace.getActiveTextEditor().destroy();
      expect(fileView.cachedTags).to.deep.equal({});
    });

    it('displays an error when no tags match text in mini-editor', async () => {
      await fileView.toggle();
      await until('the items have been displayed', () => {
        return fileView.setItems.callCount === 1;
      });
      fileView.setItems.reset();
      fileView.selectListView.refs.queryEditor.setText('nothing will match this');
      await until('the items are filtered', () => {
        return fileView.panel.item.items.length === 0;
      });
      expect(fileView.selectListView.props.emptyMessage).to.equal('No symbols found');
      expect(fileView.selectListView.props.emptyMessage.length).to.be.above(0);
      expect(fileView.panel.item.items.length).to.equal(0);
      expect(fileView.selectListView.element.getElementsByTagName('span')[1].innerText).to.equal('No symbols found');
      // Should remove error
      fileView.selectListView.refs.queryEditor.setText('');
      await etch.getScheduler().getNextUpdatePromise();
      await until('the element exists', () => {
        return fileView.selectListView.element.getElementsByTagName('li').length > 1;
      });
      expect(fileView.panel.item.items.length).to.equal(2);
    });

    // it('moves the cursor to the selected function', () => {
    //   runs(() => {
    //     fileView = mainModule.createFileView();
    //     spyOn(fileView, 'setItems').andCallThrough();
    //     expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual([0, 0]);
    //     expect(document.querySelector('.symbols-view')).not.toExist();
    //     atom.commands.dispatch(getEditorView(), 'symbols-view:toggle-file-symbols');
    //   });
    //
    //   waitsFor('items to be loaded', () => {
    //     return fileView.setItems.callCount > 0;
    //   });
    //
    //   runs(() => {
    //     symbolsView = document.querySelector('.symbols-view');
    //   });
    //
    //   waitsFor(() => {
    //     return symbolsView.getElementsByTagName('li').length > 0;
    //   });
    //
    //   runs(() => {
    //     symbolsView.getElementsByTagName('li')[1].click();
    //     expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual([1, 2]);
    //   });
    // });
  });
  /*
  describe("when tags can't be generated for a file", () => {
    beforeEach(() => {
      waitsForPromise(() => atom.workspace.open('sample.txt'));
    });

    it('shows an error message when no matching tags are found', () => {
      runs(() => atom.commands.dispatch(getEditorView(), 'symbols-view:toggle-file-symbols'));

      waitsForPromise(() => activationPromise);

      runs(() => symbolsView = $(getWorkspaceView()).find('.symbols-view').view());

      waitsFor(() => symbolsView.error.isVisible());

      runs(() => {
        expect(symbolsView).toExist();
        expect(symbolsView.list.children('li').length).toBe(0);
        expect(symbolsView.error).toBeVisible();
        expect(symbolsView.error.text().length).toBeGreaterThan(0);
        expect(symbolsView.loadingArea).not.toBeVisible();
      });
    });
  });

  describe('TagGenerator', () => {
    it('generates tags for all JavaScript functions', () => {
      let tags = [];

      waitsForPromise(() => {
        const sampleJsPath = directory.resolve('sample.js');
        return new TagGenerator(sampleJsPath).generate().then(o => tags = o);
      });

      runs(() => {
        expect(tags.length).toBe(2);
        expect(tags[0].name).toBe('quicksort');
        expect(tags[0].position.row).toBe(0);
        expect(tags[1].name).toBe('quicksort.sort');
        expect(tags[1].position.row).toBe(1);
      });
    });

    it('generates no tags for text file', () => {
      let tags = [];

      waitsForPromise(() => {
        const sampleJsPath = directory.resolve('sample.txt');
        return new TagGenerator(sampleJsPath).generate().then(o => tags = o);
      });

      runs(() => expect(tags.length).toBe(0));
    });
  });

  describe('go to declaration', () => {
    it("doesn't move the cursor when no declaration is found", () => {
      waitsForPromise(() => atom.workspace.open(directory.resolve('tagged.js')));

      runs(() => {
        editor = atom.workspace.getActiveTextEditor();
        editor.setCursorBufferPosition([0, 2]);
        atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration');
      });

      waitsForPromise(() => activationPromise);

      runs(() => expect(editor.getCursorBufferPosition()).toEqual([0, 2]));
    });

    it('moves the cursor to the declaration when there is a single matching declaration', () => {
      waitsForPromise(() => atom.workspace.open(directory.resolve('tagged.js')));

      runs(() => {
        editor = atom.workspace.getActiveTextEditor();
        editor.setCursorBufferPosition([6, 24]);
        spyOn(SymbolsView.prototype, 'moveToPosition').andCallThrough();
        atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration');
      });

      waitsFor(() => SymbolsView.prototype.moveToPosition.callCount === 1);

      runs(() => expect(editor.getCursorBufferPosition()).toEqual([2, 0]));
    });

    it('displays matches when more than one exists and opens the selected match', () => {
      waitsForPromise(() => atom.workspace.open(directory.resolve('tagged.js')));

      runs(() => {
        editor = atom.workspace.getActiveTextEditor();
        editor.setCursorBufferPosition([8, 14]);
        atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration');
      });

      waitsFor(() => $(getWorkspaceView()).find('.symbols-view').find('li').length > 0);

      runs(() => {
        symbolsView = $(getWorkspaceView()).find('.symbols-view').view();
        expect(symbolsView.list.children('li').length).toBe(2);
        expect(symbolsView).toBeVisible();
        spyOn(SymbolsView.prototype, 'moveToPosition').andCallThrough();
        symbolsView.confirmed(symbolsView.items[0]);
      });

      waitsFor(() => SymbolsView.prototype.moveToPosition.callCount === 1);

      runs(() => {
        expect(atom.workspace.getActiveTextEditor().getPath()).toBe(directory.resolve('tagged-duplicate.js'));
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual([0, 4]);
      });
    });

    it('includes ? and ! characters in ruby symbols', () => {
      atom.project.setPaths([temp.mkdirSync('atom-symbols-view-ruby-')]);
      fs.copySync(path.join(__dirname, 'fixtures', 'ruby'), atom.project.getPaths()[0]);

      waitsForPromise(() => atom.packages.activatePackage('language-ruby'));

      waitsForPromise(() => atom.workspace.open('file1.rb'));

      runs(() => {
        spyOn(SymbolsView.prototype, 'moveToPosition').andCallThrough();
        atom.workspace.getActiveTextEditor().setCursorBufferPosition([18, 4]);
        atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration');
      });

      waitsForPromise(() => activationPromise);

      waitsFor(() => SymbolsView.prototype.moveToPosition.callCount === 1);

      runs(() => {
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual([7, 2]);
        SymbolsView.prototype.moveToPosition.reset();
        atom.workspace.getActiveTextEditor().setCursorBufferPosition([19, 2]);
        atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration');
      });

      waitsFor(() => SymbolsView.prototype.moveToPosition.callCount === 1);

      runs(() => {
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual([11, 2]);
        SymbolsView.prototype.moveToPosition.reset();
        atom.workspace.getActiveTextEditor().setCursorBufferPosition([20, 5]);
        atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration');
      });

      waitsFor(() => SymbolsView.prototype.moveToPosition.callCount === 1);

      runs(() => {
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual([3, 2]);
        SymbolsView.prototype.moveToPosition.reset();
        atom.workspace.getActiveTextEditor().setCursorBufferPosition([21, 7]);
        atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration');
      });

      waitsFor(() => SymbolsView.prototype.moveToPosition.callCount === 1);

      runs(() => expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual([3, 2]));
    });

    it('handles jumping to assignment ruby method definitions', () => {
      atom.project.setPaths([temp.mkdirSync('atom-symbols-view-ruby-')]);
      fs.copySync(path.join(__dirname, 'fixtures', 'ruby'), atom.project.getPaths()[0]);

      waitsForPromise(() => atom.packages.activatePackage('language-ruby'));

      waitsForPromise(() => atom.workspace.open('file1.rb'));

      runs(() => {
        spyOn(SymbolsView.prototype, 'moveToPosition').andCallThrough();
        atom.workspace.getActiveTextEditor().setCursorBufferPosition([22, 5]);
        atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration');
      });

      waitsFor(() => SymbolsView.prototype.moveToPosition.callCount === 1);

      runs(() => {
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual([14, 2]);
        SymbolsView.prototype.moveToPosition.reset();
        atom.workspace.getActiveTextEditor().setCursorBufferPosition([23, 5]);
        atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration');
      });

      waitsFor(() => SymbolsView.prototype.moveToPosition.callCount === 1);

      runs(() => {
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual([14, 2]);
        SymbolsView.prototype.moveToPosition.reset();
        atom.workspace.getActiveTextEditor().setCursorBufferPosition([24, 5]);
        atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration');
      });

      waitsFor(() => SymbolsView.prototype.moveToPosition.callCount === 1);

      runs(() => {
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual([0, 0]);
        SymbolsView.prototype.moveToPosition.reset();
        atom.workspace.getActiveTextEditor().setCursorBufferPosition([25, 5]);
        atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration');
      });

      waitsFor(() => SymbolsView.prototype.moveToPosition.callCount === 1);

      runs(() => expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual([11, 2]));
    });

    it('handles jumping to fully qualified ruby constant definitions', () => {
      atom.project.setPaths([temp.mkdirSync('atom-symbols-view-ruby-')]);
      fs.copySync(path.join(__dirname, 'fixtures', 'ruby'), atom.project.getPaths()[0]);

      waitsForPromise(() => atom.packages.activatePackage('language-ruby'));

      waitsForPromise(() => atom.workspace.open('file1.rb'));

      runs(() => {
        spyOn(SymbolsView.prototype, 'moveToPosition').andCallThrough();
        atom.workspace.getActiveTextEditor().setCursorBufferPosition([26, 10]);
        atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration');
      });

      waitsFor(() => SymbolsView.prototype.moveToPosition.callCount === 1);

      runs(() => {
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual([1, 2]);
        SymbolsView.prototype.moveToPosition.reset();
        atom.workspace.getActiveTextEditor().setCursorBufferPosition([27, 5]);
        atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration');
      });

      waitsFor(() => SymbolsView.prototype.moveToPosition.callCount === 1);

      runs(() => {
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual([0, 0]);
        SymbolsView.prototype.moveToPosition.reset();
        atom.workspace.getActiveTextEditor().setCursorBufferPosition([28, 5]);
        atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration');
      });

      waitsFor(() => SymbolsView.prototype.moveToPosition.callCount === 1);

      runs(() => expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual([31, 0]));
    });

    describe('return from declaration', () => {
      it("doesn't do anything when no go-to have been triggered", () => {
        waitsForPromise(() => atom.workspace.open(directory.resolve('tagged.js')));

        runs(() => {
          editor = atom.workspace.getActiveTextEditor();
          editor.setCursorBufferPosition([6, 0]);
          atom.commands.dispatch(getEditorView(), 'symbols-view:return-from-declaration');
        });

        waitsForPromise(() => activationPromise);

        runs(() => expect(editor.getCursorBufferPosition()).toEqual([6, 0]));
      });

      it('returns to previous row and column', () => {
        waitsForPromise(() => atom.workspace.open(directory.resolve('tagged.js')));

        runs(() => {
          editor = atom.workspace.getActiveTextEditor();
          editor.setCursorBufferPosition([6, 24]);
          spyOn(SymbolsView.prototype, 'moveToPosition').andCallThrough();
          atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration');
        });

        waitsForPromise(() => activationPromise);

        waitsFor(() => SymbolsView.prototype.moveToPosition.callCount === 1);

        runs(() => {
          expect(editor.getCursorBufferPosition()).toEqual([2, 0]);
          atom.commands.dispatch(getEditorView(), 'symbols-view:return-from-declaration');
        });

        waitsFor(() => SymbolsView.prototype.moveToPosition.callCount === 2);

        runs(() => expect(editor.getCursorBufferPosition()).toEqual([6, 24]));
      });
    });

    describe("when the tag is in a file that doesn't exist", () => {
      it("doesn't display the tag", () => {
        fs.removeSync(directory.resolve('tagged-duplicate.js'));

        waitsForPromise(() => atom.workspace.open(directory.resolve('tagged.js')));

        runs(() => {
          editor = atom.workspace.getActiveTextEditor();
          editor.setCursorBufferPosition([8, 14]);
          spyOn(SymbolsView.prototype, 'moveToPosition').andCallThrough();
          atom.commands.dispatch(getEditorView(), 'symbols-view:go-to-declaration');
        });

        waitsFor(() => SymbolsView.prototype.moveToPosition.callCount === 1);

        runs(() => expect(editor.getCursorBufferPosition()).toEqual([8, 0]));
      });
    });
  });

  describe('project symbols', () => {
    it('displays all tags', () => {
      jasmine.unspy(window, 'setTimeout');

      waitsForPromise(() => atom.workspace.open(directory.resolve('tagged.js')));

      runs(() => {
        expect($(getWorkspaceView()).find('.symbols-view')).not.toExist();
        atom.commands.dispatch(getWorkspaceView(), 'symbols-view:toggle-project-symbols');
      });

      waitsForPromise(() => activationPromise);

      runs(() => symbolsView = $(getWorkspaceView()).find('.symbols-view').view());

      waitsFor('loading', () => symbolsView.setLoading.callCount > 1);

      waitsFor(() => symbolsView.list.children('li').length > 0);

      runs(() => {
        const directoryBasename = path.basename(directory.getPath());
        const taggedFile = path.join(directoryBasename, 'tagged.js');
        expect(symbolsView.loading).toBeEmpty();
        expect($(getWorkspaceView()).find('.symbols-view')).toExist();
        expect(symbolsView.list.children('li').length).toBe(4);
        expect(symbolsView.list.children('li:first').find('.primary-line')).toHaveText('callMeMaybe');
        expect(symbolsView.list.children('li:first').find('.secondary-line')).toHaveText(taggedFile);
        expect(symbolsView.list.children('li:last').find('.primary-line')).toHaveText('thisIsCrazy');
        expect(symbolsView.list.children('li:last').find('.secondary-line')).toHaveText(taggedFile);
        expect(symbolsView.error).not.toBeVisible();
        atom.commands.dispatch(getWorkspaceView(), 'symbols-view:toggle-project-symbols');

        fs.removeSync(directory.resolve('tags'));
      });

      waitsFor(() => symbolsView.reloadTags);

      runs(() => atom.commands.dispatch(getWorkspaceView(), 'symbols-view:toggle-project-symbols'));

      waitsFor(() => symbolsView.error.text().length > 0);

      runs(() => expect(symbolsView.list.children('li').length).toBe(0));
    });

    describe('when there is only one project', () => {
      beforeEach(() => atom.project.setPaths([directory.getPath()]));

      it("does not include the root directory's name when displaying the tag's filename", () => {
        jasmine.unspy(window, 'setTimeout');

        waitsForPromise(() => atom.workspace.open(directory.resolve('tagged.js')));

        runs(() => {
          expect($(getWorkspaceView()).find('.symbols-view')).not.toExist();
          atom.commands.dispatch(getWorkspaceView(), 'symbols-view:toggle-project-symbols');
        });

        waitsForPromise(() => activationPromise);

        runs(() => symbolsView = $(getWorkspaceView()).find('.symbols-view').view());

        waitsFor(() => symbolsView.list.children('li').length > 0);

        runs(() => {
          expect(symbolsView.list.children('li:first').find('.primary-line')).toHaveText('callMeMaybe');
          expect(symbolsView.list.children('li:first').find('.secondary-line')).toHaveText('tagged.js');
        });
      });
    });

    describe('when selecting a tag', () => {
      describe("when the file doesn't exist", () => {
        beforeEach(() => fs.removeSync(directory.resolve('tagged.js')));

        it("doesn't open the editor", () => {
          atom.commands.dispatch(getWorkspaceView(), 'symbols-view:toggle-project-symbols');

          waitsForPromise(() => activationPromise);

          runs(() => symbolsView = $(getWorkspaceView()).find('.symbols-view').view());

          waitsFor(() => symbolsView.list.children('li').length > 0);

          runs(() => {
            spyOn(atom.workspace, 'open').andCallThrough();
            symbolsView.list.children('li:first').mousedown().mouseup();
            expect(atom.workspace.open).not.toHaveBeenCalled();
            expect(symbolsView.error.text().length).toBeGreaterThan(0);
          });
        });
      });
    });
  });

  describe('when useEditorGrammarAsCtagsLanguage is set to true', () => {
    it("uses the language associated with the editor's grammar", () => {
      atom.config.set('symbols-view.useEditorGrammarAsCtagsLanguage', true);

      waitsForPromise(() => atom.packages.activatePackage('language-javascript'));

      waitsForPromise(() => atom.workspace.open('sample.javascript'));

      runs(() => {
        atom.workspace.getActiveTextEditor().setText('var test = function() {}');
        atom.workspace.getActiveTextEditor().save();
        atom.commands.dispatch(getEditorView(), 'symbols-view:toggle-file-symbols');
      });

      waitsForPromise(() => activationPromise);

      waitsFor(() => $(getWorkspaceView()).find('.symbols-view').view().error.isVisible());

      runs(() => {
        atom.commands.dispatch(getEditorView(), 'symbols-view:toggle-file-symbols');
        atom.workspace.getActiveTextEditor().setGrammar(atom.grammars.grammarForScopeName('source.js'));
        symbolsView.setLoading.reset();
        atom.commands.dispatch(getEditorView(), 'symbols-view:toggle-file-symbols');
        symbolsView = $(getWorkspaceView()).find('.symbols-view').view();
      });

      waitsFor('loading', () => symbolsView.setLoading.callCount > 1);

      waitsFor(() => symbolsView.list.children('li').length === 1);

      runs(() => {
        expect(symbolsView.loading).toBeEmpty();
        expect($(getWorkspaceView()).find('.symbols-view')).toExist();
        expect(symbolsView.list.children('li:first').find('.primary-line')).toHaveText('test');
        expect(symbolsView.list.children('li:first').find('.secondary-line')).toHaveText('Line 1');
      });
    });
  });

  describe('match highlighting', () => {
    beforeEach(() => {
      waitsForPromise(() => atom.workspace.open(directory.resolve('sample.js')));
    });

    it('highlights an exact match', () => {
      runs(() => atom.commands.dispatch(getEditorView(), 'symbols-view:toggle-file-symbols'));

      waitsForPromise(() => activationPromise);

      runs(() => symbolsView = $(getWorkspaceView()).find('.symbols-view').view());

      waitsFor(() => symbolsView.list.children('li').length > 0);

      runs(() => {
        symbolsView.filterEditorView.getModel().setText('quicksort');
        expect(symbolsView.filterEditorView.getModel().getText()).toBe('quicksort');
        symbolsView.populateList();
        const resultView = symbolsView.getSelectedItemView();

        const matches = resultView.find('.character-match');
        expect(matches.length).toBe(1);
        expect(matches.last().text()).toBe('quicksort');
      });
    });

    it('highlights a partial match', () => {
      runs(() => atom.commands.dispatch(getEditorView(), 'symbols-view:toggle-file-symbols'));

      waitsForPromise(() => activationPromise);

      runs(() => symbolsView = $(getWorkspaceView()).find('.symbols-view').view());

      waitsFor(() => symbolsView.list.children('li').length > 0);

      runs(() => {
        symbolsView.filterEditorView.getModel().setText('quick');
        symbolsView.populateList();
        const resultView = symbolsView.getSelectedItemView();

        const matches = resultView.find('.character-match');
        expect(matches.length).toBe(1);
        expect(matches.last().text()).toBe('quick');
      });
    });

    it('highlights multiple matches in the symbol name', () => {
      runs(() => atom.commands.dispatch(getEditorView(), 'symbols-view:toggle-file-symbols'));

      waitsForPromise(() => activationPromise);

      runs(() => symbolsView = $(getWorkspaceView()).find('.symbols-view').view());

      waitsFor(() => symbolsView.list.children('li').length > 0);

      runs(() => {
        symbolsView.filterEditorView.getModel().setText('quicort');
        symbolsView.populateList();
        const resultView = symbolsView.getSelectedItemView();

        const matches = resultView.find('.character-match');
        expect(matches.length).toBe(2);
        expect(matches.first().text()).toBe('quic');
        expect(matches.last().text()).toBe('ort');
      });
    });
  });

  describe('quickjump to symbol', () => {
    beforeEach(() => {
      waitsForPromise(() => atom.workspace.open(directory.resolve('sample.js')));
    });

    it('jumps to the selected function', () => {
      runs(() => {
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual([0, 0]);
        atom.commands.dispatch(getEditorView(), 'symbols-view:toggle-file-symbols');
      });

      waitsForPromise(() => activationPromise);

      runs(() => symbolsView = $(getWorkspaceView()).find('.symbols-view').view());

      waitsFor(() => symbolsView.list.children('li').length > 0);

      runs(() => {
        symbolsView.selectNextItemView();
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual([1, 2]);
      });
    });

    it('restores previous editor state on cancel', () => {
      const bufferRanges = [{start: {row: 0, column: 0}, end: {row: 0, column: 3}}];

      runs(() => {
        atom.workspace.getActiveTextEditor().setSelectedBufferRanges(bufferRanges);
        atom.commands.dispatch(getEditorView(), 'symbols-view:toggle-file-symbols');
      });

      waitsForPromise(() => activationPromise);

      runs(() => symbolsView = $(getWorkspaceView()).find('.symbols-view').view());

      waitsFor(() => symbolsView.list.children('li').length > 0);

      runs(() => {
        symbolsView.selectNextItemView();
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual([1, 2]);
        symbolsView.cancel();
        expect(atom.workspace.getActiveTextEditor().getSelectedBufferRanges()).toEqual(bufferRanges);
      });
    });
  });

  describe('when quickJumpToSymbol is set to false', () => {
    beforeEach(() => {
      atom.config.set('symbols-view.quickJumpToFileSymbol', false);
      waitsForPromise(() => atom.workspace.open(directory.resolve('sample.js')));
    });

    it("won't jumps to the selected function", () => {
      runs(() => {
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual([0, 0]);
        atom.commands.dispatch(getEditorView(), 'symbols-view:toggle-file-symbols');
      });

      waitsForPromise(() => activationPromise);

      runs(() => symbolsView = $(getWorkspaceView()).find('.symbols-view').view());

      waitsFor(() => symbolsView.list.children('li').length > 0);

      runs(() => {
        symbolsView.selectNextItemView();
        expect(atom.workspace.getActiveTextEditor().getCursorBufferPosition()).toEqual([0, 0]);
      });
    });
  });
  */
});
