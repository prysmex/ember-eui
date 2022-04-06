---
order: 2
---

# Complex steps

<EuiText>
<p>If you need to call out a set of substeps that are not lines of code, most likely a <EuiCode>&lt;ol/&gt;</EuiCode>, wrap the block in a <EuiCode>&lt;EuiSubSteps/&gt;</EuiCode>.</p>
</EuiText>

```hbs template
<EuiSteps>
  <EuiStep @step={{1}} @title='Step 1 has intro plus code snippet'>
    <EuiText>
      <p>Run this code snippet to install things.</p>
    </EuiText>
    <EuiSpacer />
    <EuiCodeBlock @language='bash'>npm install</EuiCodeBlock>
  </EuiStep>
  <EuiStep @step={{2}} @title='Step 2 has sub steps'>
    <EuiText>
      <p>
        In order to complete this step, do the following things{' '}
        <strong>in order</strong>.
      </p>
      <EuiSubSteps>
        <ol>
          <li>Do thing 1</li>
          <li>Do thing 2</li>
          <li>Do thing 3</li>
        </ol>
      </EuiSubSteps>
      <p>Here are some bullet point reminders.</p>
      <ul>
        <li>Reminder 1</li>
        <li>Reminder 2</li>
        <li>Reminder 3</li>
      </ul>
    </EuiText>
  </EuiStep>
  <EuiStep @step={{3}} @title='Step 3 has an intro and one line instruction'>
    <EuiText>
      <p>
        Now that you&apos;ve completed step 2, go find the{' '}
        <EuiCode>thing</EuiCode>.
      </p>
      <p>
        Go to
        <strong>Overview &gt;&gt; Endpoints</strong>
        note{' '}
        <strong>Elasticsearch</strong>
        as
        <EuiCode>&lt;thing&gt;</EuiCode>.
      </p>
    </EuiText>
  </EuiStep>
  <EuiStep @step={{4}} @title='The last step has two options'>
    <EuiText @size='s'>
      <h3>
        <strong>Option 1:</strong>
        If you have this type of instance
      </h3>
      <EuiSubSteps>
        <ol>
          <li>Do thing 1</li>
          <li>Do thing 2</li>
          <li>Do thing 3</li>
        </ol>
      </EuiSubSteps>
      <h3>
        <strong>Option 2:</strong>
        If you have the other type of instance
      </h3>
      <EuiSubSteps>
        <ol>
          <li>Do thing 1</li>
          <li>Do thing 2</li>
          <li>Do thing 3</li>
        </ol>
      </EuiSubSteps>
    </EuiText>
  </EuiStep>
</EuiSteps>
```
