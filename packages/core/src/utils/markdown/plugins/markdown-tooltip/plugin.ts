export const tooltipPlugin = {
  name: 'tooltipPlugin',
  button: {
    label: 'Tooltip',
    iconType: 'comment'
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
