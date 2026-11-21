---
title: Attachments and upload progress
order: 39
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: attachments and upload progress"/>
<EuiSpacer @size="l" />

<EuiText>

An `attachment` field holds files. With `upload` it gets a file picker,
drop and paste of files, and a progress bar while your upload reports
one.

- **Attachment**: thumbnails (`thumbnailUrl`, or `url` for an `image/*`
  file), else a file icon and the name. The editor (the paperclip button,
  Enter or a double-click) lists the files with links that open them in a
  new tab and remove buttons, and has a file picker when the field has
  `upload`; each upload or removal is saved at once and the editor stays
  open. Files dropped on a cell, or pasted on one, are uploaded too: the
  cell shows as pending, then the new files are added to its value as it
  is then; a failed upload marks the cell "Upload failed". An `upload`
  that calls `onProgress(fraction)` (0 to 1 for the whole call, for
  example from `XMLHttpRequest`'s `upload.onprogress`) shows a 2 px bar
  along the cell's bottom edge and "Uploading… 40%" as its title, and the
  editor and the expanded record show the same value in a progress bar;
  calls after the upload settled or was aborted are ignored. One that
  never calls it shows the cell pending, as before. Only `http:`,
  `https:`, `blob:` and `data:image/` URLs are used as links or images.

## Related

- [All field types](/docs/sheet/docs/sheet/field-types)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
