import Component from '@glimmer/component';

//@ts-ignore
import changelog from 'site/assets/CHANGELOG.md';

export default class ChangelogComponent extends Component {
  changelog = changelog;
}
