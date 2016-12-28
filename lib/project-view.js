'use babel';

import { CompositeDisposable, File } from 'atom';
import humanize from 'humanize-plus';
import SymbolsView from './symbols-view';
import TagReader from './tag-reader';
import getTagsFile from './get-tags-file';

export default class ProjectView extends SymbolsView {
  initialize() {
    super.initialize(...arguments);
    this.reloadTags = true;
    this.setMaxItems(10);
  }

  destroy() {
    this.stopTask();
    this.unwatchTagsFiles();
    super.destroy(...arguments);
  }

  toggle() {
    if (this.panel.isVisible()) {
      this.cancel();
    } else {
      this.populate();
      this.attach();
    }
  }

  getEmptyMessage(itemCount) {
    if (itemCount === 0) {
      return 'Project has no tags file or it is empty';
    } else {
      return super.getEmptyMessage(...arguments);
    }
  }

  populate() {
    if (this.tags) {
      this.setItems(this.tags);
    }

    if (this.reloadTags) {
      this.reloadTags = false;
      this.startTask();

      if (this.tags) {
        this.setLoading('Reloading project symbols\u2026');
      } else {
        this.setLoading('Loading project symbols\u2026');
        this.loadingBadge.text('0');
        let tagsRead = 0;
        this.loadTagsTask.on('tags', tags => {
          tagsRead += tags.length;
          this.loadingBadge.text(humanize.intComma(tagsRead));
        });
      }
    }
  }

  stopTask() {
    if (this.loadTagsTask) {
      this.loadTagsTask.terminate();
    }
  }

  startTask() {
    this.stopTask();

    this.loadTagsTask = TagReader.getAllTags(tags => {
      this.tags = tags;
      this.reloadTags = this.tags.length === 0;
      this.setItems(this.tags);
    });

    this.watchTagsFiles();
  }

  watchTagsFiles() {
    this.unwatchTagsFiles();

    this.tagsFileSubscriptions = new CompositeDisposable();
    let reloadTags = () => {
      this.reloadTags = true;
      this.watchTagsFiles();
    };

    for (const projectPath of Array.from(atom.project.getPaths())) {
      const tagsFilePath = getTagsFile(projectPath);
      if (tagsFilePath) {
        const tagsFile = new File(tagsFilePath);
        this.tagsFileSubscriptions.add(tagsFile.onDidChange(reloadTags));
        this.tagsFileSubscriptions.add(tagsFile.onDidDelete(reloadTags));
        this.tagsFileSubscriptions.add(tagsFile.onDidRename(reloadTags));
      }
    }
  }

  unwatchTagsFiles() {
    if (this.tagsFileSubscriptions) {
      this.tagsFileSubscriptions.dispose();
    }
    this.tagsFileSubscriptions = null;
  }
}
