// @types/refractor types only some of refractor's language files; the
// others are the same kind of module (see src/-private/languages.ts)
declare module 'refractor/lang/*' {
  import type { RefractorSyntax } from 'refractor/core';

  const syntax: RefractorSyntax;
  export = syntax;
}
