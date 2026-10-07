import { tracked } from '@glimmer/tracking';
import Helper from '@ember/component/helper';
import { cancel, later } from '@ember/runloop';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * Keeps its content shown for a minimum time once it appears, even if
 * `@hide` becomes true sooner, e.g. so a fast loading indicator does not
 * flash.
 */
export interface EuiDelayHideSignature {
  Args: {
    /** Hides the content (once it has been shown for the minimum time). */
    hide?: boolean;
    /** Milliseconds the content stays at least. Defaults to `1000`. */
    minimumDuration?: number;
  };
  Blocks: {
    /** The content. */
    default: [];
  };
}

/**
 * Whether the content is shown. Each time it appears a countdown starts;
 * it may hide once the latest countdown has expired.
 */
class IsShown extends Helper<{
  Args: { Positional: [hide: boolean | undefined, minimumDuration: number | undefined] };
  Return: boolean;
}> {
  countdown = 0;
  @tracked expiredCountdown = 0;
  timer?: ReturnType<typeof later>;
  wasHidden?: boolean;

  compute([hide, minimumDuration]: [boolean | undefined, number | undefined]): boolean {
    const hidden = Boolean(hide);

    // becoming visible starts a countdown, unless one is running
    if (!hidden && this.wasHidden !== false && !this.timer) {
      const countdown = ++this.countdown;

      this.timer = later(() => {
        this.timer = undefined;
        this.expiredCountdown = countdown;
      }, minimumDuration ?? 1000);
    }

    this.wasHidden = hidden;

    // hidden from the start (no countdown yet) shows nothing
    return !hidden || (this.countdown > 0 && this.expiredCountdown !== this.countdown);
  }

  willDestroy(): void {
    super.willDestroy();
    if (this.timer) cancel(this.timer);
  }
}

const EuiDelayHide: TemplateOnlyComponent<EuiDelayHideSignature> = <template>
  {{#if (IsShown @hide @minimumDuration)}}
    {{yield}}
  {{/if}}
</template>;

export default EuiDelayHide;
