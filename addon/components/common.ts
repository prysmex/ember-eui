export interface CommonArgs {
  className?: string;
  'aria-label'?: string;
  'data-test-subj'?: string;
}
/**
 * Wraps Object.keys with proper typescript definition of the resulting array
 */
export function keysOf<T, K extends keyof T>(obj: T): K[] {
  return Object.keys(obj) as K[];
}
