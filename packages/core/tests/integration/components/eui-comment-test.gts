import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiComment from '#src/components/eui-comment.gts';
import EuiCommentList from '#src/components/eui-comment-list.gts';

module('Integration | Component | eui-comment', function (hooks) {
  setupRenderingTest(hooks);

  test('a regular comment with header and body inside a list', async function (assert) {
    await render(
      <template>
        <EuiCommentList>
          <EuiComment>
            <:username>janed</:username>
            <:event>added a comment</:event>
            <:timestamp>on Jan 1</:timestamp>
            <:body><p>Looks good</p></:body>
          </EuiComment>
        </EuiCommentList>
      </template>
    );

    assert.dom('.euiCommentList .euiComment').hasClass('euiComment--hasBody');
    assert.dom('.euiCommentEvent__headerUsername').hasText('janed');
    assert.dom('.euiCommentEvent__headerEvent').hasText('added a comment');
    assert.dom('.euiCommentEvent__headerTimestamp time').hasText('on Jan 1');
    assert.dom('.euiCommentEvent__body p').hasText('Looks good');
    assert.dom('.euiCommentTimeline svg.euiIcon').exists('default user timeline icon');
  });

  test('an update comment without body and a custom timeline icon', async function (assert) {
    await render(
      <template>
        <EuiComment @type="update" @timelineIcon="tag">
          <:username>bot</:username>
          <:event>added a tag</:event>
        </EuiComment>
      </template>
    );

    assert.dom('.euiComment').hasClass('euiComment--update');
    assert.dom('.euiCommentEvent__headerEvent').hasText('added a tag');
    assert.dom('.euiCommentTimeline svg.euiIcon').exists();
  });
});
