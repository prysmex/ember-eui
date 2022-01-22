import EmberSvgJarService from 'ember-svg-jar/services/asset-map';
import resolveAsset from 'ember-cli-resolve-asset';

export default class SvgJar extends EmberSvgJarService {
  resolve(path) {
    return resolveAsset(path);
  }
}
