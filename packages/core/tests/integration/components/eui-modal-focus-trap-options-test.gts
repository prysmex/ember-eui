import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { hash } from '@ember/helper';
import { click, render } from '@ember/test-helpers';
import Component from '@glimmer/component';

import { or } from 'ember-truth-helpers';

import EuiModal from '#src/components/eui-modal.gts';
import type { EuiModalSignature } from '#src/components/eui-modal.gts';

// a `(noop true)`-style helper: returns a function that returns `value`
const returns = (value: boolean) => () => value;

class ModalWithDefaultOptions extends Component<{
  Args: { focusTrapOptions?: EuiModalSignature['Args']['focusTrapOptions'] };
}> {
  allowOutsideClick = (event: MouseEvent | TouchEvent) => event.isTrusted;

  <template>
    <EuiModal
      @focusTrapOptions={{or
        @focusTrapOptions
        (hash allowOutsideClick=this.allowOutsideClick)
      }}
    >
      <p>Hello</p>
    </EuiModal>
  </template>
}

module(
  'Integration | Component | eui-modal | @focusTrapOptions',
  function (hooks) {
    setupRenderingTest(hooks);

    test('allowOutsideClick can be a function returned by a helper', async function (assert) {
      await render(
        <template>
          <EuiModal @focusTrapOptions={{hash allowOutsideClick=(returns true)}}>
            <p>Hello</p>
          </EuiModal>
        </template>
      );

      assert.dom('.euiModal', document.body).exists();
    });

    test('allowOutsideClick can be a function decided per click', async function (assert) {
      const events: Event[] = [];
      const allowOutsideClick = (event: MouseEvent | TouchEvent) => {
        events.push(event);
        return true;
      };

      await render(
        <template>
          <EuiModal
            @focusTrapOptions={{hash allowOutsideClick=allowOutsideClick}}
          >
            <p>Hello</p>
          </EuiModal>
        </template>
      );

      await click(document.querySelector('.euiOverlayMask') as Element);

      assert.ok(events.length > 0, 'focus-trap asked the function');
      assert.ok(events.every((e) => e instanceof MouseEvent));
    });

    test('a component can default @focusTrapOptions to a function option', async function (assert) {
      await render(<template><ModalWithDefaultOptions /></template>);

      assert.dom('.euiModal', document.body).exists();
    });
  }
);
