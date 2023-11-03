import { modifier } from 'ember-modifier';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';

import EuiHeaderSection from './eui-header-section.gts';
import EuiHeaderSectionItem from './eui-header-section-item.gts';
import EuiHeaderBreadcrumbs from './eui-header-breadcrumbs.gts';

let euiHeaderFixedCounter = 0;

const fixedHeaderModifier = modifier(function fixedHeader(
  _,
  [position]: [string]
): void | (() => unknown) {
  if (position === 'fixed') {
    // Increment fixed header counter for each fixed header
    euiHeaderFixedCounter++;
    document.body.classList.add('euiBody--headerIsFixed');

    return () => {
      // Both decrement the fixed counter AND then check if there are none
      if (--euiHeaderFixedCounter === 0) {
        // If there are none, THEN remove class
        document.body.classList.remove('euiBody--headerIsFixed');
      }
    };
  }
});

<template>
  {{! @glint-nocheck: not typesafe yet }}
  <div
    {{fixedHeaderModifier @position}}
    class={{classNames
      componentName="EuiHeader"
      theme=(argOrDefault @theme "default")
      position=(argOrDefault @position "static")
    }}
    ...attributes
  >
    {{#if @sections}}
      {{#each @sections as |section|}}
        {{#each @section.items as |itemSection|}}
          <EuiHeaderSection>
            <EuiHeaderSectionItem @border={{section.borders}}>
              {{itemSection.text}}
            </EuiHeaderSectionItem>
          </EuiHeaderSection>
        {{/each}}
        {{#each @section.breadcrumbs as |breadcrumbs|}}
          <EuiHeaderBreadcrumbs @breadcrumbs={{breadcrumbs}} />
        {{/each}}
      {{/each}}
    {{else}}
      {{yield}}
    {{/if}}
  </div>
</template>
