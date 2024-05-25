declare module 'mdast-util-to-hast/lib/all' {
  import { H } from 'mdast-util-to-hast';
  import { Node } from 'unist';

  const all: (h: H, node: Node) => Node[];
  export = all;
}
