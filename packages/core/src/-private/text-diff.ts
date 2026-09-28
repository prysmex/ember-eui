/** -1: only in the before text, 1: only in the after text, 0: in both. */
export type DiffOperation = -1 | 0 | 1;
export type DiffChunk = [DiffOperation, string];

/** Splits text into words and the whitespace between them. */
export function words(text: string): string[] {
  return text.match(/\s+|[^\s]+/g) ?? [];
}

/**
 * Diffs two lists of tokens (characters or words) with Myers' algorithm
 * and returns the text of consecutive tokens with the same operation.
 */
export function diffTokens(before: string[], after: string[]): DiffChunk[] {
  // common prefix and suffix need no search
  let start = 0;
  while (start < before.length && start < after.length && before[start] === after[start]) {
    start++;
  }

  let endBefore = before.length;
  let endAfter = after.length;
  while (endBefore > start && endAfter > start && before[endBefore - 1] === after[endAfter - 1]) {
    endBefore--;
    endAfter--;
  }

  const chunks: DiffChunk[] = [];
  const push = (operation: DiffOperation, token: string) => {
    const last = chunks[chunks.length - 1];

    if (last && last[0] === operation) {
      last[1] += token;
    } else {
      chunks.push([operation, token]);
    }
  };

  before.slice(0, start).forEach((token) => push(0, token));
  myers(before.slice(start, endBefore), after.slice(start, endAfter)).forEach(([op, token]) =>
    push(op, token)
  );
  before.slice(endBefore).forEach((token) => push(0, token));

  return chunks;
}

function myers(a: string[], b: string[]): DiffChunk[] {
  const n = a.length;
  const m = b.length;

  if (n === 0) return b.map((token) => [1, token]);
  if (m === 0) return a.map((token) => [-1, token]);

  const max = n + m;
  const offset = max + 1;
  const v = new Int32Array(2 * max + 3);
  // v's entries for diagonals -(d + 1)..(d + 1) at the start of each step
  const trace: Int32Array[] = [];

  let found = -1;

  for (let d = 0; d <= max && found < 0; d++) {
    trace.push(v.slice(offset - d - 1, offset + d + 2));

    for (let k = -d; k <= d; k += 2) {
      let x =
        k === -d || (k !== d && v[offset + k - 1]! < v[offset + k + 1]!)
          ? v[offset + k + 1]!
          : v[offset + k - 1]! + 1;
      let y = x - k;

      while (x < n && y < m && a[x] === b[y]) {
        x++;
        y++;
      }

      v[offset + k] = x;

      if (x >= n && y >= m) {
        found = d;
        break;
      }
    }
  }

  const reversed: DiffChunk[] = [];
  let x = n;
  let y = m;

  for (let d = found; d >= 0; d--) {
    const snapshot = trace[d]!;
    const at = (k: number) => snapshot[k + d + 1]!;
    const k = x - y;
    const prevK = k === -d || (k !== d && at(k - 1) < at(k + 1)) ? k + 1 : k - 1;
    const prevX = at(prevK);
    const prevY = prevX - prevK;

    while (x > prevX && y > prevY) {
      reversed.push([0, a[x - 1]!]);
      x--;
      y--;
    }

    if (d > 0) {
      if (x === prevX) {
        reversed.push([1, b[prevY]!]);
      } else {
        reversed.push([-1, a[prevX]!]);
      }
    }

    x = prevX;
    y = prevY;
  }

  return reversed.reverse();
}
