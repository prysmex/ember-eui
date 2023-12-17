export const tooltipPlugin = {
  name: 'tooltipPlugin',
  button: {
    label: 'Tooltip',
    iconType: 'editorComment'
  },
  formatting: {
    prefix: '!{tooltip[',
    suffix: ']()}',
    trimFirst: true
  },
  helpText: `
  \`\`\`md
  !{tooltip[anchor text](helpful description)}
  \`\`\`
  `
};
