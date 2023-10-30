import EuiOverlayMask from './eui-overlay-mask';
import focusTrapModifier from 'ember-focus-trap';
import { hash } from '@ember/helper';

<template>
  {{! @glint-nocheck: not typesafe yet }}
  <EuiOverlayMask>
    <div
      class="euiCodeBlock--fontLarge euiCodeBlock--paddingLarge euiCodeBlock-isFullScreen"
      {{focusTrapModifier
        isActive=true
        focusTrapOptions=(hash clickOutsideDeactivates=true)
      }}
      ...attributes
    >
      {{yield}}
    </div>
  </EuiOverlayMask>
</template>
