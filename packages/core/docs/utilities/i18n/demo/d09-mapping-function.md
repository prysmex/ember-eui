---
order: 9
---

# Mapping function

<EuiText>

Upstream's <EuiCode>mappingFunc</EuiCode> transforms every text after it is looked up, for example to pseudo-localize an app and find texts that are not translatable. Pass it as <EuiCode>mappingFunc</EuiCode> in <EuiCode>@i18n</EuiCode> of one <strong>EuiI18n</strong>, or set it on the <EuiCode>euiI18n</EuiCode> service (<EuiCode>this.euiI18n.mappingFunc = (text) => text.toUpperCase()</EuiCode>) to transform the texts of all EUI components. It also maps the string <EuiCode>@values</EuiCode>, and the result of a formatting function as a whole.

</EuiText>

<EuiSpacer />

```gjs component
import { EuiI18n } from '@ember-eui/core/components';
import { hash } from '@ember/helper';

const upper = (text) => text.toUpperCase();

<template>
  <EuiI18n
    @token='mappingFunc.example'
    @default='Hello, {name}. This text is mapped.'
    @values={{hash name='Ada'}}
    @i18n={{hash mappingFunc=upper}}
    as |Text|
  >
    <p><Text /></p>
  </EuiI18n>
</template>
```
