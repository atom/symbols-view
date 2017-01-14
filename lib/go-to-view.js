import path from 'path';
import SymbolsView from './symbols-view';
import TagReader from './tag-reader';

export default class GoToView extends SymbolsView {
  async toggle() {
    if (this.panel) {
      this.cancel();
    } else {
      this.populate();
      await this.selectListView.update();
      this.attach();
    }
  }

  detached() {
    if (this.resolveFindTagPromise) {
      this.resolveFindTagPromise([]);
    }
  }

  findTag(editor) {
    if (this.resolveFindTagPromise) {
      this.resolveFindTagPromise([]);
    }

    return new Promise((resolve, reject) => {
      this.resolveFindTagPromise = resolve;
      TagReader.find(editor, (error, m) => {
        let matches = m;
        if (!matches) {
          matches = [];
        }
        if (error) {
          return reject(error);
        } else {
          return resolve(matches);
        }
      });
    });
  }

  populate() {
    const editor = atom.workspace.getActiveTextEditor();
    if (!editor) {
      return;
    }

    this.findTag(editor).then(matches => {
      const tags = [];
      for (const match of Array.from(matches)) {
        const position = this.getTagLine(match);
        if (!position) { continue; }
        match.name = path.basename(match.file);
        tags.push(match);
      }

      if (tags.length === 1) {
        this.openTag(tags[0]);
      } else if (tags.length > 0) {
        this.setItems(tags);
        this.attach();
      }
    });
  }
}
