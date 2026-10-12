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
          <EuiPageSideBar
            @sticky={{true}}
            @paddingSize="m"
          >Side</EuiPageSideBar>
          <EuiPageBody @panelled={{true}}>
            <EuiPageContent
              @verticalPosition="center"
              @horizontalPosition="center"
            >
              <EuiPageContentHeader @responsive={{true}}>
                <EuiPageContentHeaderSection
                >Header</EuiPageContentHeaderSection>
              </EuiPageContentHeader>
              <EuiPageContentBody
                @paddingSize="s"
                @restrictWidth="600px"
              >Body</EuiPageContentBody>
            </EuiPageContent>
          </EuiPageBody>
        </EuiPage>
      </template>
    );

    // Legacy modifier classes are gone; check the computed latest styles.
    assert.dom('.euiPage').hasStyle({
      flexGrow: '1',
      maxWidth: '1200px',
      padding: '24px',
      flexDirection: 'column'
    });
    assert
      .dom('.euiPageSideBar')
      .hasStyle({ position: 'sticky', padding: '16px' })
      .hasText('Side');
    assert.dom('.euiPageBody[data-eui-panel]').exists('panelled body');
    assert
      .dom('.euiPageContent')
      .hasAttribute('role', 'main')
      .hasStyle({ alignSelf: 'center' });
    const content = getComputedStyle(
      this.element.querySelector('.euiPageContent')!
    );
    assert.strictEqual(
      content.marginLeft,
      content.marginRight,
      'horizontally centered by auto inline margins'
    );
    assert
      .dom('.euiPageContentHeader')
      .hasStyle({ display: 'flex', justifyContent: 'space-between' });
    assert.dom('.euiPageContentHeaderSection').hasText('Header');
    assert
      .dom('.euiPageContentBody')
      .hasStyle({ maxWidth: '600px', padding: '8px' })
      .hasText('Body');
  });

  test('no stray width class without restrictWidth', async function (assert) {
    await render(
      <template>
        <EuiPage class="page"><EuiPageContentBody
            class="body"
          >x</EuiPageContentBody></EuiPage>
      </template>
    );

    assert.dom('.page').hasStyle({ maxWidth: '100%' });
    assert.dom('.body').hasStyle({ maxWidth: 'none' });
  });

  test('EuiPageHeader: title, icon, description, tabs and right side items', async function (assert) {
    await render(
      <template>
        <EuiPageHeader
          @pageTitle="Dashboard"
          @iconType="dashboardApp"
          @description="Overview"
          @tabs={{TABS}}
          @bottomBorder={{true}}
        >
          <:rightSideItems as |Item|>
            <Item><EuiButton class="action">New</EuiButton></Item>
          </:rightSideItems>
        </EuiPageHeader>
      </template>
    );

    assert
      .dom('.euiPageHeader > .euiPageHeaderContent')
      .hasStyle({ borderBottomStyle: 'solid', borderBottomWidth: '1px' });
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
    await render(
      <template>
        <EuiPageHeaderSection>Section</EuiPageHeaderSection>
      </template>
    );

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
