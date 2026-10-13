/*
 * Ported from @elastic/eui 123.1.0 `services/window_event/window_event.tsx`.
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 */
import Helper from '@ember/component/helper';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

type Handler = (event: any) => void;

/**
 * Subscribes while rendered; changing the event or the handler
 * re-subscribes, and unrendering removes the listener.
 */
class Subscription extends Helper<{
  Args: { Positional: [string, Handler] };
  Return: undefined;
}> {
  private current?: { event: string; handler: Handler };

  compute([event, handler]: [string, Handler]) {
    this.detach();
    if (event && handler) {
      window.addEventListener(event, handler);
      this.current = { event, handler };
    }
    return undefined;
  }

  willDestroy() {
    super.willDestroy();
    this.detach();
  }

  private detach() {
    if (!this.current) return;
    window.removeEventListener(this.current.event, this.current.handler);
    this.current = undefined;
  }
}

export interface EuiWindowEventSignature {
  Args: {
    /** The window event name, e.g. `'keydown'` or `'mousemove'`. */
    event: keyof WindowEventMap | (string & {});
    /** Called with the event for as long as the component is rendered. */
    handler: (event: any) => void;
  };
}

/**
 * Declaratively adds a `window` event listener that is removed when the
 * component is no longer rendered. Renders nothing.
 */
const EuiWindowEvent: TemplateOnlyComponent<EuiWindowEventSignature> = <template>
  {{Subscription @event @handler}}
</template>;

export default EuiWindowEvent;
