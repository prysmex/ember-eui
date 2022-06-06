---
title: Code
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Code"/>

<EuiSpacer @size='l' />

<EuiCallOut>
  <:body>
    <strong>EuiCode</strong> and <strong>EuiCodeBlock</strong> are intended to render static lines or blocks of code in <strong>read-only</strong> contexts. If you need capabilities to edit, or want to print long code (e.g., printing JSON from an API), we recommend installing a version of Monaco. If you are building within the Kibana platform, you can use their CodeEditor.
  </:body>
</EuiCallOut>

<EuiText>
<p>
  The <strong>EuiCode</strong> and <strong>EuiCodeBlock</strong> components support <a href="https://prismjs.com/#supported-languages" target="_blank">all language syntaxes</a> supported by the <EuiCode>prism</EuiCode> <a href="https://prismjs.com" target="_blank">library</a>. The language prop can also be omitted to simply render formatted but unhighlighted code.
</p>
<p>
  JSX code (often React) has distinct language syntaxes from the base JavaScript and TypeScript languages. For these instances, use <EuiCode @language="jsx">language="jsx"</EuiCode> or <EuiCode @language="tsx">language="tsx"</EuiCode>.
</p>
</EuiText>

<EuiHorizontalRule />
<EuiSpacer/>
