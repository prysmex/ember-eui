import { throttle } from '@ember/runloop';
import Component from '@glimmer/component';
import { modifier } from 'ember-modifier';
import { EuiBreakpointSize, getBreakpoint } from '../../utils/breakpoint';
import { cached, tracked } from '@glimmer/tracking';

export type EuiBreadcrumbResponsiveMaxCount = {
  /**
   * Any of the following keys are allowed: `'xs' | 's' | 'm' | 'l' | 'xl'`
   * Omitting a key will display all breadcrumbs at that breakpoint
   */
  [key in EuiBreakpointSize]?: number;
};

const responsiveDefault: EuiBreadcrumbResponsiveMaxCount = {
  xs: 1,
  s: 2,
  m: 4
};

export type EuiBreadcrumb = {
  /**
   * Visible label of the breadcrumb
   */
  text: string;
  href?: string;
  onClick?: (e: MouseEvent) => void;
  /**
   * Force a max-width on the breadcrumb text
   */
  truncate?: boolean;

  'aria-current': string;
};

const onWindowResizeModifier = modifier(
  (
    _ele: HTMLElement,
    _pos,
    {
      functionToCallOnWindowResize
    }: { isDocked: boolean; functionToCallOnWindowResize: () => void }
  ) => {
    window.addEventListener('resize', functionToCallOnWindowResize);

    return () => {
      window.removeEventListener('resize', functionToCallOnWindowResize);
    };
  }
);

const limitedBreadcrumbs = (max: number, breadcrumbs: EuiBreadcrumb[]) => {
  const breadcrumbsAtStart = [];
  const breadcrumbsAtEnd = [];
  const limit = Math.min(max, breadcrumbs.length);
  const start = Math.floor(limit / 2);
  const overflowBreadcrumbs = breadcrumbs.slice(
    start,
    start + breadcrumbs.length - limit
  );

  if (overflowBreadcrumbs.length) {
    overflowBreadcrumbs[overflowBreadcrumbs.length - 1]['aria-current'] =
      'false';
  }

  for (let i = 0; i < limit; i++) {
    // We'll alternate with displaying breadcrumbs at the end and at the start, but be biased
    // towards breadcrumbs the end so that if max is an odd number, we'll have one more
    // breadcrumb visible at the end than at the beginning.
    const isEven = i % 2 === 0;

    // We're picking breadcrumbs from the front AND the back, so we treat each iteration as a
    // half-iteration.
    const normalizedIndex = Math.floor(i * 0.5);
    const indexOfBreadcrumb = isEven
      ? breadcrumbs.length - 1 - normalizedIndex
      : normalizedIndex;
    const breadcrumb = breadcrumbs[indexOfBreadcrumb];

    if (isEven) {
      breadcrumbsAtEnd.unshift(breadcrumb);
    } else {
      breadcrumbsAtStart.push(breadcrumb);
    }
  }

  if (max < breadcrumbs.length) {
    breadcrumbsAtStart.push({ ellipsis: true });
  }

  return {
    breadcrumbs: [...breadcrumbsAtStart, ...breadcrumbsAtEnd],
    overflowBreadcrumbs
  };
};

interface EuiBreadcrumbsComponentArgs {
  /**
   * Hides extra (above the max) breadcrumbs under a collapsed item as the window gets smaller.
   * Pass a custom #EuiBreadcrumbResponsiveMaxCount object to change the number of breadcrumbs to show at the particular breakpoints.
   *
   * Pass `false` to turn this behavior off.
   *
   * Default: `{ xs: 1, s: 2, m: 4 }`
   */
  responsive?: boolean | EuiBreadcrumbResponsiveMaxCount;

  /**
   * Forces all breadcrumbs to single line and
   * truncates each breadcrumb to a particular width,
   * except for the last item
   */
  truncate?: boolean;

  /**
   * Collapses the inner items past the maximum set here
   * into a single ellipses item.
   * Omitting or passing a `0` value will show all breadcrumbs.
   */
  max?: number | null;

  /**
   * The array of individual #EuiBreadcrumb items
   */
  breadcrumbs: EuiBreadcrumb[];
}

export default class EuiBreadcrumbsComponent extends Component<EuiBreadcrumbsComponentArgs> {
  onWidowResize = onWindowResizeModifier;
  @tracked currentBreakpoint;

  constructor(owner: unknown, args: EuiBreadcrumbsComponentArgs) {
    super(owner, args);
    this.currentBreakpoint = getBreakpoint(
      typeof window === 'undefined' ? -Infinity : window.innerWidth
    );
  }

  functionToCallOnWindowResize = () => {
    throttle(() => {
      const newBreakpoint = getBreakpoint(window.innerWidth);
      if (newBreakpoint !== this.currentBreakpoint) {
        this.currentBreakpoint = newBreakpoint;
      }
    }, 50);
  };

  get responsiveObject() {
    return typeof this.args.responsive === 'object'
      ? this.args.responsive
      : responsiveDefault;
  }

  get max() {
    return this.args.max || 5;
  }

  get calculatedMax(): EuiBreadcrumbsComponentArgs['max'] {
    // The max property collapses any breadcrumbs past the max quantity.
    // This is the same behavior we want for responsiveness.
    // So calculate the max value based on the combination of `max` and `responsive`
    let calculatedMax: EuiBreadcrumbsComponentArgs['max'] = this.max;
    // Set the calculated max to the number associated with the currentBreakpoint key if it exists
    if (
      this.args.responsive &&
      this.responsiveObject[this.currentBreakpoint as EuiBreakpointSize]
    ) {
      calculatedMax =
        this.responsiveObject[this.currentBreakpoint as EuiBreakpointSize];
    }
    // Final check is to make sure max is used over a larger breakpoint value
    if (this.max && calculatedMax) {
      calculatedMax = this.max < calculatedMax ? this.max : calculatedMax;
    }

    return calculatedMax;
  }

  @cached
  get limitedBreadcrumbs() {
    const calculatedMax = this.calculatedMax;
    return calculatedMax
      ? limitedBreadcrumbs(calculatedMax, this.args.breadcrumbs)
      : { breadcrumbs: this.args.breadcrumbs };
  }
}
