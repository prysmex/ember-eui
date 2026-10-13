---
order: 2
---

# Text can come in various sizes

<EuiText>

Using the `@size` argument on `EuiText` you can scale text relative to the default (`s`, ~14px, aligned with the unstyled body/html base). This demo compares the scaling for all sizes. The goal is that every line-height lands on the `4px` baseline grid.

</EuiText>

```hbs template
<style>
  .docsTextLines {
    background-image: linear-gradient(rgba(0, 119, 204, 0.3) 1px, transparent 1px);
    background-size: 100% 4px;
    background-position-y: -1px;
  }
  .docsTextLines > * {
    background-color: rgba(255, 220, 0, 0.18);
  }
</style>

<EuiFlexGroup>
  <EuiFlexItem>
    <EuiButtonGroup
      @isFullWidth={{true}}
      @legend='First text size'
      @name='first'
      @idSelected={{this.firstIdSelected}}
      @onChange={{this.setFirst}}
      @options={{this.firstOptions}}
    />
    <EuiHorizontalRule />
    <EuiText class='docsTextLines' @size={{this.firstSize}}>
      <h1>This is Heading One</h1>
      <p>
        Far out in the uncharted backwaters of the unfashionable end of the
        western spiral arm of the Galaxy lies a small unregarded yellow sun.
      </p>
      <pre><code>const completelyUnexpected = &quot;the audacity!&quot;;</code></pre>
      <h2>This is Heading Two</h2>
      <p>
        Orbiting this at a distance of roughly ninety-two million miles is an
        utterly insignificant little blue green planet whose ape- descended life
        forms are so amazingly primitive that they still think digital watches
        are a pretty neat idea.
      </p>
      <ul>
        <li>List item one</li>
        <li>List item two</li>
        <li>Dolphins</li>
      </ul>
      <p>
        This planet has - or rather had - a problem, which was this: most of the
        people living on it were unhappy for pretty much of the time. Many
        solutions were suggested for this problem, but most of these were
        largely concerned with the movements of small green pieces of paper,
        which is odd because on the whole it was not the small green pieces of
        paper that were unhappy.
      </p>
      <h3>This is Heading Three</h3>
      <ol>
        <li>Number one</li>
        <li>Number two</li>
        <li>Dolphins again</li>
      </ol>
      <p>
        But the dog wasn&rsquo;t lazy, it was just practicing mindfulness, so it
        had a greater sense of life-satisfaction than that fox with all its
        silly jumping.
      </p>
      <p>
        And from the fox&rsquo;s perspective, life was full of hoops to jump
        <em>through</em>, low-hanging fruit to jump <em>for</em>, and dead car
        batteries to jump-<em>start</em>.
      </p>
      <h4>This is Heading Four</h4>
      <p>
        So it thought the dog was making a poor life choice by focusing so much
        on mindfulness. What if its car broke down?
      </p>
      <h5>This is Heading Five</h5>
      <p>
        <small>
          So it thought the dog was making a poor life choice by focusing so
          much on mindfulness. What if its car broke down?
        </small>
      </p>
      <h6>This is Heading Six</h6>
    </EuiText>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiButtonGroup
      @isFullWidth={{true}}
      @legend='Second text size'
      @name='second'
      @idSelected={{this.secondIdSelected}}
      @onChange={{this.setSecond}}
      @options={{this.secondOptions}}
    />
    <EuiHorizontalRule />
    <EuiText class='docsTextLines' @size={{this.secondSize}}>
      <h1>This is Heading One</h1>
      <p>
        Far out in the uncharted backwaters of the unfashionable end of the
        western spiral arm of the Galaxy lies a small unregarded yellow sun.
      </p>
      <pre><code>const completelyUnexpected = &quot;the audacity!&quot;;</code></pre>
      <h2>This is Heading Two</h2>
      <p>
        Orbiting this at a distance of roughly ninety-two million miles is an
        utterly insignificant little blue green planet whose ape- descended life
        forms are so amazingly primitive that they still think digital watches
        are a pretty neat idea.
      </p>
      <ul>
        <li>List item one</li>
        <li>List item two</li>
        <li>Dolphins</li>
      </ul>
      <p>
        This planet has - or rather had - a problem, which was this: most of the
        people living on it were unhappy for pretty much of the time. Many
        solutions were suggested for this problem, but most of these were
        largely concerned with the movements of small green pieces of paper,
        which is odd because on the whole it was not the small green pieces of
        paper that were unhappy.
      </p>
      <h3>This is Heading Three</h3>
      <ol>
        <li>Number one</li>
        <li>Number two</li>
        <li>Dolphins again</li>
      </ol>
      <p>
        But the dog wasn&rsquo;t lazy, it was just practicing mindfulness, so it
        had a greater sense of life-satisfaction than that fox with all its
        silly jumping.
      </p>
      <p>
        And from the fox&rsquo;s perspective, life was full of hoops to jump
        <em>through</em>, low-hanging fruit to jump <em>for</em>, and dead car
        batteries to jump-<em>start</em>.
      </p>
      <h4>This is Heading Four</h4>
      <p>
        So it thought the dog was making a poor life choice by focusing so much
        on mindfulness. What if its car broke down?
      </p>
      <h5>This is Heading Five</h5>
      <p>
        <small>
          So it thought the dog was making a poor life choice by focusing so
          much on mindfulness. What if its car broke down?
        </small>
      </p>
      <h6>This is Heading Six</h6>
    </EuiText>
  </EuiFlexItem>
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

const sizes = [
  { value: 'xs', label: 'Extra small' },
  { value: 's', label: 'Small' },
  { value: 'm', label: 'Medium' },
];

export default class extends Component {
  firstOptions = sizes.map((o) => ({ id: `first${o.value}`, ...o }));
  secondOptions = sizes.map((o) => ({ id: `second${o.value}`, ...o }));

  @tracked firstIdSelected = 'firsts';
  @tracked secondIdSelected = 'secondxs';
  @tracked firstSize = 's';
  @tracked secondSize = 'xs';

  @action
  setFirst(id) {
    this.firstIdSelected = id;
    this.firstSize = this.firstOptions.find((o) => o.id === id).value;
  }

  @action
  setSecond(id) {
    this.secondIdSelected = id;
    this.secondSize = this.secondOptions.find((o) => o.id === id).value;
  }
}
```
