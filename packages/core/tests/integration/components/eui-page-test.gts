import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { hash } from '@ember/helper';
import { render } from '@ember/test-helpers';

import EuiButton from '#src/components/eui-button.gts';
import EuiPage from '#src/components/eui-page.gts';
import EuiPageBody from '#src/components/eui-page-body.gts';
import EuiPageContent from '#src/components/eui-page-content.gts';
import EuiPageContentBody from '#src/components/eui-page-content-body.gts';
import EuiPageContentHeader from '#src/components/eui-page-content-header.gts';
import EuiPageContentHeaderSection from '#src/components/eui-page-content-header-section.gts';
import EuiPageHeader from '#src/components/eui-page-header.gts';
import EuiPageHeaderSection from '#src/components/eui-page-header-section.gts';
import EuiPageSideBar from '#src/components/eui-page-side-bar.gts';
import EuiPageTemplate from '#src/components/eui-page-template.gts';

const TABS = [
  { id: 'a', label: 'Tab A', isSelected: true },
  { id: 'b', label: 'Tab B' }
];

module('Integration | Component | eui-page', function (hooks) {
  setupRenderingTest(hooks);

  test('the page building blocks compose', async function (assert) {
    await render(
      <template>
        <EuiPage @paddingSize="l" @direction="column" @restrictWidth={{true}}>
          <EuiPageSideBar @sticky={{true}} @paddingSize="m">Side</EuiPageSideBar>
          <EuiPageBody @panelled={{true}}>
            <EuiPageContent @verticalPosition="center" @horizontalPosition="center">
              <EuiPageContentHeader @responsive={{true}}>
                <EuiPageContentHeaderSection>Header</EuiPageContentHeaderSection>
              </EuiPageContentHeader>
              <EuiPageContentBody @paddingSize="s" @restrictWidth="600px">Body</EuiPageContentBody>
            </EuiPageContent>
          </EuiPageBody>
        </EuiPage>
      </template>
    );

    assert.dom('.euiPage').hasClass('euiPage--grow').hasClass('euiPage--restrictWidth-default').hasClass('euiPage--paddingLarge').hasClass('euiPage--column');
    assert.dom('.euiPageSideBar').hasClass('euiPageSideBar--sticky').hasText('Side');
    assert.dom('.euiPageBody.euiPanel').exists('panelled body');
    assert.dom('.euiPageContent').hasAttribute('role', 'main').hasClass('euiPageContent--verticalCenter').hasClass('euiPageContent--horizontalCenter');
    assert.dom('.euiPageContentHeader').hasClass('euiPageContentHeader--responsive');
    assert.dom('.euiPageContentHeaderSection').hasText('Header');
    assert.dom('.euiPageContentBody').hasClass('euiPage--restrictWidth-custom').hasStyle({ maxWidth: '600px' }).hasText('Body');
  });

  // Bug: without restrictWidth, EuiPage / EuiPageContentBody render a stray "euiPage--" class
  test.todo('no stray width class without restrictWidth', async function (assert) {
    await render(
      <template>
        <EuiPage class="page"><EuiPageContentBody class="body">x</EuiPageContentBody></EuiPage>
      </template>
    );

    assert.dom('.page').doesNotHaveClass('euiPage--');
    assert.dom('.body').doesNotHaveClass('euiPage--');
  });

  test('EuiPageHeader: title, icon, description, tabs and right side items', async function (assert) {
    await render(
      <template>
        <EuiPageHeader @pageTitle="Dashboard" @iconType="dashboardApp" @description="Overview" @tabs={{TABS}} @bottomBorder={{true}}>
          <:rightSideItems as |Item|>
            <Item><EuiButton class="action">New</EuiButton></Item>
          </:rightSideItems>
        </EuiPageHeader>
      </template>
    );

    assert.dom('.euiPageHeader').hasClass('euiPageHeader--bottomBorder').hasClass('euiPageHeader--responsive');
    assert.dom('.euiPageHeader h1.euiTitle').containsText('Dashboard');
    assert.dom('.euiPageHeader h1 svg.euiIcon').exists();
    assert.dom('.euiPageHeader').containsText('Overview');
    assert.dom('.euiPageHeaderContent__rightSideItems .action').exists();
  });

  test('EuiPageHeader with tabs and no title', async function (assert) {
    await render(<template><EuiPageHeader @tabs={{TABS}} /></template>);

    assert.dom('.euiPageHeader .euiTab').exists({ count: 2 });
    assert.dom('.euiPageHeader .euiTab-isSelected').hasText('Tab A');
  });

  test('EuiPageHeaderSection wraps content', async function (assert) {
    await render(<template><EuiPageHeaderSection>Section</EuiPageHeaderSection></template>);

    assert.dom('.euiPageHeaderSection').hasText('Section');
  });

  test('EuiPageTemplate renders side bar, header and content', async function (assert) {
    await render(
      <template>
        <EuiPageTemplate @pageHeader={{hash pageTitle="Template title"}}>
          <:pageSideBar><span class="side">side</span></:pageSideBar>
          <:default><p class="main">main content</p></:default>
        </EuiPageTemplate>
      </template>
    );

    assert.dom('.euiPage .euiPageSideBar .side').exists();
    assert.dom('.euiPage h1').containsText('Template title');
    assert.dom('.euiPage .main').hasText('main content');
  });
});
