# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit flag-o-matic
inherit qmake-utils
inherit user

DESCRIPTION="Gridcoin Proof-of-Stake based crypto-currency that rewards BOINC computation"
HOMEPAGE="https://gridcoin.us/"
SRC_URI="https://github.com/${PN}/Gridcoin-Research/archive/development.tar.gz"

RESTRICT="mirror"

LICENSE="MIT"
SLOT="testnet"
KEYWORDS=""
IUSE="+boinc dbus pie qrcode qt5 upnp"

DEPEND=">=dev-libs/boost-1.55.0
	>=dev-libs/openssl-1.0.1g
	>=sys-libs/db-5.3.28:*
	dbus? ( dev-qt/qtdbus:5 )
	qrcode? ( media-gfx/qrencode )
	qt5? ( dev-qt/qtcore:5 dev-qt/qtnetwork:5 dev-qt/qtconcurrent:5 )
	upnp? ( >=net-libs/miniupnpc-1.9.20140401 )
	boinc? ( sci-misc/boinc )"
RDEPEND="${DEPEND}"

S="${WORKDIR}/Gridcoin-Research-development"

pkg_pretend() {
	if use pie ; then
		host-is-pax || die "PIE enabled in USE but host not PAX capable! Select a hardened profile."
	fi
}

pkg_setup() {
	BDB_VER="$(best_version sys-libs/db)"
	export BDB_INCLUDE_PATH="/usr/include/db${BDB_VER:12:3}"
	use upnp || BUILDOPTS+="USE_UPNP=- "
	use upnp && BUILDOPTS+="USE_UPNP=1 "
	use qrcode && BUILDOPTS+="USE_QRCODE=1 "
	use pie	&& host-is-pax && BUILDOPTS+="-e PIE=1 "

	enewgroup ${PN}
	local groups="${PN}"
	use boinc && groups+=",boinc"
	enewuser ${PN} -1 /bin/bash /var/lib/${PN} "${groups}"
}

src_unpack() {
	unpack ${A}
	cd "${S}"
	if use qt5 ; then
		epatch "${FILESDIR}/${P}-pr414-appendflags.patch"
	fi
}

src_compile() {
	append-flags -Wa,--noexecstack
	if use qt5 ; then
		append-flags "-I${BDB_INCLUDE_PATH}"
		eqmake5 ${BUILDOPTS} NO_UPGRADE=1
		emake
	fi
	cd "${S}/src" ; mkdir -p obj
	emake -f makefile.unix ${BUILDOPTS} NO_UPGRADE=1
}

src_install() {
	newbin src/gridcoinresearchd gridcoinresearchd-testnet
	newman doc/gridcoinresearchd.1 gridcoinresearchd-testnet.1
	if use qt5 ; then
		newbin gridcoinresearch gridcoinresearch-testnet
		newman doc/gridcoinresearch.1 gridcoinresearch-testnet.1
	fi
	dodoc README.md CHANGELOG.md INSTALL CompilingGridcoinOnLinux.txt

	diropts -o${PN} -g${PN}
	keepdir /var/lib/${PN}/.GridcoinResearch/testnet/
	insinto /var/lib/${PN}/.GridcoinResearch/testnet/
	insopts -o${PN} -g${PN} -m0600
	newins "${FILESDIR}"/gridcoinresearch-testnet.conf gridcoinresearch.conf
}

pkg_postinst() {
	elog
	elog "You are using a source compiled version of the gridcoin development branch."
	ewarn "NB: This branch is only intended for debugging on the gridcoin testnet!"
	ewarn "    Only proceed if you know what you are doing."
	elog
	elog "The daemon can be found at /usr/bin/gridcoinresearchd-testnet"
	use qt5 && elog "The graphical manager can be found at /usr/bin/gridcoinresearch-testnet"
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
