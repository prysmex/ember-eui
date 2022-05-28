```hbs template
<EuiFlexGroup>
  <EuiFlexItem>
    <EuiListGroup
      @bordered={{this.bordered}}
      @flush={{this.flush}}
      @maxWidth={{this.maxWidth}}
      @gutterSize={{this.gutterSize}}
    >
      <EuiListGroupItem
        @href={{if this.useHref '/'}}
        @onClick={{if this.useOnClick this.onClick}}
        @isActive={{this.isActive}}
        @isDisabled={{this.isDisabled}}
        @wrapText={{this.wrapText}}
        @size={{this.size}}
        @color={{this.color}}
        @iconType={{if this.useIconType 'bell'}}
      >
        {{#if this.wrapText}}
          First item with very long text with Lorem ipsum dolor sit amet,
          consectetur adipiscing elit
        {{else}}
          First item
        {{/if}}
      </EuiListGroupItem>
      <EuiListGroupItem>
        Second item
      </EuiListGroupItem>
      <EuiListGroupItem>
        Third item
      </EuiListGroupItem>
      <EuiListGroupItem>
        Fourth item
      </EuiListGroupItem>
    </EuiListGroup>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiFlexGroup>
      <EuiFlexItem>
        <EuiTitle @size='xs'>Group</EuiTitle>
        <div>
          <Input @type='checkbox' @checked={{this.bordered}} name='bordered' />
          <label for='bordered'>Bordered</label>
        </div>
        <div>
          <Input @type='checkbox' @checked={{this.flush}} name='flushed' />
          <label for='flushed'>Flush</label>
        </div>
        <div>
          <EuiText>Gutter size</EuiText>
          <EuiBadge
            @color={{if (eq this.gutterSize 'none') 'primary'}}
            @onClick={{set this 'gutterSize' 'none'}}
          >none</EuiBadge>
          <EuiBadge
            @color={{if (eq this.gutterSize 's') 'primary'}}
            @onClick={{set this 'gutterSize' 's'}}
          >small</EuiBadge>
          <EuiBadge
            @color={{if (eq this.gutterSize 'm') 'primary'}}
            @onClick={{set this 'gutterSize' 'm'}}
          >medium</EuiBadge>
        </div>
        <div>
          <EuiText>Max width</EuiText>
          <EuiBadge
            @color={{if (eq this.maxWidthType 'bool') 'primary'}}
            @onClick={{pipe
              (set this 'maxWidthType' 'bool')
              (set this 'maxWidth' false)
            }}
          >
            boolean
          </EuiBadge>
          <EuiBadge
            @color={{if (eq this.maxWidthType 'num') 'primary'}}
            @onClick={{pipe
              (set this 'maxWidthType' 'num')
              (set this 'maxWidth' 400)
            }}
          >
            number
          </EuiBadge>
          <EuiBadge
            @color={{if (eq this.maxWidthType 'string') 'primary'}}
            @onClick={{pipe
              (set this 'maxWidthType' 'string')
              (set this 'maxWidth' '')
            }}
          >
            string
          </EuiBadge>
        </div>
        <div>
          {{#if (eq this.maxWidthType 'bool')}}
            <Input
              @type='checkbox'
              @checked={{this.maxWidth}}
              name='maxwidth'
            />
            <label for='maxwidth'>{{this.maxWidth}}</label>
          {{else if (eq this.maxWidthType 'num')}}
            <label for='maxwidth'>Enter value</label>
            <input
              type='number'
              value={{this.maxWidth}}
              {{on 'input' this.parseToNum}}
              name='maxwidth'
            />
          {{else}}
            <label for='maxwidth'>Enter value</label>
            <Input @value={{this.maxWidth}} name='maxwidth' />
          {{/if}}
        </div>
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiTitle @size='xs'>First Item</EuiTitle>
        <div>
          <Input @type='checkbox' @checked={{this.useHref}} name='useHref' />
          <label for='useHref'>use Href</label>
        </div>
        <div>
          <Input
            @type='checkbox'
            @checked={{this.useOnClick}}
            name='useOnClick'
          />
          <label for='useOnClick'>use onClick</label>
        </div>
        <div>
          <Input @type='checkbox' @checked={{this.isActive}} name='isActive' />
          <label for='isActive'>isActive</label>
        </div>
        <div>
          <Input
            @type='checkbox'
            @checked={{this.isDisabled}}
            name='isDisabled'
          />
          <label for='isDisabled'>isDisabled</label>
        </div>
        <div>
          <Input @type='checkbox' @checked={{this.wrapText}} name='wrapText' />
          <label for='wrapText'>wrapText</label>
        </div>
        <div>
          <EuiText>Size</EuiText>
          <EuiBadge
            @color={{if (eq this.size 'xs') 'primary'}}
            @onClick={{set this 'size' 'xs'}}
          >extra small</EuiBadge>
          <EuiBadge
            @color={{if (eq this.size 's') 'primary'}}
            @onClick={{set this 'size' 's'}}
          >small</EuiBadge>
          <EuiBadge
            @color={{if (eq this.size 'm') 'primary'}}
            @onClick={{set this 'size' 'm'}}
          >medium</EuiBadge>
          <EuiBadge
            @color={{if (eq this.size 'l') 'primary'}}
            @onClick={{set this 'size' 'l'}}
          >large</EuiBadge>
        </div>
        <div>
          <EuiText>Color</EuiText>
          <EuiBadge
            @color={{if (eq this.color 'inherit') 'primary'}}
            @onClick={{set this 'color' 'inherit'}}
          >inherit</EuiBadge>
          <EuiBadge
            @color={{if (eq this.color 'text') 'primary'}}
            @onClick={{set this 'color' 'text'}}
          >text</EuiBadge>
          <EuiBadge
            @color={{if (eq this.color 'subdued') 'primary'}}
            @onClick={{set this 'color' 'subdued'}}
          >subdued</EuiBadge>
          <EuiBadge
            @color={{if (eq this.color 'ghost') 'primary'}}
            @onClick={{set this 'color' 'ghost'}}
          >ghost</EuiBadge>
          <EuiBadge
            @color={{if (eq this.color 'primary') 'primary'}}
            @onClick={{set this 'color' 'primary'}}
          >primary</EuiBadge>
        </div>
        <div>
          <Input
            @type='checkbox'
            @checked={{this.useIconType}}
            name='useIconType'
          />
          <label for='useIconType'>use iconType</label>
        </div>
      </EuiFlexItem>
    </EuiFlexGroup>
  </EuiFlexItem>
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoListGroupComponent extends Component {
  // Group config
  @tracked bordered = false;
  @tracked flush = false;
  @tracked gutterSize = 's';
  @tracked maxWidthType = 'bool';
  @tracked maxWidth = false;

  @action
  parseToNum(event) {
    this.maxWidth = Number(event.target.value);
  }

  @action
  onClick(event) {
    console.log('Item clicked');
  }

  //Item config
  @tracked useHref = false;
  @tracked useOnClick = false;
  @tracked isActive = false;
  @tracked isDisabled = false;
  @tracked wrapText = false;
  @tracked size = 'm';
  @tracked color = 'inherit';
  @tracked useIconType = false;
}
```
