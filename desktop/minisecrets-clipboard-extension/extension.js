/* extension.js
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

'use strict';

const { Clutter, GObject, Meta, Secret, Shell, St } = imports.gi;

const Dialog = imports.ui.dialog;
const ExtensionUtils = imports.misc.extensionUtils;
const Main = imports.ui.main;
const ModalDialog = imports.ui.modalDialog;
const ShellEntry = imports.ui.shellEntry;

const Me = ExtensionUtils.getCurrentExtension();

const SECRET_SCHEMA = Secret.Schema.new('com.osandov.minisecrets',
    Secret.SchemaFlags.NONE,
    { name: Secret.SchemaAttributeType.STRING },
);

var MiniSecretsCopyDialog = GObject.registerClass(
class MiniSecretsCopyDialog extends ModalDialog.ModalDialog {
    _init() {
        super._init({
            styleClass: 'run-dialog',
            destroyOnClose: false,
        });

        let title = _('Copy Secret to Clipboard');
        let content = new Dialog.MessageDialogContent({ title });
        this.contentLayout.add_actor(content);

        let entry = new St.Entry({
            style_class: 'run-dialog-entry',
            can_focus: true,
        });
        ShellEntry.addContextMenu(entry);

        this._entryText = entry.clutter_text;
        content.add_child(entry);
        this.setInitialKeyFocus(this._entryText);

        let defaultDescriptionText = _('Press ESC to close');

        this._descriptionLabel = new St.Label({
            style_class: 'run-dialog-description',
            text: defaultDescriptionText,
        });
        content.add_child(this._descriptionLabel);

        // TODO: tab completion for secret names would be nice.
        this._entryText.connect('activate', o => {
            this.popModal();
            Secret.password_lookup(
                SECRET_SCHEMA,
                { name: o.get_text() },
                null,
                this._on_password_lookup.bind(this));
        });
        this._entryText.connect('text-changed', () => {
            this._descriptionLabel.set_text(defaultDescriptionText);
        });
    }

    vfunc_key_release_event(event) {
        if (event.keyval === Clutter.KEY_Escape) {
            this.close();
            return Clutter.EVENT_STOP;
        }
        return Clutter.EVENT_PROPAGATE;
    }

    _on_password_lookup(source, result) {
        var secret = Secret.password_lookup_finish(result);
        if (secret === null) {
            this._descriptionLabel.set_text('Secret not found');
            if (!this.pushModal())
                this.close();
        } else {
            St.Clipboard.get_default().set_text(St.ClipboardType.CLIPBOARD, secret);
            this.close();
        }
    }

    open() {
        this._entryText.set_text('');
        super.open();
    }
});

class Extension {
    constructor() {
        this._settings = ExtensionUtils.getSettings(Me.metadata['settings-schema']);
        this._dialog = null;
    }

    enable() {
        Main.wm.addKeybinding(
            'minisecrets-copy-dialog',
            this._settings,
            Meta.KeyBindingFlags.IGNORE_AUTOREPEAT,
            Shell.ActionMode.NORMAL | Shell.ActionMode.OVERVIEW,
            this._copySecretDialog.bind(this));
    }

    disable() {
        Main.wm.removeKeybinding('minisecrets-copy-dialog');
        if (this._dialog !== null) {
            this._dialog.destroy();
            this._dialog = null;
        }
    }

    _copySecretDialog() {
        if (this._dialog === null)
            this._dialog = new MiniSecretsCopyDialog();
        this._dialog.open();
    }
}

function init() {
    return new Extension();
}
