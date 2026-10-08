import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { EuiButtonEmpty } from '@ember-eui/core/components';

let manifestPromise;

export default class DemoPlayground extends Component {
  @tracked project;
  @tracked error;

  constructor(owner, args) {
    super(owner, args);
    // One shared, separate bundle; only pages containing demos request it.
    manifestPromise ??= import('../demo-playgrounds.json').then(
      (module) => module.default,
    );
    manifestPromise
      .then((manifest) => {
        if (this.isDestroying || this.isDestroyed) return;
        const demo = manifest.demos[this.args.id];
        if (demo) {
          this.project = {
            title: demo.title,
            files: { ...manifest.starter, ...demo.files },
          };
        }
      })
      .catch(() => {
        if (!this.isDestroying && !this.isDestroyed) {
          this.error =
            'Could not load the playground. Reload this page to retry.';
        }
      });
  }

  open = () => {
    if (!this.project) return;
    const form = document.createElement('form');
    form.method = 'POST';
    form.action = 'https://stackblitz.com/run';
    form.target = '_blank';
    form.rel = 'noopener noreferrer';
    form.hidden = true;
    const fields = {
      'project[title]': this.project.title,
      'project[description]': 'An editable Ember EUI demo',
      'project[template]': 'node',
      'project[settings]': JSON.stringify({
        compile: { trigger: 'auto', clearConsole: false },
      }),
      ...Object.fromEntries(
        Object.entries(this.project.files).map(([path, content]) => [
          `project[files][${path}]`,
          content,
        ]),
      ),
    };
    for (const [name, value] of Object.entries(fields)) {
      const input = document.createElement('input');
      input.type = 'hidden';
      input.name = name;
      input.value = value;
      form.append(input);
    }
    document.body.append(form);
    try {
      // Submit synchronously from the click so browsers allow the new tab.
      form.submit();
    } finally {
      form.remove();
    }
  };

  <template>
    <div class="docfy-demo__playground" ...attributes>
      <EuiButtonEmpty
        @size="xs"
        @iconType="popout"
        @isDisabled={{if this.project false true}}
        data-test-demo-playground
        {{on "click" this.open}}
      >
        Open in StackBlitz
      </EuiButtonEmpty>
      {{#if this.error}}
        <span role="status">{{this.error}}</span>
      {{/if}}
    </div>
  </template>
}
