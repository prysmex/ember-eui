---
order: 3
---

# Multiple accordions

<EuiText>
  Use any number of
  <strong>EuiAccordion</strong>
  elements to visually display them as a group.<br /><br />
  Due to the previously mentioned bare styles, it is recommended to place an
  <strong>EuiSpacer</strong>
  between accordion items. Padding within each accordion item can be applied via
  the
  <EuiCode>paddingSize</EuiCode>
  prop.
</EuiText>

```hbs template
<EuiSpacer />
<EuiAccordion @paddingSize='l'>
  <:buttonContent>
    An accordion with padding applied through props
  </:buttonContent>
  <:content>
    <EuiText @size='s'>
      <p>The content inside can be of any height.</p>
      <p>The content inside can be of any height.</p>
      <p>The content inside can be of any height.</p>
    </EuiText>
  </:content>
</EuiAccordion>
<EuiSpacer />
<EuiAccordion @paddingSize='l' @buttonContentClassName='eui-textTruncate'>
  <:buttonContent>
    A second accordion with padding and a very long title that should truncate
    because of eui-textTruncate
  </:buttonContent>
  <:content>
    <EuiText @size='s'>
      <p>The content inside can be of any height.</p>
      <p>The content inside can be of any height.</p>
      <p>The content inside can be of any height.</p>
      <p>The content inside can be of any height.</p>
      <p>The content inside can be of any height.</p>
      <p>The content inside can be of any height.</p>
    </EuiText>
  </:content>
</EuiAccordion>
<EuiSpacer />
<EuiAccordion @paddingSize='m'>
  <:buttonContent>
    A third accordion with nested accordion
  </:buttonContent>
  <:content>
    <EuiText @size='s'>
      <p>
        This content area will grow to accommodate when the accordion below
        opens
      </p>
    </EuiText>
    <EuiSpacer/>
    <EuiAccordion>
      <:buttonContent>
        A fourth nested accordion
      </:buttonContent>
      <:content>
        <EuiPanel @color='subdued'>
          Any content inside of
          <strong>EuiAccordion</strong>
          will appear here.
        </EuiPanel>
      </:content>
    </EuiAccordion>
  </:content>
</EuiAccordion>
```
