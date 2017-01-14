import {CompositeDisposable, File} from 'atom';
import humanize from 'humanize-plus';
import SymbolsView from './symbols-view';
import TagReader from './tag-reader';
import getTagsFile from './get-tags-file';

export default class ProjectView extends SymbolsView {
  constructor(stack) {
    super(stack);
    this.reloadTags = true;
    this.setMaxItems(10);
    this.selectListView.emptyMessage = 'Project has no tags or it is empty';
  }

  destroy(...args) {
    this.stopTask();
    this.unwatchTagsFiles();
    super.destroy(...args);
  }

  async toggle() {
    if (this.panel) {
      this.cancel();
    } else {
      this.populate();
      await this.selectListView.update();
      this.attach();
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
        const loading = 'Loading project symbols\u2026';
        this.setLoading(loading);
        let tagsRead = 0;
        this.loadTagsTask.on('tags', tags => {
          tagsRead += tags.length;
          this.setLoading(loading + ' ' + humanize.intComma(tagsRead));
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
    const reloadTags = () => {
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
