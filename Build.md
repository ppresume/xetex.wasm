## Build native XeTeX

We're trying to build XeTeX on Ubuntu 20.04 LTS.

First install necessary tools:

- `sudo apt install autoconf build-essential libtool pkg-config`

Make sure that you have autoconf version 2.69 or lower, version 2.70+ has a
breaking change which would lead to a build failure, see this
[ticket](https://sourceforge.net/p/xetex/bugs/195/) for detailed analysis
(Ubuntu 22.04 LTS has autoconf 2.70+ version by default thus it failed to build
XeTeX by default).

Then install necessary libraries:

- `sudo apt install libfontconfig1-dev`

Again, we found some bug in the latest version of XeTeX, see this
[ticket](https://sourceforge.net/p/xetex/bugs/196/) for more analysis.

To make the build succeed, we need to checkout a specific commit, here we reset
the repo to a last working commit
[8af2b5](https://github.com/TeX-Live/xetex/tree/8af2b5):

- `git reset --hard 8af2b58c82bdfcd2791a31b506c602d6b9abdf1c

Then try to build by:

- `./build.sh`

If everything goes well, you should be able to get a binary
`build/texk/web2c/xetex`.
