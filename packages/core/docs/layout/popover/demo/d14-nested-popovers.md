---
order: 14
---

# Nested popovers

<EuiText>

Popovers can be nested, but avoid popover inception (a popover triggering
another popover). Use an `EuiContextMenu` to swap the popover panel content
instead. This is only an Ember EUI example of how nested focus traps behave.

</EuiText>

```hbs template
<div>
  <EuiPopover
    @ownFocus={{true}}
    @isOpen={{this.popover}}
    @anchorPosition='downCenter'
    @closePopover={{set this 'popover' false}}
  >
    <:button>

      <EuiButton
        @iconType='arrowDown'
        @iconSide='right'
        {{on 'click' (set this 'popover' true)}}
      >
        Show Popover
      </EuiButton>
    </:button>
    <:content>

      <EuiPopover
        @ownFocus={{true}}
        @isOpen={{this.first}}
        @anchorPosition='downCenter'
        @closePopover={{set this 'first' false}}
      >
        <:button>

          <EuiButton
            @iconType='arrowDown'
            @iconSide='right'
            {{on 'click' (set this 'first' true)}}
          >
            > First nest
          </EuiButton>
        </:button>
        <:content>

          <EuiText @size='m' style='width: 300px;'>
            <EuiPopover
              @ownFocus={{true}}
              @isOpen={{this.second}}
              @anchorPosition='downCenter'
              @closePopover={{set this 'second' false}}
            >
              <:button>

                <EuiButton
                  @iconType='arrowDown'
                  @iconSide='right'
                  {{on 'click' (set this 'second' true)}}
                >
                  >> Second nest
                </EuiButton>
              </:button>
              <:content>

                <EuiText @size='m' style='width: 300px;'>
                  <EuiPopover
                    @ownFocus={{true}}
                    @isOpen={{this.third}}
                    @anchorPosition='downCenter'
                    @closePopover={{set this 'third' false}}
                  >
                    <:button>

                      <EuiButton
                        @iconType='arrowDown'
                        @iconSide='right'
                        {{on 'click' (set this 'third' true)}}
                      >
                        >> Third nest
                      </EuiButton>
                    </:button>
                    <:content>

                      <EuiText @size='m' style='width: 300px;'>
                        <p>
                          >> Third
                        </p>
                      </EuiText>
                    </:content>
                  </EuiPopover>
                  <p>
                    >> Second
                  </p>
                </EuiText>
              </:content>
            </EuiPopover>
            <p>
              > First
            </p>
          </EuiText>
        </:content>
      </EuiPopover>

      <EuiText @size='m' style='width: 300px;'>
        <p>
          Popover content that’s wider than the default width
        </p>
      </EuiText>
    </:content>
  </EuiPopover>
</div>
```

```javascript component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class PopoverDemo1 extends Component {
  @tracked popover = false;
  @tracked first = false;
  @tracked second = false;
  @tracked third = false;

  onClickOutside() {
    console.log('clicked outside');
  }
}
```
