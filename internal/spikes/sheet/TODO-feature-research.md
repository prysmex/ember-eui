# TODO: feature research against other grids (added 2026-11-19)

The user's request: find features in other grids that `@ember-eui/sheet`
does not have and is not planned to have, then analyze the delta and decide
which are worth adding.

## Products to compare

- Glide Data Grid (canvas grid, React)
- AG Grid (Community and Enterprise, so the line between them is visible)
- Handsontable
- RevoGrid
- NocoDB's grid view (an Airtable-like app, not a library)
- Optional, if useful: Baserow and Teable (also Airtable-like apps)

## What "we have" means

The baseline is everything built in v0.1, v0.2 and v0.3, plus what is
designed for v0.3 batches 3b, 3c, 4 and 5: `PACKAGE-DESIGN.md`,
`V02-DESIGN.md`, `V03-DESIGN.md` and their RESULTS files. A feature that is
already in or designed there is not part of the delta.

## The output

One table, with one row per feature:

- the feature;
- which products have it;
- our status (none / partial / designed);
- its value for a data-entry grid like Airtable's;
- its cost: lines, and whether it needs an EuiDataGrid change
  (`packages/core/src`);
- its performance risk (does anything run per cell?);
- whether it fits the sheet's rules (V03-DESIGN.md section 1: a pure view of
  the owner's rows, data down and actions up, every write a change set, no
  built-in toolbar);
- a verdict: worth it, maybe, or not.

Then a short list of the "worth it" features, grouped into possible batches.

## Rules

- Out of scope on purpose (do not count them as gaps): formulas, computed
  fields, rollups, and real-time collaboration. Those are the owner's job.
- Facts about a product come from its documentation, with a link. Mark
  anything taken from memory as unverified (support.airtable.com already
  refused automated fetches once).
- Research only: no code changes.
