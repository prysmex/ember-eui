import GlimmerComponent from '@glimmer/component';

interface EuiHeaderLinksArgs {
  popoverBreakpoints?: string[];
}
export default class EuiHeaderLinksComponent extends GlimmerComponent<EuiHeaderLinksArgs> {
  get popoverBreakpoints() {
    return this.args.popoverBreakpoints || ['xs', 's'];
  }

  get hasMobileVersion() {
    return this.popoverBreakpoints?.length > 0;
  }
}
