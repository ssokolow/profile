#!/usr/bin/env python3
"""Flatpak CLI Shortcut Generator

A simple no-argument tool that generates launchers with traditional non-flatpak
command names for your installed Flatpak applications in ~/.local/bin/flatpak.

Does full collision detection and warns you if you forgot to add its output
directory to your PATH. Also overrules the command-line specified in the
``.desktop`` file if the Flatpak maintainer didn't include support for
command-line arguments.

Also includes some built-in mappings to compensate for the less desirable
launcher/wrapper names some Flatpak packages use.

Dependencies:
- Python 3.8+
- PyGobject (eg. python3-gi)
- Glib and Gio 2.0 with GIR bindings (eg. gir1.2-glib-2.0)
- Flatpak 1.0 GIR binding (eg. gir1.2-flatpak-1.0)

Known shortcomings:

* Still need to look into the best way to query the set of `.desktop` files
  installed by Things like OpenRA so I don't need to *manually* amend the
  `EXTRA_COMMANDS` list in cases involving secondary GUI apps.
* Uses the sledgehammer approach of just removing all non-folders from the
  target directory before generating new launchers to clear out stale entries.
  (A proper solution would keep track of which ones it created, but that'd
  require me to go back and implement detection of all prior versions which
  don't have a specific marker.)
* Doesn't solve the problem of flatpaks still not installing manpages

MIT License

Copyright (c) 2021-2022 Stephan Sokolow (deitarion/SSokolow)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

import re
from distutils.spawn import find_executable
import os.path

from typing import Dict, List

import gi  # type: ignore
gi.require_version('Flatpak', '1.0')
gi.require_version('Gio', '2.0')
gi.require_version('GLib', '2.0')

from gi.repository import Flatpak, Gio, GLib  # type: ignore

#: Add this to the end of your $PATH
BIN_DIR = os.path.expanduser("~/.local/bin/flatpak")

#: Remappings for flatpak packages that use less-than-ideal command names
CMD_REMAPPINGS = {
    'com.github.tchx84.Flatseal': 'flatseal',
    'com.sweethome3d.Sweethome3d': 'sweethome3d',
    'io.github.simple64.simple64': 'simple64',
    'net._86box._86Box': '86box',
    'net.cebix.basilisk': 'basilikii',
    'org.fritzing.Fritzing': 'fritzing',
    'org.jdownloader.JDownloader': 'jdownloader',
    'org.ppsspp.PPSSPP': 'ppsspp',
    'org.scummvm.ScummVM': 'scummvm',
}

#: Secondary commands to expose
EXTRA_CMDS = {
    "com.github.AmatCoder.mednaffe": ['mednafen'],
    'net.openra.OpenRA': ['openra-cnc', 'openra-d2k'],
    "org.atheme.audacious": ['audtool'],
}

#: Paths to check for .desktop files, since ``Gio.DesktopAppInfo.new`` doesn't
FLATPAK_DESKTOP_FILE_PATHS = (
    '/var/lib/flatpak/exports/share/applications',

    # TODO: Confirm this is correct for --user
    os.path.expanduser('~/.local/share/flatpak/exports/share/applications')
)

#: The template for generating wrapper scripts.
#: (Uses Python's ``.format``, so escape { and } as {{ and }}
#:
#: Uses bash for the wrapper script because I need to iterate an array
#: and conditionally rewrite arguments and the Python interpreter is an
#: order of magnitude slower to start.
WRAPPER_TEMPLATE = """#!/bin/bash
# AUTOGENERATED FILE! DO NOT EDIT!

# Unset LD_PRELOAD to silence errors about gtk-nocsd being
# missing from the Flatpak runtime
unset LD_PRELOAD

# Make arguments that are existing paths absolute
# (Necessary to make forwarding work reliably)
declare -a args
for arg in "$@"; do
    if [ -a "$arg" ]; then
        args+=("$(readlink -f "$arg")")
    else
        args+=("$arg")
    fi
done

# Use file forwarding to make paths Just Work™
exec {flatpak_cmd}
"""

arg_placeholder_re = re.compile("%[uUfF]")


def get_installed_packages() -> Dict[str, str]:
    """Retrieve a dict mapping package names to command names for
    installed flatpaks"""
    results = {}

    for installation in (
            Flatpak.Installation.new_system(),
            Flatpak.Installation.new_user()):
        refs = installation.list_installed_refs_by_kind(
            Flatpak.RefKind.APP, None)
        for ref in refs:
            meta = ref.load_metadata().get_data().decode('utf8')
            keyfile = GLib.KeyFile.new()
            keyfile.load_from_data(meta, len(meta), GLib.KeyFileFlags.NONE)

            command = keyfile.get_string('Application', 'command').strip()
            if command:
                results[ref.get_name()] = command

    return results


def make_flatpak_cmd(ref: str, extra_args: str = '') -> str:
    """Construct a ``flatpak run`` command for the given arguments

    This is used for secondary commands and for the fallback for the primary
    command"""
    return (f'flatpak run {extra_args} --file-forwarding "{ref}" @@u '
            f'"${{args[@]}}" @@')


def get_flatpak_cmd(ref: str) -> str:
    """Extract or construct the best possible command to launch ``ref``

    (This tries to extract it from the ``.desktop`` file and then falls back to
    ``make_flatpak_cmd`` if it fails or the extracted command line doesn't
    include ``--file-forwarding`` to ensure that upstream can't prevent us from
    feeding command-line arguments... ScummVM as of this writing, for example.)
    """
    desktop_file = None
    for candidate in FLATPAK_DESKTOP_FILE_PATHS:
        try:
            desktop_file = Gio.DesktopAppInfo.new_from_filename(
                os.path.join(candidate, ref + '.desktop'))
            break
        except TypeError:
            pass

    # If we found a .desktop file AND it uses --file-forwarding
    if desktop_file:
        command = desktop_file.get_commandline()
        if '--file-forwarding' in command:
            return arg_placeholder_re.sub('"${args[@]}"', command)

    # ...otherwise, fall back to the generated command line that's been working
    # well for me for months.
    return make_flatpak_cmd(ref)


def make_wrapper(flatpak_cmd: str, command: str, bin_dir: str,
                 seen: List[str] = None):
    """Render ``WRAPPER_TEMPLATE`` to a command in the folder ``bin_dir`` and
    mark it executable.

    If provided, ``extra_args`` will be inserted into the portion of the
    ``flatpak run`` command before ``run``.

    If ``seen`` is not ``None``, use it to detect and reject naming collisions.

    Also warn if we're masking existing commands.
    """
    out_path = os.path.join(bin_dir, command)
    if seen is not None and out_path in seen:
        print(f'ERROR: Wrapper name "{out_path}" was already claimed and '
              f'could not be mapped to "{flatpak_cmd}". Please add a '
              f' CMD_REMAPPINGS entry.')
        return

    existing = find_executable(command)
    with open(out_path, 'w') as fobj:
        fobj.write(WRAPPER_TEMPLATE.format(
            flatpak_cmd=flatpak_cmd))
        os.chmod(out_path, os.stat(out_path).st_mode | 0o755)
        if seen is not None:
            seen.append(out_path)

    if existing:
        msg = (f'WARNING: Command "{command}" already exists in your PATH at '
             f'"{existing}".')
        winner = find_executable(command)
        if winner == existing:
            print(msg + f' The Flatpak wrapper will be inaccessible.')
        else:
            print(msg + f' The Flatpak wrapper will mask access to it.')


def main():
    """setuptools-compatible entry point"""
    # Ensure BIN_DIR exists and remove any stale launch scripts
    if not os.path.exists(BIN_DIR):
        os.makedirs(BIN_DIR)
    for name in os.listdir(BIN_DIR):
        path = os.path.join(BIN_DIR, name)
        if os.path.isfile(path):
            os.remove(path)

    print(f"Getting list of installed application/non-runtime packages...")
    added = []
    for (ref, command) in get_installed_packages().items():
        print(f"Generating wrapper for {ref}...")

        command = CMD_REMAPPINGS.get(ref, command)
        make_wrapper(get_flatpak_cmd(ref), command, BIN_DIR, seen=added)

        if ref in EXTRA_CMDS:
            for cmd in EXTRA_CMDS[ref]:
                make_wrapper(make_flatpak_cmd(ref, f"--command={cmd}"),
                             cmd, BIN_DIR, added)

    # Check if BIN_DIR is in the PATH so people don't need to read this source
    if BIN_DIR not in os.environ.get('PATH', '').split(os.pathsep):
        print(f"WARNING: Could not find {BIN_DIR} in PATH. You will need to "
            "add it before you can use the generated launchers.")


if __name__ == '__main__':
    main()
