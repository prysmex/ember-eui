---
order: 5
---

# Comments in the expanded record

<EuiText>

`<:recordFooter as |record sheet|>` draws your own block below the
expanded record's fields, with a line above it: here a list of comments
and a box to add one. The sheet stores no comments: this demo keeps them
in its own state by record id, as your app would in its API. The arrows
in the record's header go to the next record, and the block follows it.
Typing in the box types there (it does not open a field's editor), and
Escape in it does not close the record; Escape on a box does.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { EuiButton, EuiFieldText, EuiFlexGroup, EuiFlexItem, EuiSpacer, EuiText, EuiTitle } from '@ember-eui/core/components';
import { EuiSheet, localRecords } from '@ember-eui/sheet';

const FIELDS = [
  { id: 'title', label: 'Request', required: true },
  { id: 'owner', label: 'Owner' },
  { id: 'hours', label: 'Hours', type: 'number', min: 0 },
  { id: 'done', label: 'Done', type: 'checkbox' },
];

const RECORDS = [
  { id: 'q1', title: 'New badge for the warehouse', owner: 'Ana', hours: 1, done: false },
  { id: 'q2', title: 'Replace the dock door sensor', owner: 'Luis', hours: 4, done: false },
  { id: 'q3', title: 'Monthly fire drill report', owner: 'Marta', hours: 2, done: true },
];

const COMMENTS = {
  q1: [{ author: 'Luis', text: 'Photo is in the shared folder.' }],
  q2: [
    { author: 'Ana', text: 'The supplier can come on Thursday.' },
    { author: 'Marta', text: 'Thursday works, the dock is closed after 4 pm.' },
  ],
};

const commentsOf = (comments, record) => comments[record.id] ?? [];
const countOf = (comments, record) => commentsOf(comments, record).length;

export default class SheetRecordFooter extends Component {
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId });

  @tracked comments = COMMENTS;
  @tracked draft = '';

  onInput = (event) => (this.draft = event.target.value);

  post = (record) => {
    const text = this.draft.trim();
    if (!text) return;
    const list = [...commentsOf(this.comments, record), { author: 'You', text }];
    this.comments = { ...this.comments, [record.id]: list };
    this.draft = '';
  };

  onKeyDown = (record, event) => {
    if (event.key === 'Enter') this.post(record);
  };

  <template>
    <EuiSheet
      @fields={{FIELDS}}
      @records={{this.store.records}}
      @getRecordId={{this.getId}}
      @onChange={{this.store.apply}}
      @height={{220}}
      @ariaLabel='Requests'
    >
      <:recordFooter as |record|>
        <EuiTitle @size='xxs'><h3>Comments ({{countOf this.comments record}})</h3></EuiTitle>
        <EuiSpacer @size='s' />
        <ul style='list-style: none; margin: 0; padding: 0;' data-test-subj='recordComments'>
          {{#each (commentsOf this.comments record) as |comment|}}
            <li>
              <EuiText @size='s'><p><strong>{{comment.author}}</strong>: {{comment.text}}</p></EuiText>
            </li>
          {{else}}
            <li><EuiText @size='s' @color='subdued'><p>No comments yet.</p></EuiText></li>
          {{/each}}
        </ul>
        <EuiSpacer @size='s' />
        <EuiFlexGroup @gutterSize='s' @responsive={{false}}>
          <EuiFlexItem>
            <EuiFieldText
              @value={{this.draft}}
              @placeholder='Add a comment'
              @compressed={{true}}
              aria-label='Add a comment'
              data-test-subj='recordCommentInput'
              {{on 'input' this.onInput}}
              {{on 'keydown' (fn this.onKeyDown record)}}
            />
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiButton @size='s' data-test-subj='recordCommentPost' {{on 'click' (fn this.post record)}}>Post</EuiButton>
          </EuiFlexItem>
        </EuiFlexGroup>
      </:recordFooter>
    </EuiSheet>
  </template>
}
```
