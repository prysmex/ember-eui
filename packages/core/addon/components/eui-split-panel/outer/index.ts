import Component from '@glimmer/component';
import {
  EuiBreakpointSize,
  isWithinBreakpoints
} from '../../../utils/breakpoint';
import { modifier } from 'ember-modifier';
import { tracked } from '@glimmer/tracking';

const isWithinBreakpointsModifier = modifier(function (
  _element: Element,
  _pos: unknown[],
  {
    sizes,
    isActive = true,
    setIsWithinBreakpointsValue
  }: {
    sizes: EuiBreakpointSize[];
    isActive: boolean;
    setIsWithinBreakpointsValue: (value: boolean) => void;
  }
) {
  function handleResize() {
    setIsWithinBreakpointsValue(isWithinBreakpoints(window.innerWidth, sizes));
  }

  if (isActive) {
    window.removeEventListener('resize', handleResize);
    window.addEventListener('resize', handleResize);
    handleResize();
  }

  return () => window.removeEventListener('resize', handleResize);
});
export default class EuiSplitPanelOuterComponent extends Component {
  isWithinBreakpointsModifier = isWithinBreakpointsModifier;
  @tracked isResponsive = false;
}
