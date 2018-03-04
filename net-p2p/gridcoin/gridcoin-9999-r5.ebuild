# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit flag-o-matic
inherit user
inherit git-r3

DESCRIPTION="Gridcoin Proof-of-Stake based crypto-currency that rewards BOINC computation"
HOMEPAGE="https://gridcoin.us/"
EGIT_REPO_URI="https://github.com/gridcoin/Gridcoin-Research.git"
EGIT_BRANCH="development"

LICENSE="MIT"
SLOT="testnet"
KEYWORDS=""
IUSE="+boinc daemon dbus qrcode qt5 upnp"

DEPEND=">=dev-libs/boost-1.55.0
	>=dev-libs/openssl-1.0.1g
	sys-libs/db:4.8
	>=dev-libs/libzip-1.3.0
	dev-libs/libevent
	dbus? ( dev-qt/qtdbus:5 )
	qrcode? ( media-gfx/qrencode )
	qt5? ( dev-qt/qtcore:5 dev-qt/qtnetwork:5 dev-qt/qtconcurrent:5 dev-qt/qtcharts:5 )
	upnp? ( >=net-libs/miniupnpc-1.9.20140401 )
	boinc? ( sci-misc/boinc )"
RDEPEND="${DEPEND}"

S="${WORKDIR}/gridcoin-${PV}"

pkg_setup() {
	BDB_VER="$(best_version sys-libs/db)"
	export BDB_INCLUDE_PATH="/usr/include/db${BDB_VER:12:3}"

	enewgroup ${PN}
	local groups="${PN}"
	use boinc && groups+=",boinc"
	enewuser ${PN} -1 -1 /var/lib/${PN} "${groups}"
}

src_unpack() {
	git-r3_src_unpack
	mkdir -p "$(dirname "${S}")" || die
	ln -s "${WORKDIR}/${P}" "${S}" || die
}

src_prepare() {
	eapply_user
	./autogen.sh
}

src_configure() {
	econf \
		$(use_with daemon) \
		$(use_with dbus qtdbus) \
		$(use_with qt5 gui qt5) \
		$(use_with qrcode qrencode) \
		$(use_with upnp miniupnpc)
}

src_compile() {
	emake
}

src_install() {
	if use daemon ; then
		newbin src/gridcoinresearchd gridcoinresearchd-testnet
		newman doc/gridcoinresearchd.1 gridcoinresearchd-testnet.1
	fi
	if use qt5 ; then
		newbin src/qt/gridcoinresearch gridcoinresearch-testnet
		newman doc/gridcoinresearch.1 gridcoinresearch-testnet.1
	fi
	dodoc README.md CHANGELOG.md doc/build-unix.md

	diropts -o${PN} -g${PN}
	keepdir /var/lib/${PN}/.GridcoinResearch/testnet/
	newconfd "${FILESDIR}"/gridcoinresearch-testnet.conf gridcoinresearch-testnet
	fowners gridcoin:gridcoin /etc/conf.d/gridcoinresearch-testnet
	fperms 0660 /etc/conf.d/gridcoinresearch-testnet
	dosym ../../../../../etc/conf.d/gridcoinresearch-testnet /var/lib/${PN}/.GridcoinResearch/testnet/gridcoinresearch.conf
}

pkg_postinst() {
	elog
	elog "You are using a source compiled version of the gridcoin staging branch."
	ewarn "NB: This branch is only intended for debugging on the gridcoin testnet!"
	ewarn "    Only proceed if you know what you are doing."
	ewarn "    Testnet users must join Slack at https://teamgridcoin.slack.com #testnet"
	ewarn "    To request an invitation, ask in irc://chat.freenode.net/#gridcoin-testnet"
	elog
	use daemon && elog "The daemon can be found at /usr/bin/gridcoinresearchd-testnet"
	use qt5 && elog "The graphical wallet can be found at /usr/bin/gridcoinresearch-testnet"
	ewarn "Remember to run with the '-testnet' option."
	elog
	elog "You need to configure this node with a few basic details to do anything useful with gridcoin."
	elog "You can do this by editing /var/lib/${PN}/.GridcoinResearch/testnet/gridcoinresearch.conf"
	elog "The howto for this configuration file is located at:"
	elog "http://wiki.gridcoin.us/Gridcoinresearch_config_file"
	elog
	if use boinc ; then
		elog "To run your wallet as a researcher you should add gridcoin user to boinc group."
		elog "Run as root:"
		elog "gpasswd -a gridcoin boinc"
		elog
	fi
}
