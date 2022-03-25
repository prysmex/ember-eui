---
order: 3
---

# Overflow height

<EuiText>
  <p>
    For long content, you can set an <EuiCode>overflowHeight</EuiCode> which will scroll if the text exceeds that height, and allows users to view the code in fullscreen mode.
  </p>
</EuiText>

```hbs template
<EuiPanel>
  <EuiCodeBlock
    @language='sql'
    @fontSize='m'
    @paddingSize='m'
		@overflowHeight={{150}}
  >
    {{this.sqlCode}}
  </EuiCodeBlock>
</EuiPanel>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiMarkdownEditor1 extends Component {
  sqlCode = `-- I'm an example of SQL
CREATE TABLE "topic" (
  "id" serial NOT NULL PRIMARY KEY,
  "forum_id" integer NOT NULL,
  "subject" varchar(255) NOT NULL
);
ALTER TABLE "topic"
ADD CONSTRAINT forum_id FOREIGN KEY ("forum_id")
REFERENCES "forum" ("id");

insert into "topic" ("forum_id", "subject")
values (2, 'D''artagnian');`;
}
```
