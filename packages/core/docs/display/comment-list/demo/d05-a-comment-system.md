---
order: 5
---

# A comment system

<EuiText>

The below example uses a list of **EuiComment**s, an **EuiMarkdownEditor**, and an **EuiMarkdownFormat** to create a simple comment system.

- Each comment renders in a **EuiComment**.
- We use the **EuiMarkdownEditor** to post the comment's body. This means the content uses Markdown.
- When the new **EuiComment** is posted, we use the **EuiMarkdownFormat** to wrap the body and render the Markdown correctly.

When dealing with asynchronous events like posting a message we recommend setting the **EuiMarkdownEditor** to a `@readOnly` state and the "Add comment" **EuiButton** to an `@isLoading` state. This will ensure users understand that the content cannot be changed while the comment is being submitted.

</EuiText>
<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiAvatar, EuiBadge, EuiButton, EuiButtonIcon, EuiComment, EuiCommentList, EuiFlexGroup, EuiFlexItem, EuiMarkdownEditor, EuiMarkdownFormat, EuiSpacer, EuiToolTip } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

const replyMsg = `Thanks, Tiago for taking a look. :tada:

I also found something suspicious: [Update.exe](http://my-drive.elastic.co/suspicious-file).
`;

export default class CommentSystemDemo extends Component {
  @tracked editorValue = replyMsg;
  @tracked isLoading = false;
  @tracked comments = [
    {
      username: 'emma',
      fullname: 'Emma Watson',
      event: 'added a comment',
      timestamp: 'on 3rd March 2022',
      markdown: 'Phishing emails have been on the rise since February',
    },
    {
      username: 'emma',
      fullname: 'Emma Watson',
      tags: ['case', 'phishing', 'security'],
      timestamp: 'on 3rd March 2022',
      eventIcon: 'tag',
    },
    {
      username: 'system',
      fullname: 'System',
      timelineIcon: 'dot',
      avatarLabel: 'System',
      event: 'pushed a new incident',
      timestamp: 'on 4th March 2022',
      eventColor: 'danger',
    },
    {
      username: 'tiago',
      fullname: 'Tiago Pontes',
      event: 'added a comment',
      timestamp: 'on 4th March 2022',
      markdown:
        'Take a look at this [Office.exe](http://my-drive.elastic.co/suspicious-file)',
    },
    {
      username: 'emma',
      fullname: 'Emma Watson',
      inProgress: true,
      timestamp: 'on 4th March 2022',
    },
  ];

  get isEmpty() {
    return this.editorValue === '';
  }

  @action setEditorValue(value) {
    this.editorValue = value;
  }

  @action addComment() {
    this.isLoading = true;
    const date = new Intl.DateTimeFormat('en', { dateStyle: 'long' }).format(
      new Date()
    );
    const markdown = this.editorValue;

    setTimeout(() => {
      this.isLoading = false;
      this.editorValue = '';
      this.comments = [
        ...this.comments,
        {
          username: 'emma',
          fullname: 'Emma Watson',
          event: 'added a comment',
          timestamp: `on ${date}`,
          markdown,
        },
      ];
    }, 3000);
  }

  <template>
    <EuiCommentList aria-label="Comment system example">
      {{#each this.comments as |comment|}}
        {{#if comment.markdown}}
          <EuiComment
            @timelineAvatarAriaLabel={{comment.username}}
            @eventIcon={{comment.eventIcon}}
            @eventIconAriaLabel={{comment.eventIcon}}
            @eventColor={{comment.eventColor}}
          >
            <:timelineIcon>
              <EuiAvatar @name={{comment.username}} @iconType={{comment.timelineIcon}} @color={{if comment.timelineIcon "subdued"}} />
            </:timelineIcon>
            <:username>
              <EuiToolTip @position="top" @content={{comment.fullname}}>
                <strong>{{comment.username}}</strong>
              </EuiToolTip>
            </:username>
            <:event>
              {{#if comment.tags}}
                <EuiFlexGroup @responsive={{false}} @alignItems="center" @gutterSize="xs" @wrap={{true}}>
                  <EuiFlexItem @grow={{false}}>added tags</EuiFlexItem>
                  {{#each comment.tags as |tag|}}
                    <EuiFlexItem @grow={{false}}><EuiBadge>{{tag}}</EuiBadge></EuiFlexItem>
                  {{/each}}
                </EuiFlexGroup>
              {{else if comment.inProgress}}
                marked case as <EuiBadge @color="warning">In progress</EuiBadge>
              {{else}}
                {{comment.event}}
              {{/if}}
            </:event>
            <:timestamp>{{comment.timestamp}}</:timestamp>
            <:actions>
              <EuiToolTip @content="Custom action" @disableScreenReaderOutput={{true}}>
                <EuiButtonIcon aria-label="Custom action" @color="text" @iconType="copy" />
              </EuiToolTip>
            </:actions>
            <:body>
              <EuiMarkdownFormat @textSize="s" @value={{comment.markdown}} />
            </:body>
          </EuiComment>
        {{else}}
          <EuiComment
            @timelineAvatarAriaLabel={{comment.username}}
            @eventIcon={{comment.eventIcon}}
            @eventIconAriaLabel={{comment.eventIcon}}
            @eventColor={{comment.eventColor}}
          >
            <:timelineIcon>
              <EuiAvatar @name={{comment.username}} @iconType={{comment.timelineIcon}} @color={{if comment.timelineIcon "subdued"}} />
            </:timelineIcon>
            <:username>
              <EuiToolTip @position="top" @content={{comment.fullname}}>
                <strong>{{comment.username}}</strong>
              </EuiToolTip>
            </:username>
            <:event>
              {{#if comment.tags}}
                <EuiFlexGroup @responsive={{false}} @alignItems="center" @gutterSize="xs" @wrap={{true}}>
                  <EuiFlexItem @grow={{false}}>added tags</EuiFlexItem>
                  {{#each comment.tags as |tag|}}
                    <EuiFlexItem @grow={{false}}><EuiBadge>{{tag}}</EuiBadge></EuiFlexItem>
                  {{/each}}
                </EuiFlexGroup>
              {{else if comment.inProgress}}
                marked case as <EuiBadge @color="warning">In progress</EuiBadge>
              {{else}}
                {{comment.event}}
              {{/if}}
            </:event>
            <:timestamp>{{comment.timestamp}}</:timestamp>
          </EuiComment>
        {{/if}}
      {{/each}}
      <EuiComment>
        <:timelineIcon><EuiAvatar @name="juana" /></:timelineIcon>
        <:username>juana</:username>
        <:body>
          <EuiMarkdownEditor
            @ariaLabel="Markdown editor"
            @placeholder="Add a comment..."
            @value={{this.editorValue}}
            @onChange={{this.setEditorValue}}
            @readOnly={{this.isLoading}}
            @initialViewMode="editing"
            @formatTextSize="s"
          />
        </:body>
      </EuiComment>
    </EuiCommentList>
    <EuiSpacer />

    <EuiFlexGroup @justifyContent="flexEnd" @responsive={{false}}>
      <EuiFlexItem @grow={{false}}>
        <div>
          <EuiButton
            @isLoading={{this.isLoading}}
            @isDisabled={{this.isEmpty}}
            {{on "click" this.addComment}}
          >
            Add comment
          </EuiButton>
        </div>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```

