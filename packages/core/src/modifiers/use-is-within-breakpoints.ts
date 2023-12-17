import { modifier } from "ember-modifier";

import { isWithinBreakpoints } from "../utils/breakpoint";

import type { EuiBreakpointSize } from "../utils/breakpoint";

export interface Named {
  sizes: EuiBreakpointSize[];
  isActive: boolean;
  setIsWithinBreakpointsValue: (value: boolean) => void;
}

export default modifier(function (
  _element: Element,
  _pos: any[],
  {
    sizes,
    isActive = true,
    setIsWithinBreakpointsValue,
  }: Named,
) {
  function handleResize() {
    setIsWithinBreakpointsValue(isWithinBreakpoints(window.innerWidth, sizes));
  }

  if (isActive) {
    window.removeEventListener("resize", handleResize);
    window.addEventListener("resize", handleResize);
    handleResize();
  }

  return () => window.removeEventListener("resize", handleResize);
});
