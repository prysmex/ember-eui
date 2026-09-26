import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiMarkdownFormat from '#src/components/eui-markdown-format.gts';

const basic = '# Title\n\nSome **bold** text';
const checklist = '- [x] done\n- [ ] todo';

module('Integration | Component | eui-markdown-format', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders markdown to html', async function (assert) {
    await render(
      <template><EuiMarkdownFormat @value={{basic}} /></template>
    );

    assert.dom('h1').hasText('Title');
    assert.dom('strong').hasText('bold');
  });

  test('it renders plugin nodes through their component', async function (assert) {
    // the checkbox plugin sets `componentName` to a component class, which
    // eui-markdown-format invokes with (component CompNode.componentName)
    await render(
      <template><EuiMarkdownFormat @value={{checklist}} /></template>
    );

    assert.dom('input[type="checkbox"]').exists({ count: 2 });
    assert.dom('input[type="checkbox"]:checked').exists({ count: 1 });
  });
});
