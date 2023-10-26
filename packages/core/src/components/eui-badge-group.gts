import argOrDefault from '../helpers/arg-or-default';
import { hash } from '@ember/helper';
import classNames from '../helpers/class-names';

const BadgeGroupItem = <template>
  <span class="euiBadgeGroup__item">
    {{yield}}
  </span>
</template>;

<template>
  <div
    class={{classNames
      componentName="EuiBadgeGroup"
      gutterSize=(argOrDefault @gutterSize "xs")
    }}
    ...attributes
  >
    {{yield (hash item=BadgeGroupItem)}}
  </div>
</template>
