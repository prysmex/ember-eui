---
order: 5
---

# Common pattern

<EuiText>
	A common pattern is to use a single breadcrumb to return the user to a listing page from which the current page was navigated to
</EuiText>

```hbs template
<EuiPageHeader
  @bottomBorder={{true}}
  @pageTitle='Page title'
  @description='Example of a description.'
  @breadcrumbs={{array
    (hash
      text=(component
        'eui-button-title'
        title='Return'
        iconType='arrowLeft'
        color='primary'
        size='s'
				buttonEmpty=true
      )
      href='http://www.elastic.co'
    )
  }}
>
  <:rightSideItems>
    <EuiFlexItem>
      <EuiButton @fill={{true}}>Add something</EuiButton>
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiButton>Do something</EuiButton>
    </EuiFlexItem>
  </:rightSideItems>
</EuiPageHeader>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class AccordionDemo1Component extends Component {
  breadcrumbs = [
    {
      text: 'Breadcrumb 1',
      href: '#',
      onClick: (e) => e.preventDefault()
    },
    {
      text: 'Breadcrumb 2',
      href: '#',
      onClick: (e) => e.preventDefault()
    },
    {
      text: 'Current',
      href: '#',
      onClick: (e) => e.preventDefault()
    }
  ];
}
```
