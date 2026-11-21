---
title: Email, URL, phone
order: 36
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: email, URL and phone"/>
<EuiSpacer @size="l" />

<EuiText>

Strings shown as links: a click on the text opens the link, a click
beside it selects the cell. Validation checks the format of each.

- **URL, email, phone**: link-styled text. A click on the text opens the
  link in a new tab (`mailto:` and `tel:` for email and phone); a click
  beside it selects the cell as usual. The row menu has "Open link", and
  the expanded record a button next to the box. Only `http:`, `https:`,
  `mailto:` and `tel:` links are opened, so a `javascript:` value opens
  nothing (and fails validation).

A `url` is a web address when its scheme is `http` or `https` (`https://`
is added when it has none) and its host, as written, is `localhost`, an
IPv6 address in brackets, an IPv4 address of four numbers (`192.168.0.1`),
or a name of two or more parts whose last part has a letter
(`example.com`, `ñandú.mx`): `19/11/2026`, `12` and `1.2.3` are not.

## Related

- [All field types](/docs/sheet/docs/sheet/field-types)
- [Field rules](/docs/sheet/docs/sheet/validation/field-rules)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
