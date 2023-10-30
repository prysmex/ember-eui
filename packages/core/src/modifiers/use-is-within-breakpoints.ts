import { isWithinBreakpoints } from "../utils/breakpoint";
import type { EuiBreakpointSize } from "../utils/breakpoint";
import { modifier } from "ember-modifier";

export default modifier(function (
  _element: Element,
  _pos: unknown[],
  {
    sizes,
    isActive = true,
    setIsWithinBreakpointsValue,
  }: {
    sizes: EuiBreakpointSize[];
    isActive: boolean;
    setIsWithinBreakpointsValue: (value: boolean) => void;
  },
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
