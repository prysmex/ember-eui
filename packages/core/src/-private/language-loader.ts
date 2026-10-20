import { tracked } from '@glimmer/tracking';
import { buildWaiter } from '@ember/test-waiters';

import { register } from 'refractor/core';

import { BUILT_IN_LANGUAGES, LOADABLE_LANGUAGES } from './language-names.ts';

// `await render()` / `settled()` wait for languages that are still loading
const waiter = buildWaiter('@ember-eui/core:code-language');

class LoadingLanguage {
  @tracked isLoaded = false;

  promise: Promise<void>;

  constructor(name: string) {
    const token = waiter.beginAsync();

    // the loaders (one import per language, ~35KB) come with the first
    // language that needs one
    this.promise = import('./languages.ts')
      .then(({ default: languageLoaders }) => languageLoaders[name]!())
      .then(
        ({ default: syntax }) => {
          register(syntax);
          this.isLoaded = true;
        },
        (error: unknown) => {
          // a later render retries, e.g. after a failed chunk request
          cache.delete(name);
          console.error(`EuiCode: could not load the "${name}" language`, error);
        }
      )
      .finally(() => waiter.endAsync(token));
  }
}

const cache = new Map<string, LoadingLanguage>();

const loadable = new Set(LOADABLE_LANGUAGES);

function isLoadable(name: string): boolean {
  return loadable.has(name);
}

function load(name: string): LoadingLanguage {
  let language = cache.get(name);

  if (!language) {
    language = new LoadingLanguage(name);
    cache.set(name, language);
  }

  return language;
}

/** Every language that can be highlighted, by name and alias. */
export const SUPPORTED_LANGUAGES: string[] = [
  ...BUILT_IN_LANGUAGES,
  ...LOADABLE_LANGUAGES
];

export function isSupportedLanguage(name: string): boolean {
  return BUILT_IN_LANGUAGES.includes(name) || isLoadable(name);
}

/**
 * The language to highlight with now: `name` once it has loaded (the first
 * use starts loading it), `'text'` until then. Reading it inside a template
 * or getter re-renders once the language has loaded.
 */
export function highlightLanguage(name: string): string {
  if (BUILT_IN_LANGUAGES.includes(name)) return name;
  if (!isLoadable(name)) return 'text';

  return load(name).isLoaded ? name : 'text';
}

/** Resolves once the languages have loaded (or failed to). */
export async function loadLanguages(names: string[]): Promise<void> {
  await Promise.all(names.filter(isLoadable).map((name) => load(name).promise));
}
