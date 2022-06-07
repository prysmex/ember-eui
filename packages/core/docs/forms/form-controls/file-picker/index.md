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
