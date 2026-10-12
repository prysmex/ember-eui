import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createRequire, Module } from 'node:module';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { readFileSync } from 'node:fs';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(resolve(root, 'packages/core/package.json'));
const { buildSync } = require('esbuild');
const source = resolve(root, 'packages/core/src/utils/eui/styles.generated.ts');
const bundle = buildSync({
  entryPoints: [source],
  bundle: true,
  write: false,
  format: 'cjs',
  platform: 'node',
  external: [
    '@elastic/eui-theme-common',
    '@elastic/eui-theme-borealis',
    '@emotion/serialize',
    'chroma-js'
  ]
});
const filename = resolve(root, 'packages/core/eui-style-parity.cjs');
const adapted = new Module(filename);
adapted.paths = Module._nodeModulePaths(dirname(filename));
adapted._compile(bundle.outputFiles[0].text, filename);
const styles = adapted.exports;
const { EuiThemeBorealis } = require('@elastic/eui-theme-borealis');
const { getComputed, buildTheme } = require('@elastic/eui-theme-common');
const eui = dirname(require.resolve('@elastic/eui/package.json'));

const factories = {
  'components/spacer/spacer.styles.js': ['euiSpacerStyles'],
  'components/horizontal_rule/horizontal_rule.styles.js': ['euiHorizontalRuleStyles'],
  'components/panel/panel.styles.js': ['euiPanelStyles'],
  'components/loading/loading_spinner.styles.js': ['euiLoadingSpinnerStyles', 'euiSpinnerBorderColorsCSS'],
  'components/button/button_display/_button_display.styles.js': ['euiButtonDisplayStyles'],
  'components/button/button_display/_button_display_content.styles.js': ['euiButtonDisplayContentStyles'],
  'global_styling/mixins/_button.js': ['euiButtonDisplaysColors'],
  'global_styling/mixins/_states.js': ['euiFocusRing'],
  'components/text/text.styles.js': ['euiTextStyles'],
  'components/text/text_color.styles.js': ['euiTextColorStyles'],
  'components/title/title.styles.js': ['euiTitleStyles'],
  'components/link/link.styles.js': ['euiLinkStyles'],
  'components/badge/badge.styles.js': ['euiBadgeStyles'],
  'components/badge/color_utils.js': ['euiBadgeColors'],
  'components/badge/badge_group/badge_group.styles.js': ['euiBadgeGroupStyles'],
  'components/badge/beta_badge/beta_badge.styles.js': ['euiBetaBadgeStyles'],
  'components/badge/notification_badge/badge_notification.styles.js': ['euiNotificationBadgeStyles'],
  'components/flex/flex_group.styles.js': ['euiFlexGroupStyles'],
  'components/flex/flex_grid.styles.js': ['euiFlexGridStyles'],
  'components/button/button_empty/button_empty.styles.js': ['euiButtonEmptyStyles'],
  'components/button/button_icon/button_icon.styles.js': ['euiButtonIconStyles'],
  // checkables
  'components/form/checkbox/checkbox.styles.js': ['euiCheckboxStyles'],
  'components/form/checkbox/checkbox_control.styles.js': ['euiCheckboxControlStyles'],
  'components/form/checkbox/checkbox_group.styles.js': ['euiCheckboxGroupStyles'],
  'components/form/radio/radio.styles.js': ['euiRadioStyles'],
  'components/form/radio/radio_group.styles.js': ['euiRadioGroupStyles'],
  'components/form/switch/switch.styles.js': ['euiSwitchStyles'],
  // forms-layout
  'components/form/form_row/form_row.styles.js': ['euiFormRowStyles'],
  'components/form/form_label/form_label.styles.js': ['euiFormLabelStyles'],
  'components/form/form_fieldset/form_legend.styles.js': ['euiFormLegendStyles'],
  'components/form/form_help_text/form_help_text.styles.js': ['euiFormHelpTextStyles'],
  'components/form/form_error_text/form_error_text.styles.js': ['euiFormErrorTextStyles'],
  'components/form/form_label_append/form_label_append.styles.js': ['euiFormLabelAppendStyles'],
  'components/form/described_form_group/described_form_group.styles.js': ['euiDescribedFormGroupStyles'],
  // form controls
  'components/form/form.styles.js': ['euiFormVariables', 'euiFormControlStyles'],
  'components/form/field_text/field_text.styles.js': ['euiFieldTextStyles'],
  'components/form/field_number/field_number.styles.js': ['euiFieldNumberStyles'],
  'components/form/field_password/field_password.styles.js': ['euiFieldPasswordStyles'],
  'components/form/field_search/field_search.styles.js': ['euiFieldSearchStyles'],
  'components/form/text_area/text_area.styles.js': ['euiTextAreaStyles'],
  'components/form/select/select.styles.js': ['euiSelectStyles'],
  'components/form/form_control_layout/form_control_layout.styles.js': ['euiFormControlLayoutStyles', 'euiFormControlLayoutSideNodeStyles'],
  'components/form/form_control_layout/form_control_layout_icons.styles.js': ['euiFormControlLayoutIconsStyles'],
  'components/form/form_control_layout/form_control_layout_clear_button.styles.js': ['EuiFormControlLayoutClearButtonStyles'],
  'components/form/form_control_layout/form_control_layout_delimited.styles.js': ['euiFormControlLayoutDelimitedStyles', 'euiFormControlLayoutDelimited__delimiter'],
  // page layout
  'components/page/page.styles.js': ['euiPageStyles'],
  'components/page/page_body/page_body.styles.js': ['euiPageBodyStyles'],
  'components/page/page_section/page_section.styles.js': ['euiPageSectionStyles', 'euiPageSectionContentStyles'],
  'components/page/page_sidebar/page_sidebar.styles.js': ['euiPageSidebarStyles'],
  'components/page/page_header/page_header.styles.js': ['euiPageHeaderStyles'],
  'components/page/page_header/page_header_content.styles.js': ['euiPageHeaderContentStyles'],
  'components/page_template/inner/page_inner.styles.js': ['euiPageInnerStyles'],
  'components/bottom_bar/bottom_bar.styles.js': ['euiBottomBarStyles'],
  // utilities
  'components/accessibility/skip_link/skip_link.styles.js': ['euiSkipLinkStyles'],
  'components/progress/progress.styles.js': ['euiProgressDataStyles', 'euiProgressValueTextStyles'],
  'components/skeleton/skeleton_text.styles.js': ['euiSkeletonTextStyles'],
  'components/loading/loading_chart.styles.js': ['euiLoadingChartStyles', 'euiLoadingChartBarStyles'],
  'components/loading/loading_logo.styles.js': ['euiLoadingLogoStyles'],
  'components/code/code.styles.js': ['euiCodeStyles'],
  'components/image/image.styles.js': ['euiImageStyles'],
  'components/image/image_wrapper.styles.js': ['euiImageWrapperStyles'],
  'components/image/image_button.styles.js': ['euiImageButtonStyles', 'euiImageButtonIconStyles'],
  'components/image/image_caption.styles.js': ['euiImageCaptionStyles'],
  'components/image/image_fullscreen_wrapper.styles.js': ['euiImageFullscreenWrapperStyles'],
  // icon family
  'components/icon/icon.styles.js': ['euiIconStyles'],
  'components/avatar/avatar.styles.js': ['euiAvatarStyles'],
  'components/beacon/beacon.styles.js': ['euiBeaconStyles'],
  'components/health/health.styles.js': ['euiHealthStyles'],
  // navigation
  'components/tabs/tabs.styles.js': ['euiTabsStyles'],
  'components/tabs/tab.styles.js': ['euiTabStyles', 'euiTabContentStyles'],
  'components/breadcrumbs/breadcrumbs.styles.js': ['euiBreadcrumbsListStyles'],
  'components/breadcrumbs/breadcrumb.styles.js': ['euiBreadcrumbStyles'],
  'components/breadcrumbs/_breadcrumb_content.styles.js': ['euiBreadcrumbContentStyles', 'euiBreadcrumbPopoverStyles'],
  'components/pagination/pagination.styles.js': ['euiPaginationStyles'],
  'components/pagination/pagination_button.styles.js': ['euiPaginationButtonStyles'],
  'components/steps/step.styles.js': ['euiStepStyles', 'euiStepContentStyles', 'euiStepTitleStyles'],
  'components/steps/step_number.styles.js': ['euiStepNumberStyles', 'euiStepNumberContentStyles'],
  'components/steps/steps_horizontal.styles.js': ['euiStepsHorizontalStyles'],
  'components/steps/step_horizontal.styles.js': ['euiStepHorizontalStyles', 'euiStepHorizontalNumberStyles', 'euiStepHorizontalTitleStyles'],
  'components/steps/sub_steps.styles.js': ['euiSubStepsStyles'],
  // content-blocks
  'components/call_out/call_out.styles.js': ['euiCallOutStyles', 'euiCallOutHeaderStyles'],
  'components/empty_prompt/empty_prompt.styles.js': ['euiEmptyPromptStyles'],
  'components/stat/stat.styles.js': ['euiStatStyles', 'euiStatTitleStyles'],
  // lists
  'components/list_item_layout/_list_item_layout.styles.js': ['euiListItemLayoutStyles', 'euiListItemLayoutWrapperStyles', 'euiListItemVariables'],
  'components/list_group/list_group.styles.js': ['euiListGroupStyles'],
  'components/list_group/list_group_item.styles.js': ['euiListGroupItemStyles'],
  'components/list_group/list_group_item_extra_action.styles.js': ['euiListGroupItemExtraActionStyles'],
  'components/list_group/pinnable_list_group/pinnable_list_group.styles.js': ['euiPinnableListGroupItemExtraActionStyles'],
  'components/key_pad_menu/key_pad_menu.styles.js': ['euiKeyPadMenuStyles', 'euiKeyPadMenuVariables'],
  'components/description_list/description_list.styles.js': ['euiDescriptionListStyles'],
  'components/description_list/description_list_title.styles.js': ['euiDescriptionListTitleStyles'],
  'components/description_list/description_list_description.styles.js': ['euiDescriptionListDescriptionStyles'],
  'components/side_nav/side_nav.styles.js': ['euiSideNavMobileStyles'],
  'components/side_nav/side_nav_item.styles.js': ['euiSideNavItemStyles', 'euiSideNavItemButtonStyles'],
  // header and collapsible nav
  'components/header/header.styles.js': ['euiHeaderVariables', 'euiHeaderStyles'],
  'components/header/header_section/header_section.styles.js': ['euiHeaderSectionStyles'],
  'components/header/header_section/header_section_item.styles.js': ['euiHeaderSectionItemStyles'],
  'components/header/header_section/header_section_item_button.styles.js': ['euiHeaderSectionItemButtonStyles'],
  'components/header/header_logo/header_logo.styles.js': ['euiHeaderLogoStyles'],
  'components/header/header_links/header_links.styles.js': ['euiHeaderLinksStyles'],
  'components/header/header_alert/header_alert.styles.js': ['euiHeaderAlertStyles'],
  'components/header/header_breadcrumbs/header_breadcrumbs.styles.js': ['euiHeaderBreadcrumbsStyles'],
  'components/collapsible_nav/collapsible_nav.styles.js': ['euiCollapsibleNavStyles'],
  'components/collapsible_nav/collapsible_nav_group/collapsible_nav_group.styles.js': ['euiCollapsibleNavGroupStyles'],
  // modal and flyout
  'components/modal/modal.styles.js': ['euiModalStyles'],
  'components/modal/modal_header.styles.js': ['euiModalHeaderStyles'],
  'components/modal/modal_body.styles.js': ['euiModalBodyStyles'],
  'components/modal/modal_footer.styles.js': ['euiModalFooterStyles'],
  'components/flyout/flyout.styles.js': ['euiFlyoutStyles'],
  'components/flyout/_flyout_close_button.styles.js': ['euiFlyoutCloseButtonStyles'],
  'components/flyout/flyout_header.styles.js': ['euiFlyoutHeaderStyles'],
  'components/flyout/flyout_body.styles.js': ['euiFlyoutBodyStyles'],
  'components/flyout/flyout_footer.styles.js': ['euiFlyoutFooterStyles'],
  // overlays
  'components/popover/popover.styles.js': ['euiPopoverStyles'],
  'components/popover/popover_title.styles.js': ['euiPopoverTitleStyles'],
  'components/popover/popover_footer.styles.js': ['euiPopoverFooterStyles'],
  'components/popover/popover_panel/_popover_panel.styles.js': ['euiPopoverPanelStyles'],
  'components/popover/popover_arrow/_popover_arrow.styles.js': ['euiPopoverArrowStyles'],
  'components/tool_tip/tool_tip.styles.js': ['euiToolTipStyles', 'euiToolTipAnchorStyles'],
  'components/context_menu/context_menu.styles.js': ['euiContextMenuStyles', 'euiContextMenuVariables'],
  'components/context_menu/context_menu_item.styles.js': ['euiContextMenuItemStyles'],
  'components/context_menu/context_menu_panel.styles.js': ['euiContextMenuPanelStyles'],
  'components/context_menu/context_menu_panel_title.styles.js': ['euiContextMenuPanelTitleStyles'],
  // cards (padding-dependent card factories have their own test below)
  'components/card/card.styles.js': ['euiCardTextStyles'],
  'components/card/card_select/card_select.styles.js': ['euiCardSelectStyles'],
  'components/card/checkable_card/checkable_card.styles.js': ['euiCheckableCardStyles'],
  'components/panel/split_panel/split_panel.styles.js': ['euiSplitPanelInnerStyles'],
  // feedback
  'components/accordion/accordion.styles.js': ['euiAccordionStyles'],
  'components/accordion/accordion_children/accordion_children.styles.js': ['euiAccordionChildrenStyles', 'euiAccordionChildWrapperStyles'],
  'components/accordion/accordion_trigger/accordion_arrow.styles.js': ['euiAccordionArrowStyles'],
  'components/accordion/accordion_trigger/accordion_button.styles.js': ['euiAccordionButtonStyles'],
  'components/toast/toast.styles.js': ['euiToastStyles', 'euiToastHeaderStyles'],
  'components/toast/global_toast_list.styles.js': ['euiGlobalToastListStyles', 'euiGlobalToastListItemStyles'],
  'components/notification_icon/notification_icon.styles.js': ['euiNotificationIconStyles'],
  'components/comment_list/comment_event.styles.js': ['euiCommentEventStyles', 'euiCommentEventHeaderStyles', 'euiCommentEventBodyStyles'],
  'components/timeline/timeline.styles.js': ['euiTimelineStyles'],
  'components/timeline/timeline_item.styles.js': ['euiTimelineItemStyles'],
  'components/timeline/timeline_item_event.styles.js': ['euiTimelineItemEventStyles'],
  'components/timeline/timeline_item_icon.styles.js': ['euiTimelineItemIconStyles'],
  // misc-display
  'components/tree_view/tree_view.styles.js': ['euiTreeViewStyles'],
  'components/tree_view/tree_view_item.styles.js': ['euiTreeViewItemStyles'],
  'components/text_diff/text_diff.styles.js': ['euiTextDiffStyles'],
  'components/expression/expression.styles.js': ['euiExpressionStyles', 'euiExpressionDescriptionStyles', 'euiExpressionIconStyles'],
  'components/tour/tour.styles.js': ['euiTourStyles', 'euiTourBeaconStyles'],
  'components/tour/_tour_header.styles.js': ['euiTourHeaderStyles'],
  'components/tour/_tour_footer.styles.js': ['euiTourFooterStyles', '_tourFooterBgColor'],
  // date pickers
  'components/date_picker/date_picker.styles.js': ['euiDatePickerStyles'],
  'components/date_picker/date_picker_range.styles.js': ['euiDatePickerRangeStyles', 'euiDatePickerRangeInlineStyles'],
  'components/date_picker/super_date_picker/super_date_picker.styles.js': ['euiSuperDatePickerStyles'],
  'components/date_picker/super_date_picker/date_popover/date_popover_button.styles.js': ['euiDatePopoverButtonStyles'],
  'components/date_picker/super_date_picker/date_popover/date_popover_content.styles.js': ['euiDatePopoverContentStyles'],
  'components/date_picker/super_date_picker/date_popover/absolute_tab.styles.js': ['euiAbsoluteTabDateFormStyles'],
  'components/date_picker/super_date_picker/quick_select_popover/quick_select_panel.styles.js': ['euiQuickSelectPanelStyles'],
  'components/date_picker/super_date_picker/quick_select_popover/quick_select_popover.styles.js': ['euiQuickSelectPopoverStyles'],
  'components/form/form_control_layout/append_prepend/form_append_prepend.styles.js': ['euiFormAppendPrependStyles'],
  'components/form/form.styles.js': ['euiFormControlText', 'euiFormControlDefaultShadow']
};
function normalize(value) {
  if (Array.isArray(value)) return value.map(normalize);
  if (value && typeof value === 'object')
    return Object.fromEntries(
      Object.entries(value)
        .filter(([, v]) => typeof v !== 'function')
        .map(([k, v]) => [k, normalize(v)])
    );
  return value;
}
for (const [path, names] of Object.entries(factories)) {
  const reference = require(resolve(eui, 'lib', path));
  for (const name of names)
    test(`${name}: all serialized slots match upstream in 12 theme configurations`, () => {
      for (const colorMode of ['LIGHT', 'DARK'])
        for (const highContrastMode of [false, 'preferred', 'forced'])
          for (const modifications of [
            {},
            {
              base: 20,
              border: { radius: { panel: '20px' } },
              colors: {
                LIGHT: { primary: '#663399' },
                DARK: { primary: '#aa77dd' }
              }
            }
          ]) {
            const context = {
              colorMode,
              highContrastMode,
              modifications,
              euiTheme: getComputed(
                EuiThemeBorealis,
                buildTheme(modifications, 'parity'),
                colorMode,
                highContrastMode
              )
            };
            assert.deepEqual(
              normalize(styles[name](context)),
              normalize(reference[name](context)),
              `${colorMode}/${highContrastMode}/${JSON.stringify(modifications)}`
            );
          }
    });
}

test('pure color and padding helpers match upstream for all migrated variants', () => {
  const { euiPaddingSize } = require(
    resolve(eui, 'lib/global_styling/mixins/_padding.js')
  );
  const { euiBackgroundColor, euiBorderColor } = require(
    resolve(eui, 'lib/global_styling/mixins/_color.js')
  );
  for (const mode of ['LIGHT', 'DARK']) {
    const context = {
      euiTheme: getComputed(EuiThemeBorealis, buildTheme({}, 'parity'), mode),
      colorMode: mode,
      highContrastMode: false
    };
    for (const size of ['none', 'xs', 's', 'm', 'l', 'xl'])
      assert.equal(
        styles.euiPaddingSize(context, size),
        euiPaddingSize(context, size)
      );
    for (const color of [
      'transparent',
      'plain',
      'subdued',
      'highlighted',
      'accent',
      'accentSecondary',
      'primary',
      'success',
      'warning',
      'danger'
    ]) {
      assert.equal(
        styles.euiBackgroundColor(context, color),
        euiBackgroundColor(context, color)
      );
      assert.equal(
        styles.euiBorderColor(context, color),
        euiBorderColor(context, color)
      );
    }
  }
});

test('navigation helpers match upstream (step variables, screen reader only, text truncate)', () => {
  const { euiStepVariables } = require(
    resolve(eui, 'lib/components/steps/step.styles.js')
  );
  const { euiScreenReaderOnly } = require(
    resolve(
      eui,
      'lib/components/accessibility/screen_reader_only/screen_reader_only.styles.js'
    )
  );
  const { euiTextTruncate } = require(
    resolve(eui, 'lib/global_styling/mixins/_typography.js')
  );
  for (const modifications of [{}, { base: 20 }]) {
    const euiTheme = getComputed(
      EuiThemeBorealis,
      buildTheme(modifications, 'parity'),
      'LIGHT'
    );
    assert.deepEqual(
      styles.euiStepVariables(euiTheme),
      euiStepVariables(euiTheme)
    );
  }
  for (const showOnFocus of [undefined, false, true])
    assert.equal(
      styles.euiScreenReaderOnly(showOnFocus),
      euiScreenReaderOnly(showOnFocus)
    );
  for (const args of [[], ['160px'], ['none'], ['100%', 'nowrap']])
    assert.equal(styles.euiTextTruncate(...args), euiTextTruncate(...args));
});

test('misc-display: static expression value styles match upstream', () => {
  const reference = require(
    resolve(eui, 'lib/components/expression/expression.styles.js')
  );
  assert.deepEqual(
    normalize(styles.euiExpressionValueStyles),
    normalize(reference.euiExpressionValueStyles)
  );
});

test('generated artifact has no React or upstream hook execution paths', () => {
  const code = readFileSync(source, 'utf8');
  assert.doesNotMatch(
    code,
    /from ["'](?:react|react-dom|@emotion\/react)(?:["'/])/
  );
  assert.doesNotMatch(code, /React hooks cannot run in Ember/);
});

test('button interactions match upstream fill and overlay in every mode and contrast', () => {
  const reference = require(
    resolve(eui, 'lib/global_styling/mixins/_button.js')
  );
  const colors = {
    color: '#123456',
    background: '#eaf0fa',
    backgroundHover: '#ccddee',
    backgroundActive: '#8899aa',
    borderColor: 'transparent'
  };
  for (const colorMode of ['LIGHT', 'DARK'])
    for (const highContrastMode of [false, 'preferred', 'forced']) {
      const context = {
        colorMode,
        highContrastMode,
        euiTheme: getComputed(
          EuiThemeBorealis,
          buildTheme({}, 'parity'),
          colorMode,
          highContrastMode
        )
      };
      for (const kind of ['fill', 'overlay'])
        assert.equal(
          styles.euiButtonInteractionStyles(context, colors, kind),
          reference.euiButtonInteractionStyles(context, colors, kind)
        );
    }
});

test('text alignment slots match upstream static styles', () => {
  const reference = require(
    resolve(eui, 'lib/components/text/text_align.styles.js')
  );
  assert.deepEqual(
    normalize(styles.euiTextAlignStyles),
    normalize(reference.euiTextAlignStyles)
  );
});

test('typography factories match upstream with text token and font overrides', () => {
  const modifications = {
    font: { title: { weight: 'medium', letterSpacing: '0.02em' }, scale: { m: 1.1 } },
    size: { m: '14px' },
    colors: {
      LIGHT: { textParagraph: '#202020', textHeading: '#101010', textSubdued: '#555555' },
      DARK: { textParagraph: '#eeeeee', textHeading: '#ffffff', textSubdued: '#aaaaaa' }
    }
  };
  for (const [path, name] of [
    ['components/text/text.styles.js', 'euiTextStyles'],
    ['components/text/text_color.styles.js', 'euiTextColorStyles'],
    ['components/title/title.styles.js', 'euiTitleStyles']
  ]) {
    const reference = require(resolve(eui, 'lib', path));
    for (const colorMode of ['LIGHT', 'DARK']) {
      const context = {
        colorMode,
        highContrastMode: false,
        modifications,
        euiTheme: getComputed(
          EuiThemeBorealis,
          buildTheme(modifications, 'parity'),
          colorMode,
          false
        )
      };
      assert.deepEqual(
        normalize(styles[name](context)),
        normalize(reference[name](context)),
        `${name}/${colorMode}`
      );
    }
  }
});

test('flex item slots match upstream static styles', () => {
  const reference = require(resolve(eui, 'lib/components/flex/flex_item.styles.js'));
  assert.deepEqual(
    normalize(styles.euiFlexItemStyles),
    normalize(reference.euiFlexItemStyles)
  );
});

test('badge color helpers match upstream for named, custom and invalid colors', () => {
  const reference = require(resolve(eui, 'lib/components/badge/color_utils.js'));
  const colors = ['#ffffff', '#000000', '#E7664C', '#54B399', '#6092C0', 'rgb(200, 100, 50)'];
  for (const colorMode of ['LIGHT', 'DARK'])
    for (const highContrastMode of [false, 'preferred', 'forced']) {
      const context = {
        colorMode,
        highContrastMode,
        euiTheme: getComputed(
          EuiThemeBorealis,
          buildTheme({}, 'parity'),
          colorMode,
          highContrastMode
        )
      };
      for (const color of colors) {
        assert.deepEqual(
          styles.getBadgeColors(context, color),
          reference.getBadgeColors(context, color),
          `getBadgeColors ${color}`
        );
        assert.deepEqual(
          styles.getTextColor(context, color),
          reference.getTextColor(context, color)
        );
        assert.deepEqual(
          styles.getCustomInteractiveColors(context, color),
          reference.getCustomInteractiveColors(context, color)
        );
      }
    }
  for (const color of [...colors, 'primary', 'not-a-color', '#12', ''])
    assert.strictEqual(
      styles.getIsValidColor(color),
      reference.getIsValidColor(color),
      `getIsValidColor ${color}`
    );
});

test('global styles port matches upstream EuiGlobalStyles in every mode and contrast', () => {
  const { serializeStyles } = require('@emotion/serialize');
  const ported = buildSync({
    entryPoints: [resolve(root, 'packages/core/src/utils/eui/global-styles.ts')],
    bundle: true,
    write: false,
    format: 'cjs',
    platform: 'node',
    external: [
      '@elastic/eui-theme-common',
      '@elastic/eui-theme-borealis',
      '@emotion/serialize',
      'chroma-js'
    ]
  });
  const portFile = resolve(root, 'packages/core/eui-global-parity.cjs');
  const portModule = new Module(portFile);
  portModule.paths = Module._nodeModulePaths(dirname(portFile));
  portModule._compile(ported.outputFiles[0].text, portFile);
  const { euiGlobalStyles } = portModule.exports;

  // Run upstream's React component body with React/Emotion/hooks stubbed out.
  let current;
  const originalLoad = Module._load;
  Module._load = function (request, parent, isMain) {
    if (request === '@emotion/react')
      return {
        Global: 'Global',
        css: (...args) => serializeStyles(args),
        jsx: (type, props) => ({ type, props })
      };
    if (/services\/theme$/.test(request))
      return { useEuiTheme: () => current };
    return originalLoad.call(this, request, parent, isMain);
  };
  try {
    const globalsPath = resolve(eui, 'lib/global_styling/reset/global_styles.js');
    delete require.cache[globalsPath];
    const { EuiGlobalStyles } = require(globalsPath);
    for (const colorMode of ['LIGHT', 'DARK'])
      for (const highContrastMode of [false, 'preferred', 'forced'])
        for (const modifications of [{}, { font: { defaultUnits: 'px' }, base: 18 }]) {
          current = {
            colorMode,
            highContrastMode,
            modifications,
            euiTheme: getComputed(
              EuiThemeBorealis,
              buildTheme(modifications, 'parity'),
              colorMode,
              highContrastMode
            )
          };
          const upstream = EuiGlobalStyles({}).props.styles.styles;
          assert.strictEqual(
            serializeStyles(euiGlobalStyles(current)).styles,
            upstream,
            `${colorMode}/${highContrastMode}/${JSON.stringify(modifications)}`
          );
        }
  } finally {
    Module._load = originalLoad;
  }
});

test('delimited input slot matches upstream static styles', () => {
  const reference = require(
    resolve(
      eui,
      'lib/components/form/form_control_layout/form_control_layout_delimited.styles.js'
    )
  );
  assert.deepEqual(
    normalize(styles.euiFormControlLayoutDelimited__input),
    normalize(reference.euiFormControlLayoutDelimited__input)
  );
});

test('form control hand ports match upstream custom icon styles and icon affordance counts', () => {
  const ported = buildSync({
    entryPoints: [resolve(root, 'packages/core/src/utils/eui/form-controls.ts')],
    bundle: true,
    write: false,
    format: 'cjs',
    platform: 'node',
    external: ['@ember/template']
  });
  const portFile = resolve(root, 'packages/core/eui-form-controls-parity.cjs');
  const portModule = new Module(portFile);
  portModule.paths = Module._nodeModulePaths(dirname(portFile));
  // `htmlSafe` only wraps the string for Glimmer; a passthrough is enough here.
  portModule.require = (request) =>
    request === '@ember/template'
      ? { htmlSafe: (value) => value }
      : require(request);
  portModule._compile(ported.outputFiles[0].text, portFile);
  const { euiFormControlLayoutCustomIconStyles: port, iconAffordanceStyle } =
    portModule.exports;

  // Load upstream's React modules with React, Emotion and icons stubbed out.
  const { serializeStyles } = require('@emotion/serialize');
  const originalLoad = Module._load;
  Module._load = function (request, parent, isMain) {
    if (request === 'react') return { __esModule: true, default: {} };
    if (request === '@emotion/react')
      return {
        css: (...args) => serializeStyles(args),
        jsx: (type, props) => ({ type, props })
      };
    if (request === '../../icon') return { EuiIcon: 'EuiIcon' };
    if (request === './form_control_layout_icons')
      return {
        isIconShape: (icon) => !!icon && Object.hasOwn(icon, 'type')
      };
    return originalLoad.call(this, request, parent, isMain);
  };
  try {
    const dir = resolve(eui, 'lib/components/form/form_control_layout');
    for (const file of ['form_control_layout_custom_icon.js', '_num_icons.js'])
      delete require.cache[resolve(dir, file)];
    const { EuiFormControlLayoutCustomIcon } = require(
      resolve(dir, 'form_control_layout_custom_icon.js')
    );
    const { getIconAffordanceStyles } = require(resolve(dir, '_num_icons.js'));
    const text = (style) => (typeof style === 'string' ? style : style.styles);
    const unclickable = EuiFormControlLayoutCustomIcon({ type: 'x' }).props.css;
    const clickable = EuiFormControlLayoutCustomIcon({
      type: 'x',
      onClick() {}
    }).props.css;
    assert.deepEqual(unclickable.map(text), [
      port.euiFormControlLayoutCustomIcon,
      port.unclickable
    ]);
    assert.deepEqual(clickable.map(text), [
      port.euiFormControlLayoutCustomIcon,
      port.clickable
    ]);

    const flags = ['clear', 'isLoading', 'isInvalid', 'isDropdown'];
    for (let mask = 0; mask < 1 << flags.length; mask++)
      for (const side of [undefined, 'left', 'right']) {
        const args = Object.fromEntries(
          flags.map((flag, i) => [flag, Boolean(mask & (1 << i))])
        );
        const upstream = getIconAffordanceStyles({
          ...args,
          icon: side ? (side === 'right' ? { type: 'x', side } : 'x') : undefined
        });
        const ours = iconAffordanceStyle({
          ...args,
          icon: side ? 'x' : undefined,
          iconSide: side
        });
        const parsed = ours
          ? Object.fromEntries(
              String(ours)
                .split('; ')
                .map((pair) => pair.split(': '))
                .map(([key, value]) => [key, Number(value)])
            )
          : undefined;
        assert.deepEqual(parsed, upstream, `${side}/${mask}`);
      }
  } finally {
    Module._load = originalLoad;
  }
});

// page layout
test('page outer slots match upstream static styles', () => {
  const reference = require(
    resolve(eui, 'lib/components/page_template/outer/page_outer.styles.js')
  );
  assert.deepEqual(
    normalize(styles.euiPageOuterStyles),
    normalize(reference.euiPageOuterStyles)
  );
});

test('page width, breakpoint and scroll helpers match upstream', () => {
  const width = require(resolve(eui, 'lib/components/page/_restrict_width.js'));
  const responsive = require(
    resolve(eui, 'lib/global_styling/mixins/_responsive.js')
  );
  const helpers = require(resolve(eui, 'lib/global_styling/mixins/_helpers.js'));
  assert.strictEqual(styles.PAGE_MAX_WIDTH, width.PAGE_MAX_WIDTH);
  for (const restrict of [true, false, 600, '40rem', 0])
    for (const style of [undefined, { color: 'red', maxWidth: '1px' }])
      assert.deepEqual(
        styles.setStyleForRestrictedPageWidth(restrict, style),
        width.setStyleForRestrictedPageWidth(restrict, style)
      );
  for (const modifications of [{}, { breakpoint: { m: 900, l: 1300 } }])
    for (const colorMode of ['LIGHT', 'DARK']) {
      const context = {
        colorMode,
        highContrastMode: false,
        modifications,
        euiTheme: getComputed(
          EuiThemeBorealis,
          buildTheme(modifications, 'parity'),
          colorMode,
          false
        )
      };
      for (const size of ['xs', 's', 'm', 'l', 'xl']) {
        assert.strictEqual(
          styles.euiMinBreakpoint(context, size),
          responsive.euiMinBreakpoint(context, size)
        );
        assert.strictEqual(
          styles.euiMaxBreakpoint(context, size),
          responsive.euiMaxBreakpoint(context, size)
        );
      }
      for (const sizes of [['xs', 's'], ['m', 'l', 'xl'], ['s'], ['xl'], ['l', 'm']])
        assert.strictEqual(
          styles.euiBreakpoint(context, [...sizes]),
          responsive.euiBreakpoint(context, [...sizes])
        );
      for (const options of [undefined, { height: 'auto' }])
        assert.strictEqual(
          styles.euiYScroll(context, options),
          helpers.euiYScroll(context, options)
        );
      assert.strictEqual(styles.euiFullHeight(), helpers.euiFullHeight());
    }
});

// utilities
function utilityContexts() {
  const contexts = [];
  for (const colorMode of ['LIGHT', 'DARK'])
    for (const highContrastMode of [false, 'preferred', 'forced'])
      for (const modifications of [
        {},
        {
          base: 20,
          colors: {
            LIGHT: { primary: '#663399', success: '#117711' },
            DARK: { primary: '#aa77dd', success: '#77dd77' }
          },
          components: { LIGHT: { markBackground: '#ffee00' }, DARK: { markBackground: '#665500' } }
        }
      ])
        contexts.push({
          colorMode,
          highContrastMode,
          modifications,
          euiTheme: getComputed(
            EuiThemeBorealis,
            buildTheme(modifications, 'parity'),
            colorMode,
            highContrastMode
          )
        });
  return contexts;
}

test('progress bar slots match upstream for native and indeterminate bars', () => {
  const reference = require(resolve(eui, 'lib/components/progress/progress.styles.js'));
  for (const context of utilityContexts())
    for (const isNative of [true, false])
      assert.deepEqual(
        normalize(styles.euiProgressStyles(context, isNative)),
        normalize(reference.euiProgressStyles(context, isNative)),
        `${context.colorMode}/${context.highContrastMode}/${isNative}`
      );
});

test('static utility styles match upstream', () => {
  const sr = require(
    resolve(eui, 'lib/components/accessibility/screen_reader_only/screen_reader_only.styles.js')
  );
  assert.deepEqual(normalize(styles.euiScreenReaderOnlyStyles), normalize(sr.euiScreenReaderOnlyStyles));
  assert.strictEqual(styles.euiScreenReaderOnly(), sr.euiScreenReaderOnly());
  const progress = require(resolve(eui, 'lib/components/progress/progress.styles.js'));
  assert.deepEqual(
    normalize(styles.euiProgressLabelStyles),
    normalize(progress.euiProgressLabelStyles)
  );
  const elastic = require(resolve(eui, 'lib/components/loading/loading_elastic.styles.js'));
  assert.deepEqual(
    normalize(styles.euiLoadingElasticStyles),
    normalize(elastic.euiLoadingElasticStyles)
  );
});

test('high contrast text color helper matches upstream for custom colors', () => {
  const reference = require(resolve(eui, 'lib/services/color/contrast.js'));
  for (const context of utilityContexts())
    for (const color of ['#E7664C', '#54B399', '#ffff00', 'rgb(20, 40, 200)', context.euiTheme.colors.vis.euiColorVis3])
      assert.strictEqual(
        styles.makeHighContrastColor(color)(context.euiTheme),
        reference.makeHighContrastColor(color)(context.euiTheme),
        color
      );
});

test('hand-ported mark and overlay mask styles match upstream', () => {
  const ported = buildSync({
    entryPoints: [resolve(root, 'packages/core/src/utils/eui/utilities.ts')],
    bundle: true,
    write: false,
    format: 'cjs',
    platform: 'node',
    external: [
      '@elastic/eui-theme-common',
      '@elastic/eui-theme-borealis',
      '@emotion/serialize',
      'chroma-js'
    ]
  });
  const portFile = resolve(root, 'packages/core/eui-utilities-parity.cjs');
  const portModule = new Module(portFile);
  portModule.paths = Module._nodeModulePaths(dirname(portFile));
  portModule._compile(ported.outputFiles[0].text, portFile);
  const port = portModule.exports;
  const mark = require(resolve(eui, 'lib/components/mark/mark.styles.js'));
  const mask = require(resolve(eui, 'lib/components/overlay_mask/overlay_mask.styles.js'));
  const { cache } = require('@emotion/css');
  for (const context of utilityContexts()) {
    const label = `${context.colorMode}/${context.highContrastMode}`;
    assert.deepEqual(normalize(port.euiMarkStyles(context)), normalize(mark.euiMarkStyles(context)), label);
    // Upstream registers @emotion/css classes; compare the registered styles and names.
    const upstream = mask.euiOverlayMaskStyles(context);
    const ours = port.euiOverlayMaskStyles(context);
    for (const slot of Object.keys(upstream)) {
      assert.strictEqual(upstream[slot], `css-${ours[slot].name}`, `${label} ${slot}`);
      assert.strictEqual(cache.registered[upstream[slot]], ours[slot].styles, `${label} ${slot}`);
    }
  }
  for (const [start, end] of [['highlight start', 'highlight end'], ['début', 'fin']])
    assert.deepEqual(
      normalize(port.euiMarkScreenReaderStyles(start, end)),
      normalize(mark.euiMarkScreenReaderStyles(start, end))
    );
});

// icon family
test('token map and icon-family color helpers match upstream', () => {
  const tokenMap = require(resolve(eui, 'lib/components/token/token_map.js'));
  assert.deepEqual(styles.TOKEN_MAP, tokenMap.TOKEN_MAP);
  assert.deepEqual(
    styles.TOKEN_COLOR_TO_ICON_COLOR_MAP,
    tokenMap.TOKEN_COLOR_TO_ICON_COLOR_MAP
  );
  const manipulation = require(
    resolve(eui, 'lib/services/color/manipulation.js')
  );
  const { isColorDark } = require(
    resolve(eui, 'lib/services/color/is_color_dark.js')
  );
  const { hexToRgb } = require(resolve(eui, 'lib/services/color/hex_to_rgb.js'));
  for (const color of ['#16C5C0', '#5A6D8C', '#000000', '#ffffff', '#EAAE01'])
    for (const ratio of [0.2, 0.3, 0.6, 0.9]) {
      assert.equal(styles.tint(color, ratio), manipulation.tint(color, ratio));
      assert.equal(styles.shade(color, ratio), manipulation.shade(color, ratio));
      assert.deepEqual(styles.hexToRgb(color), hexToRgb(color));
      assert.equal(
        styles.isColorDark(...hexToRgb(color)),
        isColorDark(...hexToRgb(color))
      );
    }
  const logicals = require(resolve(eui, 'lib/global_styling/functions/logicals.js'));
  for (const property of ['height', 'padding-vertical', 'padding-horizontal', 'left', 'top'])
    assert.equal(styles.logicalCSS(property, '4px'), logicals.logicalCSS(property, '4px'));
  assert.equal(styles.logicalSizeCSS('12px'), logicals.logicalSizeCSS('12px'));
});

test('token styles port matches upstream euiTokenStyles for every fill, mode and contrast', () => {
  const ported = buildSync({
    entryPoints: [resolve(root, 'packages/core/src/utils/eui/token.ts')],
    bundle: true,
    write: false,
    format: 'cjs',
    platform: 'node',
    external: [
      '@elastic/eui-theme-common',
      '@elastic/eui-theme-borealis',
      '@emotion/serialize',
      'chroma-js'
    ]
  });
  const portFile = resolve(root, 'packages/core/eui-token-parity.cjs');
  const portModule = new Module(portFile);
  portModule.paths = Module._nodeModulePaths(dirname(portFile));
  portModule._compile(ported.outputFiles[0].text, portFile);
  const { euiTokenStyles } = portModule.exports;
  const reference = require(resolve(eui, 'lib/components/token/token.styles.js'));
  // Upstream reads the palette from the global store the React provider fills.
  const { EUI_VIS_COLOR_STORE } = require(
    resolve(eui, 'lib/services/color/vis_color_store.js')
  );
  for (const colorMode of ['LIGHT', 'DARK'])
    for (const highContrastMode of [false, 'preferred', 'forced'])
      for (const modifications of [
        {},
        { border: { radius: { inline: '6px' } }, colors: { LIGHT: { darkShade: '#333366' }, DARK: { darkShade: '#9999cc' } } }
      ])
        for (const fill of ['light', 'dark', 'none']) {
          const context = {
            colorMode,
            highContrastMode,
            modifications,
            euiTheme: getComputed(
              EuiThemeBorealis,
              buildTheme(modifications, 'parity'),
              colorMode,
              highContrastMode
            )
          };
          EUI_VIS_COLOR_STORE.setVisColors(context.euiTheme.colors.vis);
          const ours = euiTokenStyles(context, fill);
          const upstream = reference.euiTokenStyles(context, fill);
          assert.deepEqual(Object.keys(ours).sort(), Object.keys(upstream).sort());
          for (const key of Object.keys(upstream))
            assert.equal(
              ours[key].styles,
              upstream[key].styles,
              `${key} ${fill} ${colorMode}/${highContrastMode}/${JSON.stringify(modifications)}`
            );
        }
});

test('list group tooltip slot matches upstream static styles', () => {
  const reference = require(
    resolve(eui, 'lib/components/list_group/list_group_item.styles.js')
  );
  assert.deepEqual(
    normalize(styles.euiListGroupItemTooltipStyles),
    normalize(reference.euiListGroupItemTooltipStyles)
  );
});

test('list helper exports match upstream logicals, typography, contrast and sr-only mixins', () => {
  const logicals = require(resolve(eui, 'lib/global_styling/functions/logicals.js'));
  const typography = require(resolve(eui, 'lib/global_styling/mixins/_typography.js'));
  const contrast = require(resolve(eui, 'lib/global_styling/functions/high_contrast.js'));
  const srOnly = require(
    resolve(eui, 'lib/components/accessibility/screen_reader_only/screen_reader_only.styles.js')
  );
  for (const [property, value] of [
    ['margin-bottom', '8px'],
    ['top', 'auto'],
    ['right', '4px'],
    ['padding-horizontal', '8px'],
    ['border-left', '1px solid red'],
    ['max-width', '400px']
  ])
    assert.equal(styles.logicalCSS(property, value), logicals.logicalCSS(property, value));
  assert.equal(styles.logicalSizeCSS('96px'), logicals.logicalSizeCSS('96px'));
  assert.equal(styles.euiTextTruncate(), typography.euiTextTruncate());
  assert.equal(styles.logicalSizeCSS('1px', '2px'), logicals.logicalSizeCSS('1px', '2px'));
  assert.equal(styles.euiScreenReaderOnly(), srOnly.euiScreenReaderOnly());
  for (const colorMode of ['LIGHT', 'DARK'])
    for (const highContrastMode of [false, 'preferred', 'forced']) {
      const context = {
        colorMode,
        highContrastMode,
        euiTheme: getComputed(
          EuiThemeBorealis,
          buildTheme({ font: { defaultUnits: 'px' } }, 'parity'),
          colorMode,
          highContrastMode
        )
      };
      for (const scale of ['xxs', 'xs', 's', 'm', 'l'])
        assert.deepEqual(
          styles.euiFontSize(context, scale),
          typography.euiFontSize(context, scale)
        );
      const options = { none: 'a:1;', preferred: 'b:2;', forced: 'c:3;' };
      assert.equal(
        styles.highContrastModeStyles(context, options),
        contrast.highContrastModeStyles(context, options)
      );
    }
});

test('key pad menu item hand port matches upstream in 12 theme configurations', () => {
  const ported = buildSync({
    entryPoints: [resolve(root, 'packages/core/src/utils/eui/lists.ts')],
    bundle: true,
    write: false,
    format: 'cjs',
    platform: 'node',
    external: [
      '@elastic/eui-theme-common',
      '@elastic/eui-theme-borealis',
      '@emotion/serialize',
      'chroma-js'
    ]
  });
  const portFile = resolve(root, 'packages/core/eui-lists-parity.cjs');
  const portModule = new Module(portFile);
  portModule.paths = Module._nodeModulePaths(dirname(portFile));
  portModule._compile(ported.outputFiles[0].text, portFile);
  const port = portModule.exports;
  const reference = require(
    resolve(eui, 'lib/components/key_pad_menu/key_pad_menu_item.styles.js')
  );
  for (const colorMode of ['LIGHT', 'DARK'])
    for (const highContrastMode of [false, 'preferred', 'forced'])
      for (const modifications of [
        {},
        { base: 20, colors: { LIGHT: { primary: '#663399' }, DARK: { primary: '#aa77dd' } } }
      ]) {
        const context = {
          colorMode,
          highContrastMode,
          modifications,
          euiTheme: getComputed(
            EuiThemeBorealis,
            buildTheme(modifications, 'parity'),
            colorMode,
            highContrastMode
          )
        };
        for (const name of ['euiKeyPadMenuItemStyles', 'euiKeyPadMenuItemChildStyles'])
          assert.deepEqual(
            normalize(port[name](context)),
            normalize(reference[name](context)),
            `${name} ${colorMode}/${highContrastMode}/${JSON.stringify(modifications)}`
          );
      }
});

// modal and flyout
test('flyout constants and inline style composition match upstream', () => {
  const consts = require(resolve(eui, 'lib/components/flyout/const.js'));
  const reference = require(resolve(eui, 'lib/components/flyout/flyout.styles.js'));
  for (const name of ['FLYOUT_SIZES', 'FLYOUT_SIDES', 'FLYOUT_TYPES', 'FLYOUT_PADDING_SIZES'])
    assert.deepEqual(styles[name], consts[name], name);
  assert.equal(styles.FLYOUT_BREAKPOINT, reference.FLYOUT_BREAKPOINT);
  for (const value of ['s', 'm', 'l', 'fill', 480, '40vw', 'nope', undefined])
    assert.equal(styles.isEuiFlyoutSizeNamed(value), consts.isEuiFlyoutSizeNamed(value), String(value));
  for (const size of ['s', 'm', 'l', 'fill', 480, '40vw'])
    for (const maxWidth of [false, true, 600, '35rem'])
      for (const zIndex of [1000, 6000])
        assert.deepEqual(
          styles.composeFlyoutInlineStyles(size, 'side-by-side', null, null, maxWidth, zIndex),
          reference.composeFlyoutInlineStyles(size, 'side-by-side', null, null, maxWidth, zIndex),
          `${size}/${maxWidth}/${zIndex}`
        );
});

test('card factories match upstream for every padding size in 12 theme configurations', () => {
  const reference = require(resolve(eui, 'lib/components/card/card.styles.js'));
  for (const colorMode of ['LIGHT', 'DARK'])
    for (const highContrastMode of [false, 'preferred', 'forced'])
      for (const modifications of [
        {},
        { base: 20, border: { radius: { panel: '20px' } } }
      ]) {
        const context = {
          colorMode,
          highContrastMode,
          modifications,
          euiTheme: getComputed(
            EuiThemeBorealis,
            buildTheme(modifications, 'parity'),
            colorMode,
            highContrastMode
          )
        };
        for (const padding of ['none', 'xs', 's', 'm', 'l', 'xl'])
          for (const name of ['euiCardStyles', 'euiCardBetaBadgeStyles'])
            assert.deepEqual(
              normalize(styles[name](context, padding)),
              normalize(reference[name](context, padding)),
              `${name}/${padding}/${colorMode}/${highContrastMode}`
            );
      }
});

test('split panel outer slots match upstream static styles', () => {
  const reference = require(resolve(eui, 'lib/components/panel/split_panel/split_panel.styles.js'));
  assert.deepEqual(
    normalize(styles.euiSplitPanelOuterStyles),
    normalize(reference.euiSplitPanelOuterStyles)
  );
});

// date pickers
test('date picker hand ports match upstream react-datepicker and quick select styles', () => {
  const ported = buildSync({
    entryPoints: [resolve(root, 'packages/core/src/utils/eui/date-pickers.ts')],
    bundle: true,
    write: false,
    format: 'cjs',
    platform: 'node',
    external: [
      '@elastic/eui-theme-common',
      '@elastic/eui-theme-borealis',
      '@emotion/serialize',
      'chroma-js'
    ]
  });
  const portFile = resolve(root, 'packages/core/eui-date-pickers-parity.cjs');
  const portModule = new Module(portFile);
  portModule.paths = Module._nodeModulePaths(dirname(portFile));
  portModule._compile(ported.outputFiles[0].text, portFile);
  const port = portModule.exports;
  const reference = require(
    resolve(eui, 'lib/components/date_picker/react_date_picker.styles.js')
  );
  const { cache } = require('@emotion/css');
  for (const colorMode of ['LIGHT', 'DARK'])
    for (const highContrastMode of [false, 'preferred', 'forced'])
      for (const modifications of [
        {},
        { base: 20, colors: { LIGHT: { primary: '#663399' }, DARK: { primary: '#aa77dd' } } }
      ]) {
        const context = {
          colorMode,
          highContrastMode,
          modifications,
          euiTheme: getComputed(
            EuiThemeBorealis,
            buildTheme(modifications, 'parity'),
            colorMode,
            highContrastMode
          )
        };
        const label = `${colorMode}/${highContrastMode}/${JSON.stringify(modifications)}`;
        assert.deepEqual(
          normalize(port.euiDatePickerVariables(context)),
          normalize(reference.euiDatePickerVariables(context)),
          label
        );
        // Upstream registers an @emotion/css class; compare its name and registered styles.
        const upstream = reference.euiReactDatePickerStyles(context).euiReactDatePicker;
        const ours = port.euiReactDatePickerStyles(context).euiReactDatePicker;
        assert.strictEqual(upstream, `css-${ours.name}`, label);
        assert.strictEqual(cache.registered[upstream], ours.styles, label);
      }

  // quick_select.js module-level styles, from upstream's compiled source
  const quickSelect = readFileSync(
    resolve(eui, 'lib/components/date_picker/super_date_picker/quick_select_popover/quick_select.js'),
    'utf8'
  );
  for (const slot of Object.values(port.euiQuickSelectStyles)) {
    assert.ok(quickSelect.includes(`name: "${slot.name}"`), slot.name);
    assert.ok(quickSelect.includes(`styles: ${JSON.stringify(slot.styles)}`), slot.name);
  }
});

test('date picker style helpers match upstream button colors, animation and math', () => {
  const button = require(resolve(eui, 'lib/global_styling/mixins/_button.js'));
  const { euiCanAnimate } = require(resolve(eui, 'lib/global_styling/variables/animations.js'));
  const { mathWithUnits } = require(resolve(eui, 'lib/global_styling/functions/math.js'));
  assert.strictEqual(styles.euiCanAnimate, euiCanAnimate);
  for (const args of [['8px', (x) => x * 2], [['4px', '2px'], (x, y) => x + y], ['1rem', (x) => x / 2]])
    assert.strictEqual(styles.mathWithUnits(...args), mathWithUnits(...args));
  for (const colorMode of ['LIGHT', 'DARK'])
    for (const highContrastMode of [false, 'preferred', 'forced']) {
      const context = {
        colorMode,
        highContrastMode,
        euiTheme: getComputed(EuiThemeBorealis, buildTheme({}, 'parity'), colorMode, highContrastMode)
      };
      for (const color of ['primary', 'success', 'danger', 'disabled', 'text'])
        for (const name of ['euiButtonColor', 'euiButtonEmptyColor', 'euiButtonFillColor'])
          assert.deepEqual(
            styles[name](context, color),
            button[name](context, color),
            `${name} ${color} ${colorMode}/${highContrastMode}`
          );
    }
});
