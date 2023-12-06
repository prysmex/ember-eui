declare module 'mdast-util-to-hast/lib/all' {
  import { Node } from 'unist';
  import { H } from 'mdast-util-to-hast';

  const all: (h: H, node: Node) => Node[];
  export = all;
}