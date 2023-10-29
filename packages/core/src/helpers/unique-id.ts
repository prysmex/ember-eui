import { helper } from '@ember/component/helper';

export default helper(uniqueId);

// Copy-pasted from the ember-source implementation:
// https://github.com/emberjs/ember.js/blob/master/packages/@ember/-internals/glimmer/lib/helpers/unique-id.ts
export function uniqueId() {
	//@ts-expect-error
  return ([3e7] + -1e3 + -4e3 + -2e3 + -1e11).replace(/[0-3]/g, (a) =>
    ((a * 4) ^ ((Math.random() * 16) >> (a & 2))).toString(16)
  );
}
