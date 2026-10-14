pragma Singleton

import QtQuick
import Quickshell

// At most one popout open; while one is, hovering another trigger swaps to it.
Singleton {
    id: root

    property var current: null

    function opened(popout: var): void {
        if (root.current && root.current !== popout)
            root.current.visible = false;
        root.current = popout;
    }

    function closed(popout: var): void {
        if (root.current === popout)
            root.current = null;
    }

    function handoff(next: var): void {
        if (!next || !root.current || root.current === next)
            return;
        next.handoffAt = Date.now();
        next.visible = true;
    }

    function close(): void {
        if (root.current)
            root.current.visible = false;
    }
}
