import async from 'async';
import ctags from 'ctags';
import getTagsFile from './get-tags-file';

export default function(directoryPaths) {
  return async.each(
    directoryPaths,
    (directoryPath, done) => {
      const tagsFilePath = getTagsFile(directoryPath);
      if (!tagsFilePath) { return done(); }

      const stream = ctags.createReadStream(tagsFilePath);
      stream.on('data', tags => {
        for (const tag of Array.from(tags)) { tag.directory = directoryPath; }
        return emit('tags', tags);
      });
      stream.on('end', done);
      return stream.on('error', done);
    }
    , this.async(),
  );
}
