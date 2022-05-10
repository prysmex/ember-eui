import { helper } from '@ember/component/helper';

export default helper(function (hashes: Array<object>, hash: object) {
  return Object.assign({}, ...hashes, hash);
});
