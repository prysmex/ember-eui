const defaultTheme = require('tailwindcss/defaultTheme');

module.exports = {
  purge: [],
  theme: {
    extend: {
      colors: {
        gray: {
          ...defaultTheme.colors.gray,
          1000: '#12161f'
        }
      }
    }
  },
  variants: {},
  plugins: []
};
