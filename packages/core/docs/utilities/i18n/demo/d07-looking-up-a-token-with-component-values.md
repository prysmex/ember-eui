---
order: 7
---

# Component values

<EuiText>

Interpolation values can be components (upstream's React elements), e.g. to make part of a translation bold or a link. <strong>EuiI18n</strong> yields a component; invoked without a block it renders the text with each component value in place of its placeholder. With a block it yields every part in turn: the text pieces as strings and the component values as components, so you can wrap or inspect them. Components take no arguments from the translation, so build them with the data they need (a template-only component or <EuiCode>(component ...)</EuiCode> with arguments). Named blocks cannot be chosen at run time, which is why a block value is a component.

</EuiText>

<EuiSpacer />

```gjs component
import { EuiBadge, EuiI18n, EuiSpacer } from '@ember-eui/core/components';
import { hash } from '@ember/helper';

const Name = <template><strong>Ada Lovelace</strong></template>;
const Count = <template><EuiBadge @color="primary">12</EuiBadge></template>;

<template>
  <p>
    <EuiI18n
      @token='euiI18nComponents.signedIn'
      @default='Signed in as {name}, with {count} new messages.'
      @values={{hash name=Name count=Count}}
      as |Text|
    ><Text /></EuiI18n>
  </p>
  <EuiSpacer />
  <p>
    <EuiI18n
      @token='euiI18nComponents.signedIn'
      @default='Signed in as {name}, with {count} new messages.'
      @values={{hash name='Grace' count=3}}
      as |Text|
    ><Text /></EuiI18n>
  </p>
</template>
```
