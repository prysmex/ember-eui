module.exports = {
  root: true,
  extends: [
    '@underline/eslint-config-ember-typescript',

    'plugin:ember/recommended'
  ],
  rules: {
    // 'prettier/prettier': ['error', {}, { usePrettierrc: false }],
    '@typescript-eslint/no-empty-interface': 'off',
    '@typescript-eslint/no-non-null-assertion': 'off',
    'ember/no-empty-glimmer-component-classes': 'off',
    'prefer-const': 'off',
    '@typescript-eslint/no-inferrable-types': 'off',
    '@typescript-eslint/explicit-function-return-type': 'off',
    '@typescript-eslint/no-explicit-any': 'off',
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    '@typescript-eslint/restrict-plus-operands': 'off',
    'no-prototype-builtins': 'off'
  },
  overrides: [
    {
      files: ['packages/**/tests/**/*.ts', '**/*.gts'],
      rules: {
        '@typescript-eslint/explicit-function-return-type': 'off',
        '@typescript-eslint/no-non-null-assertion': 'off'
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
