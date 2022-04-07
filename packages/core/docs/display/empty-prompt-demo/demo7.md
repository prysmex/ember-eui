---
order: 7
---

# More types of empty states

<!-- <EuiText>
 <strong>EuiEmptyPrompt</strong> can be used for more than just empty pages. The following example showcases different types of empty states that you can create with the <strong>EuiEmptyPrompt</strong>. For a full list see the usage guidelines.
</EuiText> -->

```hbs template
{{#let (unique-id) as |selectId|}}
  <EuiFormRow
    @id={{selectId}}
  >
    <EuiSelect
      @value={{this.exampleValue}}
      @hasNoInitialSelection={{true}}
      @options={{array
        (hash value='page not found' text='Page not found')
        (hash value='no permission' text='No permission')
        (hash value='license upgrade' text='License Upgrade')
        (hash value='complex' text='Complex')
      }}
      @id={{selectId}}
      {{on 'change' (pick 'target.value' (set this 'exampleValue'))}}
    >
      <:prepend as |classes|>
        <EuiFormLabel class={{classes}} for={{selectId}}>
          Examples
        </EuiFormLabel>
      </:prepend>
    </EuiSelect>
  </EuiFormRow>
{{/let}}
<EuiSpacer @size="xl"/>
{{#if (eq this.exampleValue 'page not found')}}
  <EuiEmptyPrompt
    @title='Page not found'
    @layout='vertical'
    @body='The page you are looking for might have been removed or temporarily
        unavailable.'
    @actions={{array
      (component 'eui-button-title' title='Go Home')
      (component
        'eui-button-title' title='Go Back' iconType='arrowLeft' flush='left'
      )
    }}
  >
    <:icon>
      <EuiImage @size='fullWidth' @src={{this.illustration}} alt='' />
    </:icon>
  </EuiEmptyPrompt>
{{else if (eq this.exampleValue 'no permission')}}
  <EuiEmptyPrompt
    @iconType='lock'
    @color='subdued'
    @title='Contact your administrator for access'
    @body='To view cases in this space, you need additional privileges.'
  />
{{else if (eq this.exampleValue 'license upgrade')}}
  <EuiEmptyPrompt
    @iconType='logoKibana'
    @title='Do more with Kibana!'
    @layout='vertical'
    @hasBorder={{true}}
    @body='Start a free trial or upgrade your license to use anomaly detection.'
    @actions={{array
      (component 'eui-button-title' title='Update')
      (component 'eui-button-title' title='start a free trial' color='warning')
    }}
  >
    <:footer>
      <EuiTitle @size='xxs'>
        <h3>Want to learn more?</h3>
      </EuiTitle>
      <EuiLink href='#' target='_blank'>
        Read documentation
      </EuiLink>
    </:footer>
  </EuiEmptyPrompt>
{{else}}
  <EuiEmptyPrompt
    @title='Get started by adding your data'
    @layout='horizontal'
    @color='plain'
    @actions={{array
      (component 'eui-button-title' title='Add your data')
      (component
        'eui-button-title' title='Try sample data' color='warning'
      )
    }}
  >
    <:icon>
      <EuiImage @size='fullWidth' @src={{this.illustration}} alt='' />
    </:icon>
    <:body>
      <p>
        To start working with your data, use one of our many ingest options.
        Collect data from an app or service, or upload a file.
      </p>
      <p>
        If you&apos;re not ready to use your own data, add a sample data set.
      </p>
    </:body>
    <:footer>
      <EuiFlexGroup class="eui-textLeft">
        <EuiFlexItem @grow={{false}}>
          <EuiTitle @size="xxs">
            <h3>Want to learn more?</h3>
          </EuiTitle>
          <span>
            <EuiButtonEmpty
              href="#"
              @iconType="popout"
              @iconSide="right"
              @iconSize="s"
              @flush="both"
              @size="s"
            >
              Read documentation
            </EuiButtonEmpty>
          </span>
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiTitle @size="xxs">
            <h3>Pretty sure you have data?</h3>
          </EuiTitle>
          <span>
            <EuiButtonEmpty
              onClick={{this.onClick}}
              @iconType="refresh"
              @iconSide="right"
              @iconSize="s"
              @flush="both"
              @size="s"
            >
              Check for new data
            </EuiButtonEmpty>
          </span>
        </EuiFlexItem>
      </EuiFlexGroup>
    </:footer>
  </EuiEmptyPrompt>
{{/if}}
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoComponent extends Component {
  @tracked illustration = 'https://source.unsplash.com/64x64/?cat';
  @tracked exampleValue = 'page not found';

  @action
  onClick(e){
    e.preventDefault();
  }
}
```
