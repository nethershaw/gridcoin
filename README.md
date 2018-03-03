gridcoin
========

A Gentoo GNU/Linux overlay containing ebuilds for the [Gridcoin-Research](https://github.com/gridcoin/Gridcoin-Research) project.

Upstream home page: https://gridcoin.us/

If you use this overlay, please give us a :star: so that we might how useful we're being.

## Adding with layman
```shell
layman -f -o https://raw.githubusercontent.com/nethershaw/gridcoin/master/repositories.xml -a gridcoin
```
## Retention of ebuilds
Upstream publishes two types of Gridcoin wallet software releases: _leisure_ and _mandatory_. Leisure releases are backward-compatible and may include minor improvements, whereas a mandatory release is not backward-compatible and invalidates all prior releases of the client.

From commit 0d42905f086b9ea99f5753354efd0010c2d95a44 onward, this repository will only retire ebuilds when upstream publishes a new mandatory release, at which time all ebuilds prior to the most recent mandatory release version shall be masked. Following Gentoo distribution convention, masked ebuilds shall be removed from the repository after 30 days.

## Testnet support
Gentoo uses version specifier `9999` to indicate _live_ ebuilds. The live ebuild in this repository checks out the upstream [developmment branch](https://github.com/gridcoin/Gridcoin-Research/tree/development) and installs a client suitable for use on the Gridcoin testnet in a distinct slot so that it may coexist with the main network client. This ebuild is masked (for good reason), but can be unmasked by adding the following to Portage's [ACCEPT_KEYWORDS](https://wiki.gentoo.org/wiki/ACCEPT_KEYWORDS):

```
# required by >=net-p2p/gridcoin-9999 (argument)
>=net-p2p/gridcoin-9999 **
```

:warning: **Important:** Note that the binaries installed by the live ebuild are _for development and testing use **only**_ and as such are installed with the suffix `-testnet` appended to their names. The user will be reminded to run the binary with its `-testnet` command-line option (yes, that's `gridcoinresearch-testnet -testnet`) after the ebuild is installed. A suitable testnet configuration file template is also provided in the appropriate path. Please _do not_ try to run the testnet client on the main network; testnet users are expected to join the #testnet channel on [TeamGridcoin Slack](https://teamgridcoin.slack.com).

## Maintenance
Issue reports and pull requests are welcome and encouraged. If you think you have identified a solution to an issue, please by all means do fork the repository and submit a PR without delay; there is no need to wait for permission. These ebuilds were originally written as a mere personal convenience, but they have apparently found usefulness elsewhere.

## Thanks
Whether simply using or contributing, thank you for crunching. :heart:
