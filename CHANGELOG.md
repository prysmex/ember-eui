# Ember Eui Changelog

### Master


### 0.0.16
🏠 Internal
- Fixes netlify redirects

### 0.0.16
🚀 Enhancements
- EuiBadge
- Use empty icon svg as placeholder while downloading the desired one 
- Adds @victor-aguilars to contributors

🏠 Internal
- Update ember-svg-jar fork

🐛 Bug / Fixes
- Add accordion to demo

### 0.0.15
🚀 Enhancements
- EuiSideNav
- EuiAvatar

### 0.0.14
🚀 Enhancements
- EuiCallout

### 0.0.13
🚀 Enhancements
- Updates ember-svg-jar dependency and loads all svgs on demand.

### 0.0.12

🏠 Internal
- Let apps define svgPath in environment.js
  ```ts
    `ember-eui`: {
      svgPath: 'svg/assets'
    }
  ```
  This assumes that you setup ember-svg-jar with the prefix `svg/` (which is the default one)

🐛 Bug / Fixes
- Fixed EuiIcon camelCase svgs

### 0.0.11

🚀 Enhancements
- EuiIcon
- EuiAccordion
- EuiPage
- EuiTitle
- EuiText
- EuiImage
- EuiSpinner
- EuiOverlayMask

🏠 Internal
- Update class-names helper to always concat

### 0.0.7

Update license and add a short description to the readme

### 0.0.6

Support importing only compiled css

```ts
  "ember-eui": {
        "theme": "amsterdam_dark",
        "useCompiledCss": true
    }
```

### 0.0.5

Add ember-cli-sass and app.scss blueprint

### 0.0.4

Expose scss files so you can now use eui sass variables

### 0.0.3

Delete blueprint for now

### 0.0.2

Fix changelog location

### 0.0.1

Support importing custom themes

```ts
  "ember-eui": {
        "theme": "light"
    }

```
