---
title: File picker
---
<EuiSpacer/>
<EuiPageHeader @pageTitle="File picker"/>

<EuiSpacer />

<EuiText>
  <p>
    <strong>EuiFilePicker</strong> is a stylized, but generic HTML <EuiCode @language="html">{{'<input type="file">'}}</EuiCode> tag.
    It supports drag and drop as well as on click style selection of files.
    The example below shows how to grab the files using the
    <EuiLink
      @href="https://developer.mozilla.org/en-US/docs/Web/API/FileList"
      @target="_blank"
    >
      FileList API
    </EuiLink>.
    Like other form elements, you can wrap it in a <strong>EuiFormRow</strong> to apply a label.
  </p>
</EuiText>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiFilePicker

A file input styled as a drop zone. Attributes such as `accept` go to the
`<input type="file">`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@id` | `string` | a random id | Id of the file input. |
| `@name` | `string` |  | `name` of the file input, for forms. |
| `@initialPromptText` | `Component \| string \| null` | "Select or drag and drop a file" | The content that appears in the dropzone if no file is attached. |
| `@onChange` | `(files: FileList \| null) => void` |  | Called with the selected files (a `FileList`) when they change, including when they are removed (an empty list). |
| `@compressed` | `boolean` |  | Reduces the size to a typical (compressed) input |
| `@display` | `EuiFilePickerDisplay` |  | Size or type of display; `default` for normal height, similar to other controls; `large` for taller size |
| `@fullWidth` | `boolean` |  | Stretches the picker to its container's width. |
| `@isInvalid` | `boolean` |  | Shows the invalid state and marks the input invalid for native form validation. |
| `@isLoading` | `boolean` |  | Shows a spinner. |
| `@disabled` | `boolean` |  | Disables the picker. |
| `@multiple` | `boolean` |  | Allows selecting several files. |
| `@ref` |  |  | Called with the component instance, e.g. to call its `removeFiles()` action and reset the picker. |

Deprecated: `@class` (Has no effect, use `class=`.).

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<input>`.

</EuiText>
<!-- api:end -->
