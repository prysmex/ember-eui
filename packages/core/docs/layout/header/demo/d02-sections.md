---
order: 2
---

# Sections

<EuiText>

Upstream builds a header from an array passed to `sections`, where each item has `items` (children wrapped in an `EuiHeaderSectionItem`) and/or `breadcrumbs`. Each entry is wrapped in an `EuiHeaderSection`.

In Ember EUI you normally compose the header from blocks: a left and a right `EuiHeaderSection` holding `EuiHeaderSectionItem`s. `@grow={{true}}` on a section lets it take the remaining width, e.g. for a search bar.

This example has been simplified to showcase just the buttons within sections. See the main example for all the menu items.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import {
  EuiAvatar,
  EuiHeader,
  EuiHeaderBreadcrumbs,
  EuiHeaderLogo,
  EuiHeaderSection,
  EuiHeaderSectionItem,
  EuiHeaderSectionItemButton,
  EuiIcon,
} from '@ember-eui/core/components';

export default class HeaderSectionsDemo extends Component {
  breadcrumbs = [
    { text: 'Management', href: '#', onClick: this.preventDefault },
    { text: 'Users', href: '#', onClick: this.preventDefault },
    { text: 'Create' },
  ];

  @action
  preventDefault(event) {
    event.preventDefault();
  }

  <template>
    <EuiHeader>
      <EuiHeaderSection>
        <EuiHeaderSectionItem>
          <EuiHeaderLogo @iconType="logoElastic" @href="#" aria-label="Go to home page" {{on "click" this.preventDefault}} />
        </EuiHeaderSectionItem>
        <EuiHeaderSectionItem>
          <EuiHeaderSectionItemButton aria-label="Spaces menu">
            <EuiAvatar @type="space" @name="Sales Team" @size="s" />
          </EuiHeaderSectionItemButton>
        </EuiHeaderSectionItem>
      </EuiHeaderSection>

      <EuiHeaderBreadcrumbs
        aria-label="Header sections breadcrumbs"
        @breadcrumbs={{this.breadcrumbs}}
      />

      <EuiHeaderSection @side="right">
        <EuiHeaderSectionItem>
          <EuiHeaderSectionItemButton @disabled={{true}} aria-label="Sitewide search">
            <EuiIcon @type="magnify" @size="m" />
          </EuiHeaderSectionItemButton>
        </EuiHeaderSectionItem>
        <EuiHeaderSectionItem>
          <EuiHeaderSectionItemButton @disabled={{true}} aria-label="Account menu">
            <EuiAvatar @isDisabled={{true}} @name="John Username" @size="s" />
          </EuiHeaderSectionItemButton>
        </EuiHeaderSectionItem>
        <EuiHeaderSectionItem>
          <EuiHeaderSectionItemButton
            @disabled={{true}}
            aria-label="Apps menu with 1 new app"
            @notification="1"
          >
            <EuiIcon @type="apps" @size="m" />
          </EuiHeaderSectionItemButton>
        </EuiHeaderSectionItem>
      </EuiHeaderSection>
    </EuiHeader>
  </template>
}
```

## The `@sections` argument

<EuiText>

`EuiHeader` also has a `@sections` argument that builds the header from data, but unlike upstream its `items` can only be plain text (`{ text }`), not arbitrary nodes. Passing `@sections` ignores the block.

</EuiText>

```gjs component
import { EuiHeader } from '@ember-eui/core/components';

const sections = [
  { items: [{ text: 'Home' }, { text: 'Dashboards' }] },
  { items: [{ text: 'Help' }] },
];

<template>
  <EuiHeader @sections={{sections}} />
</template>
```
