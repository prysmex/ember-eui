import Component from '@glimmer/component';
import { action } from '@ember/object';
import { BufferedChangeset } from 'ember-changeset/types';
import { assert } from '@ember/debug';

interface EuiChangesetFormArgs {
	changeset: BufferedChangeset;
	onSubmit?: (e: Event) => void;
}

export default class EuiChangesetFormComponent extends Component<EuiChangesetFormArgs> {
	form: HTMLFormElement | null = null;

	constructor(owner: unknown, args: EuiChangesetFormArgs) {
		super(owner, args);
		assert('Must provide a changeset', this.args.changeset);
		
	}
	@action
	didInsertForm(form: HTMLFormElement) {
		this.form = form;
	}

	@action
	validate() {
		
	}

	@action
	onSubmit(e: Event) {
		e.preventDefault();
		this.args.onSubmit?.(e);
	}
}
