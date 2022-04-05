---
order: 7
---

# Beta badge type

<EuiText>
  <p>
The <strong>EuiBetaBadge</strong> was created specifically to call out modules that are not in GA. Generally the labels used are "Beta" or "Lab". They require an extra <EuiCode>tooltipContent</EuiCode> to describe the purpose of the badge. You can pass an optional title prop to populate the tooltip title or html title attribute but by default it will use the <EuiCode>label</EuiCode>.

If you pass in an <EuiCode>iconType</EuiCode>, only the icon will be used in the badge itself and the label will be applied as the title. Only use an icon when attaching the beta badge to small components. Beta badges can also be made clickable by passing <EuiCode>href</EuiCode> or <EuiCode>onClick</EuiCode> as needed.

They can also be used in conjunction with EuiCards.

  </p>
</EuiText>

```hbs template
<EuiPanel @hasShadow={{false}}>
  <EuiBetaBadge @label='Beta' @title='Philly' />
  <EuiBetaBadge @label='Beta' @title='Philly' />
  <EuiBetaBadge @label='B' @title='Philly' />
  <EuiBetaBadge @label='B' @title='Philly' />
  <EuiBetaBadge @label='Lab' @title='Coat' @iconType='beaker' />
  <EuiBetaBadge @label='Lab' @title='Coat' @iconType='beaker' />
  <EuiSpacer @size='xs' />
  <EuiBetaBadge @label='Beta' @title='Philly' @color='accent' />
  <EuiBetaBadge @label='Beta' @title='Philly' @color='accent' />
  <EuiBetaBadge @label='B' @title='Philly' @color='accent' />
  <EuiBetaBadge @label='B' @title='Philly' @color='accent' />
  <EuiBetaBadge @label='Lab' @title='Coat' @iconType='beaker' @color='accent' />
  <EuiBetaBadge @label='Lab' @title='Coat' @iconType='beaker' @color='accent' />
  <EuiSpacer @size='xs' />
  <EuiBetaBadge @label='Beta' @title='Philly' @color='subdued' />
  <EuiBetaBadge @label='Beta' @title='Philly' @color='subdued' />
  <EuiBetaBadge @label='B' @title='Philly' @color='subdued' />
  <EuiBetaBadge @label='B' @title='Philly' @color='subdued' />
  <EuiBetaBadge
    @label='Lab'
    @title='Coat'
    @iconType='beaker'
    @color='subdued'
  />
  <EuiBetaBadge
    @label='Lab'
    @title='Coat'
    @iconType='beaker'
    @color='subdued'
  />
  <EuiSpacer />
  <EuiTitle @size='m'>
    Beta badges will also line up nicely with titles
    <EuiBetaBadge @label='Beta' @title='Philly' />
  </EuiTitle>
  <EuiTitle @size='xs'>
    Clickable beta badges
  </EuiTitle>
  <EuiSpacer />
  <EuiBetaBadge
    @label='Lab'
    @title='Coat'
    @iconType='beaker'
    @onClick={{this.clickBetaBadge}}
  />
  <EuiBetaBadge
    @label='Beta'
    @title='Philly'
    @href='http://www.elastic.co/subscriptions'
  />
</EuiPanel>
```
