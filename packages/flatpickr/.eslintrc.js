const { configs } = require('@nullvoxpopuli/eslint-configs');

const config = configs.ember();

module.exports = {
  ...config,
  overrides: [
    ...config.overrides,
    {
      files: ['**/*.ts', '**/*.gts'],
      rules: {
        /**
         * This one is incorrectly parsed for now, because
         * the rule doesn't understand decorators
         */
        '@typescript-eslint/no-unused-vars': 'off',
        /**
         * any can be useful
         */
        '@typescript-eslint/no-explicit-any': 'off',
        /**
         * there is heavy use of `object` in this library
         */
        '@typescript-eslint/ban-types': 'off',
        /**
         * The following types do are not defined by the definitely typed packages
         * - @glimmer/tracking/primitives/cache
         *   - getValue
         * - @ember/helper
         *   - invokeHelper
         *   - capabilities
         *   - setHelperManager
         */
        '@typescript-eslint/ban-ts-comment': 'off',
        '@typescript-eslint/no-empty-interface': 'off',
        '@typescript-eslint/no-non-null-assertion': 'off',
        'ember/no-empty-glimmer-component-classes': 'off',
        'prefer-const': 'off',
        '@typescript-eslint/no-inferrable-types': 'off',
        '@typescript-eslint/explicit-function-return-type': 'off',
        '@typescript-eslint/explicit-module-boundary-types': 'off',
        '@typescript-eslint/restrict-plus-operands': 'off',
        'no-prototype-builtins': 'off'
      }
    },
    // node files
    {
      files: [
        '.eslintrc.js',
        '.prettierrc.js',
        '.template-lintrc.js',
        'testem.js',
        'config/**/*.js',
        'packages/*/.ember-cli.js',
        'packages/*/ember-cli-build.js',
        'packages/*/index.js',
        'packages/*/adddon-main.js',
        'packages/*/testem.js',
        'packages/*/blueprints/*/index.js',
        'packages/*/config/**/*.js',
        'packages/*/tests/dummy/config/**/*.js',
        'site/ember-cli-build.js',
        'site/testem.js',
        'site/config/**/*.js',
        'site/tests/dummy/config/**/*.js',
        'site/**/tailwind.config.js',
        'site/.docfy-config.js'
      ],
      extends: ['@underline/eslint-config-node'],
      rules: {}
    }
  ]
};
