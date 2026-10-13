# Parallel agent starting task

Read README.md, progress.md and components.md before working. Target branch is feat/eui-latest. A separate checkout must start from the migration foundation checkpoint, not from feat/emotion alone.

Suggested next owner: EuiText, EuiTitle, EuiTextColor and EuiTextAlign (near the bottom of the inventory). Claim these rows before editing. Keep this family together instead of taking every remaining component in reverse order; complex overlay/form/table components need dependency audits first.

Use pinned EUI123.1.0 / Borealis8.1.0. Existing entry points:

- `getEuiThemeContext(this)` from utils/emotion/consume.ts
- `context.upstream` for native resolved theme/contrast/modifications
- `useEuiBorealisStyles(context, factory)` and `euiClass(context, ...styles)` from utils/eui/styles.ts
- `@borealisOverrides` and `@highContrastMode` on EuiEmotionProvider
- Extend extraction entries in scripts/generate-eui-styles.mjs only after coordinating ownership; never hand-edit styles.generated.ts. Add independent upstream parity coverage for new factories.

Latest-only styling is required. Do not restore legacy selector variants, specificity shields, or coexistence tests. Scoped resets still matter because Ember does not run React's global reset.

Tests should cover variants, reactive argument/token changes, light/dark nested inheritance and sibling isolation, native attributes/events/blocks, semantic/accessibility contracts, and relevant logical CSS/contrast. Use computed style/behavior assertions. Record API/default changes and unresolved work in a component-family handoff Markdown, with exact validation evidence. Mark Migrated only after checks pass.

Avoid editing the five first ports/providers/showcase while the coordinator finalizes them. Coordinate generator edits and site builds/tests (shared outputs), and dependency synchronization. Preserve unrelated .vscode/settings.json. Do not push or publish without user instructions.
