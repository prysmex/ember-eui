---
order: 2
---

# Less content, more actions

<EuiText>
 You can remove parts of the prompt to simplify it. You can also provide an array of multiple actions. Be sure to list primary actions first and secondary actions as empty buttons.
</EuiText>

```hbs template
<EuiEmptyPrompt
  @title="Upgrade your license to use Machine Learning"
  @actions={{array (component "eui-button-title" title="Add a case") (component "eui-button-title" title="Start a trial")}}
/>
```
