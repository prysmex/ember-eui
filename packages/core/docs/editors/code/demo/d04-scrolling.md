---
order: 4
---

# Scrolling

<EuiText>
  <p>
    For long content, you can set an <EuiCode>@overflowHeight</EuiCode> which will scroll if the text exceeds that height, and allows users to view the code in fullscreen mode.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiCodeBlock } from '@ember-eui/core/components';

export default class Scrolling extends Component {
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

  <template>
    <EuiCodeBlock
      @language='sql'
      @overflowHeight={{150}}
    >
      {{this.sqlCode}}
    </EuiCodeBlock>
  </template>
}
```

