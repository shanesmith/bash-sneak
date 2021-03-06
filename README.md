sneak.bash
==========

sneak.bash is a Bash readline binding to jump to a position in the current
command line specified by two characters. The idea (and name...) is borrowed
from the excellent [vim-sneak] plugin.

![Demo](https://cloud.githubusercontent.com/assets/348425/22004869/10f3d84a-dc2d-11e6-9c5e-f56b550ae7cf.gif)

Usage
-----

Use `Ctrl-G` or `Ctrl-T` followed by two character to perform a forwards or
backwards sneak, the cursor will be moved to the next or previous instance of
those two characters. To repeat the same sneak double up and hit the same
trigger twice. To quit the sneak prompt hit `esc`.


```sh
# Let's say the pipe | is your cursor
$ echo "99 bottles of beer on the wall, 99 bottles of beer, take one down..."|
                                                                             ^ 

# Press Ctrl-T followed by `be`, the cursor will move in front of "beer"
$ echo "99 bottles of beer on the wall, 99 bottles of |beer, take one down..."
                                                      ^

# Press Ctrl-T Ctrl-T to redo the same sneak
$ echo "99 bottles of |beer on the wall, 99 bottles of beer, take one down..."
                      ^

# Now to redo the sneak but in the forwards direction press Ctrl-G Ctrl-G
$ echo "99 bottles of beer on the wall, 99 bottles of |beer, take one down..."
                                                      ^
```

Installation
------------

Download `sneak.bash` somewhere and source it.

```sh
# Download it
curl -L https://raw.githubusercontent.com/shanesmith/bash-sneak/v0.1.0/sneak.bash -o ~/sneak.bash

# Source it
source ~/sneak.bash

# Use it
echo "Golly this is a lng command, would hate to find a typo" [Ctrl-T]ng
```

You'll probably also want to source it in your `.bashrc`.

```sh
echo "source ~/sneak.bash" >> ~/.bashrc
```

**Requirements**

- Bash 4+

Tested mainly on macOS, and minimally on both Ubuntu and Windows (Git Bash and
subsystem Bash).

Options
-------

Set the following bash variables to customize some options.


`SNEAK_PROMPT="/ "`

> When sneak is triggered bash will clear the current line, so sneak redisplays
> the current command with a prepended prompt, set it here if you want it to be
> different.


`SNEAK_NUM_CHARS=2`

> Want to be able to type more than two characters? Set this option. Also note
> that this is a maximum number of characters before sneak will automatically
> start the search, you can hit ENTER anytime to search for the characters
> typed so far.


`SNEAK_BINDING_FORWARD="\C-g"`
`SNEAK_BINDING_BACKWARD="\C-t"`

> Key bindings for triggering sneak, see `help bind` for more information.
> These need to be set before sourcing `sneak.bash`. Set to empty (or unset) to
> disable the default trigger and do your own thing with the available
> `__sneak_forward` and `__sneak_backward` functions.


License
-------

Copyright (c) Shane Smith. Distributed under the MIT license.

[vim-sneak]: https://github.com/justinmk/vim-sneak

