import { modifier } from "ember-modifier";

import { isWithinBreakpoints } from "../utils/breakpoint.ts";

import type { EuiBreakpointSize } from "../utils/breakpoint.ts";

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
