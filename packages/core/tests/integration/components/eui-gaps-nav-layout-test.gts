import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, settled, triggerEvent, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { array, hash } from '@ember/helper';

import EuiButton from '#src/components/eui-button.gts';
import EuiCollapsibleNavGroup from '#src/components/eui-collapsible-nav-group.gts';
import EuiContextMenu from '#src/components/eui-context-menu.gts';
import EuiFlexGrid from '#src/components/eui-flex-grid.gts';
import EuiFlexGroup from '#src/components/eui-flex-group.gts';
import EuiHeader from '#src/components/eui-header.gts';
import EuiPage from '#src/components/eui-page.gts';
import EuiPageHeader from '#src/components/eui-page-header.gts';
import EuiSideNav from '#src/components/eui-side-nav.gts';
import EuiStep from '#src/components/eui-step.gts';
import EuiSteps from '#src/components/eui-steps.gts';
import EuiTabbedContent from '#src/components/eui-tabbed-content.gts';

const Marker = <template><span class="marker">M</span></template>;
const Custom = <template><em class="custom-row">custom</em></template>;
const Link = <template><a class="custom-link" href={{@href}} ...attributes>{{yield}}</a></template>;

module('Integration | Component | nav and layout gaps', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiButton @minWidth sets the inline min-inline-size', async function (assert) {
    await render(
      <template>
        <EuiButton class="plain">a</EuiButton>
        <EuiButton class="px" @minWidth={{200}}>b</EuiButton>
        <EuiButton class="css" @minWidth="10rem">c</EuiButton>
      </template>
    );

    assert.dom('.plain').doesNotHaveAttribute('style');
    assert.dom('.px').hasStyle({ minInlineSize: '200px' });
    assert.dom('.css').hasAttribute('style', /min-inline-size: 10rem/);
  });

  test('EuiContextMenu @height fixes the height and scrolls the list', async function (assert) {
    const panels = [
      {
        id: 0,
        items: Array.from({ length: 30 }, (_, i) => ({ name: `Item ${i}` }))
      }
    ];

    await render(<template><EuiContextMenu @panels={{panels}} @initialPanelId={{0}} @height={{150}} /></template>);

    assert.dom('.euiContextMenu').hasStyle({ height: '150px' });
    const list = this.element.querySelector('.euiContextMenuPanel__list') as HTMLElement;
    assert.strictEqual(getComputedStyle(list).overflowY, 'auto', 'the list scrolls');
    assert.true(list.scrollHeight > list.clientHeight);
  });

  test('EuiContextMenu items: renderItem, separator props, icon component, toolTipProps', async function (assert) {
    const Icon = <template><span class="el-icon" ...attributes>i</span></template>;
    const panels = [
      {
        id: 0,
        items: [
          { name: 'One', icon: Icon, toolTipContent: 'Tip', toolTipProps: { title: 'Heading', anchorClassName: 'my-anchor' } },
          { isSeparator: true, margin: 'xl', className: 'sep', 'aria-label': 'divider', 'data-test-subj': 'sep' },
          { renderItem: Custom },
          { isSeparator: true, key: 'plain' },
          { name: 'Two' }
        ]
      }
    ];

    await render(<template><EuiContextMenu @panels={{panels}} @initialPanelId={{0}} /></template>);

    assert.dom('.custom-row').hasText('custom');
    assert.dom('hr.sep').hasAttribute('aria-label', 'divider').hasAttribute('data-test-subj', 'sep').hasAttribute('role', 'separator');
    assert.strictEqual(getComputedStyle(this.element.querySelector('hr.sep')!).marginBlockStart, '32px', 'margin xl');
    assert.strictEqual(getComputedStyle(this.element.querySelector('hr[role="separator"]:not(.sep)')!).marginBlockStart, '8px', 'default margin xs');
    assert.dom('.euiContextMenuItem .euiContextMenu__icon.el-icon').exists('icon component gets the icon class');
    assert.dom('.my-anchor').exists('tooltip anchor class');

    await triggerEvent('.my-anchor', 'mouseover');
    await waitUntil(() => document.querySelector('.euiToolTip__title'), { timeout: 5000 });
    assert.dom('.euiToolTip__title', document.body).hasText('Heading');
  });

  test('EuiCollapsibleNavGroup passes extraAction, arrowDisplay, paddingSize, buttonElement and onToggle to the accordion', async function (assert) {
    const calls: boolean[] = [];
    const onToggle = (isOpen: boolean) => calls.push(isOpen);

    await render(
      <template>
        <EuiCollapsibleNavGroup
          class="g1"
          @isCollapsible={{true}}
          @arrowDisplay="left"
          @paddingSize="l"
          @onToggle={{onToggle}}
        >
          <:title>Group</:title>
          <:extraAction as |isOpen|><button type="button" class="extra">{{if isOpen "open" "closed"}}</button></:extraAction>
          <:content>links</:content>
        </EuiCollapsibleNavGroup>
        <EuiCollapsibleNavGroup class="g4" @isCollapsible={{true}} @arrowDisplay="none">
          <:title>None</:title>
          <:content>links</:content>
        </EuiCollapsibleNavGroup>
        <EuiCollapsibleNavGroup class="g2" @isCollapsible={{true}} @buttonElement="div">
          <:title>Other</:title>
          <:content>links</:content>
        </EuiCollapsibleNavGroup>
        <EuiCollapsibleNavGroup class="g3" @isCollapsible={{true}}>
          <:title>Default</:title>
          <:content>links</:content>
        </EuiCollapsibleNavGroup>
      </template>
    );

    assert.dom('.g1 .euiAccordion__optionalAction .extra').hasText('open');
    assert.dom('.g1 .euiAccordion__triggerWrapper > :first-child').hasClass('euiAccordion__arrow', 'left arrow first');
    assert.dom('.g4 .euiAccordion__arrow').doesNotExist();
    assert.dom('.g2 div.euiAccordion__button').exists('buttonElement div');
    assert.dom('.g3 .euiAccordion__optionalAction').doesNotExist();
    assert.dom('.g3 .euiAccordion__arrow').exists('arrow stays on the right by default');
    assert.dom('.g3 .euiAccordion__triggerWrapper > :last-child').hasClass('euiAccordion__arrow');
    assert.strictEqual(getComputedStyle(this.element.querySelector('.g1 .euiAccordion__childWrapper > *')!).paddingBlockStart, '24px', 'paddingSize l');

    await click('.g1 button.euiAccordion__button');
    assert.deepEqual(calls, [false]);
    assert.dom('.g1 .extra').hasText('closed');
  });

  test('EuiSideNav: isOpen, icon component and renderItem', async function (assert) {
    const items = [
      {
        id: 'root',
        name: 'Root',
        icon: Marker,
        items: [
          { id: 'closed', name: 'Parent', onClick: () => {}, items: [{ id: 'kid', name: 'Kid' }] },
          { id: 'open', name: 'Opened', onClick: () => {}, isOpen: true, items: [{ id: 'kid2', name: 'Kid two' }] },
          { id: 'custom', name: 'Custom', href: '#c', renderItem: Link }
        ]
      }
    ];

    await render(<template><EuiSideNav @items={{items}} @mobileBreakpoints={{(array)}} /></template>);

    assert.dom('.euiSideNavItemButton__content .marker').exists('icon component rendered as is');
    assert.dom('.euiSideNavItem__items').exists();
    const texts = Array.from(this.element.querySelectorAll('.euiSideNavItemButton__label')).map((e) => e.textContent!.trim());
    assert.false(texts.includes('Kid'), 'closed parent hides its children');
    assert.true(texts.includes('Kid two'), 'isOpen opens an unselected parent');
    assert.dom('a.custom-link').hasAttribute('href', '#c').hasClass('euiSideNavItemButton').hasText('Custom');
  });

  test('EuiSideNav @renderItem applies to every item, an item renderItem wins', async function (assert) {
    const items = [
      { id: 'a', name: 'A', href: '#a' },
      { id: 'b', name: 'B', onClick: () => {}, renderItem: Custom }
    ];

    await render(<template><EuiSideNav @items={{items}} @renderItem={{Link}} @mobileBreakpoints={{(array)}} /></template>);

    assert.dom('a.custom-link').exists({ count: 1 });
    assert.dom('a.custom-link').hasText('A');
    assert.dom('.custom-row').exists({ count: 1 });
  });

  test('EuiSteps numbers its steps and passes titleSize and headingElement', async function (assert) {
    class State {
      @tracked extra = false;
    }
    const state = new State();

    await render(
      <template>
        <EuiSteps @firstStepNumber={{5}} @headingElement="h3" @titleSize="xs">
          <EuiStep @title="A">a</EuiStep>
          {{#if state.extra}}<EuiStep @title="Inserted">i</EuiStep>{{/if}}
          <EuiStep @title="B" @headingElement="h4">b</EuiStep>
          <EuiStep @title="C" @step={{42}}>c</EuiStep>
        </EuiSteps>
        <EuiSteps class="plain"><EuiStep @title="X">x</EuiStep><EuiStep @title="Y">y</EuiStep></EuiSteps>
      </template>
    );

    const numbers = () =>
      Array.from(this.element.querySelectorAll('.euiSteps:not(.plain) .euiStep')).map((step) => /Step (\d+)/.exec(step.querySelector('.euiStepNumber')!.textContent!)![1]);
    assert.deepEqual(numbers(), ['5', '6', '42']);
    assert.dom('h3.euiStep__title').hasText('A');
    assert.dom('h4.euiStep__title').hasText('B', 'step heading wins');
    assert.notStrictEqual(
      getComputedStyle(this.element.querySelector('h3.euiStep__title')!).fontSize,
      getComputedStyle(this.element.querySelector('.plain .euiStep__title')!).fontSize,
      'titleSize xs differs from the default s'
    );
    assert.deepEqual(Array.from(this.element.querySelectorAll('.plain .euiStep')).map((step) => /Step (\d+)/.exec(step.querySelector('.euiStepNumber')!.textContent!)![1]), ['1', '2']);

    state.extra = true;
    await settled();
    assert.deepEqual(numbers(), ['5', '6', '7', '42'], 'inserted step renumbers the rest');
  });

  test('EuiTabbedContent tabs take prepend, append, href, className and non-string names', async function (assert) {
    const Name = <template><b class="name-node">Rich</b></template>;
    const tabs = [
      { id: 'one', name: 'One', content: Custom, prepend: Marker, append: 'new', className: 'tab-one' },
      { id: 'two', name: Name, href: '#two', content: Custom }
    ];

    await render(<template><EuiTabbedContent @tabs={{tabs}} /></template>);

    assert.dom('#one').hasClass('tab-one');
    assert.dom('#one .euiTab__prepend .marker').exists();
    assert.dom('#one .euiTab__append').hasText('new');
    assert.dom('#two').hasTagName('a').hasAttribute('href', '#two');
    assert.dom('#two .name-node').hasText('Rich');
    assert.dom('#two .euiTab__prepend').doesNotExist();
  });

  test('EuiPageHeader forwards tabsProps, breadcrumbProps, rightSideGroupProps, pageTitleProps and iconProps', async function (assert) {
    const tabs = [{ label: 'Overview', isSelected: true }, { label: 'Other' }];
    const breadcrumbs = [{ text: 'Home', href: '#' }, { text: 'Page' }];

    await render(
      <template>
        <EuiPageHeader
          @pageTitle="Title"
          @iconType="gear"
          @breadcrumbs={{breadcrumbs}}
          @tabs={{tabs}}
          @tabsProps={{(hash className="my-tabs" aria-label="Page tabs" data-test-subj="tabs")}}
          @breadcrumbProps={{(hash className="my-crumbs" data-test-subj="crumbs" lastBreadcrumbIsCurrentPage=false)}}
          @pageTitleProps={{(hash className="my-title" aria-label="Heading" data-test-subj="title")}}
          @iconProps={{(hash className="my-icon" color="success" data-test-subj="icon")}}
          @rightSideGroupProps={{(hash className="my-group" gutterSize="xl" data-test-subj="group")}}
        >
          <:rightSideItems as |Item|><Item>x</Item></:rightSideItems>
        </EuiPageHeader>
      </template>
    );

    assert.dom('[data-test-subj="tabs"]').hasClass('my-tabs').hasAttribute('aria-label', 'Page tabs');
    assert.dom('[data-test-subj="crumbs"]').hasClass('my-crumbs');
    assert.dom('h1[data-test-subj="title"]').hasClass('my-title').hasAttribute('aria-label', 'Heading');
    assert.dom('[data-test-subj="icon"]').hasClass('my-icon');
    assert.dom('[data-test-subj="group"]').hasClass('my-group').hasStyle({ columnGap: '40px' });
  });

  test('EuiPage @css, EuiFlexGroup any @tagName and EuiFlexGrid @css', async function (assert) {
    const css = { outlineStyle: 'dashed', outlineWidth: '3px' };
    await render(
      <template>
        <EuiPage class="page" @css={{css}}>p</EuiPage>
        <EuiFlexGroup class="group" @tagName="section">g</EuiFlexGroup>
        <EuiFlexGroup class="list" @tagName="ul">l</EuiFlexGroup>
        <EuiFlexGroup class="dflt">d</EuiFlexGroup>
        <EuiFlexGrid class="grid" @css={{css}}>x</EuiFlexGrid>
      </template>
    );

    assert.dom('.page').hasStyle({ outlineStyle: 'dashed' });
    assert.dom('section.group').hasClass('euiFlexGroup');
    assert.dom('ul.list').hasStyle({ listStyleType: 'none' });
    assert.dom('div.dflt').exists();
    assert.dom('.grid').hasStyle({ outlineStyle: 'dashed', outlineWidth: '3px' });
  });

  test('EuiHeader @sections items take components, a block, and breadcrumbProps', async function (assert) {
    const sections = [
      { items: ['Text', Marker, { text: 'Legacy' }], breadcrumbs: [{ text: 'Home', href: '#' }, { text: 'Page' }], breadcrumbProps: { className: 'my-crumbs', 'data-test-subj': 'hb', max: 1 } }
    ];
    const blockSections = [{ items: [{ id: 1 }, { id: 2 }] }];

    await render(
      <template>
        <EuiHeader class="h1" @sections={{sections}} />
        <EuiHeader class="h2" @sections={{blockSections}}>
          <:sectionItem as |item index|><i class="blk">{{item.id}}-{{index}}</i></:sectionItem>
        </EuiHeader>
      </template>
    );

    assert.dom('.h1 .euiHeaderSectionItem').exists({ count: 3 });
    assert.dom('.h1 .euiHeaderSectionItem:nth-child(1)').hasText('Text');
    assert.dom('.h1 .marker').exists();
    assert.dom('.h1 .euiHeaderSectionItem:nth-child(3)').hasText('Legacy');
    assert.dom('.h1 [data-test-subj="hb"]').hasClass('my-crumbs');
    assert.dom('.h2 .blk').exists({ count: 2 });
    assert.dom('.h2 .euiHeaderSectionItem:nth-child(2) .blk').hasText('2-1');
  });
});
