import Helper from '@ember/component/helper';
import { getOwner } from '@ember/owner';

/**
 * Replacement for `ember-set-body-class` (a v1 addon with no v2 release).
 *
 *   {{(setBodyClass "euiBody-hasOverlayMask")}}
 *
 * Adds the given class names to <body> while the helper is rendered and
 * removes them when it is torn down. Class names are reference counted, so
 * with nested usages (e.g. a modal opened from a flyout, both rendering an
 * overlay mask) the class stays until the last one goes away.
 *
 * Like the original, it goes through the `-document` service so it also
 * works in FastBoot, and it keeps the classes when the app is torn down in
 * FastBoot so they end up in the rendered HTML.
 */

interface BodyLike {
  getAttribute(name: string): string | null;
  setAttribute(name: string, value: string): void;
}

interface DocumentLike {
  body: BodyLike;
}

const countsByDocument = new WeakMap<DocumentLike, Map<string, number>>();

function countsFor(doc: DocumentLike) {
  let counts = countsByDocument.get(doc);

  if (!counts) {
    counts = new Map();
    countsByDocument.set(doc, counts);
  }

  return counts;
}

function splitClassNames(value: string | null | undefined): string[] {
  return value ? value.split(/\s+/).filter(Boolean) : [];
}

function updateBody(doc: DocumentLike, add: string[], remove: string[]) {
  const classList = new Set(splitClassNames(doc.body.getAttribute('class')));

  remove.forEach((name) => classList.delete(name));
  add.forEach((name) => classList.add(name));

  doc.body.setAttribute('class', [...classList].join(' '));
}

function retain(doc: DocumentLike, names: string[]) {
  const counts = countsFor(doc);
  const added: string[] = [];

  for (const name of names) {
    const count = counts.get(name) ?? 0;

    if (count === 0) added.push(name);
    counts.set(name, count + 1);
  }

  if (added.length) updateBody(doc, added, []);
}

function release(doc: DocumentLike, names: string[]) {
  const counts = countsFor(doc);
  const removed: string[] = [];

  for (const name of names) {
    const count = (counts.get(name) ?? 0) - 1;

    if (count <= 0) {
      counts.delete(name);
      removed.push(name);
    } else {
      counts.set(name, count);
    }
  }

  if (removed.length) updateBody(doc, [], removed);
}

interface SetBodyClassSignature {
  Args: {
    Positional: [classNames: string | undefined];
  };
  Return: undefined;
}

export default class SetBodyClass extends Helper<SetBodyClassSignature> {
  #names: string[] = [];

  get #document(): DocumentLike | undefined {
    return getOwner(this)?.lookup('service:-document') as
      | DocumentLike
      | undefined;
  }

  get #isFastBoot(): boolean {
    const fastboot = getOwner(this)?.lookup('service:fastboot') as
      | { isFastBoot?: boolean }
      | undefined;

    return Boolean(fastboot?.isFastBoot);
  }

  compute([classNames]: [string | undefined]): undefined {
    const doc = this.#document;

    if (!doc) return;

    const next = [...new Set(splitClassNames(classNames))];

    // retain before releasing, so names kept across updates never flicker
    retain(doc, next);
    release(doc, this.#names);
    this.#names = next;
  }

  willDestroy() {
    super.willDestroy();

    const doc = this.#document;

    if (!doc || this.#isFastBoot) return;

    release(doc, this.#names);
    this.#names = [];
  }
}
