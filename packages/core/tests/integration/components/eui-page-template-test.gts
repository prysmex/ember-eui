import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { array, hash } from '@ember/helper';
import { clearRender, render, rerender, settled } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiPageTemplate, {
  TEMPLATES
} from '#src/components/eui-page-template.gts';
import lightTheme from '../../../vendor/eui_theme_light.min.css?raw';
import darkTheme from '../../../vendor/eui_theme_dark.min.css?raw';

const SIDEBARS = [false, true];
const HEADERS = [false, true];
const MODES = [false, true, 'noscroll'] as const;

module('Integration | Component | eui-page-template', function (hooks) {
  setupRenderingTest(hooks);

  let widthDescriptor: PropertyDescriptor | undefined;
  hooks.beforeEach(function () {
    widthDescriptor = Object.getOwnPropertyDescriptor(window, 'innerWidth');
  });
  hooks.afterEach(function () {
    if (widthDescriptor)
      Object.defineProperty(window, 'innerWidth', widthDescriptor);
  });

  async function resize(width: number) {
    // Exercise the modifier's real resize listener. CSS viewport behavior is
    // checked separately with the bundled themes, without mocking innerWidth.
    Object.defineProperty(window, 'innerWidth', {
      configurable: true,
      value: width
    });
    window.dispatchEvent(new Event('resize'));
    await settled();
  }

  for (const template of TEMPLATES) {
    for (const sidebar of SIDEBARS) {
      for (const header of HEADERS) {
        test(`${template}, sidebar=${sidebar}, header=${header}: layout and landmarks`, async function (assert) {
          const pageHeader = header
            ? { pageTitle: 'Title', description: 'Description' }
            : undefined;

          await render(
            <template>
              <EuiPageTemplate
                @template={{template}}
                @pageHeader={{pageHeader}}
                @hasPageSideBarBlock={{sidebar}}
                class="custom-root"
                data-test-page
              >
                <:pageSideBar><nav
                    data-test-sidebar
                  >Navigation</nav></:pageSideBar>
                <:default><p data-test-content>Content</p></:default>
                <:bottomBar><button
                    type="button"
                    data-test-save
                  >Save</button></:bottomBar>
              </EuiPageTemplate>
            </template>
          );

          assert
            .dom('.euiPageTemplate')
            .exists({ count: 1 })
            .hasClass('custom-root')
            .hasClass('euiPage--grow')
            .hasAttribute('data-test-page')
            .hasStyle({ minHeight: '460px' });
          assert
            .dom('[data-test-content]')
            .exists({ count: 1 })
            .hasText('Content');
          assert
            .dom('[role="main"]')
            .exists(
              { count: 1 },
              'one main landmark, including nested centered content'
            );
          assert.dom('.euiPageContent--horizontalCenter').exists({
            count:
              template === 'centeredBody' || template === 'centeredContent'
                ? 1
                : 0
          });
          assert.dom('.euiPageHeader').exists({ count: header ? 1 : 0 });
          assert.dom('.euiPageSideBar').exists({ count: sidebar ? 1 : 0 });
          if (header) {
            assert.dom('.euiPageHeader h1').hasText('Title');
            assert.dom('.euiPageHeader').includesText('Description');
            assert.strictEqual(
              this.element
                .querySelector('.euiPageHeader')!
                .classList.contains('euiPageHeader--bottomBorder'),
              (!sidebar &&
                (template === 'centeredBody' || template === 'empty')) ||
                (sidebar && template === 'default'),
              'header border follows the v41 layout defaults'
            );
          }
          assert.strictEqual(
            this.element
              .querySelector('.euiPage > .euiPageBody')!
              .classList.contains('euiPanel'),
            sidebar &&
              (template === 'default' || template === 'centeredContent'),
            'only the appropriate sidebar layouts use a panelled body'
          );
          if (template === 'default' && !sidebar) {
            assert.strictEqual(
              this.element
                .querySelector('.euiPageContent')!
                .classList.contains('euiPanel--noBorder'),
              !header,
              'default content removes its theme border only without a header'
            );
          }
          if (sidebar)
            assert
              .dom('.euiPageSideBar')
              .hasClass('euiPageSideBar--sticky')
              .hasText('Navigation');
          assert
            .dom('.euiBottomBar')
            .exists(
              { count: template === 'default' ? 1 : 0 },
              'v41 only supports bottom bars in the default layout'
            );
          if (template === 'default')
            assert
              .dom('.euiBottomBar')
              .hasClass('euiBottomBar--sticky')
              .includesText('Save');
          for (const element of this.element.querySelectorAll('[class]')) {
            assert.false(
              element.classList.contains('undefined'),
              'optional props do not leak into classes'
            );
          }
        });
      }

      test(`${template}, sidebar=${sidebar}: nested props override layout defaults`, async function (assert) {
        await render(
          <template>
            <EuiPageTemplate
              @template={{template}}
              @hasPageSideBarBlock={{sidebar}}
              @restrictWidth="600px"
              @pageSideBarProps={{hash
                className="custom-sidebar"
                sticky=false
                paddingSize="s"
              }}
              @pageBodyProps={{hash
                className="custom-body"
                tagName="section"
                panelled=false
                paddingSize="s"
                restrictWidth=640
                style=(hash border-top-width="3px" border-top-style="solid")
              }}
              @pageContentProps={{hash
                className="custom-content"
                color="plain"
                hasBorder=true
                hasShadow=true
                borderRadius="m"
                grow=false
                paddingSize="s"
                role="article"
              }}
              @pageContentBodyProps={{hash
                className="custom-content-body"
                paddingSize="m"
                restrictWidth=450
                style=(hash border-top-width="5px" border-top-style="solid")
              }}
              @pageHeader={{hash
                className="custom-header"
                pageTitle="Custom title"
                pageTitleProps=(hash className="custom-title")
                description="Custom description"
                breadcrumbs=(array (hash text="Home" href="#home"))
                paddingSize="s"
                restrictWidth=550
                bottomBorder=true
                responsive="reverse"
                alignItems="bottom"
                style=(hash border-top-width="7px" border-top-style="solid")
              }}
            >
              <:pageSideBar>Side</:pageSideBar>
              <:default><p data-test-content>Content</p></:default>
            </EuiPageTemplate>
          </template>
        );

        assert
          .dom('.euiPage > section.custom-body')
          .exists()
          .hasClass('euiPageBody--paddingSmall')
          .doesNotHaveClass('euiPanel')
          .hasStyle({ maxWidth: '640px', borderTopWidth: '3px' });
        assert
          .dom('.custom-content')
          .exists({ count: 1 })
          .hasClass('euiPanel--plain')
          .hasClass('euiPanel--hasBorder')
          .hasClass('euiPanel--hasShadow')
          .hasClass('euiPanel--borderRadiusMedium')
          .hasClass('euiPanel--flexGrowZero')
          .hasClass('euiPanel--paddingSmall')
          .hasAttribute('role', 'article');
        assert
          .dom('.custom-content-body')
          .exists({ count: 1 })
          .hasText('Content')
          .hasStyle({ maxWidth: '450px', borderTopWidth: '5px' })
          .hasClass('euiPageContentBody--paddingMedium');
        assert
          .dom('.custom-header')
          .hasClass('euiPageHeader--paddingSmall')
          .hasClass('euiPageHeader--responsiveReverse')
          .hasClass('euiPageHeader--bottom')
          .hasClass('euiPageHeader--bottomBorder')
          .hasStyle({ maxWidth: '550px', borderTopWidth: '7px' });
        assert.dom('.custom-title').hasText('Custom title');
        assert.dom('.euiBreadcrumbs').includesText('Home');
        if (sidebar)
          assert
            .dom('.custom-sidebar')
            .hasClass('euiPageSideBar--paddingSmall')
            .doesNotHaveClass('euiPageSideBar--sticky');
      });

      test(`${template}, sidebar=${sidebar}: header blocks and their gates update independently`, async function (assert) {
        const state = new (class {
          @tracked title = true;
          @tracked description = true;
          @tracked extra = true;
          @tracked action = true;
          @tracked header:
            { pageTitle: string; description: string } | undefined;
        })();
        await render(
          <template>
            <EuiPageTemplate
              @template={{template}}
              @hasPageSideBarBlock={{sidebar}}
              @pageHeader={{state.header}}
              @hasPageHeaderPageTitleBlock={{state.title}}
              @hasPageHeaderDescriptionBlock={{state.description}}
              @hasPageHeaderDefaultBlock={{state.extra}}
              @hasPageHeaderRightSideItemsBlock={{state.action}}
            >
              <:pageSideBar>Side</:pageSideBar>
              <:pageHeaderPageTitle><span data-test-title>Block title</span></:pageHeaderPageTitle>
              <:pageHeaderDescription><span data-test-description>Block
                  description</span></:pageHeaderDescription>
              <:pageHeaderDefault><span
                  data-test-extra
                >Extra</span></:pageHeaderDefault>
              <:pageHeaderRightSideItems as |Item|><Item><button
                    data-test-action
                    type="button"
                  >Action</button></Item></:pageHeaderRightSideItems>
              <:default><p data-test-content>Content</p></:default>
            </EuiPageTemplate>
          </template>
        );
        assert.dom('.euiPageHeader').exists({ count: 1 });
        assert.dom('[data-test-title]').hasText('Block title');
        assert.dom('[data-test-description]').hasText('Block description');
        assert.dom('[data-test-extra]').hasText('Extra');
        assert
          .dom('.euiPageHeaderContent__rightSideItems [data-test-action]')
          .hasText('Action');

        const gates = ['title', 'description', 'extra', 'action'] as const;
        for (const gate of gates) {
          state[gate] = false;
          await rerender();
          for (const block of gates) {
            assert
              .dom(`[data-test-${block}]`)
              .exists(
                { count: state[block] ? 1 : 0 },
                `${gate} gate only affects its own block`
              );
          }
        }
        assert.dom('.euiPageHeader').doesNotExist();
        assert.dom('[data-test-content]').hasText('Content');
        state.header = {
          pageTitle: 'Argument title',
          description: 'Argument description'
        };
        await rerender();
        assert.dom('.euiPageHeader h1').hasText('Argument title');
        assert.dom('.euiPageHeader').includesText('Argument description');
        for (const gate of gates)
          assert
            .dom(`[data-test-${gate}]`)
            .doesNotExist('argument fallback does not resurrect a gated block');
        state.header = undefined;
        for (const gate of gates) state[gate] = true;
        await rerender();
        assert.dom('[data-test-action]').exists({ count: 1 });
      });

      test(`${template}, sidebar=${sidebar}: explicit false, zero and null overrides survive updates`, async function (assert) {
        const state = new (class {
          @tracked width: boolean | number = true;
          @tracked role: string | null = 'article';
          @tracked panelled = true;
          @tracked border = true;
        })();
        await render(
          <template>
            <EuiPageTemplate
              @template={{template}}
              @hasPageSideBarBlock={{sidebar}}
              @pageBodyProps={{hash
                panelled=state.panelled
                restrictWidth=state.width
              }}
              @pageContentProps={{hash
                role=state.role
                hasBorder=state.border
                hasShadow=state.border
              }}
              @pageContentBodyProps={{hash restrictWidth=state.width}}
              @pageHeader={{hash
                pageTitle="Title"
                restrictWidth=state.width
                bottomBorder=state.border
              }}
            >
              <:pageSideBar>Side</:pageSideBar>
              <:default><p data-test-content>Content</p></:default>
            </EuiPageTemplate>
          </template>
        );
        assert
          .dom('.euiPage > .euiPageBody')
          .hasClass('euiPanel')
          .hasClass('euiPageBody--restrictWidth-default');
        assert
          .dom('.euiPageContentBody')
          .hasClass('euiPage--restrictWidth-default');
        assert.dom('[role="article"]').exists({ count: 1 });
        state.width = 0;
        state.role = null;
        state.panelled = false;
        state.border = false;
        await rerender();
        assert
          .dom('.euiPage > .euiPageBody')
          .doesNotHaveClass('euiPanel')
          .hasStyle({ maxWidth: '0px' });
        assert.dom('.euiPageContentBody').hasStyle({ maxWidth: '0px' });
        assert
          .dom('.euiPageHeader')
          .hasStyle({ maxWidth: '0px' })
          .doesNotHaveClass('euiPageHeader--bottomBorder');
        assert.dom('[role="article"]').doesNotExist();
        assert.dom('[role="main"]').doesNotExist();
        const content = this.element
          .querySelector('[data-test-content]')!
          .closest('.euiPageContent')!;
        assert
          .dom(content)
          .doesNotHaveAttribute('role')
          .doesNotHaveClass('euiPanel--hasBorder')
          .doesNotHaveClass('euiPanel--hasShadow');
        state.width = false;
        await rerender();
        assert
          .dom('.euiPage > .euiPageBody')
          .hasStyle({ maxWidth: 'none' })
          .doesNotHaveClass('euiPageBody--restrictWidth-custom');
        assert.dom('.euiPageHeader').hasStyle({ maxWidth: 'none' });
        assert.dom('.euiPageContentBody').hasStyle({ maxWidth: 'none' });
      });

      for (const fullHeight of MODES) {
        test(`${template}, sidebar=${sidebar}, fullHeight=${fullHeight}: breakpoint and scroll transitions`, async function (assert) {
          await resize(1440);
          await render(
            <template>
              <EuiPageTemplate
                @template={{template}}
                @fullHeight={{fullHeight}}
                @hasPageSideBarBlock={{sidebar}}
              >
                <:pageSideBar>Side</:pageSideBar>
                <:default><p data-test-content>Content</p></:default>
                <:bottomBar>Save</:bottomBar>
              </EuiPageTemplate>
            </template>
          );
          const active =
            fullHeight !== false &&
            (template === 'default' || template === 'empty');
          assert.strictEqual(
            this.element
              .querySelector('.euiPageTemplate')!
              .classList.contains('eui-fullHeight'),
            active
          );
          const group = this.element.querySelector(
            '.euiPageContentBody > .euiFlexGroup'
          );
          assert.strictEqual(Boolean(group), active);
          if (active) {
            assert.dom('.euiPageContentBody').hasClass('eui-fullHeight');
            assert
              .dom(group!.querySelector('.euiFlexItem'))
              .hasClass(fullHeight === true ? 'eui-yScroll' : 'eui-fullHeight');
          }
          if (template === 'default')
            assert
              .dom('.euiBottomBar')
              .hasClass(
                active ? 'euiBottomBar--static' : 'euiBottomBar--sticky'
              );

          await resize(767);
          assert.dom('.euiPageTemplate').doesNotHaveClass('eui-fullHeight');
          assert.dom('.euiPageContentBody > .euiFlexGroup').doesNotExist();
          if (template === 'default')
            assert.dom('.euiBottomBar').hasClass('euiBottomBar--sticky');
          await resize(768);
          assert.strictEqual(
            this.element
              .querySelector('.euiPageTemplate')!
              .classList.contains('eui-fullHeight'),
            active,
            'medium breakpoint starts at 768px'
          );
          assert.dom('[data-test-content]').exists({ count: 1 });
        });
      }
    }
  }

  test('external template, width, height, padding and sidebar changes replace stale layout state', async function (assert) {
    const state = new (class {
      @tracked template: (typeof TEMPLATES)[number] = 'default';
      @tracked width: boolean | number | string = true;
      @tracked height: number | string = 0;
      @tracked sidebar = true;
      @tracked padding: 's' | 'm' | 'l' = 'l';
      @tracked grow = true;
    })();
    await render(
      <template>
        <EuiPageTemplate
          @template={{state.template}}
          @restrictWidth={{state.width}}
          @minHeight={{state.height}}
          @hasPageSideBarBlock={{state.sidebar}}
          @paddingSize={{state.padding}}
          @grow={{state.grow}}
          @pageHeader={{hash pageTitle="Title"}}
          class="root"
          style="background-color: rgb(1, 2, 3)"
        >
          <:pageSideBar>Side</:pageSideBar>
          <:default><p data-test-content>Content</p></:default>
        </EuiPageTemplate>
      </template>
    );
    assert
      .dom('.root')
      .hasStyle({ minHeight: '0px', backgroundColor: 'rgb(1, 2, 3)' });
    state.width = 680;
    state.height = 320;
    state.sidebar = false;
    state.padding = 's';
    state.grow = false;
    await rerender();
    assert
      .dom('.root')
      .hasStyle({ minHeight: '320px' })
      .doesNotHaveClass('euiPage--grow');
    assert.dom('.euiPageSideBar').doesNotExist();
    assert
      .dom('.euiPageContentBody')
      .hasStyle({ maxWidth: '680px' })
      .hasClass('euiPageContentBody--paddingSmall');
    state.template = 'centeredContent';
    state.width = '40rem';
    state.height = '50vh';
    await rerender();
    assert.dom('.root').hasAttribute('style', /min-height: 50vh/);
    assert.dom('.euiPageContentBody').hasAttribute('style', /max-width: 40rem/);
    assert.dom('.euiPageContent--horizontalCenter').exists({ count: 1 });
    state.template = 'empty';
    state.width = false;
    await rerender();
    assert.dom('.euiPageContent--horizontalCenter').doesNotExist();
    assert.dom('.euiPageBody--restrictWidth-default').doesNotExist();
    assert
      .dom('.euiPageContentBody')
      .doesNotHaveClass('euiPage--restrictWidth-custom');
    assert.dom('[data-test-content]').exists({ count: 1 });
  });

  test('bottom-bar overrides and visibility changes clean up body styles', async function (assert) {
    const state = new (class {
      @tracked visible = true;
    })();
    const padding = document.body.style.paddingBottom;
    await render(
      <template>
        <EuiPageTemplate
          @hasBottomBarBlock={{state.visible}}
          @bottomBarProps={{hash
            position="fixed"
            paddingSize="s"
            landmarkHeading="Save changes"
            bodyClassName="template-bar-open"
            left=12
          }}
        >
          <:default>Content</:default>
          <:bottomBar><button
              data-test-save
              type="button"
            >Save</button></:bottomBar>
        </EuiPageTemplate>
      </template>
    );
    assert
      .dom('.euiBottomBar', document.body)
      .hasClass('euiBottomBar--paddingSmall')
      .hasAria('label', 'Save changes')
      .hasStyle({ left: '12px' });
    assert.dom(document.body).hasClass('template-bar-open');
    state.visible = false;
    await rerender();
    assert.dom('.euiBottomBar', document.body).doesNotExist();
    assert.dom(document.body).doesNotHaveClass('template-bar-open');
    assert.strictEqual(document.body.style.paddingBottom, padding);
    state.visible = true;
    await rerender();
    await clearRender();
    assert.dom('.euiBottomBar', document.body).doesNotExist();
    assert.dom(document.body).doesNotHaveClass('template-bar-open');
    assert.strictEqual(document.body.style.paddingBottom, padding);
  });

  module('bundled v41.4.0 Amsterdam CSS', function (hooks) {
    let style: HTMLStyleElement;
    hooks.beforeEach(function () {
      style = document.createElement('style');
      document.head.append(style);
    });
    hooks.afterEach(function () {
      style.remove();
    });

    for (const [theme, css] of [
      ['light', lightTheme],
      ['dark', darkTheme]
    ]) {
      for (const template of TEMPLATES) {
        for (const sidebar of SIDEBARS) {
          test(`${theme}: ${template}, sidebar=${sidebar}: computed layout matches the shipped CSS`, async function (assert) {
            style.textContent = css!;
            const state = new (class {
              @tracked header: { pageTitle: string } | undefined = {
                pageTitle: 'Title'
              };
            })();
            await render(
              <template>
                <EuiPageTemplate
                  @template={{template}}
                  @hasPageSideBarBlock={{sidebar}}
                  @pageHeader={{state.header}}
                >
                  <:pageSideBar>Side</:pageSideBar>
                  <:default><p data-test-content>Content</p></:default>
                </EuiPageTemplate>
              </template>
            );
            assert
              .dom('.euiPageTemplate')
              .hasStyle({ display: 'flex', minHeight: '460px' });
            assert.dom('.euiPageContentBody').hasStyle({
              maxWidth: template === 'empty' && !sidebar ? 'none' : '1200px'
            });
            assert.dom('.euiPageHeader').hasStyle({
              maxWidth:
                (template === 'empty' || template === 'centeredBody') &&
                !sidebar
                  ? 'none'
                  : '1200px'
            });
            const content = this.element
              .querySelector('[data-test-content]')!
              .closest('.euiPageContent')!;
            assert.dom(content).hasStyle({
              padding:
                template === 'centeredBody' || template === 'centeredContent'
                  ? '24px'
                  : '0px'
            });
            if (template === 'centeredBody' || template === 'centeredContent')
              assert
                .dom(content)
                .hasStyle({ alignSelf: 'center', flexGrow: '0' });
            assert.dom(content).hasStyle({
              borderTopWidth: '0px'
            });
            if (template !== 'centeredBody')
              assert.dom(content).hasStyle({ boxShadow: 'none' });
            if (template === 'centeredContent')
              assert.dom(content).hasStyle({ boxShadow: 'none' });
            if (template === 'empty')
              assert.dom(content).hasStyle({
                backgroundColor: 'rgba(0, 0, 0, 0)',
                boxShadow: 'none'
              });
            if (sidebar)
              assert
                .dom('.euiPageSideBar')
                .hasStyle({ position: 'sticky', padding: '24px' });
            // Give the rendered markup a real CSS viewport; mocking innerWidth
            // exercises the modifier but cannot change media queries.
            const frame = document.createElement('iframe');
            frame.title = 'Responsive layout test';
            frame.style.height = '600px';
            this.element.append(frame);
            try {
              const doc = frame.contentDocument!;
              const themeStyle = doc.createElement('style');
              themeStyle.textContent = css!;
              doc.head.append(themeStyle);
              doc.body.append(
                this.element.querySelector('.euiPageTemplate')!.cloneNode(true)
              );
              for (const width of [375, 767, 768, 1200]) {
                frame.style.width = `${width}px`;
                const view = frame.contentWindow!;
                const page = doc.querySelector('.euiPageTemplate')!;
                assert.strictEqual(
                  view.getComputedStyle(page).flexDirection,
                  width < 768 ? 'column' : 'row',
                  `${width}px: CSS stacks the page below the medium breakpoint`
                );
                if (sidebar)
                  assert.strictEqual(
                    view.getComputedStyle(doc.querySelector('.euiPageSideBar')!)
                      .position,
                    width < 768 ? 'static' : 'sticky',
                    `${width}px: sticky sidebar only on medium screens and up`
                  );
              }
            } finally {
              frame.remove();
            }
            state.header = undefined;
            await rerender();
            assert.dom('.euiPageHeader').doesNotExist();
            if (template === 'default' && !sidebar)
              assert.dom('.euiPageContent').hasStyle({ borderTopWidth: '0px' });
          });
        }
      }
      for (const template of ['default', 'empty'] as const) {
        for (const sidebar of SIDEBARS) {
          test(`${theme}: ${template}, sidebar=${sidebar}: full height contains scrolling and switches modes`, async function (assert) {
            style.textContent = css!;
            await resize(1440);
            const state = new (class {
              @tracked mode: boolean | 'noscroll' = true;
            })();
            await render(
              <template>
                <div
                  style="height: 600px; display: flex; flex-direction: column;"
                >
                  <EuiPageTemplate
                    @template={{template}}
                    @hasPageSideBarBlock={{sidebar}}
                    @fullHeight={{state.mode}}
                    @minHeight={{0}}
                    @pageHeader={{hash pageTitle="Title"}}
                  >
                    <:pageSideBar>Side</:pageSideBar>
                    <:default><div
                        style="height: 2000px; flex-shrink: 0;"
                        data-test-tall
                      >Long content</div></:default>
                    <:bottomBar>Save</:bottomBar>
                  </EuiPageTemplate>
                </div>
              </template>
            );
            const scroll = this.element.querySelector(
              '.euiPageContentBody > .euiFlexGroup > .euiFlexItem'
            ) as HTMLElement;
            assert.dom(scroll).hasStyle({ overflowY: 'auto' });
            assert.true(
              scroll.scrollHeight > scroll.clientHeight,
              'content overflows its constrained viewport'
            );
            scroll.scrollTop = 100;
            assert.strictEqual(
              scroll.scrollTop,
              100,
              'the content actually scrolls'
            );
            assert.true(
              this.element
                .querySelector('.euiPageTemplate')!
                .getBoundingClientRect().height <= 600,
              'the page stays within its allocated height'
            );
            state.mode = 'noscroll';
            await rerender();
            assert
              .dom('.euiPageContentBody > .euiFlexGroup > .euiFlexItem')
              .hasClass('eui-fullHeight')
              .doesNotHaveClass('eui-yScroll')
              .hasStyle({ overflowY: 'hidden' });
            state.mode = false;
            await rerender();
            assert.dom('.euiPageTemplate').doesNotHaveClass('eui-fullHeight');
            assert.dom('.euiPageContentBody > .euiFlexGroup').doesNotExist();
            assert.dom('[data-test-tall]').exists({ count: 1 });
          });
        }
      }
    }
  });
});
