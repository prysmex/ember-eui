import Component from '@glimmer/component';
import { action } from '@ember/object';
import { BufferedChangeset } from 'ember-changeset/types';
import { assert } from '@ember/debug';
import { later } from '@ember/runloop';
import { tracked } from '@glimmer/tracking';

interface EuiChangesetFormArgs {
  changeset: BufferedChangeset;
  beforeSubmit?: (changeset: BufferedChangeset, e: Event) => void;
  onSubmit?: (data: {}, e: Event) => void;
  onReset?: (data: {}, e: Event) => void;
  runExecuteInsteadOfSave?: boolean;
}

export default class EuiChangesetFormComponent extends Component<EuiChangesetFormArgs> {
  form: HTMLFormElement | null = null;

  @tracked hasSubmitted: boolean = false;

  constructor(owner: unknown, args: EuiChangesetFormArgs) {
    super(owner, args);
    assert('Must provide a changeset', this.args.changeset);
  }

  @action
  async validate() {
    later(
      this,
      () => {
        this.args.changeset.validate();
      },
      1
    );
  }

  @action
  async handleSubmit(changeset: BufferedChangeset, event: Event) {
    event.preventDefault();

    if (typeof this.args.beforeSubmit === 'function') {
      this.args.beforeSubmit(changeset, event);
    }
    await changeset.validate();

    this.hasSubmitted = true;

    if (changeset.isInvalid) {
      return;
    }

    let result;
    if (this.args.runExecuteInsteadOfSave) {
      result = changeset.execute();
    } else {
      result = await changeset.save({});
    }

    if (typeof this.args.onSubmit === 'function') {
      this.args.onSubmit(result.data, event);
    }
  }

  @action
  handleReset(changeset: BufferedChangeset, event: Event) {
    event.preventDefault();
    this.hasSubmitted = false;

    const { data } = changeset.rollback();
    if (typeof this.args.onReset === 'function') {
      this.args.onReset(data, event);
    }
  }
}
