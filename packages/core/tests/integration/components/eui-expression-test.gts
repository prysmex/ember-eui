import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';

import EuiExpression from '#src/components/eui-expression.gts';

module('Integration | Component | eui-expression', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders a description and a value', async function (assert) {
    await render(<template><EuiExpression @description="when" @value="avg()" /></template>);

    assert
      .dom('span.euiExpression')
      .hasClass('euiExpression--success')
      .hasClass('euiExpression-isUppercase')
      .doesNotHaveClass('euiExpression-isClickable');
    assert.dom('.euiExpression__description').hasText('when');
    assert.dom('.euiExpression__value').hasText('avg()');
  });

  test('@onClick makes it a button', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(<template><EuiExpression @description="is above" @value="100" @onClick={{onClick}} @isActive={{true}} /></template>);

    assert.dom('button.euiExpression').hasClass('euiExpression-isClickable').hasClass('euiExpression-isActive');
    await click('button.euiExpression');
    assert.strictEqual(clicks, 1);
  });

  test('@isInvalid shows danger with an alert icon', async function (assert) {
    await render(<template><EuiExpression @description="when" @value="?" @color="primary" @isInvalid={{true}} /></template>);

    assert.dom('.euiExpression').hasClass('euiExpression--danger').doesNotHaveClass('euiExpression--primary');
    assert.dom('.euiExpression__icon').exists();
  });

  test('columns display and blocks', async function (assert) {
    await render(
      <template>
        <EuiExpression @display="columns" @descriptionWidth={{100}} @uppercase={{false}}>
          <:description><em>from</em></:description>
          <:value><strong>logs-*</strong></:value>
        </EuiExpression>
      </template>
    );

    assert.dom('.euiExpression').hasClass('euiExpression--columns').doesNotHaveClass('euiExpression-isUppercase');
    assert.dom('.euiExpression__description').hasStyle({ flexBasis: '100px' });
    assert.dom('.euiExpression__description em').hasText('from');
    assert.dom('.euiExpression__value strong').hasText('logs-*');
  });
});
