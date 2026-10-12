import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiImage from '#src/components/eui-image.gts';

const URL = 'data:image/gif;base64,R0lGODlhAQABAAAAACw=';

module('Integration | Component | eui-image', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders the image without an inline style by default', async function (assert) {
    await render(<template><EuiImage @url={{URL}} @alt="Pixel" /></template>);

    // Upstream class names: `euiImage` on the img, `euiImageWrapper` on the figure.
    assert.dom('figure.euiImageWrapper img.euiImage').hasAttribute('src', URL);
    assert.dom('img.euiImage').hasAttribute('alt', 'Pixel');
    assert.dom('img.euiImage').doesNotHaveAttribute('style');
  });

  test('a numeric @size becomes an inline max size', async function (assert) {
    await render(
      <template><EuiImage @url={{URL}} @alt="Pixel" @size={{120}} /></template>
    );

    assert.dom('img.euiImage').hasStyle({ maxWidth: '120px' });
  });

  test('allowFullScreen renders the image inside a button', async function (assert) {
    await render(
      <template>
        <EuiImage @url={{URL}} @alt="Pixel" @allowFullScreen={{true}} />
      </template>
    );

    assert.dom('button.euiImageButton img.euiImage').exists();
    assert.dom('img.euiImage').doesNotHaveAttribute('style');
  });
});
