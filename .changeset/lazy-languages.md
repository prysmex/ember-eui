---
"@ember-eui/core": minor
---

EuiCode, EuiCodeBlock and EuiMarkdownFormat load each syntax highlighting
language the first time it is used, instead of bundling all of refractor's
~280 languages (about 580 KB minified) with the first code component. Code
shows as plain text until its language has loaded, then highlights;
`settled()` waits for it in tests. HTML/XML, CSS and JavaScript are built in
and need no loading.
