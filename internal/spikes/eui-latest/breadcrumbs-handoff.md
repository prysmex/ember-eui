# EuiBreadcrumbs popover content handoff

Branch `eui-wave/breadcrumbs`.

## Files

- `packages/core/src/components/eui-breadcrumbs.gts`: per-item `popoverContent` / `popoverProps`, `<:popoverContent>` block.
- `packages/core/src/components/eui-header-breadcrumbs.gts`: forwards `@max` (default 4), `@truncate` (default true), `@responsive`, `@type` (default `application`, as upstream), `@lastBreadcrumbIsCurrentPage`, `@css` (composed after the header's) and the `<:popoverContent>` block.
- `packages/core/tests/integration/components/eui-breadcrumbs-popover-test.gts` (new, 11 tests).
- Docs: `docs/navigation/breadcrumbs/demo/d07-popover-content.md` (upstream's Deployment + Space switcher example), regenerated API tables (breadcrumbs, header).
- `docs-audit-gaps.md`: removed the EuiBreadcrumbs popover row and the EuiHeaderBreadcrumbs row.
- No generator, `components.ts`, template-registry or `package.json` changes: the style factories were already generated.

## API and the Ember choice for upstream's render function

Upstream: `popoverContent: ReactNode | (closePopover) => ReactNode`. Ember has no render functions, so `popoverContent` is one of:

- a string, shown as text;
- a component, rendered inside the popover with `@closePopover` and `@breadcrumb` (data-driven, works from a plain `breadcrumbs` array, the closest equivalent to the render function);
- `true`, which renders the `<:popoverContent as |breadcrumb closePopover|>` block of `EuiBreadcrumbs` (lets the caller write inline template code that closes over its own state, e.g. the Selectable in the demo). The block is forwarded through the "…" overflow popover and `EuiHeaderBreadcrumbs`, so breadcrumbs inside the overflow keep their popovers.

`popoverProps` is `Omit<EuiPopoverArgs, 'button' | 'closePopover' | 'isOpen' | 'buttonRef' | 'insert'>`. Ember cannot splat args, so the common `EuiPopover` args are forwarded one by one (list in the template); `popoverProps.css` is composed after the wrapper styles.

## DOM / aria (as upstream)

`li.euiBreadcrumb > EuiPopover > EuiToolTip(text, no SR output) > button.euiLink.euiBreadcrumb__content` containing `span` (truncation) and a `chevronSingleDown` icon (upstream 123.1.0 uses chevronSingleDown, not arrowDown) with `aria-label=" - Clicking this button will toggle a popover dialog."` (token `euiBreadcrumb.popoverAriaLabel`). EuiPopover sets `aria-expanded`/`aria-controls` on the button. The last breadcrumb keeps `aria-current="page"`. `href`/`onClick` are ignored. Styles: the same `euiBreadcrumbPopoverStyles` / content styles via `useEuiBorealisStyles` and `@cached` getters; the "…" item and popover breadcrumbs share one code path.

## Ember differences

- Upstream sets the tooltip text from the rendered inner text and shows the SR text only for an explicit `title`; Ember uses `text` (a string) and always disables SR output. There is no `title` on `EuiBreadcrumb`.
- `EuiHeaderBreadcrumbs` now defaults to `type="application"` like upstream (it was `page` before). Existing header tests pass unchanged.

## Checks

- Filtered breadcrumbs run: 22/22 (11 new + existing).
- Full core suite 1344/1344 (1333 + 11 new), ember-tsc clean, eslint clean on changed files, parity 349/349.
- `generate-eui-styles.mjs` rewrote source-path comments in `styles.generated.ts` (symlinked node_modules); reverted, nothing to commit there.
- Focus return to the trigger after Escape is not asserted: even a bare `EuiPopover` loses focus to `body` in the test environment (checked with a control test), so it is not breadcrumb-specific.

## Remaining gaps (not in this scope, still in docs-audit-gaps.md)

- `EuiPageHeader` `breadcrumbProps` accepts only `{className}` (upstream passes `aria-label`, `data-test-subj`, any breadcrumbs prop): belongs to the page-template/header family.
- `EuiHeader` `sections[].breadcrumbProps` (M): header family.
- `EuiBreadcrumb.title` (explicit tooltip title) and `EuiBreadcrumbs` `data-test-subj` forwarding are not implemented / only via `...attributes`.
