---
order: 1
---

# Looking up a token

<EuiText>

`EuiI18n` yields a component rendering the translated text for `@token`
(or `@default`), with its `{placeholders}` filled from `@values`. Values
can be components.

</EuiText>

```hbs template
<EuiI18n
  @token='euiPagination.pageOfTotalCompressed'
  @default='{page} of {total}'
  @values={{hash page=(component 'eui-button') total=(component 'eui-button')}}
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
```
