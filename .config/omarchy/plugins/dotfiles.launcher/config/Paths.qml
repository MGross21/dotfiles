pragma Singleton

import QtQuick
import Quickshell

QtObject {
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`) + "/dotfiles-launcher"
    readonly property string dataDir: Quickshell.env("DOTFILES_LAUNCHER_DATA")

    function state(name: string): string {
        return `${stateDir}/${name}`;
    }

    function data(name: string): string {
        return `${dataDir}/${name}`;
    }
}
