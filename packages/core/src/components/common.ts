// utility types:
/**
 * XOR for some properties applied to a type
 * (XOR is one of these but not both or neither)
 *
 * Usage: OneOf<typeToExtend, one | but | not | multiple | of | these | are | required>
 *
 * To require aria-label or aria-labelledby but not both
 * Example: OneOf<Type, 'aria-label' | 'aria-labelledby'>
 */
export type OneOf<T, K extends keyof T> = Omit<T, K> &
  { [k in K]: Pick<Required<T>, k> & { [k1 in Exclude<K, k>]?: never } }[K];

export interface CommonArgs {
  id?: string;
  className?: string;
  'aria-label'?: string;
  'data-test-subj'?: string;
}

/**
 * Wraps Object.keys with proper typescript definition of the resulting array
 */
export function keysOf<T extends Record<string, unknown>, K extends keyof T>(
  obj: T
): K[] {
  return Object.keys(obj) as K[];
}

/**
 * Returns member keys in U not present in T set to never
 * T = { 'one', 'two', 'three' }
 * U = { 'three', 'four', 'five' }
 * returns { 'four': never, 'five': never }
 */
export type DisambiguateSet<T, U> = {
  [P in Exclude<keyof T, keyof U>]?: never;
};

/**
 * Allow either T or U, preventing any additional keys of the other type from being present
 */
export type ExclusiveUnion<T, U> = T | U extends Record<string, unknown> // if there are any shared keys between T and U
  ? (DisambiguateSet<T, U> & U) | (DisambiguateSet<U, T> & T) // otherwise the TS union is already unique
  : T | U;

/*
https://github.com/Microsoft/TypeScript/issues/28339
Problem: Pick and Omit do not distribute over union types, which manifests when
optional values become required after a Pick or Omit operation. These
Distributive forms correctly operate on union types, preserving optionality.
 */
type UnionKeys<T> = T extends any ? keyof T : never;
export type DistributivePick<T, K extends UnionKeys<T>> = T extends any
  ? Pick<T, Extract<keyof T, K>>
  : never;
export type DistributiveOmit<T, K extends UnionKeys<T>> = T extends any
  ? Omit<T, Extract<keyof T, K>>
  : never;


export default keysOf;