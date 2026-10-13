/*
 * Ported from @elastic/eui 123.1.0 `components/flyout/manager/layout_mode.test.tsx`.
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 *
 * Upstream tests `useApplyFlyoutLayoutMode` through a mocked React context.
 * Its decision is the pure `getDesiredLayoutMode` here; the window listener
 * and dispatches belong to the `eui-flyout-manager` service.
 */
import {
  afterEach,
  describe,
  expect,
  it,
  jest
} from '../../helpers/jest-compat.ts';
import EuiFlyoutManagerService from '#src/services/eui-flyout-manager.ts';
import {
  LAYOUT_MODE_SIDE_BY_SIDE,
  LAYOUT_MODE_STACKED,
  LEVEL_CHILD,
  LEVEL_MAIN
} from '#src/utils/eui/flyout-manager/const.ts';
import {
  getDesiredLayoutMode,
  getWidthFromSize
} from '#src/utils/eui/flyout-manager/layout-mode.ts';
import { initialState } from '#src/utils/eui/flyout-manager/reducer.ts';

import type {
  EuiFlyoutLayoutMode,
  EuiFlyoutManagerState,
  EuiManagedFlyoutState
} from '#src/utils/eui/flyout-manager/types.ts';

/** Borealis `breakpoint.s`: stacked below 575 * 1.4 = 805px. */
const BREAKPOINT_S = 575;

const buildState = ({
  layoutMode = LAYOUT_MODE_SIDE_BY_SIDE,
  session = { mainFlyoutId: 'main-1', childFlyoutId: 'child-1' as string | null },
  mainFlyout = {
    flyoutId: 'main-1',
    level: LEVEL_MAIN,
    size: 'm',
    width: 600
  } as EuiManagedFlyoutState | null,
  childFlyout = {
    flyoutId: 'child-1',
    level: LEVEL_CHILD,
    size: 's',
    width: 300
  } as EuiManagedFlyoutState | null
}: {
  layoutMode?: EuiFlyoutLayoutMode;
  session?: { mainFlyoutId: string; childFlyoutId: string | null } | null;
  mainFlyout?: EuiManagedFlyoutState | null;
  childFlyout?: EuiManagedFlyoutState | null;
} = {}): EuiFlyoutManagerState => ({
  ...initialState,
  layoutMode,
  sessions: session
    ? [
        {
          ...session,
          title: 'Main',
          zIndex: 0,
          childHistory: [],
          historyKey: Symbol()
        }
      ]
    : [],
  flyouts: [mainFlyout, childFlyout].filter(
    (flyout): flyout is EuiManagedFlyoutState => flyout !== null
  )
});

describe('Unit | flyout manager | layout mode', () => {
  describe('getWidthFromSize', () => {
    it('returns number values as-is', () => {
      expect(getWidthFromSize(500)).toBe(500);
      expect(getWidthFromSize(0)).toBe(0);
      expect(getWidthFromSize(1000)).toBe(1000);
    });

    it('parses numeric strings', () => {
      expect(getWidthFromSize('500')).toBe(500);
      expect(getWidthFromSize('0')).toBe(0);
      expect(getWidthFromSize('1000')).toBe(1000);
    });

    it('calculates named sizes as a share of the reference width', () => {
      expect(getWidthFromSize('s', 1200)).toBe(300);
      expect(getWidthFromSize('m', 1200)).toBe(600);
      expect(getWidthFromSize('l', 1200)).toBe(900);
      expect(getWidthFromSize('fill', 1200)).toBe(1080);
    });

    it('handles different reference widths', () => {
      expect(getWidthFromSize('s', 800)).toBe(200);
      expect(getWidthFromSize('m', 800)).toBe(400);
      expect(getWidthFromSize('l', 800)).toBe(600);
    });

    it('falls back to the window width', () => {
      expect(getWidthFromSize('m')).toBe(Math.round(window.innerWidth * 0.5));
    });

    it('returns 0 for unknown and non-numeric strings', () => {
      expect(getWidthFromSize('unknown')).toBe(0);
      expect(getWidthFromSize('xl')).toBe(0);
      expect(getWidthFromSize('abc')).toBe(0);
      expect(getWidthFromSize('')).toBe(0);
    });

    it('parses partial numeric strings', () => {
      expect(getWidthFromSize('12abc')).toBe(12);
      expect(getWidthFromSize('500px')).toBe(500);
    });

    it('handles edge cases', () => {
      expect(getWidthFromSize(null as unknown as string)).toBe(0);
      expect(getWidthFromSize(undefined as unknown as string)).toBe(0);
    });
  });

  describe('getDesiredLayoutMode', () => {
    it('returns null when no flyout is open', () => {
      expect(
        getDesiredLayoutMode(buildState({ session: null }), 1200, BREAKPOINT_S)
      ).toBe(null);
      expect(getDesiredLayoutMode(null, 1200, BREAKPOINT_S)).toBe(null);
    });

    it('is STACKED when the reference width is too small', () => {
      expect(getDesiredLayoutMode(buildState(), 500, BREAKPOINT_S)).toBe(
        LAYOUT_MODE_STACKED
      );
      expect(
        getDesiredLayoutMode(
          buildState({ layoutMode: LAYOUT_MODE_STACKED }),
          500,
          BREAKPOINT_S
        )
      ).toBe(LAYOUT_MODE_STACKED);
    });

    it('is SIDE_BY_SIDE without a child flyout', () => {
      expect(
        getDesiredLayoutMode(
          buildState({
            layoutMode: LAYOUT_MODE_STACKED,
            session: { mainFlyoutId: 'main-1', childFlyoutId: null },
            childFlyout: null
          }),
          1200,
          BREAKPOINT_S
        )
      ).toBe(LAYOUT_MODE_SIDE_BY_SIDE);
    });

    it('estimates unmeasured widths from the sizes', () => {
      // m + s = 75% of the width: side by side
      expect(
        getDesiredLayoutMode(
          buildState({
            layoutMode: LAYOUT_MODE_STACKED,
            mainFlyout: { flyoutId: 'main-1', level: LEVEL_MAIN, size: 'm' },
            childFlyout: { flyoutId: 'child-1', level: LEVEL_CHILD, size: 's' }
          }),
          1200,
          BREAKPOINT_S
        )
      ).toBe(LAYOUT_MODE_SIDE_BY_SIDE);
      // l + m = 125%: stacked
      expect(
        getDesiredLayoutMode(
          buildState({
            mainFlyout: { flyoutId: 'main-1', level: LEVEL_MAIN, size: 'l' },
            childFlyout: { flyoutId: 'child-1', level: LEVEL_CHILD, size: 'm' }
          }),
          1200,
          BREAKPOINT_S
        )
      ).toBe(LAYOUT_MODE_STACKED);
    });

    it('is SIDE_BY_SIDE when the widths stay unknown', () => {
      expect(
        getDesiredLayoutMode(
          buildState({
            layoutMode: LAYOUT_MODE_STACKED,
            mainFlyout: { flyoutId: 'main-1', level: LEVEL_MAIN },
            childFlyout: { flyoutId: 'child-1', level: LEVEL_CHILD }
          }),
          1200,
          BREAKPOINT_S
        )
      ).toBe(LAYOUT_MODE_SIDE_BY_SIDE);
    });

    it('switches back to SIDE_BY_SIDE from STACKED at 85% or less', () => {
      // 600 + 300 = 75%
      expect(
        getDesiredLayoutMode(
          buildState({ layoutMode: LAYOUT_MODE_STACKED }),
          1200,
          BREAKPOINT_S
        )
      ).toBe(LAYOUT_MODE_SIDE_BY_SIDE);
      // 700 + 400 = 91.7%: stays stacked (hysteresis)
      expect(
        getDesiredLayoutMode(
          buildState({
            layoutMode: LAYOUT_MODE_STACKED,
            mainFlyout: { flyoutId: 'main-1', level: LEVEL_MAIN, size: 'm', width: 700 },
            childFlyout: { flyoutId: 'child-1', level: LEVEL_CHILD, size: 's', width: 400 }
          }),
          1200,
          BREAKPOINT_S
        )
      ).toBe(LAYOUT_MODE_STACKED);
    });

    it('switches to STACKED at 95% or more', () => {
      // 800 + 400 = 100%
      expect(
        getDesiredLayoutMode(
          buildState({
            mainFlyout: { flyoutId: 'main-1', level: LEVEL_MAIN, size: 'm', width: 800 },
            childFlyout: { flyoutId: 'child-1', level: LEVEL_CHILD, size: 's', width: 400 }
          }),
          1200,
          BREAKPOINT_S
        )
      ).toBe(LAYOUT_MODE_STACKED);
      // 700 + 400 = 91.7%: stays side by side
      expect(
        getDesiredLayoutMode(
          buildState({
            mainFlyout: { flyoutId: 'main-1', level: LEVEL_MAIN, size: 'm', width: 700 },
            childFlyout: { flyoutId: 'child-1', level: LEVEL_CHILD, size: 's', width: 400 }
          }),
          1200,
          BREAKPOINT_S
        )
      ).toBe(LAYOUT_MODE_SIDE_BY_SIDE);
    });

    describe('with fill size', () => {
      it('keeps side by side when the parent, the child or both are fill', () => {
        for (const [mainSize, childSize] of [
          ['fill', 's'],
          ['m', 'fill'],
          ['fill', 'fill']
        ]) {
          expect(
            getDesiredLayoutMode(
              buildState({
                mainFlyout: { flyoutId: 'main-1', level: LEVEL_MAIN, size: mainSize },
                childFlyout: { flyoutId: 'child-1', level: LEVEL_CHILD, size: childSize }
              }),
              1200,
              BREAKPOINT_S
            )
          ).toBe(LAYOUT_MODE_SIDE_BY_SIDE);
        }
      });

      it('stacks when the reference width is too small for fill flyouts', () => {
        expect(
          getDesiredLayoutMode(
            buildState({
              mainFlyout: { flyoutId: 'main-1', level: LEVEL_MAIN, size: 'fill' },
              childFlyout: { flyoutId: 'child-1', level: LEVEL_CHILD, size: 's' }
            }),
            700,
            BREAKPOINT_S
          )
        ).toBe(LAYOUT_MODE_STACKED);
      });

      it('handles a fill flyout with no child', () => {
        expect(
          getDesiredLayoutMode(
            buildState({
              session: { mainFlyoutId: 'main-1', childFlyoutId: null },
              mainFlyout: { flyoutId: 'main-1', level: LEVEL_MAIN, size: 'fill' },
              childFlyout: null
            }),
            1200,
            BREAKPOINT_S
          )
        ).toBe(LAYOUT_MODE_SIDE_BY_SIDE);
      });
    });
  });

  describe('eui-flyout-manager service', () => {
    let service: EuiFlyoutManagerService | undefined;

    afterEach(() => {
      service?.destroy();
      service = undefined;
    });

    it('listens to window resizes only while a main flyout is open', () => {
      const add = jest.spyOn(window, 'addEventListener');
      const remove = jest.spyOn(window, 'removeEventListener');
      try {
        service = EuiFlyoutManagerService.create();
        expect(add.mock.calls.filter(([type]) => type === 'resize')).toHaveLength(0);

        service.addFlyout('main-1', 'Main', LEVEL_MAIN, 'm');
        expect(add.mock.calls.filter(([type]) => type === 'resize')).toHaveLength(1);
        expect(service.state.referenceWidth).toBe(window.innerWidth);

        service.addFlyout('child-1', 'Child', LEVEL_CHILD, 's');
        expect(add.mock.calls.filter(([type]) => type === 'resize')).toHaveLength(1);

        service.closeAllFlyouts();
        expect(remove.mock.calls.filter(([type]) => type === 'resize')).toHaveLength(1);
      } finally {
        add.mockRestore();
        remove.mockRestore();
      }
    });

    it('applies the layout mode of a narrow container', () => {
      const container = document.createElement('div');
      container.style.width = '600px';
      document.body.appendChild(container);
      try {
        service = EuiFlyoutManagerService.create();
        service.addFlyout('main-1', 'Main', LEVEL_MAIN, 'm');
        expect(service.state.layoutMode).toBe(LAYOUT_MODE_SIDE_BY_SIDE);

        const release = service.useContainer(container);
        expect(service.state.containerElement).toBe(container);
        expect(service.state.layoutMode).toBe(LAYOUT_MODE_STACKED);
        expect(service.state.referenceWidth).toBe(600);

        release();
        expect(service.state.containerElement).toBe(null);
        expect(service.state.layoutMode).toBe(LAYOUT_MODE_SIDE_BY_SIDE);
      } finally {
        container.remove();
      }
    });

    it('keeps a shared container until its last flyout releases it', () => {
      const container = document.createElement('div');
      document.body.appendChild(container);
      try {
        service = EuiFlyoutManagerService.create();
        const releaseA = service.useContainer(container);
        const releaseB = service.useContainer(container);
        releaseA();
        expect(service.state.containerElement).toBe(container);
        releaseB();
        expect(service.state.containerElement).toBe(null);
      } finally {
        container.remove();
      }
    });
  });
});
