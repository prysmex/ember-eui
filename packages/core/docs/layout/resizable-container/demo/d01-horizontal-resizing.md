---
order: 1
---

# Horizontal resizing

<EuiText>
  <p>
    This component is handy for various resizable containers. <strong>EuiResizableContainer</strong> yields <strong>Panel</strong> and <strong>Button</strong> components for layout (and a <EuiCode>togglePanel</EuiCode> action for custom handling of collapse functionality in your app). Wrap parts of your content with the <strong>Panel</strong> component and put the <strong>Button</strong> component between.
  </p>
  <p>
    Simple resizable container with two panels and a resizer between. This is the most common case you'll need in your app. Just drag <strong>the resizer</strong> button between two panels to increase/decrease panel size. You could also use arrow keys <strong>←</strong>|<strong>→</strong> on <strong>the focused resizer</strong> button to change panel size.
  </p>
  <ul>
    <li>add <EuiCode>@initialSize</EuiCode> in percents to each panel to specify the initial size of it. Other calculations will be encapsulated, you don't worry about it.</li>
    <li>add <EuiCode>@scrollable=&#123;&#123;false&#125;&#125;</EuiCode> to a panel to eliminate overflow scrolling</li>
  </ul>
  <p>
    <strong>Accessibility recommendation:</strong> consider adding <EuiCode>tabindex="0"</EuiCode> to the panels (or the <strong>EuiResizableContainer</strong>) if it is a fixed height or has a lot of content. This ensures keyboard users can set focus on the container and scroll to the bottom using arrow keys.
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
    <EuiResizableContainer style='height: 200px;' as |c|>
      <c.Panel @initialSize={{50}} @minSize='30%' tabindex='0'>
        <EuiText>
          <div>{{#each this.paragraphs as |paragraph|}}<p>{{paragraph}}</p>{{/each}}</div>
          <a href=''>Hello world</a>
        </EuiText>
      </c.Panel>
      <c.Button @accountForScrollbars='before' />
      <c.Panel @initialSize={{50}} @minSize='200px' tabindex='0'>
        <EuiText>{{#each this.paragraphs as |paragraph|}}<p>{{paragraph}}</p>{{/each}}</EuiText>
      </c.Panel>
    </EuiResizableContainer>
  </template>
}
```
