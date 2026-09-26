import EuiMarkdownFormat from '@ember-eui/core/components/eui-markdown-format';

import changelog from '../../../packages/core/CHANGELOG.md?raw';

<template><EuiMarkdownFormat @value={{changelog}} /></template>
