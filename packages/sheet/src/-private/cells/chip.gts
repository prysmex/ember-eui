/**
 * A chip in a cell (the single-select, multi-select and linked-record
 * cells): the DOM `<EuiBadge @color=…>` renders for a `<span>` badge (no
 * `@onClick`, `@href` or icon), with the same classes, built from the same
 * styles, and the same `title`, computed from the text instead of read
 * back from the DOM. EuiBadge's `EuiInnerText` sets its `title` with a
 * tracked write after the render (and another when the badge goes), which
 * makes the grid render again on every scroll step; a cell's chip needs
 * neither (READINESS.md, Performance, step 1).
 */
import { warn } from '@ember/debug';

import {
  euiBadgeReset,
  BADGE_COLORS
} from '@ember-eui/core/components/eui-badge';
import {
  euiClass,
  useEuiBorealisStyles
} from '@ember-eui/core/utils/eui/styles';
import {
  euiBadgeStyles,
  getCustomInteractiveColors,
  getIsValidColor,
  getTextColor
} from '@ember-eui/core/utils/eui/styles.generated';

import type { TemplateOnlyComponent } from '@ember/component/template-only';
import type { EuiThemeContext } from '@ember-eui/core/utils/emotion/context';

/** The classes of a chip's three spans (after `euiBadge`, `euiBadge__content`, `euiBadge__text`). */
export interface ChipClasses {
  root: string;
  content: string;
  text: string;
}

type Upstream = EuiThemeContext['upstream'];
/** Emotion's style object (the sheet does not depend on Emotion itself). */
type CSSObject = ReturnType<typeof euiBadgeReset>;

const NAMED: readonly string[] = BADGE_COLORS;

// Per resolved theme: EuiBadge builds these objects on every render; the
// same object each time lets `euiClass` find its class without Emotion.
const resets = new WeakMap<Upstream, CSSObject>();
const customColors = new WeakMap<
  Upstream,
  Map<string, CSSObject | undefined>
>();

function resetCss(upstream: Upstream): CSSObject {
  let css = resets.get(upstream);
  if (!css) resets.set(upstream, (css = euiBadgeReset(upstream)));
  return css;
}

/** EuiBadge's `customColorCss`: a CSS colour's custom properties. */
function customColorCss(
  upstream: Upstream,
  color: string
): CSSObject | undefined {
  let byColor = customColors.get(upstream);
  if (!byColor) customColors.set(upstream, (byColor = new Map()));
  if (byColor.has(color)) return byColor.get(color);
  let css: CSSObject | undefined;
  try {
    const textColor = getTextColor(upstream, color) as string;
    const interactive = getCustomInteractiveColors(upstream, color) as {
      backgroundHover: string;
      backgroundActive: string;
    };
    css = {
      '--euiBadgeBackgroundColor': color,
      '--euiBadgeTextColor': textColor,
      '--euiBadgeBackgroundHoverColor': interactive.backgroundHover,
      '--euiBadgeBackgroundActiveColor': interactive.backgroundActive
    };
  } catch {
    warn(
      `EuiBadge expects a valid color: a hex, rgb(a) or hsv value, or one of ${BADGE_COLORS.join(', ')}. Instead got ${color}.`,
      Boolean(getIsValidColor(color)),
      { id: 'ember-eui.eui-badge.invalid-color' }
    );
    css = undefined;
  }
  byColor.set(color, css);
  return css;
}

/**
 * The classes `<EuiBadge @color={{color}}>` gives its root, content and
 * text spans (a span badge with text: not clickable, not disabled, no
 * `@fill`, no icon, no `@css`), in the order EuiBadge composes them.
 */
export function chipClasses(
  context: EuiThemeContext,
  color: string
): ChipClasses {
  const upstream = context.upstream;
  const styles = useEuiBorealisStyles(context, euiBadgeStyles);
  const isNamed = NAMED.includes(color);
  return {
    root: euiClass(
      context,
      resetCss(upstream),
      undefined,
      styles.euiBadge,
      undefined,
      undefined,
      isNamed
        ? styles.colors.base[color as keyof typeof styles.colors.base]
        : undefined,
      undefined,
      undefined,
      isNamed ? undefined : customColorCss(upstream, color),
      undefined
    ),
    content: euiClass(context, styles.euiBadge__content),
    text: euiClass(context, styles.text.euiBadge__text, undefined)
  };
}

// The white space `innerText` collapses (CSS "document white space"; not
// NBSP, which it keeps).
const COLLAPSIBLE = /[\t\n\f\r ]+/g;
const EDGES = /^ | $/g;

/**
 * The badge's `title`: the text as `innerText` reads it on the badge
 * (`white-space: nowrap`): runs of white space as one space, none at the
 * ends.
 */
export function chipTitle(text: string): string {
  return text.replace(COLLAPSIBLE, ' ').replace(EDGES, '');
}

interface ChipSignature {
  Args: { classes: ChipClasses; title: string };
  Blocks: { default: [] };
}

/** `<Chip @classes={{…}} @title={{…}}>text</Chip>`: EuiBadge's span, without its after-render title. */
const Chip: TemplateOnlyComponent<ChipSignature> = <template>
  <span
    class="euiBadge {{@classes.root}}"
    title={{@title}}
    data-test-subj="euiSheetChip"
  ><span class="euiBadge__content {{@classes.content}}"><span
        class="euiBadge__text {{@classes.text}}"
      >{{yield}}</span></span></span>
</template>;

export default Chip;
