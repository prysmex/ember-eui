# Installation

`ember-pikaday` for `@ember-eui/core`

1. `ember install @ember-eui/pikaday`


We are currently using a fork of `ember-pikaday` for more flexibility, so next intructions are regarding styling using that fork.
## Styles

In order to give apps control over styling, the default CSS does not load unless you tell it to. The recommended way to load the CSS is to create this file:

```js
// app/modifiers/pikaday.js

/* Opt-in to using pikaday's default CSS */
import 'ember-pikaday-prysmex/pikaday.css';
export { default } from 'ember-pikaday-prysmex/modifiers/pikaday';
```