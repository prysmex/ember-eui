import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, waitUntil } from '@ember/test-helpers';

import EuiNotificationEvent from '#src/components/eui-notification-event.gts';
import EuiNotificationEventMessages from '#src/components/eui-notification-event-messages.gts';

const MESSAGES = ['First message', 'Second message', 'Third message'];

module('Integration | Component | eui-notification-event', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders meta, title, messages and actions', async function (assert) {
    let titleClicks = 0;
    const onClickTitle = () => titleClicks++;

    await render(
      <template>
        <EuiNotificationEvent
          @id="event-1"
          @type="Alert"
          @severity="Critical"
          @badgeColor="danger"
          @iconType="alert"
          @iconAriaLabel="Alert icon"
          @time="1 min ago"
          @title="CPU usage above 90%"
          @onClickTitle={{onClickTitle}}
          @messages={{MESSAGES}}
          @accordionButtonText="+ 2 more"
          @accordionHideText="hide"
        >
          <:primaryAction><button type="button" class="primary">View</button></:primaryAction>
          <:contextMenu><span class="menu-item">Mute</span></:contextMenu>
        </EuiNotificationEvent>
      </template>
    );

    assert.dom('article.euiNotificationEvent').exists();
    assert.dom('.euiNotificationEventMeta__badge').containsText('Alert').containsText('Critical').hasClass('euiBadge');
    assert.dom('.euiNotificationEventMeta__icon').hasAttribute('aria-label', 'Alert icon').doesNotHaveAttribute('aria-hidden');
    assert.dom('.euiNotificationEventMeta__time').hasText('1 min ago');
    assert.dom('.euiNotificationEventMeta').hasClass('euiNotificationEventMeta--hasContextMenu');
    assert.dom('button.euiNotificationEvent__title h2').hasText('CPU usage above 90%');
    assert.dom('article').hasAttribute('aria-labelledby', document.querySelector('.euiNotificationEvent__title')!.id);
    assert.dom('.euiNotificationEventMessages > .euiText p').hasText('First message');
    assert.dom('.euiNotificationEvent__primaryAction .primary').exists();

    await click('button.euiNotificationEvent__title');
    assert.strictEqual(titleClicks, 1);
  });

  test('read state with a read button or icon', async function (assert) {
    const read: boolean[] = [];
    const onRead = () => read.push(true);

    await render(
      <template>
        <EuiNotificationEvent @id="a" @title="Unread with button" @messages={{MESSAGES}} @isRead={{false}} @onRead={{onRead}} class="with-button" />
        <EuiNotificationEvent @id="b" @title="Read icon" @messages={{MESSAGES}} @isRead={{true}} class="with-icon" />
      </template>
    );

    assert.dom('.with-button').hasClass('euiNotificationEvent--withReadState');
    assert.dom('.with-button .euiNotificationEventReadButton').hasAttribute('aria-label', 'Mark Unread with button as read').hasAttribute('title', 'Unread');
    await click('.with-button .euiNotificationEventReadButton');
    assert.deepEqual(read, [true]);

    assert.dom('.with-icon .euiNotificationEventReadIcon').hasClass('euiNotificationEventReadIcon--isRead');
    assert.dom('.with-icon .euiNotificationEventReadIcon svg').hasAttribute('aria-label', 'Read icon is read');
    assert.dom('.with-icon .euiNotificationEvent__title').hasClass('euiNotificationEvent__title--isRead');
  });

  test('the context menu opens from the meta button', async function (assert) {
    await render(
      <template>
        <EuiNotificationEvent @id="c" @title="With menu" @time="now" @messages={{MESSAGES}}>
          <:contextMenu><span class="menu-item">Mute</span></:contextMenu>
        </EuiNotificationEvent>
      </template>
    );

    assert.dom('.euiNotificationEventMeta__contextMenuWrapper .euiButtonIcon').hasAttribute('aria-expanded', 'false');
    await click('.euiNotificationEventMeta__contextMenuWrapper .euiButtonIcon');
    await waitUntil(() => document.querySelector('.menu-item'));
    assert.dom('.menu-item', document.body).hasText('Mute');
    assert.dom('.euiNotificationEventMeta__contextMenuWrapper .euiButtonIcon').hasAttribute('aria-expanded', 'true');
  });

  test('messages: the first is visible, the rest in an accordion', async function (assert) {
    await render(
      <template><EuiNotificationEventMessages @messages={{MESSAGES}} @accordionButtonText="+ 2 more" @accordionHideText="hide" /></template>
    );

    assert.dom('.euiNotificationEventMessages__accordionButton').containsText('+ 2 more');
    await click('.euiNotificationEventMessages__accordionButton');
    assert.dom('.euiNotificationEventMessages__accordionContent p').exists({ count: 2 });
  });

  test('repeated messages are all kept', async function (assert) {
    const repeated = ['Retry', 'Retry', 'Retry'];

    await render(<template><EuiNotificationEventMessages @messages={{repeated}} @accordionButtonText="more" /></template>);

    await click('.euiNotificationEventMessages__accordionButton');
    assert.dom('.euiNotificationEventMessages__accordionContent p').exists({ count: 2 });
  });
});
