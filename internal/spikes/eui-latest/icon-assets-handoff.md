# Icon assets handoff: EUI 123.1.0 icon set with legacy aliases

Branch `eui-wave/icon-assets`. This bundles the upstream `@elastic/eui@123.1.0` icon set, keeps every icon name that worked before, and switches migrated components to the upstream icon names that earlier handoffs could not use. This supersedes the uncommitted `wt/icons-refresh` attempt. That attempt deleted the legacy names; here they stay as aliases. Its rename table was reused after a visual review, with changes listed below.

## Counts

- **698 icon names** in total, up from 470:
  - **569 upstream names**: all 567 keys of upstream's `icon_map`, including the 84 names upstream itself deprecated (`search`, `alert`, `help`, `stopFill`, …), plus EuiNotificationIcon's `infoFill` and `warningStatic`, which upstream keeps outside its icon map.
  - **111 legacy aliases**: old Ember names that upstream renamed or dropped. Each renders its upstream icon from the same svg and chunk.
  - **18 legacy assets**: old Ember names with no upstream equivalent. They keep their previous svg.
- **228 names are new** compared with the previous set. All 470 previous names still resolve.
- **550 svg files** under `vendor/icon/svgs`:
  - 530 upstream files (`svgs/`, `svgs/tokens/`).
  - 2 notification files (`svgs/notification/`).
  - 18 legacy files (`svgs/legacy/`).
  - The 220 other old svgs were deleted, because no name uses them any more.

## Files

- `packages/core/scripts/update-eui-icons.mjs` (new):
  - Re-syncs the svgs from the pinned upstream and rewrites the generated block of `src/utils/css-mappings/eui-icon.ts`.
  - Holds the hand-maintained `LEGACY_ALIASES`, `LEGACY_ASSETS` and `NOTIFICATION_ICONS` tables.
  - `--check` changes nothing and fails if the svgs or the block are stale.
  - Run `node scripts/update-eui-icons.mjs && node scripts/generate-icons.mjs` after an upstream bump.
  - It parses upstream `icon_map.js`. Babel moves upstream's trailing `// Deprecated in favor of …` comments below each entry, and the parser accounts for that.
- `packages/core/scripts/generate-icons.mjs`: `typeToPathMap` values are now explicit svg paths relative to `vendor/icon/svgs` (e.g. `tokens/token_alias`, `legacy/boxes_horizontal`). Before, they were basenames matched anywhere in the folder. Aliases share their target's import specifier, so they share its chunk.
- `packages/core/src/utils/css-mappings/eui-icon.ts`, generated block. New public exports:
  - `typeToPathMap` (698 names).
  - `deprecatedIconTypes`: upstream deprecations → replacement, or `null`.
  - `legacyIconAliases`.
  - `legacyIconTypes`.
- `packages/core/src/-private/icons.ts`: regenerated, 698 loaders. `iconDataTypes` now also has `logoVectorDB`.
- `packages/core/vendor/icon/NOTICE.txt` (new): provenance and license (Elastic License 2.0 / SSPL v1), pointing to `vendor/eui-latest`.
- `packages/core/src/components/eui-icon.gts`: **a name registered in the `euiIcon.icons` config now wins over an EUI icon of the same name.**
  - EUI 123 added common names like `rocket`, `copy`, `return` and `send`. Before this change, an app icon registered as `rocket` silently became EUI's rocket, which is what the existing `iconsFromGlob` test caught.
  - The new getters are `registeredIcon` and `euiIconType`. Loading, `data-icon-type` and `data-type` follow the resolved source.
- Docs:
  - `docs/display/icons/index.md` gets a new "Renamed icons" section and updated counts and examples.
  - The icon demos and `README.md` use upstream names.
  - API docs were regenerated (6 pages).
  - `site/app/components/icon-gallery.gjs` (a minimal change outside core) hides legacy and deprecated names from the gallery, as upstream's docs do. They still render.
- Tests: see "Checks" below.
- `components.md`: note added to the `eui-icon.gts` row.

## Component icon names switched (names only)

Only `@type`/`@iconType` values, icon maps and the doc comments next to them changed. A few comments stated that an icon was missing; those were removed.

| Component | Was | Now (upstream) |
|---|---|---|
| EuiCallOut, EuiToast default icons | `iInCircle`, `checkInCircleFilled`, `warning` (color warning), `error` | `infoFill`, `checkCircleFill`, `warningStatic` (no color, its own two tones), `errorFill`. The toast map type became `color?: string`. |
| EuiIconTip default | `questionInCircle` | `question` |
| EuiMarkdownFormat tooltip icon | `questionInCircle` | `question` |
| Markdown tooltip plugin button | `editorComment` | `comment` |
| EuiMarkdownEditor toolbar | `editorBold`, `editorItalic`, `editorUnorderedList`, `editorOrderedList`, task list = `MarkdownCheckmark` component, `editorCodeBlock`, `editorLink`; preview switch `editorCodeBlock` | `textBold`, `textItalic`, `listBullet`, `listNumber`, `listCheck`, `code`, `link`; preview switch `code`. The `MarkdownCheckmark` import was dropped from the toolbar; the component file is kept. |
| EuiLink, EuiListGroupItem external icon | `popout` | `external` |
| EuiFieldSearch | `search` | `magnify` |
| EuiFieldPassword (dual, visible) | `eyeClosed` | `eyeSlash` |
| EuiFormControlLayoutIcons dropdown (super select, color picker, …) | `arrowDown` | `chevronSingleDown` |
| EuiComboBox trigger arrow | `arrowDown` | `chevronSingleDown` |
| EuiComboBox options / create option enter badge | `returnKey` | `return` |
| EuiSelectableListItem focus badge | `returnKey` | `return` |
| EuiSelectableListItem mixed checkbox | `stopFilled` | `stopFill` |
| EuiCheckbox indeterminate | `stopFilled` | `stopFill` |
| EuiAccordion arrow (2) | `arrowRight` | `chevronSingleRight` |
| EuiBreadcrumbs collapsed | `arrowDown` | `chevronSingleDown` |
| EuiContextMenuItem / Panel back | `arrowRight` / `arrowLeft` | `chevronSingleRight` / `chevronSingleLeft` |
| EuiPagination arrows | `arrowStart`, `arrowLeft`, `arrowRight`, `arrowEnd` | `chevronLimitLeft`, `chevronSingleLeft`, `chevronSingleRight`, `chevronLimitRight` |
| EuiTablePagination, EuiTableSortMobile | `arrowDown` | `chevronSingleDown` |
| EuiSideNavItem, EuiTreeView carets | `arrowDown`/`arrowRight` | `chevronSingleDown`/`chevronSingleRight` |
| EuiSuperDatePicker quick select popover button / prev-next | `arrowDown` / `arrowLeft`, `arrowRight` | `chevronSingleDown` / `chevronSingleLeft`, `chevronSingleRight` |
| EuiResizableContainer collapse button | `menuLeft/Right/Up/Down` | `transition{Left,Right,Top,Bottom}{In,Out}` (upstream's mapping) |
| EuiExpression invalid | `alert` | `warning` |
| EuiFilePicker prompt | `importAction` | `upload` (upstream's default; its invalid/disabled variants are not ported) |
| EuiPinnableListGroup pin | `pinFilled` | `pinFill` |
| EuiNotificationEvent meta menu | `boxesVertical` | `ellipsis` |
| EuiSuggestInput saved status | `checkInCircleFilled` | `checkCircleFill` |

Doc comments only: EuiCallOut/EuiToast `@iconType` examples, EuiFilterButton (still treats `arrowDown` as a popover anchor), EuiEmptyPrompt, EuiSuggestItem, EuiTreeView, EuiDraggable and `preloadIcons`.

Kept, because upstream uses the same names: EuiHeaderLinks/EuiSideNav `apps`, EuiColorPicker `stopSlash`, date picker `sortLeft`/`sortRight`, `calendar`.

Most switches render identically, because the old name is an alias of the new one. The glyph actually changes in these cases:
- Callout/toast defaults, because the notification glyphs are new.
- File picker: `upload` instead of `download`.
- Resizable collapse: transition glyphs instead of menu triangles.
- Markdown task list: `listCheck` instead of the custom checkmark component.
- Markdown preview: `code` instead of the old `editorCodeBlock` alias, which was `code` anyway.
- Notification event: `ellipsis` instead of vertical boxes.

Every upstream glyph is new Borealis artwork, so every icon looks different from the EUI 41 set.

## Legacy aliases (111)

The previous agent's rename table had three sources: upstream deprecation comments, the EUI 118 alias table (#9279) and the changelogs. It could not be re-verified offline, because the CDN fetch was blocked. Every legacy → upstream pair was reviewed visually instead: old and new svgs were rendered side by side in Chromium. Six entries were dropped in favour of keeping the legacy asset, because the upstream glyph means something different:
- `boxesHorizontal`: upstream's `ellipsis` is vertical.
- `listAdd`: `plusCircle` loses the list.
- `indexFlush`: `chartThreshold`.
- `node`: a hexagon became a triangle graph.
- `plusInCircleFilled` and `minusInCircleFilled`: filled became outline.

"Ember pick" marks entries with no declared upstream successor where the upstream glyph is equivalent (checked visually).

| Legacy name | Renders (EUI 123 name) |
|---|---|
| `apmTrace` | `chartWaterfall` |
| `arrowDown` | `chevronSingleDown` |
| `arrowEnd` | `chevronLimitRight` |
| `arrowLeft` | `chevronSingleLeft` |
| `arrowRight` | `chevronSingleRight` |
| `arrowStart` | `chevronLimitLeft` |
| `arrowUp` | `chevronSingleUp` |
| `beaker` | `flask` |
| `checkInCircleFilled` | `checkCircleFill` |
| `cheer` | `popper` |
| `color` | `paintBucket` |
| `console` | `commandLine` |
| `controlsHorizontal` | `controls` |
| `controlsVertical` | `controls` |
| `copyClipboard` | `copy` |
| `crosshairs` | `crosshair` |
| `currency` | `money` |
| `cut` | `scissors` |
| `desktop` | `display` |
| `discuss` | `comment` |
| `doubleArrowLeft` | `chevronDoubleLeft` |
| `doubleArrowRight` | `chevronDoubleRight` |
| `editorAlignCenter` | `textAlignCenter` |
| `editorAlignLeft` | `textAlignLeft` |
| `editorAlignRight` | `textAlignRight` |
| `editorBold` | `textBold` |
| `editorChecklist` | `listCheck` |
| `editorCodeBlock` | `code` |
| `editorDistributeHorizontal` | `distributeHorizontal` (Ember pick) |
| `editorDistributeVertical` | `distributeVertical` (Ember pick) |
| `editorHeading` | `textHeading` |
| `editorItalic` | `textItalic` |
| `editorItemAlignBottom` | `alignBottom` (Ember pick) |
| `editorItemAlignCenter` | `alignCenterHorizontal` (Ember pick) |
| `editorItemAlignLeft` | `alignLeft` (Ember pick) |
| `editorItemAlignMiddle` | `alignCenterVertical` (Ember pick) |
| `editorItemAlignRight` | `alignRight` (Ember pick) |
| `editorItemAlignTop` | `alignTop` (Ember pick) |
| `editorLink` | `link` |
| `editorOrderedList` | `listNumber` |
| `editorPositionBottomLeft` | `alignBottomLeft` (Ember pick) |
| `editorPositionBottomRight` | `alignBottomRight` (Ember pick) |
| `editorPositionTopLeft` | `alignTopLeft` (Ember pick) |
| `editorPositionTopRight` | `alignTopRight` (Ember pick) |
| `editorRedo` | `redo` |
| `editorStrike` | `textStrike` |
| `editorTable` | `table` |
| `editorUnderline` | `textUnderline` |
| `editorUndo` | `undo` |
| `editorUnorderedList` | `listBullet` |
| `email` | `mail` |
| `eql` | `query` |
| `exit` | `logOut` |
| `expand` | `maximize` |
| `expandMini` | `maximize` |
| `exportAction` | `upload` |
| `eyeClosed` | `eyeSlash` |
| `glasses` | `readOnly` |
| `grab` | `dragVertical` |
| `grabHorizontal` | `dragHorizontal` |
| `heatmap` | `chartHeatmap` |
| `iInCircle` | `info` |
| `importAction` | `download` |
| `indexMapping` | `mapping` |
| `indexTemporary` | `tableTime` |
| `invert` | `contrast` |
| `kqlField` | `queryField` |
| `kqlOperand` | `queryOperand` |
| `kqlSelector` | `querySelector` |
| `kqlValue` | `queryValue` |
| `launch` | `rocket` |
| `lettering` | `text` |
| `lineDashed` | `lineDash` |
| `lineDotted` | `lineDot` |
| `logstashIf` | `if` |
| `logstashQueue` | `queue` |
| `magnifyWithExclamation` | `magnifyExclamation` (Ember pick) |
| `magnifyWithMinus` | `magnifyMinus` (Ember pick) |
| `magnifyWithPlus` | `magnifyPlus` (Ember pick) |
| `minusInCircle` | `minusCircle` |
| `offline` | `wifiSlash` |
| `online` | `wifi` |
| `plusInCircle` | `plusCircle` |
| `popout` | `external` |
| `questionInCircle` | `question` |
| `returnKey` | `return` |
| `starFilledSpace` | `starFill` (Ember pick) |
| `starMinusFilled` | `starMinusFill` (Ember pick) |
| `starPlusFilled` | `starPlusFill` (Ember pick) |
| `stopFilled` | `stopFill` (Ember pick) |
| `submodule` | `merge` |
| `tableDensityCompact` | `tableDensityHigh` |
| `tableDensityExpanded` | `tableDensityLow` |
| `tableDensityNormal` | `table` |
| `timeRefresh` | `refreshTime` |
| `timeslider` | `clockControl` |
| `tokenDenseVector` | `tokenVectorDense` |
| `training` | `presentation` |
| `unlink` | `linkSlash` |
| `userAvatar` | `user` |
| `vector` | `vectorSquare` |
| `visAreaStacked` | `chartAreaStack` |
| `visBarHorizontal` | `chartBarHorizontal` |
| `visBarHorizontalStacked` | `chartBarHorizontalStack` |
| `visBarVerticalStacked` | `chartBarVerticalStack` |
| `visMapCoordinate` | `waypoint` |
| `visMapRegion` | `map` |
| `visMetric` | `chartMetric` |
| `visTagCloud` | `chartTagCloud` |
| `visText` | `text` |
| `visVega` | `code` |

## Legacy names kept with their previous artwork (18)

`boxesHorizontal`, `branchUser`, `continuityAboveBelow`, `continuityBelow`, `documentEdit`, `filterInCircle`, `function`, `indexFlush`, `listAdd`, `magnet`, `minusInCircleFilled`, `node`, `pageSelect`, `playFilled`, `plusInCircleFilled`, `securitySignal`, `securitySignalResolved`, `tear` (svgs in `vendor/icon/svgs/legacy/`, from the previously bundled EUI 41 set).

## Upstream-deprecated names (84, still upstream names)

They render whatever upstream's map says, which is sometimes their own legacy glyph and sometimes the replacement's svg (e.g. `search` → `magnify`). They are exported as `deprecatedIconTypes`:

`analyzeEvent` → `cube`, `annotation` → `flag`, `anomalySwimLane` → `chartHeatmap`, `apps` → `grid`, `article` (no/contextual replacement), `boxesVertical` → `ellipsis`, `visArea` → `chartArea`, `visBarVertical` → `chartBarVertical`, `visGauge` → `chartGauge`, `visLine` → `chartLine`, `visPie` → `chartPie`, `cloudDrizzle` → `cloudRain`, `cloudStormy` → `cloudBolt`, `cloudSunny` → `cloudSun`, `editorComment` → `comment`, `compute` → `processor`, `container` → `package`, `continuityAbove` → `upload`, `continuityWithin` → `maximize`, `documents` → `document`, `dotInCircle` (no/contextual replacement), `visTable` → `table`, `list` → `listBullet`, `esqlVis` → `query`, `export` → `upload`, `fold` → `minimize`, `folderClosed` → `folder`, `folderClose` → `folder`, `folderCheck` → `check`, `folderExclamation` (no/contextual replacement), `folderOpened` → `folderOpen`, `frameNext` → `chevronSingleRight`, `framePrevious` → `chevronSingleLeft`, `help` → `question`, `index` → `table`, `indexClose` → `tableCross`, `indexEdit` → `tablePencil`, `indexOpen` → `tablePlus`, `indexRuntime` → `tablePlay`, `indexSettings` → `tableGear`, `ip` → `tokenIP`, `kqlFunction` → `push`, `kubernetesNode` (no/contextual replacement), `kubernetesPod` → `cube`, `logRateAnalysis` → `chartBarVertical`, `logstashFilter` → `filter`, `logstashInput` → `download`, `logstashOutput` → `upload`, `search` → `magnify`, `mapMarker` → `waypoint`, `menuDown` → `transitionBottomOut`, `menuUp` → `transitionTopOut`, `mobile` (no/contextual replacement), `namespace` → `kubernetesNamespace`, `pagesSelect` → `documentsCheck`, `payment` → `money`, `pinFilled` → `pinFill`, `scale` (no/contextual replacement), `securitySignalDetected` (no/contextual replacement), `sessionViewer` → `commandLine`, `singleMetricViewer` → `chartArea`, `spaces` → `grid`, `starEmpty` → `star`, `starEmptySpace` → `star`, `starFilled` → `starFill`, `starFillSpace` → `starFill`, `starMinusEmpty` → `star`, `starMinusFill` → `starFill`, `starPlusEmpty` → `star`, `starPlusFill` → `starFill`, `stats` → `chartLine`, `stopFill` (no/contextual replacement), `stopSlash` (no/contextual replacement), `string` → `tokenString`, `tableOfContents` → `listBullet`, `temperature` → `thermometer`, `timelineWithArrow` → `timelinePointer`, `unfold` → `maximize`, `visGoal` → `chartGauge`, `visTimelion` → `productTimelion`, `visVisualBuilder` → `productTSVB`, `alert` → `warning`, `wordWrap` → `lineBreak`, `wordWrapDisabled` → `lineBreakSlash`

## Tests

`tests/integration/components/eui-icon-test.gts`:
- New module "icon set (EUI 123.1.0)":
  - The catalog test now runs in **6 chunks of up to 120 icons** (697 names). Each chunk renders together and takes about 0.2–0.3s; the old single test took 5–8s under load.
  - "every upstream icon name is bundled": exactly 569 non-legacy names, plus spot checks of the names agents needed and of deprecated upstream names.
  - Legacy aliases, legacy assets and upstream deprecations point at bundled icons. An alias is never an alias of an alias.
  - All 111 aliases render the same svg as their target.
  - 11 renamed pairs render identical artwork, e.g. `arrowDown`/`chevronSingleDown`, `popout`/`external`, `search`/`magnify`, `alert`/`warning`.
  - The 18 legacy assets render.
- New module "components use the upstream icon names": callout defaults (`infoFill`, `checkCircleFill`, `warningStatic`, `errorFill`), EuiIconTip `question`, EuiLink `external`, EuiFieldSearch `magnify`, EuiFieldPassword `eye` → `eyeSlash`, and the EuiPagination chevrons.
- New test: a `euiIcon.icons` registration named like an EUI icon (`copy`) wins.
- Logo test: the EUI 123 logo has no `.outline` element, so the test asserts its filled paths instead.

Updated assertions (icon name only):
- `eui-checkables-test` and `eui-selectable-family-test`: `stopFilled` → `stopFill`, `returnKey` → `return`, `checkInCircleFilled` → `checkCircleFill`.
- `eui-combo-box-family-test`: `arrowDown` → `chevronSingleDown`, `returnKey` → `return`.
- `eui-color-picker-family-test` and `eui-super-select-family-test`: `[data-icon-type="arrowDown"]` → `chevronSingleDown`.
- `eui-icon-family-test`: icon tip default `questionInCircle` → `question`.

## Checks

Environment: Chromium 130, `CI=true`, other agents building concurrently. Run in the worktree.

- `ember-tsc --noEmit`: pass.
- ESLint on every changed core file and on `scripts/update-eui-icons.mjs`: pass. Site ESLint on `icon-gallery.gjs`: pass.
- `vite build --mode=development --out-dir dist-tests` and `testem ci`, full core suite: **1063 tests, 1063 pass, 0 fail**.
  - The first full run had 1051/1062, with 11 failures. All of them asserted the switched names listed above and were updated.
  - The filtered `icon` run was 146/146.
- `node scripts/update-eui-icons.mjs --check`: pass (idempotent). It was also verified to fail on an extra svg.
- `node scripts/generate-api-docs.mjs --check`: pass, after regenerating 6 pages.
- `node --test scripts/eui-upstream-parity.test.mjs`: 304/304. It is not affected by this change.
- Not run: rollup/site build, site acceptance, visual review of the docs gallery.

## Unresolved / next

1. **The rename table could not be re-verified against EUI 118 offline.** An approval request for `cdn.jsdelivr.net` was left pending. The entries were checked visually instead. Prefer correcting `LEGACY_ALIASES` in the script if a mapping is found wrong.
2. **`warningStatic` default icons** (callout and toast, warning color): they have no `@color`, as upstream, so the glyph's own yellow and brown tones show. Earlier they used the theme warning color. Callout/toast icon sizing for upstream EuiNotificationIcon (`l` = 20px) is styling and was left to the `@css` sweep.
3. **EuiFilePicker**: upstream switches the icon to `warning` when invalid and to `minusCircle` when disabled. Only the default name was switched here, because of the names-only rule.
4. **EuiHeaderLinks/EuiSideNav `apps`** is deprecated upstream, but upstream components still use it. It was kept.
5. **Markdown `MarkdownCheckmark` component**: it is no longer used by the toolbar, and the file was kept. It may be removed later.
6. **Bundle**: 698 lazy loaders now point at 550 chunks, up from 470/418. Aliases share chunks, and only rendered icons are downloaded.
7. **Behavior change in EuiIcon**: `euiIcon.icons` registrations now win over EUI names. This affects apps that registered a name equal to an EUI name, which was previously shadowed by EUI.
