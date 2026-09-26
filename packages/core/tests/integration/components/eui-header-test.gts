import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, rerender } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiHeader from '#src/components/eui-header.gts';
import EuiHeaderAlert from '#src/components/eui-header-alert.gts';
import EuiHeaderBreadcrumbs from '#src/components/eui-header-breadcrumbs.gts';
import EuiHeaderLink from '#src/components/eui-header-link.gts';
import EuiHeaderLinks from '#src/components/eui-header-links.gts';
import EuiHeaderLogo from '#src/components/eui-header-logo.gts';
import EuiHeaderSection from '#src/components/eui-header-section.gts';
import EuiHeaderSectionItem from '#src/components/eui-header-section-item.gts';
import EuiHeaderSectionItemButton from '#src/components/eui-header-section-item-button.gts';

module('Integration | Component | eui-header', function (hooks) {
  setupRenderingTest(hooks);

  test('it composes sections, items, logo, links and buttons', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(
      <template>
        <EuiHeader @theme="dark">
          <EuiHeaderSection @grow={{true}}>
            <EuiHeaderSectionItem @border="right">
              <EuiHeaderLogo @href="#home" @iconTitle="Home">Brand</EuiHeaderLogo>
            </EuiHeaderSectionItem>
          </EuiHeaderSection>
          <EuiHeaderSection @side="right">
            <EuiHeaderSectionItem>
              <EuiHeaderLinks @gutterSize="s">
                <EuiHeaderLink @isActive={{true}} class="active">Docs</EuiHeaderLink>
                <EuiHeaderLink @href="#blog" class="blog">Blog</EuiHeaderLink>
              </EuiHeaderLinks>
            </EuiHeaderSectionItem>
            <EuiHeaderSectionItem @border="none">
              <EuiHeaderSectionItemButton @notification={{3}} @onClick={{onClick}} aria-label="News">
                N
              </EuiHeaderSectionItemButton>
            </EuiHeaderSectionItem>
          </EuiHeaderSection>
        </EuiHeader>
      </template>
    );

    assert.dom('.euiHeader').hasClass('euiHeader--dark').hasClass('euiHeader--static');
    assert.dom('.euiHeaderSection--grow').exists();
    assert.dom('.euiHeaderSection--right').exists();
    assert.dom('.euiHeaderSectionItem--borderRight a.euiHeaderLogo').hasAttribute('href', '#home');
    assert.dom('.euiHeaderLogo svg.euiHeaderLogo__icon').hasAttribute('aria-label', 'Home');
    assert.dom('.euiHeaderLogo svg.euiHeaderLogo__icon').doesNotHaveAttribute('aria-hidden');
    assert.dom('.euiHeaderLogo__text').hasText('Brand');
    assert.dom('.euiHeaderLinks__list').hasClass('euiHeaderLinks__list--gutterS');
    assert.dom('.active').hasClass('euiHeaderLink-isActive').hasClass('euiButtonEmpty--primary');
    assert.dom('a.blog').hasClass('euiButtonEmpty--text').hasAttribute('href', '#blog');
    assert.dom('.euiHeaderSectionItemButton .euiHeaderSectionItemButton__content').hasText('N');
    assert.dom('.euiHeaderSectionItemButton__notification--badge').hasText('3');

    await click('.euiHeaderSectionItemButton');
    assert.strictEqual(clicks, 1);
  });

  test('a boolean notification renders a dot', async function (assert) {
    await render(
      <template><EuiHeaderSectionItemButton @notification={{true}} aria-label="Alerts">A</EuiHeaderSectionItemButton></template>
    );

    assert.dom('svg.euiHeaderSectionItemButton__notification--dot').exists();
  });

  test('a fixed header adds a body class while rendered', async function (assert) {
    class State {
      @tracked show = true;
    }
    const state = new State();

    await render(<template>{{#if state.show}}<EuiHeader @position="fixed">Fixed</EuiHeader>{{/if}}</template>);

    assert.dom('.euiHeader').hasClass('euiHeader--fixed');
    assert.dom(document.body).hasClass('euiBody--headerIsFixed');

    state.show = false;
    await rerender();
    assert.dom(document.body).doesNotHaveClass('euiBody--headerIsFixed');
  });

  test('@sections renders section items and breadcrumbs', async function (assert) {
    const sections = [
      { items: [{ text: 'Left item' }], breadcrumbs: [{ text: 'Home', href: '#' }, { text: 'Page' }], border: 'right' }
    ];

    await render(<template><EuiHeader @sections={{sections}} /></template>);

    assert.dom('.euiHeaderSectionItem').hasText('Left item');
    assert.dom('.euiHeaderBreadcrumbs .euiBreadcrumb').exists({ count: 2 });
  });

  test('EuiHeaderBreadcrumbs truncates', async function (assert) {
    const crumbs = [{ text: 'A' }, { text: 'B' }];

    await render(<template><EuiHeaderBreadcrumbs @breadcrumbs={{crumbs}} /></template>);

    assert.dom('nav.euiHeaderBreadcrumbs').hasClass('euiBreadcrumbs--truncate');
  });

  test('EuiHeaderAlert renders its blocks', async function (assert) {
    await render(
      <template>
        <EuiHeaderAlert>
          <:date>Today</:date>
          <:badge><span class="badge">New</span></:badge>
          <:title>Release</:title>
          <:text>Version 2 is out</:text>
          <:action><a href="#notes">Read more</a></:action>
        </EuiHeaderAlert>
      </template>
    );

    assert.dom('article.euiHeaderAlert .euiHeaderAlert__date').hasText('Today');
    assert.dom('.euiHeaderAlert .badge').hasText('New');
    assert.dom('h3.euiHeaderAlert__title').hasText('Release');
    assert.dom('article').hasAttribute('aria-labelledby', document.querySelector('h3.euiHeaderAlert__title')!.id);
    assert.dom('.euiHeaderAlert__text').hasText('Version 2 is out');
    assert.dom('.euiHeaderAlert__action a').hasAttribute('href', '#notes');
  });
});
