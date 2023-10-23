import Component from '@glimmer/component';

export interface EuiSideNavArgs {
  /**
   * Required otherwise nothing ever gets returned
   */
  children: Component;

  mobileBreakpoints?: string[];
}

export default class EuiSideNavComponent extends Component<EuiSideNavArgs> {
  get mobileBreakpoints() {
    return this.args.mobileBreakpoints || ['xs', 's'];
  }

  get contentClasses() {
    return `euiSideNav__content ${this.mobileBreakpoints
      .map?.((breakpointName) => {
        return `euiSideNav__contentMobile-${breakpointName}`;
      })
      .join(' ')}`;
  }

  get hasMobileVersion() {
    return this.mobileBreakpoints?.length > 0;
  }
}
