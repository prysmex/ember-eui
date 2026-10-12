import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { array, hash } from '@ember/helper';
import { clearRender, render, rerender, settled } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiPageTemplate, {
  TEMPLATES
} from '#src/components/eui-page-template.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

const SIDEBARS = [false, true];
const HEADERS = [false, true];
const MODES = [false, true, 'noscroll'] as const;

/** A theme color as computed `rgb()`. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.append(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

/**
 * Copies markup and every stylesheet rule (including Emotion's inserted
 * rules) into an iframe of the given width, so media queries are evaluated
 * against a real viewport (see eui-flex-family-test).
 */
function inViewport(width: number, html: string) {
  const iframe = document.createElement('iframe');
  iframe.style.cssText = `position:fixed;top:0;left:0;width:${width}px;height:800px;border:0;visibility:hidden`;
  document.body.appendChild(iframe);
  const css = Array.from(document.styleSheets)
    .map((sheet) => {
      try {
        return Array.from(sheet.cssRules)
          .map((rule) => rule.cssText)
          .join('\n');
      } catch {
        return '';
      }
    })
    .join('\n');
  const doc = iframe.contentDocument!;
  doc.open();
  doc.write(
    `<!doctype html><html><head><style>${css}</style></head><body style="margin:0">${html}</body></html>`
  );
  doc.close();
  const win = iframe.contentWindow!;
  const el = (selector: string) => {
    const element = doc.querySelector(selector);
    if (!element) throw new Error(`Missing ${selector}`);
    return element;
  };
  return {
    rect: (selector: string) => el(selector).getBoundingClientRect(),
    style: (selector: string) => win.getComputedStyle(el(selector)),
    remove: () => iframe.remove()
  };
}

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
            .hasStyle({ flexGrow: '1' })
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
              getComputedStyle(
                this.element.querySelector('.euiPageHeaderContent')!
              ).borderBottomStyle === 'solid',
              (!sidebar &&
                (template === 'centeredBody' || template === 'empty')) ||
                (sidebar && template === 'default'),
              'header border follows the v41 layout defaults'
            );
          }
          assert.strictEqual(
            this.element
              .querySelector('.euiPage > .euiPageBody')!
              .hasAttribute('data-eui-panel'),
            sidebar &&
              (template === 'default' || template === 'centeredContent'),
            'only the appropriate sidebar layouts use a panelled body'
          );
          if (template === 'default' && !sidebar) {
            assert.strictEqual(
              getComputedStyle(
                this.element.querySelector('.euiPageContent')!,
                '::after'
              ).content !== 'none',
              header,
              'default content removes its theme border only without a header'
            );
          }
          if (sidebar)
            assert
              .dom('.euiPageSideBar')
              .hasStyle({ position: 'sticky' })
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
          .hasStyle({ padding: '8px' })
          .doesNotHaveAttribute('data-eui-panel')
          .hasStyle({ maxWidth: '640px', borderTopWidth: '3px' });
        assert
          .dom('.custom-content')
          .exists({ count: 1 })
          .hasClass('euiPanel--plain')
          .hasClass('euiPanelBorealis')
          .hasStyle({ paddingTop: '8px', flexGrow: '0', boxShadow: 'none' })
          .hasAttribute('role', 'article');
        const surface = this.element.querySelector('.custom-content')!;
        assert.strictEqual(
          getComputedStyle(surface, '::after').borderTopWidth,
          '1px',
          'latest panel border uses a pseudo element'
        );
        assert.strictEqual(
          getComputedStyle(surface).borderRadius,
          resolveBorealisTheme('light').euiTheme.border.radius.panel
        );
        assert
          .dom('.custom-content-body')
          .exists({ count: 1 })
          .hasText('Content')
          .hasStyle({ maxWidth: '450px', borderTopWidth: '5px', padding: '16px' });
        // Upstream splits header padding: inline on the header, block on its
        // content (with the `true` bottom border); the max width centers the
        // content while the header stays full width.
        assert
          .dom('.custom-header')
          .hasStyle({
            paddingLeft: '8px',
            paddingRight: '8px',
            paddingTop: '0px',
            borderTopWidth: '7px',
            maxWidth: 'none'
          });
        assert.dom('.custom-header > .euiPageHeaderContent').hasStyle({
          maxWidth: '550px',
          paddingTop: '8px',
          paddingBottom: '8px',
          borderBottomWidth: '1px',
          borderBottomStyle: 'solid'
        });
        assert
          .dom('.custom-header .euiPageHeaderContent__top')
          .hasStyle({ alignItems: 'flex-end' });
        assert.dom('.custom-title').hasText('Custom title');
        assert.dom('.euiBreadcrumbs').includesText('Home');
        if (sidebar)
          assert
            .dom('.custom-sidebar')
            .hasStyle({ padding: '8px', position: 'static' });
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
          .hasAttribute('data-eui-panel')
          .hasStyle({ maxWidth: '1200px' });
        assert.dom('.euiPageContentBody').hasStyle({ maxWidth: '1200px' });
        assert.dom('[role="article"]').exists({ count: 1 });
        state.width = 0;
        state.role = null;
        state.panelled = false;
        state.border = false;
        await rerender();
        assert
          .dom('.euiPage > .euiPageBody')
          .doesNotHaveAttribute('data-eui-panel')
          .hasStyle({ maxWidth: '0px' });
        assert.dom('.euiPageContentBody').hasStyle({ maxWidth: '0px' });
        assert
          .dom('.euiPageHeaderContent')
          .hasStyle({ maxWidth: '0px', borderBottomWidth: '0px' });
        assert.dom('[role="article"]').doesNotExist();
        assert.dom('[role="main"]').doesNotExist();
        const content = this.element
          .querySelector('[data-test-content]')!
          .closest('.euiPageContent')!;
        assert
          .dom(content)
          .doesNotHaveAttribute('role')
          .hasStyle({ boxShadow: 'none', borderTopWidth: '0px' });
        assert.strictEqual(
          getComputedStyle(content, '::after').content,
          'none',
          'explicit false removes the native panel border'
        );
        state.width = false;
        await rerender();
        assert
          .dom('.euiPage > .euiPageBody')
          .hasStyle({ maxWidth: '100%' }, 'upstream body max-width');
        assert.dom('.euiPageHeaderContent').hasStyle({ maxWidth: 'none' });
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
      .hasStyle({ minHeight: '320px', flexGrow: '0' });
    assert.dom('.euiPageSideBar').doesNotExist();
    assert
      .dom('.euiPageContentBody')
      .hasStyle({ maxWidth: '680px', padding: '8px' });
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
    for (const body of this.element.querySelectorAll('.euiPageBody'))
      assert.dom(body).hasStyle({ maxWidth: '100%' });
    assert.dom('.euiPageContentBody').hasStyle({ maxWidth: 'none' });
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
      .hasClass('euiBottomBar--fixed')
      .hasStyle({ padding: '8px', position: 'fixed' })
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

  // Formerly "bundled v41.4.0 Amsterdam CSS": the template now composes
  // latest Borealis styles, so the same layout contract is checked without
  // any legacy stylesheet (the core harness never loads one).
  module('latest Borealis layout without legacy CSS', function () {
    for (const mode of ['light', 'dark'] as const) {
      for (const template of TEMPLATES) {
        for (const sidebar of SIDEBARS) {
          test(`${mode}: ${template}, sidebar=${sidebar}: computed layout`, async function (assert) {
            const theme = resolveBorealisTheme(mode).euiTheme;
            const state = new (class {
              @tracked header: { pageTitle: string } | undefined = {
                pageTitle: 'Title'
              };
            })();
            await render(
              <template>
                <EuiEmotionProvider @colorMode={{mode}} @globalStyles={{false}} @wrapper={{false}}>
                  <EuiPageTemplate
                    @template={{template}}
                    @hasPageSideBarBlock={{sidebar}}
                    @pageHeader={{state.header}}
                  >
                    <:pageSideBar>Side</:pageSideBar>
                    <:default><p data-test-content>Content</p></:default>
                  </EuiPageTemplate>
                </EuiEmotionProvider>
              </template>
            );
            assert
              .dom('.euiPageTemplate')
              .hasStyle({ display: 'flex', minHeight: '460px' });
            // Without a side bar, the centered body and empty layouts restrict
            // the body; the others restrict the header content and body.
            const bodyRestricts =
              (template === 'empty' || template === 'centeredBody') &&
              !sidebar;
            assert.dom('.euiPageTemplate > .euiPageBody').hasStyle({
              maxWidth: bodyRestricts ? '1200px' : '100%'
            });
            assert.dom('.euiPageContentBody').hasStyle({
              maxWidth: template === 'empty' && !sidebar ? 'none' : '1200px'
            });
            assert.dom('.euiPageHeaderContent').hasStyle({
              maxWidth: bodyRestricts ? 'none' : '1200px'
            });
            const content = this.element
              .querySelector('[data-test-content]')!
              .closest('.euiPageContent')!;
            assert.dom(content).hasStyle({
              padding:
                template === 'centeredBody' || template === 'centeredContent'
                  ? theme.size.l
                  : '0px',
              borderTopWidth: '0px'
            });
            if (template === 'centeredBody' || template === 'centeredContent')
              assert.dom(content).hasStyle({ flexGrow: '0' });
            if (template !== 'centeredBody')
              assert.dom(content).hasStyle({ boxShadow: 'none' });
            if (template === 'empty')
              assert.dom(content).hasStyle({
                backgroundColor: 'rgba(0, 0, 0, 0)',
                boxShadow: 'none'
              });
            const panelledBody =
              sidebar &&
              (template === 'default' || template === 'centeredContent');
            if (panelledBody)
              assert
                .dom('.euiPageTemplate > .euiPageBody')
                .hasStyle({ backgroundColor: rgb(theme.colors.backgroundBasePlain) });
            if (sidebar)
              assert.dom('.euiPageSideBar').hasStyle({
                position: 'sticky',
                padding: theme.size.l,
                minWidth: '248px',
                overflowY: 'auto'
              });
            // Give the rendered markup a real CSS viewport: the markup and
            // every inserted Emotion rule are copied into iframes.
            for (const width of [375, 767, 768, 1200]) {
              const frame = inViewport(
                width,
                this.element.querySelector('.euiPageTemplate')!.outerHTML
              );
              try {
                assert.strictEqual(
                  frame.style('.euiPageTemplate').flexDirection,
                  width < theme.breakpoint.m ? 'column' : 'row',
                  `${width}px: the page stacks below the medium breakpoint`
                );
                if (sidebar) {
                  assert.strictEqual(
                    frame.style('.euiPageSideBar').position,
                    width < theme.breakpoint.m ? 'static' : 'sticky',
                    `${width}px: sticky sidebar only on medium screens and up`
                  );
                  assert.strictEqual(
                    Math.round(frame.rect('.euiPageSideBar').width),
                    width < theme.breakpoint.m
                      ? Math.round(frame.rect('.euiPageTemplate').width)
                      : 248,
                    `${width}px: the sidebar is full width only when stacked`
                  );
                }
              } finally {
                frame.remove();
              }
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
          test(`${mode}: ${template}, sidebar=${sidebar}: full height contains scrolling and switches modes`, async function (assert) {
            await resize(1440);
            const state = new (class {
              @tracked mode: boolean | 'noscroll' = true;
            })();
            await render(
              <template>
                <EuiEmotionProvider @colorMode={{mode}} @globalStyles={{false}} @wrapper={{false}}>
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
                </EuiEmotionProvider>
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
