---
order: 1
---

# Basic Steps

```hbs template
<EuiSteps>
  <EuiStep
    @step={{1}}
    @title="Step 1"
  >
    You do this!
  </EuiStep>
  <EuiStep
    @step={{2}}
    @title="Step 2"
  >
    You do that!
  </EuiStep>
  <EuiStep
    @step={{3}}
    @title="Step 3"
    @status="danger"
  >
    You did what!?
  </EuiStep>
</EuiSteps>
```
