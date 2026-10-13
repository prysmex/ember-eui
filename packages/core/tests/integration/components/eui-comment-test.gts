import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { settled, render } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

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

    // upstream derives the type from the content (no modifier classes)
    assert.dom('.euiCommentList .euiComment .euiCommentEvent').hasAttribute('data-type', 'regular');
    assert.dom('.euiCommentEvent__headerUsername').hasText('janed');
    assert.dom('.euiCommentEvent__headerEvent').hasText('added a comment');
    assert.dom('.euiCommentEvent__headerTimestamp time').hasText('on Jan 1');
    assert.dom('.euiCommentEvent__body p').hasText('Looks good');
    assert.dom('.euiComment .euiCommentAvatar svg.euiIcon').hasAttribute('data-icon-type', 'user', 'default user timeline avatar');
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

    assert.dom('.euiCommentEvent').hasAttribute('data-type', 'update');
    assert.dom('.euiCommentEvent__headerEvent').hasText('added a tag');
    assert.dom('.euiCommentAvatar svg.euiIcon').hasAttribute('data-icon-type', 'tag');
  });

  test('@comments render comments from data: text and component nodes, ahead of the block', async function (assert) {
    const Actions = <template><button type="button" class="copy">Copy</button></template>;
    const Body = <template><p class="rich">Looks <em>good</em></p></template>;
    const Avatar = <template><span class="custom-avatar">J</span></template>;
    const comments = [
      {
        username: 'janed',
        event: 'added a comment',
        timestamp: 'on Jan 1',
        body: Body,
        actions: Actions,
        timelineAvatarAriaLabel: 'Jane Doe'
      },
      { username: 'juanab', event: 'pushed', timestamp: 'on Jan 3' },
      { username: 'pancho', event: 'edited', eventIcon: 'pencil', eventIconAriaLabel: 'edit' },
      { username: 'Assistant', body: 'An error occurred', eventColor: 'danger', timelineIcon: Avatar }
    ];
    await render(
      <template>
        <EuiCommentList @comments={{comments}} aria-label="Comment list example">
          <EuiComment><:username>block user</:username><:event>from block</:event></EuiComment>
        </EuiCommentList>
      </template>
    );

    assert.dom('ol.euiCommentList').hasAttribute('aria-label', 'Comment list example');
    assert.dom('.euiComment').exists({ count: 5 });
    assert.dom('.euiComment:nth-child(1) .euiCommentEvent').hasAttribute('data-type', 'regular');
    assert.dom('.euiComment:nth-child(1) .euiCommentEvent__body .rich em').hasText('good');
    assert.dom('.euiComment:nth-child(1) .euiCommentEvent__headerActions .copy').exists();
    assert.dom('.euiComment:nth-child(1) .euiCommentEvent__headerUsername').hasText('janed');
    assert.dom('.euiComment:nth-child(1) [aria-label="Jane Doe"]').exists();
    assert.dom('.euiComment:nth-child(2) .euiCommentEvent').hasAttribute('data-type', 'update');
    assert.dom('.euiComment:nth-child(2) .euiCommentEvent__headerActions').doesNotExist();
    assert.dom('.euiComment:nth-child(3) .euiCommentEvent__headerEventIcon').exists();
    assert.dom('.euiComment:nth-child(4) .euiCommentEvent').hasAttribute('data-type', 'custom');
    assert.dom('.euiComment:nth-child(4) .custom-avatar').exists();
    assert.dom('.euiComment:nth-child(5) .euiCommentEvent__headerUsername').hasText('block user');
  });

  test('@comments update reactively', async function (assert) {
    class State {
      @tracked comments = [{ username: 'one', event: 'did' }];
    }
    const state = new State();
    await render(<template><EuiCommentList @comments={{state.comments}} /></template>);
    assert.dom('.euiComment').exists({ count: 1 });

    state.comments = [...state.comments, { username: 'two', event: 'did too' }];
    await settled();
    assert.dom('.euiComment').exists({ count: 2 });
    assert.dom('.euiComment:nth-child(2) .euiCommentEvent__headerUsername').hasText('two');
  });
});
