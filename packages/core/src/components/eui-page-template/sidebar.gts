import Component from '@glimmer/component';
import { assert } from '@ember/debug';
import { registerDestructor } from '@ember/destroyable';

import EuiPageSidebar from '../eui-page-sidebar.gts';

import type { EuiPageSidebarSignature } from '../eui-page-sidebar';
import type Owner from '@ember/owner';

/** How `T.Sidebar` tells its template that it is rendered. */
export interface EuiPageTemplateSidebarRegistry {
  /** Counts a rendered sidebar; returns the function that uncounts it. */
  register(): () => void;
}

/**
 * `T.Sidebar` of `EuiPageTemplate` (upstream `EuiPageTemplate.Sidebar`):
 * an `EuiPageSidebar` with the template's `@paddingSize` and
 * `@responsive`. Render it in the template's `<:sidebar as |T|>` block.
 */
export interface EuiPageTemplateSidebarSignature {
  Element: EuiPageSidebarSignature['Element'];
  Args: EuiPageSidebarSignature['Args'] & {
    /** @private Set by the template; absent in its default block. */
    registry?: EuiPageTemplateSidebarRegistry;
  };
  Blocks: EuiPageSidebarSignature['Blocks'];
}

/**
 * Upstream finds its sidebars by inspecting its children. Here each
 * rendered `T.Sidebar` registers with the template (derived state only:
 * a count), which renders the `<:sidebar>` block before the main element,
 * so the main element and its parts read the count after the sidebars
 * have registered, in the same render.
 */
export default class EuiPageTemplateSidebar extends Component<EuiPageTemplateSidebarSignature> {
  constructor(owner: Owner, args: EuiPageTemplateSidebarSignature['Args']) {
    super(owner, args);
    assert(
      'EuiPageTemplate: render `T.Sidebar` in the `<:sidebar as |T|>` block, not in the default block, so that it is placed beside the main content.',
      args.registry
    );
    registerDestructor(this, args.registry.register());
  }

  <template>
    <EuiPageSidebar
      @sticky={{@sticky}}
      @paddingSize={{@paddingSize}}
      @minWidth={{@minWidth}}
      @responsive={{@responsive}}
      @hasEmbellish={{@hasEmbellish}}
      @css={{@css}}
      ...attributes
    >{{yield}}</EuiPageSidebar>
  </template>
}
