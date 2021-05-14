import EmberSvgJarService from 'ember-svg-jar/services/svg-jar';
import resolveAsset from 'ember-cli-resolve-asset';

export default class SvgJar extends EmberSvgJarService {
  resolveAsset(path) {
    return resolveAsset(path);
  }
}
