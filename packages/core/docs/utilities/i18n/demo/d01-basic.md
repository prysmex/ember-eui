---
order: 1
---

<EuiText>
<p>
	Render strings to components, you can provide a hash containing custom tokens via <EuiCode>{{"@i18n"}}</EuiCode> or override i18n/index.js in your host app to export a hash containg them
</p>
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
