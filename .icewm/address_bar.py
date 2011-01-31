#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Smart parser for IceWM's address bar feature

Run without arguments for usage.

Included (somewhat slapdash but fairly comprehensive) test suite may be run
with `nosetests <name of this file>`.

@todo: Use notify_error to display exceptions.
@todo: Make sure the URL handling is robust in the face of lazy-escaped URLs.
@todo: Add support for using a config file of some sort (.gmrunrc?) to specify
    URL handlers directly since xdg-open is often configured to simply hand all
    URLs off to the user's web browser. This line (once de-obfuscated) does
    everything necessary for parsing except variable resolution:
    [[y.strip() for y in x.split('=')] for x in open('.gmrunrc','rU') if x.strip() and not x.strip().startswith('#')]
"""

__appname__ = "Smart Address Bar"
__author__  = "Stephan Sokolow (deitarion/SSokolow)"
__version__ = "0.1"
__license__ = "MIT"

import logging, os, re, shlex, string, subprocess, sys
from xml.sax.saxutils import escape as xmlescape

#{ Configuration

OPEN_CMD = ['xdg-open']
BROWSE_CMD = ['pcmanfm']
TERMINAL_CMD = ['xterm', '-hold', '-e']

NOTIFY_BACKENDS = [
        ['notify-send', '%(title)s', '%(text_xml)s'],
        ['zenity', '--title', '%(title)s', '--text', '%(text_xml)s'],
        ['xmessage', '-default', 'okay', '%(title):\n%(text)s']]

#{ Helper Functions

uri_re = re.compile(r"""^[a-zA-Z0-9+.\-]+:.+$""", re.IGNORECASE | re.UNICODE)

# Set up proper commandline split/unsplit for the platform in question
if os.name == 'nt':
    #TODO: Figure out how to split on Windows.
    _split = shlex.split
    _unsplit = subprocess.list2cmdline
    _useterm = lambda : True
else:
    _split = shlex.split
    _unsplit = lambda args: ' '.join([sh_quote(x) for x in args])
    _useterm = lambda : getattr(sys.stdout, 'fileno', None) and not os.isatty(sys.stdout.fileno())

def sh_quote(file):
    """Reliably quote a string as a single argument for /bin/sh

    Borrowed from the pipes module in Python 2.6.2 stdlib and fixed to quote
    empty strings properly and pass completely safechars strings through.
    """
    _safechars = string.ascii_letters + string.digits + '!@%_-+=:,./' # Safe unquoted
    _funnychars = '"`$\\'                           # Unsafe inside "double quotes"

    if not file:
        return "''"

    for c in file:
        if c not in _safechars:
            break
    else:
        return file

    if not [x for x in file if x not in _safechars]:
        return file
    elif '\'' not in file:
        return '\'' + file + '\''

    res = ''
    for c in file:
        if c in _funnychars:
            c = '\\' + c
        res = res + c
    return '"' + res + '"'
def which(name, flags=os.X_OK):
    """Search PATH for executable files with the given name.

    On newer versions of MS-Windows, the PATHEXT environment variable will be
    set to the list of file extensions for files considered executable. This
    will normally include things like ".EXE". This fuction will also find files
    with the given name ending with any of these extensions.

    On MS-Windows the only flag that has any meaning is os.F_OK. Any other
    flags will be ignored.

    Note: The original version of this would return directories. That has now
    been fixed.

    @type name: C{str}
    @param name: The name for which to search.

    @type flags: C{int}
    @param flags: Arguments to L{os.access}.

    @rtype: C{list}
    @param: A list of the full paths to files found, in the
    order in which they were found.

    Source: twisted/python/procutils.py (from Twisted 2.4.0)
    Copyright (c) 2001-2004 Twisted Matrix Laboratories.
    Copyright (c) 2007, 2011 Stephan Sokolow.
    License: MIT
    See LICENSE from the Twisted 2.4.0 tarball for details.
    """
    result = []
    exts = filter(None, os.environ.get('PATHEXT', '').split(os.pathsep))

    for bindir in os.environ['PATH'].split(os.pathsep):
        binpath = os.path.join(os.path.expanduser(bindir), name)
        if os.access(binpath, flags) and os.path.isfile(binpath):
            result.append(binpath)
        for ext in exts:
            pext = binpath + ext
            if os.access(pext, flags) and os.path.isfile(pext):
                result.append(pext)
    return result
def notify_error(text, title='Alert'):
    """Error-display wrapper for various notification/dialog backends.

    @todo: Add support for HTML notifications.
    @todo: Generalize for different notification types.
    @todo: Add support for using D-Bus directly.
    @todo: Add KDE detection and kdialog support.
    """
    params = {
            'title'   : title,
            'text'    : str(text),
            'text_xml': xmlescape(str(text))
            }

    for backend in NOTIFY_BACKENDS:
        if which(backend[0]):
            try:
                subprocess.check_call([x % params for x in backend])
            except subprocess.CalledProcessError:
                continue
            else:
                break
    else:
        # Just in case it's run from a console-only shell.
        print "%s:" % title
        print text

#{ Main Functionality

def run(args):
    """Heuristically guess how to handle the given commandline."""

    # Prefer the user's chosen shell for shell execute.
    if os.name == 'posix':
        shell_cmd = os.environ.get('SHELL', '/bin/sh')
    elif os.name == 'nt':
        shell_cmd = os.environ.get('COMSPEC', None)
    else:
        shell_cmd = None # Fall back to autodetection

    # Be easy-going about input for user convenience.
    if not args:
        return False
    elif isinstance(args, basestring):
        args = [args]

    if len(args) == 1:
        # May be unparsed, may just be unquoted.
        longcmd, argv = args[0], _split(args[0])
    else:
        # Either ready to use or unquoted.
        longcmd, argv = _unsplit(args), args

    # Flexible quoting for maximum versatility. (Order minimizes mistakes)
    for cmd in (longcmd, argv[0]):
        if which(cmd):
            # Valid command (shell execute for versatility)
            logging.info("Running as command: %r" % argv)
            subprocess.call(longcmd, shell=True, executable=shell_cmd)
        elif os.path.isdir(cmd):
            # Local Directory (open in file manager)
            logging.info("Opening directory: %s" % cmd)
            subprocess.call(BROWSE_CMD + [cmd])
        elif os.path.isfile(cmd):
            # Local File (open in desired application)
            logging.info("Opening file: %s" % cmd)
            subprocess.call(OPEN_CMD + [cmd])
        elif cmd.startswith('file://'):
            # Local path as URL (let file manager decide)
            subprocess.call(BROWSE_CMD + [cmd])
        elif uri_re.match(cmd):
            # Likely URI (open in desired URL handler)
            logging.info("Opening URL: %s" % cmd)
            subprocess.call(OPEN_CMD + [cmd])
        else:
            continue # No match, try the alternate interpretation.
        break # Match found, don't try the alternate interpretation.
    else:
        # No match found with either interpretation. Maybe it's a shell builtin?
        try:
            logging.info("Attempting shell fallback: %r" % argv)
            if _useterm():
                subprocess.check_call(TERMINAL_CMD + [shell_cmd, '-c', longcmd])
            else:
                subprocess.check_call(longcmd, shell=True, executable=shell_cmd)
        except subprocess.CalledProcessError:
            notify_error(repr(argv), title="Command not found")
            notify_error(repr(longcmd), title="Command not found")
            return False
    return True # Used for automated testing

#{ Test Routines for python-nose

def _check_run(args): assert run(args), repr(args)
def _check_run_fail(args): assert not run(args), repr(args)

def test_commands():
    """Testing simple commands"""
    os.environ['TEST_ECHO'] = 'echo'
    for cmd in ('echo', '/bin/echo', 'echo Success "" ...verily', "$TEST_ECHO"):
        for variant in (cmd, [cmd], shlex.split(cmd)):
            yield _check_run, variant

    # Test with TERMINAL_CMD
    global TERMINAL_CMD, _useterm
    _term_cmd, _use_term = TERMINAL_CMD, _useterm
    TERMINAL_CMD, _useterm = ['echo'], lambda: True
    try:
        os.environ['TEST_ECHO'] = 'echo'
        for cmd in ('echo', '/bin/echo', 'echo Success "" ...verily', "$TEST_ECHO"):
            for variant in (cmd, [cmd], shlex.split(cmd)):
                yield _check_run, variant
    finally:
        TERMINAL_CMD, _useterm = _term_cmd, _use_term

def test_builtins():
    """Testing shell script builtins"""
    cmd = 'for X in Success1 Success2; do echo $X "echo in for loop" > /dev/null; done'
    for variant in (cmd, [cmd]):
        yield _check_run, variant

def test_paths():
    """Testing non-command paths (files and directories) and URLs"""
    global BROWSE_CMD, OPEN_CMD
    browse_cmd, open_cmd = BROWSE_CMD, OPEN_CMD
    BROWSE_CMD, OPEN_CMD = ['echo', 'pcmanfm'], ['echo', 'xdg-open']

    try:
        for cmd in ('/etc', '/etc/resolv.conf', 'file:///etc/resolv.conf', 'http://www.example.com'):
            for variant in (cmd, [cmd], shlex.split(cmd)):
                yield _check_run, variant
    finally:
        BROWSE_CMD, OPEN_CMD = browse_cmd, open_cmd

def test_spaced_paths():
    """Testing non-command paths (files and directories) and URLs with spaces"""
    global BROWSE_CMD, OPEN_CMD
    browse_cmd, open_cmd = BROWSE_CMD, OPEN_CMD
    BROWSE_CMD, OPEN_CMD = ['echo', 'pcmanfm'], ['echo', 'xdg-open']

    try:
        import shutil, tempfile, urllib
        tmp_path = tempfile.mkdtemp()
        try:
            test_dir = os.path.join(tmp_path, 'Foo Bar')
            test_file = os.path.join(test_dir, 'baz.html')

            os.mkdir(test_dir)
            open(test_file, 'w').close()

            for cmd in (
                    test_dir, test_file,
                    'file://' + test_dir, 'file://' + test_file,
                    'file://' + urllib.pathname2url(test_dir),
                    'file://' + urllib.pathname2url(test_file),
                    'http://127.0.0.1' + test_dir):
                for variant in (cmd, [cmd], shlex.split(cmd)):
                    yield _check_run, variant
        finally:
            shutil.rmtree(tmp_path)
    finally:
        BROWSE_CMD, OPEN_CMD = browse_cmd, open_cmd

def test_failure():
    """Testing failure conditions"""
    for empty in (None, '', []):
        yield _check_run_fail, empty

    for nonsense in ('rijwoigjrwo', 'for foo in', 'for foo in x y; done'):
        for variant in (nonsense, [nonsense], shlex.split(nonsense)):
            yield _check_run_fail, variant

    os.environ['TEST_ECHO'] = 'ecoh'
    yield _check_run_fail, '$TEST_ECHO'
#}

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

    if len(sys.argv) < 2:
        notify_error((
                "%(cmd)s <cmd> [arg] ...\n" +
                "  or  \n" +
                "%(cmd)s <cmd with args>") % {'cmd': os.path.basename(sys.argv[0])}
                , title="Usage")
        sys.exit(2)
    else:
        outcome = run(sys.argv[1:])

        # Exit with a return code of 1 on failure
        sys.exit(int(not outcome))
