---
title: CallOut
---

<EuiPageHeader @pageTitle="CallOut"/>

<EuiSpacer />
  <EuiText>
  <p>
   <strong>EuiCallOut</strong> contains a message directly related to content on the page. This includes general information, success, warning, and error messages.</p><p><strong>Keep these guidelines in mind:</strong></p><ul><li>Minimize the number of callouts per page.</li><li>Stack callouts in the order in which they require users' attention: error, warning, info, and then success.</li><li>Offer only one action per callout and ensure it's an action users can perform quickly.</li><li>If the callout has a permanent spot in the UI, but needs to be less obstructive, set the <EuiCode @language="text">size</EuiCode> property to <EuiCode @language=="text">s</EuiCode> (small).</li><li>Use an <EuiCode @language="text">icon</EuiCode> prop if it adds context.</li></ul>
</EuiText>

<EuiHorizontalRule />
