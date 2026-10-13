---
order: 4
---

# Vertical resizing

<EuiText>
  <p>
    Set <EuiCode>@direction="vertical"</EuiCode> on <strong>EuiResizableContainer</strong> to set a vertical orientation of the resizable panels.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiResizableContainer, EuiText } from '@ember-eui/core/components';

export default class ResizableDemo extends Component {
  paragraphs = [
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
      'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.',
      'Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem.'
  ];

  <template>
    <EuiResizableContainer style='height: 400px;' @direction='vertical' as |c|>
      <c.Panel @initialSize={{60}} @minSize='40%' tabindex='0'>
        <EuiText>
          <div>{{#each this.paragraphs as |paragraph|}}<p>{{paragraph}}</p>{{/each}}</div>
        </EuiText>
      </c.Panel>
      <c.Button @accountForScrollbars='both' />
      <c.Panel @initialSize={{40}} @minSize='10%' tabindex='0'>
        <EuiText>
          <div>{{#each this.paragraphs as |paragraph|}}<p>{{paragraph}}</p>{{/each}}</div>
        </EuiText>
      </c.Panel>
    </EuiResizableContainer>
  </template>
}
```
