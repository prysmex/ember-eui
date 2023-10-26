import { guidFor } from '@ember/object/internals';
import EuiFlexGroup from './eui-flex-group';
import EuiFlexItem from './eui-flex-item';

<template>
  {{#let (guidFor) as |ariaId|}}
    <article
      aria-labelledby="{{ariaId}}-title"
      class="euiHeaderAlert"
      ...attributes
    >
      <EuiFlexGroup @justifyContent="spaceBetween">
        <EuiFlexItem>
          <div class="euiHeaderAlert__date">{{yield to="date"}}</div>
        </EuiFlexItem>
        {{#if (has-block "badge")}}
          <EuiFlexItem @grow={{false}}>{{yield to="badge"}}</EuiFlexItem>
        {{/if}}

      </EuiFlexGroup>

      <h3 id="{{ariaId}}-title" class="euiHeaderAlert__title">
        {{yield to="title"}}
      </h3>
      <div class="euiHeaderAlert__text">{{yield to="text"}}</div>
      {{#if (has-block "action")}}
        <div class="euiHeaderAlert__action euiLink">{{yield to="action"}}</div>
      {{/if}}
    </article>
  {{/let}}
</template>