import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import randomId from '../-private/random-id.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiHeaderAlertStyles } from '../utils/eui/styles.generated.ts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';

/** A news or update item, usually listed in a flyout opened from the header. */
export interface EuiHeaderAlertSignature {
  Element: HTMLElement;
  Blocks: {
    /** When it was published. */
    date: [];
    /** A badge next to the date, e.g. `<EuiBadge>7.0</EuiBadge>`. */
    badge: [];
    /** The title (rendered in an `<h3>` that labels the alert). */
    title: [];
    /** The text. */
    text: [];
    /** A link to read more, e.g. an `EuiLink`. */
    action: [];
  };
}

/** Upstream `EuiHeaderAlert` (`euiHeaderAlertStyles`). */
export default class EuiHeaderAlert extends Component<EuiHeaderAlertSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiHeaderAlertStyles);
    // React's global reset: border-box and no default heading/block margins.
    const reset = { boxSizing: 'border-box', margin: 0 } as const;
    return {
      root: euiClass(context, reset, styles.euiHeaderAlert),
      date: euiClass(context, reset, styles.euiHeaderAlert__date),
      title: euiClass(context, reset, styles.euiHeaderAlert__title),
      text: euiClass(context, reset, styles.euiHeaderAlert__text),
      action: euiClass(context, reset, styles.euiHeaderAlert__action)
    };
  }

  <template>
    {{#let (randomId) as |ariaId|}}
      <article
        aria-labelledby="{{ariaId}}-title"
        class="euiHeaderAlert {{this.classes.root}}"
        ...attributes
      >
        <EuiFlexGroup @justifyContent="spaceBetween">
          <EuiFlexItem>
            <div class="euiHeaderAlert__date {{this.classes.date}}">{{yield
                to="date"
              }}</div>
          </EuiFlexItem>
          {{#if (has-block "badge")}}
            <EuiFlexItem @grow={{false}}>{{yield to="badge"}}</EuiFlexItem>
          {{/if}}
        </EuiFlexGroup>

        <h3 id="{{ariaId}}-title" class="euiHeaderAlert__title {{this.classes.title}}">
          {{yield to="title"}}
        </h3>
        <div class="euiHeaderAlert__text {{this.classes.text}}">{{yield
            to="text"
          }}</div>
        {{#if (has-block "action")}}
          <div class="euiHeaderAlert__action {{this.classes.action}}">{{yield
              to="action"
            }}</div>
        {{/if}}
      </article>
    {{/let}}
  </template>
}
