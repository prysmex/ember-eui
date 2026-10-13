---
order: 10
---

# Resizable button indicator

<EuiText>
  <p>
    By default, the resizable <strong>Button</strong> shows a grab handle indicator as a UI hint. For use cases where the resize behavior is "nice to have" but not a primary UX focus, or where there are many other busy UI elements on the page, you can set <EuiCode>@indicator="border"</EuiCode> to display a subdued border element instead, which only provides resize affordance on hover or focus.
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
    <EuiResizableContainer style='height: 300px;' as |c|>
      <c.Panel @initialSize={{50}} @minSize='50px' tabindex='0'>
        <EuiText>{{#each this.paragraphs as |paragraph|}}<p>{{paragraph}}</p>{{/each}}</EuiText>
      </c.Panel>
      <c.Button @indicator='border' @accountForScrollbars='before' />
      <c.Panel @initialSize={{50}} @minSize='50px' @paddingSize='none' tabindex='0'>
        <EuiResizableContainer
          @direction='vertical'
          style='height: 100%; overflow: hidden;'
          as |nested|
        >
          <nested.Panel @initialSize={{50}} @minSize='50px' tabindex='0'>
            <EuiText style='width: 110%;'>{{#each this.paragraphs as |paragraph|}}<p>{{paragraph}}</p>{{/each}}</EuiText>
          </nested.Panel>
          <nested.Button @indicator='border' @accountForScrollbars='both' />
          <nested.Panel @initialSize={{50}} @minSize='50px' tabindex='0'>
            <EuiText>{{#each this.paragraphs as |paragraph|}}<p>{{paragraph}}</p>{{/each}}</EuiText>
          </nested.Panel>
        </EuiResizableContainer>
      </c.Panel>
    </EuiResizableContainer>
  </template>
}
```
