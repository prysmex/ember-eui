---
"@ember-eui/core": major
"@ember-eui/validated-form": minor
"@ember-eui/changeset-form": minor
---

`EuiComboBox` now behaves like EUI 123.1.0's by default:

- Matching ignores case but no longer accents (upstream's matcher); `@isCaseSensitive`, `@matcher` and the new `@optionMatcher` customize it.
- In multiple selection the selected options are no longer listed, and the list stays open after a choice (`@closeOnSelect` defaults to `true` only for single selection). Single selection keeps its option listed with a check mark.
- Leaving the combo box with typed text adds it (`@onCreateOption`, or the option it names exactly); text that is not added stays in the input and marks the combo box invalid. Enter adds the typed text too when no option is highlighted, even if it partially matches options.
- Nothing is highlighted when the list opens (tooltips and `aria-activedescendant` follow the arrow keys); the arrows wrap, Escape keeps the text, Tab is held while an option is highlighted, hovering no longer highlights, and focusing the input opens the list.
- `@sortMatchesBy="startsWith"` sorts the whole list like upstream, group titles included.
- Upstream empty states ("{searchValue} doesn't match any options", "There aren't any options available", "You've selected all available options", "{label} has already been added"); `@isLoading` shows the spinner in the list too.
- The search input is the `combobox` (with `aria-expanded`, `aria-controls`, `aria-haspopup`) and the wrapper is no longer a tab stop; the listbox is labelled "Choose from the following options"; screen reader instructions are read on focus. The enter badge on the highlighted option needs `@onFocusBadge`.
- New `@async`, `@onSearchChange`, `@optionMatcher` and `@onFocusBadge`, and upstream's `{ label, options }` groups.

The validated-form and changeset-form combo box fields forward every `EuiComboBox` argument (and the search text to their block), and the changeset field validates again after a custom option is added.

See "Migrating to Borealis" for the full list.
