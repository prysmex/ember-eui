import { helper } from '@ember/component/helper';
import { RefractorNode } from 'refractor';
import Component from '@glimmer/component';
import { getHtmlContent } from '../../../utils/code/utils';

export default class EuiCodeBlockVirtualizedComponent extends Component {
  getHtmlContent = helper(function ([node, index, rowHeight]: [
    RefractorNode,
    number,
    number
  ]) {
    const content = getHtmlContent([node]);
    const span = content.element.firstChild as HTMLElement;
    if (span) {
      span.style.position = 'absolute';
      span.style.height = `${rowHeight}px`;
      span.style.top = `${(index + 1) * rowHeight}px`;
    }
    return span;
  });
}
