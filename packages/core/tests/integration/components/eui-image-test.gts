import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';

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

  test('<:caption> renders rich content and names the figure by its text', async function (assert) {
    await render(
      <template>
        <EuiImage @url={{URL}} @alt="" @allowFullScreen={{true}}>
          <:caption>Albert <strong>Einstein</strong>, physicist</:caption>
        </EuiImage>
      </template>
    );

    assert.dom('figure.euiImageWrapper figcaption.euiImageCaption strong').hasText('Einstein');
    assert.dom('figure.euiImageWrapper').hasAttribute('aria-label', 'Albert Einstein, physicist');

    await click('[data-test-subj="activateFullScreenButton"]');
    assert.dom('[data-test-subj="fullScreenOverlayMask"] figcaption strong', document.body).hasText('Einstein');
    assert
      .dom('[data-test-subj="fullScreenOverlayMask"] figure', document.body)
      .hasAttribute('aria-label', 'Albert Einstein, physicist');
  });

  test('a string @caption still labels the figure, and no caption adds no label', async function (assert) {
    await render(
      <template>
        <EuiImage @url={{URL}} @alt="a" @caption="Plain" />
        <EuiImage @url={{URL}} @alt="b" />
      </template>
    );

    assert.dom('figure:nth-of-type(1)').hasAttribute('aria-label', 'Plain');
    assert.dom('figure:nth-of-type(2)').doesNotHaveAttribute('aria-label');
    assert.dom('figcaption').exists({ count: 1 });
  });

  test('@width is set on the image, also in full screen', async function (assert) {
    await render(
      <template>
        <EuiImage @url={{URL}} @alt="Pixel" @width={{600}} @allowFullScreen={{true}} />
      </template>
    );

    assert.dom('button.euiImageButton img').hasAttribute('width', '600');
    await click('[data-test-subj="activateFullScreenButton"]');
    assert.dom('[data-test-subj="deactivateFullScreenButton"] img', document.body).hasAttribute('width', '600');
  });

  test('@wrapperProps decorate the figure', async function (assert) {
    const wrapperProps = {
      className: 'my-figure',
      id: 'fig-1',
      'data-test-subj': 'figure-subj',
      'aria-label': 'Custom name',
      style: { backgroundColor: 'rgb(255, 0, 0)' },
      css: { paddingInlineStart: '7px' }
    };
    await render(
      <template>
        <EuiImage @url={{URL}} @alt="" @caption="Caption" @wrapperProps={{wrapperProps}} />
      </template>
    );

    assert
      .dom('figure.euiImageWrapper.my-figure')
      .hasAttribute('id', 'fig-1')
      .hasAttribute('data-test-subj', 'figure-subj')
      .hasAttribute('aria-label', 'Custom name')
      .hasStyle({ backgroundColor: 'rgb(255, 0, 0)', paddingInlineStart: '7px' });
  });
});
