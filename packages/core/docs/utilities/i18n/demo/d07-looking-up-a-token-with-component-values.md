---
order: 7
---

# Component values (Ember EUI extra)

<EuiText>

`EuiI18n` yields a component rendering the translated text for `@token`
(or `@default`), with its `{placeholders}` filled from `@values`. Values
can be components.

</EuiText>

```gjs component
import { EuiButton, EuiI18n } from '@ember-eui/core/components';
import { hash } from '@ember/helper';

<template>
<EuiI18n
  @token='euiPagination.pageOfTotalCompressed'
  @default='{page} of {total}'
  @values={{hash page=EuiButton total=EuiButton}}
  as |Token|
>
  <Token as |value|>
		{{value}}
	</Token>
</EuiI18n>
<EuiI18n
  @token='euiPagination.pageOfTotalCompressed'
  @default='{page} other {total}'
  @values={{hash page=10 total=2000}}
  as |Token|
>
  <Token as |value|>
		{{value}}
	</Token>
</EuiI18n>
</template>
```
