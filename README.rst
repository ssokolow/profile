This repository contains both the parts of my roaming profile that are safe to share, and the scripting to reinstall the broad strokes of my OS.

To set up, clone it to somewhere like ``~/.profile_repo`` and use the following commands:

1. ``ubuntu_setup.sh`` will do a complete deploy on a freshly installed 
   Kubuntu system.
2. ``ubuntu_setup.sh --system`` will do only the system-level deployment,
   including installing Ansible and the dependencies for my playbooks.
3. ``ubuntu_setup.sh --user`` will install all of the things which occupy the
   middle-ground between a system image and a user profile.
   (eg. Rust-based developer tools that install into ``$HOME/.cargo/bin``.
4. ``install.py`` will symlink the profile's components into place in the
   home directory.

``install.py`` is my own creation and provides a ``--dry-run`` option to see what it would change. By default, it will not replace files that already exist and it provides a ``--diff`` option to inspect them by comparing them to the copies it would install.

``ubuntu_setup.sh`` is also just smart enough that, if you pass the Ansible ``--check`` option but not ``--system`` or ``--user``, it will translate it to ``--dry-run --diff`` when calling ``install.py``.