import { helper } from '@ember/component/helper';
import { isArray } from '@ember/array';

function isEmptied(o, allowNull = false) {
  let isUndefined = o === undefined;
  let isNull = o === null;
  return isUndefined || (isNull && !allowNull);
}

export default helper(function ([o], { allowNull = false }) {

  return isArray(o) ? o : isEmptied(o, allowNull) ? [] : [o];
});
