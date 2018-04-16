# snabb-libmoon-compat
Fork/rewrite of Snabb Core to support DPDK NICs via libmoon

snabb-libmoon-compat reimplements some of [Snabb](https://github.com/snabbco/snabb)'s functionality using [libmoon](https://github.com/libmoon/libmoon).
DPDK NICs can be used as regular Snabb apps.
All NICs supported by libmoon work out of the box.

snabb-libmoon-compat was written as part of my [Bachelor's Thesis](https://fabianbonk.de/snabb-libmoon-compat/thesis.pdf).

## How To
snabb-libmoon-compat is written entirely in Lua; there is no need to build it.

The following instructions will start an echo server on DPDK Device 0.
Run `dpdk-devbind.py --status` to see which NICs are available and which drivers are loaded.

1. build libmoon (see [README](https://github.com/libmoon/libmoon/blob/master/README.md))
2. `git clone https://github.com/Reperator/snabb-libmoon-compat.git`
3. `cd snabb-libmoon-compat`
4. `sudo path/to/libmoon main.lua echo 0`

## License
snabb-libmoon-compat is licensed unde the terms of the APACHE 2.0 License. All files taken and/or adapted from Snabb have been marked as such.

For more information see [my homepage](https://fabianbonk.de/snabb-libmoon-compat/).
