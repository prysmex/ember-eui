/** Reproducibly extract pure EUI style factories without React components/hooks. */
import { createRequire } from 'node:module';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(resolve(root, 'packages/core/package.json'));
const { build } = require('esbuild');
const euiRoot = dirname(require.resolve('@elastic/eui/package.json'));
const expected = {
  '@elastic/eui': '123.1.0',
  '@elastic/eui-theme-borealis': '8.1.0',
  '@elastic/eui-theme-common': '10.1.0'
};
for (const [name, version] of Object.entries(expected)) {
  const actual = JSON.parse(
    readFileSync(
      name === '@elastic/eui'
        ? resolve(euiRoot, 'package.json')
        : resolve(dirname(require.resolve(name)), '../../package.json')
    )
  ).version;
  if (actual !== version)
    throw new Error(`${name}: expected ${version}, found ${actual}`);
}
const entries = {
  'components/spacer/spacer.styles.js': ['euiSpacerStyles'],
  'components/horizontal_rule/horizontal_rule.styles.js': ['euiHorizontalRuleStyles'],
  'components/panel/panel.styles.js': ['euiPanelStyles'],
  'components/loading/loading_spinner.styles.js': ['euiLoadingSpinnerStyles', 'euiSpinnerBorderColorsCSS'],
  'components/button/button_display/_button_display.styles.js': ['euiButtonDisplayStyles'],
  'components/button/button_display/_button_display_content.styles.js': ['euiButtonDisplayContentStyles'],
  'components/text/text.styles.js': ['euiTextStyles'],
  'components/text/text_color.styles.js': ['euiTextColorStyles'],
  'components/text/text_align.styles.js': ['euiTextAlignStyles'],
  'components/title/title.styles.js': ['euiTitleStyles', 'euiTitle'],
  'components/link/link.styles.js': ['euiLinkStyles'],
  'components/badge/badge.styles.js': ['euiBadgeStyles'],
  'components/badge/color_utils.js': ['euiBadgeColors', 'getBadgeColors', 'getTextColor', 'getCustomInteractiveColors', 'getIsValidColor'],
  'components/badge/badge_group/badge_group.styles.js': ['euiBadgeGroupStyles'],
  'components/badge/beta_badge/beta_badge.styles.js': ['euiBetaBadgeStyles'],
  'components/badge/notification_badge/badge_notification.styles.js': ['euiNotificationBadgeStyles'],
  'components/flex/flex_group.styles.js': ['euiFlexGroupStyles'],
  'components/flex/flex_item.styles.js': ['euiFlexItemStyles'],
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
  // content-blocks
  'components/call_out/call_out.styles.js': ['euiCallOutStyles', 'euiCallOutHeaderStyles'],
  'components/empty_prompt/empty_prompt.styles.js': ['euiEmptyPromptStyles'],
  'components/stat/stat.styles.js': ['euiStatStyles', 'euiStatTitleStyles'],
  'global_styling/mixins/_states.js': ['euiFocusRing'],
  'global_styling/reset/reset.js': ['resetStyles'],
  'global_styling/mixins/_helpers.js': ['euiScrollBarStyles', 'euiYScroll', 'euiFullHeight', 'euiYScrollWithShadows'],
  'services/color/manipulation.js': ['transparentize', 'tint', 'shade'],
  'global_styling/mixins/_padding.js': ['euiPaddingSize'],
  'global_styling/mixins/_color.js': ['euiBackgroundColor', 'euiBorderColor'],
  'global_styling/mixins/_button.js': ['euiButtonDisplaysColors', 'euiButtonInteractionStyles'],
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
  'components/form/form_control_layout/form_control_layout_delimited.styles.js': ['euiFormControlLayoutDelimitedStyles', 'euiFormControlLayoutDelimited__delimiter', 'euiFormControlLayoutDelimited__input'],
  // page layout
  'components/page/page.styles.js': ['euiPageStyles'],
  'components/page/_restrict_width.js': ['PAGE_MAX_WIDTH', 'setStyleForRestrictedPageWidth'],
  'components/page/page_body/page_body.styles.js': ['euiPageBodyStyles'],
  'components/page/page_section/page_section.styles.js': ['euiPageSectionStyles', 'euiPageSectionContentStyles'],
  'components/page/page_sidebar/page_sidebar.styles.js': ['euiPageSidebarStyles'],
  'components/page/page_header/page_header.styles.js': ['euiPageHeaderStyles'],
  'components/page/page_header/page_header_content.styles.js': ['euiPageHeaderContentStyles'],
  'components/page_template/outer/page_outer.styles.js': ['euiPageOuterStyles'],
  'components/page_template/inner/page_inner.styles.js': ['euiPageInnerStyles'],
  'components/bottom_bar/bottom_bar.styles.js': ['euiBottomBarStyles'],
  'global_styling/mixins/_responsive.js': ['euiBreakpoint', 'euiMinBreakpoint', 'euiMaxBreakpoint'],
  // utilities
  'components/accessibility/screen_reader_only/screen_reader_only.styles.js': ['euiScreenReaderOnly', 'euiScreenReaderOnlyStyles'],
  'components/accessibility/skip_link/skip_link.styles.js': ['euiSkipLinkStyles'],
  'components/progress/progress.styles.js': ['euiProgressStyles', 'euiProgressDataStyles', 'euiProgressLabelStyles', 'euiProgressValueTextStyles'],
  'services/color/contrast.js': ['makeHighContrastColor'],
  'components/skeleton/skeleton_text.styles.js': ['euiSkeletonTextStyles'],
  'components/loading/loading_chart.styles.js': ['euiLoadingChartStyles', 'euiLoadingChartBarStyles'],
  'components/loading/loading_elastic.styles.js': ['euiLoadingElasticStyles'],
  'components/loading/loading_logo.styles.js': ['euiLoadingLogoStyles'],
  'global_styling/utility/animations.js': ['euiAnimFadeIn'],
  'global_styling/functions/high_contrast.js': ['highContrastModeStyles'],
  'global_styling/functions/logicals.js': ['logicalCSS', 'logicalSizeCSS'],
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
  'components/token/token_map.js': ['TOKEN_MAP', 'TOKEN_COLOR_TO_ICON_COLOR_MAP'],
  'services/color/is_color_dark.js': ['isColorDark'],
  'services/color/hex_to_rgb.js': ['hexToRgb'],
  // navigation
  'components/tabs/tabs.styles.js': ['euiTabsStyles'],
  'components/tabs/tab.styles.js': ['euiTabStyles', 'euiTabContentStyles'],
  'components/breadcrumbs/breadcrumbs.styles.js': ['euiBreadcrumbsListStyles'],
  'components/breadcrumbs/breadcrumb.styles.js': ['euiBreadcrumbStyles'],
  'components/breadcrumbs/_breadcrumb_content.styles.js': ['euiBreadcrumbContentStyles', 'euiBreadcrumbPopoverStyles'],
  'components/pagination/pagination.styles.js': ['euiPaginationStyles'],
  'components/pagination/pagination_button.styles.js': ['euiPaginationButtonStyles'],
  'components/steps/step.styles.js': ['euiStepVariables', 'euiStepStyles', 'euiStepContentStyles', 'euiStepTitleStyles'],
  'components/steps/step_number.styles.js': ['euiStepNumberStyles', 'euiStepNumberContentStyles'],
  'components/steps/steps_horizontal.styles.js': ['euiStepsHorizontalStyles'],
  'components/steps/step_horizontal.styles.js': ['euiStepHorizontalStyles', 'euiStepHorizontalNumberStyles', 'euiStepHorizontalTitleStyles'],
  'components/steps/sub_steps.styles.js': ['euiSubStepsStyles'],
  'global_styling/mixins/_typography.js': ['euiTextTruncate', 'euiFontSize', 'euiTextBreakWord'],
  // lists
  'components/list_item_layout/_list_item_layout.styles.js': ['euiListItemLayoutStyles', 'euiListItemLayoutWrapperStyles', 'euiListItemVariables'],
  'components/list_group/list_group.styles.js': ['euiListGroupStyles'],
  'components/list_group/list_group_item.styles.js': ['euiListGroupItemStyles', 'euiListGroupItemTooltipStyles'],
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
  'components/flyout/const.js': ['FLYOUT_SIZES', 'FLYOUT_SIDES', 'FLYOUT_TYPES', 'FLYOUT_PADDING_SIZES', 'isEuiFlyoutSizeNamed'],
  'components/flyout/flyout.styles.js': ['euiFlyoutStyles', 'composeFlyoutInlineStyles', 'FLYOUT_BREAKPOINT'],
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
  'components/tool_tip/tool_tip.styles.js': ['euiToolTipStyles', 'euiToolTipAnchorStyles', 'euiToolTipBackgroundColor', 'euiToolTipBorderColor'],
  'components/context_menu/context_menu.styles.js': ['euiContextMenuStyles', 'euiContextMenuVariables'],
  'components/context_menu/context_menu_item.styles.js': ['euiContextMenuItemStyles'],
  'components/context_menu/context_menu_panel.styles.js': ['euiContextMenuPanelStyles'],
  'components/context_menu/context_menu_panel_title.styles.js': ['euiContextMenuPanelTitleStyles'],
  // cards
  'components/card/card.styles.js': ['euiCardStyles', 'euiCardTextStyles', 'euiCardBetaBadgeStyles'],
  'components/card/card_select/card_select.styles.js': ['euiCardSelectStyles'],
  'components/card/checkable_card/checkable_card.styles.js': ['euiCheckableCardStyles'],
  'components/panel/split_panel/split_panel.styles.js': ['euiSplitPanelOuterStyles', 'euiSplitPanelInnerStyles'],
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
  'components/expression/expression.styles.js': ['euiExpressionStyles', 'euiExpressionDescriptionStyles', 'euiExpressionValueStyles', 'euiExpressionIconStyles'],
  'components/tour/tour.styles.js': ['euiTourStyles', 'euiTourBeaconStyles'],
  'components/tour/_tour_header.styles.js': ['euiTourHeaderStyles'],
  'components/tour/_tour_footer.styles.js': ['euiTourFooterStyles', '_tourFooterBgColor'],
  // resizable-dnd
  'components/resizable_container/resizable_container.styles.js': ['euiResizableContainerStyles'],
  'components/resizable_container/resizable_button.styles.js': ['euiResizableButtonStyles'],
  'components/resizable_container/resizable_collapse_button.styles.js': ['euiResizableCollapseButtonStyles'],
  'components/resizable_container/resizable_panel.styles.js': ['euiResizablePanelStyles', 'euiResizablePanelContentStyles'],
  'components/drag_and_drop/draggable.styles.js': ['euiDraggableStyles', 'euiDraggableItemStyles'],
  'components/drag_and_drop/droppable.styles.js': ['euiDroppableStyles'],
  // super select
  'components/form/super_select/super_select.styles.js': ['euiSuperSelectStyles', 'euiSuperSelectControlStyles'],
  // selectable and suggest
  'components/selectable/selectable.styles.js': ['euiSelectableStyles'],
  'components/selectable/selectable_message/selectable_message.styles.js': ['euiSelectableMessageStyles'],
  // combo box
  'components/combo_box/combo_box.styles.js': ['euiComboBoxStyles'],
  'components/combo_box/combo_box_input/combo_box_input.styles.js': ['euiComboBoxInputStyles'],
  'components/combo_box/combo_box_input/combo_box_pill.styles.js': ['euiComboBoxPillStyles'],
  'components/combo_box/combo_box_options_list/combo_box_options_list.styles.js': ['euiComboBoxOptionListStyles', 'LIST_MAX_HEIGHT'],
  // code-block
  'components/code/code_syntax.styles.js': ['euiCodeSyntaxVariables', 'euiCodeTextColors'],
  'components/code/code_block.styles.js': ['euiCodeBlockStyles', 'euiCodeBlockPreStyles', 'euiCodeBlockCodeStyles'],
  'components/code/code_block_controls.styles.js': ['euiCodeBlockControlsStyles'],
  'components/code/code_block_annotations.style.js': ['euiCodeBlockAnnotationsStyles'],
  'global_styling/functions/math.js': ['mathWithUnits']
};
const hooks = `export function useEuiTheme(){throw new Error('React hooks cannot run in Ember')}
export function useEuiMemoizedStyles(){throw new Error('React hooks cannot run in Ember')}`;
const result = await build({
  stdin: {
    contents: Object.entries(entries)
      .map(
        ([path, names]) =>
          `export { ${names.join(', ')} } from ${JSON.stringify(resolve(euiRoot, 'es', path))};`
      )
      .join('\n'),
    resolveDir: root,
    sourcefile: 'eui-style-entry.js'
  },
  bundle: true,
  write: false,
  format: 'esm',
  platform: 'browser',
  target: 'es2022',
  metafile: true,
  external: [
    '@elastic/eui-theme-common',
    '@elastic/eui-theme-borealis',
    '@emotion/serialize',
    'chroma-js'
  ],
  define: { 'process.env.NODE_ENV': '"production"' },
  plugins: [
    {
      name: 'ember-eui-pure-styles',
      setup(builder) {
        builder.onResolve({ filter: /^@emotion\/react$/ }, () => ({
          path: 'emotion',
          namespace: 'ember-eui'
        }));
        builder.onResolve({ filter: /^(react|react-dom)(\/|$)/ }, (args) => {
          throw new Error(`Unexpected React runtime dependency: ${args.path}`);
        });
        builder.onLoad({ filter: /.*/, namespace: 'ember-eui' }, () => ({
          contents: `import { serializeStyles } from '@emotion/serialize';
export const css = (...args) => serializeStyles(args);
export const keyframes = (...args) => { const value = css(...args); const name = 'animation-' + value.name; return { name, styles: '@keyframes ' + name + '{' + value.styles + '}', anim: 1, toString() { return '_EMO_' + name + '_' + this.styles + '_EMO_'; } }; };`,
          loader: 'js'
        }));
        builder.onLoad(
          { filter: /\/es\/global_styling\/index\.js$/ },
          (args) => ({
            contents: readFileSync(args.path, 'utf8').replace(
              "export * from './reset/global_styles';",
              ''
            ),
            resolveDir: dirname(args.path),
            loader: 'js'
          })
        );
        builder.onLoad(
          { filter: /\/es\/services\/theme\/(index|hooks)\.js$/ },
          () => ({ contents: hooks, loader: 'js' })
        );
        builder.onLoad({ filter: /\/es\/services\/index\.js$/ }, (args) => ({
          contents: `${hooks}\nexport * from './color/contrast';\nexport * from './color/manipulation';\nexport * from './color/is_color_dark';`,
          resolveDir: dirname(args.path),
          loader: 'js'
        }));
        builder.onLoad(
          { filter: /\/es\/services\/color\/index\.js$/ },
          (args) => ({
            contents: readFileSync(args.path, 'utf8').replace(
              /^export .*eui_palettes_hooks.*$/m,
              ''
            ),
            resolveDir: dirname(args.path),
            loader: 'js'
          })
        );
        builder.onLoad({ filter: /\/es\/components\/common\.js$/ }, () => ({
          contents: 'export const keysOf = Object.keys;',
          loader: 'js'
        }));
      }
    }
  ]
});
const typedOutput = result.outputFiles[0].text
  .replace(
    /(function euiSpinnerBorderColorsCSS\d*\()(\w+)(\) \{)/,
    '$1$2: EuiBorealisContext, _colors?: { border?: string; highlight?: string }$3'
  )
  .replace(
    /(function euiButtonDisplaysColors\d*\(\w+\)) \{/,
    '$1: Record<string, Record<string, import("@emotion/serialize").SerializedStyles>> {'
  );
const generated =
  '// @ts-nocheck\n// GENERATED by scripts/generate-eui-styles.mjs. Do not edit.\n// Upstream sources licensed under Elastic License 2.0 or SSPL v1; see vendor/eui-latest.\n' +
  "import type { EuiBorealisContext } from './theme.ts';\n" +
  typedOutput;
if (
  /React hooks cannot run in Ember|from ["'](?:react|@emotion\/react)/.test(
    generated
  )
)
  throw new Error('React-dependent code survived style extraction');
const files = Object.keys(result.metafile.inputs).filter(
  (path) => !path.startsWith('ember-eui:') && !path.includes('style-entry')
);
const provenance = {
  versions: expected,
  adapters: [
    'Emotion serialization only',
    'pure style barrels',
    'Object.keys helper'
  ],
  sources: files
    .map((path) => ({
      path: path.includes('/es/')
        ? '@elastic/eui/es/' + path.split('/es/')[1]
        : path,
      sha256: createHash('sha256')
        .update(readFileSync(resolve(root, path)))
        .digest('hex')
    }))
    .sort((a, b) => a.path.localeCompare(b.path))
};
const targets = [
  ['packages/core/src/utils/eui/styles.generated.ts', generated],
  [
    'internal/spikes/eui-latest/upstream-sources.json',
    JSON.stringify(provenance, null, 2) + '\n'
  ]
];
for (const [path, content] of targets) {
  const target = resolve(root, path);
  if (process.argv.includes('--check')) {
    if (readFileSync(target, 'utf8') !== content)
      throw new Error(`Stale generated artifact: ${path}`);
  } else {
    mkdirSync(dirname(target), { recursive: true });
    writeFileSync(target, content);
  }
}
console.log(
  `EUI ${expected['@elastic/eui']}: extracted ${Object.values(entries).flat().length} style factories; React-free output verified`
);
