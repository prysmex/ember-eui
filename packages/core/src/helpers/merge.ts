import { helper } from '@ember/component/helper';
import { merge } from 'lodash-es';

export default helper(function (hashes: Array<object>, hash: object) {
  return merge({}, ...hashes, hash);
});
