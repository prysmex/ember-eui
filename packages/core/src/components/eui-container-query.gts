import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { htmlSafe } from '@ember/template';

import containerQuery from '../modifiers/container-query.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass } from '../utils/eui/styles.ts';
import { euiContainerCSS } from '../theming.ts';

import type { EuiContainerType } from '../theming.ts';

/**
 * A container that yields whether a CSS container query matches its width
 * or height (the Ember counterpart of upstream's `useEuiContainerQuery`):
 *
 * ```hbs
 * <EuiContainerQuery @condition="(width > 400px)" as |matches|>
 *   {{if matches "Wide" "Narrow"}}
 * </EuiContainerQuery>
 * ```
 *
 * It renders a `<div>` that establishes the container (`container-type:
 * inline-size` by default) and a hidden probe inside it that the query is
 * evaluated for. Prefer styling with `euiContainerQuery` in CSS; use this
 * when the result is needed in templates or JavaScript.
 */
export interface EuiContainerQuerySignature {
  Element: HTMLDivElement;
  Args: {
    /** A CSS container condition, e.g. `(min-width: 400px)`. */
    condition: string;
    /** Optional container name, e.g. `sidebar`. */
    name?: string;
    /**
     * The `container-type` of the container. Defaults to `'inline-size'`;
     * use `'size'` to query the height too (the container then needs a
     * height of its own).
     */
    type?: EuiContainerType;
    /** Called with the result on render and whenever it changes. */
    onChange?: (matches: boolean) => void;
  };
  Blocks: {
    /** Yields `true` while the container matches the condition. */
    default: [boolean];
  };
}

const PROBE_STYLE = htmlSafe('position:absolute;inline-size:0;block-size:0;overflow:hidden;visibility:hidden;pointer-events:none;');

export default class EuiContainerQuery extends Component<EuiContainerQuerySignature> {
  @tracked matches = false;

  @action
  setMatches(matches: boolean) {
    this.matches = matches;
    this.args.onChange?.(matches);
  }

  @cached
  get classes() {
    const context = getEuiThemeContext(this);

    return `euiContainerQuery ${euiClass(
      context,
      euiContainerCSS(this.args.type ?? 'inline-size', this.args.name),
      { position: 'relative' }
    )}`;
  }

  <template>
    <div class={{this.classes}} ...attributes>
      <span
        aria-hidden="true"
        style={{PROBE_STYLE}}
        {{containerQuery
          @condition
          name=@name
          onChange=this.setMatches
        }}
      ></span>
      {{yield this.matches}}
    </div>
  </template>
}
