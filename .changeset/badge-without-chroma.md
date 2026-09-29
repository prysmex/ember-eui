---
"@ember-eui/core": patch
---

EuiBadge and EuiAvatar no longer load chroma-js (about 43 KB minified): the
palette they color with is kept precomputed.
