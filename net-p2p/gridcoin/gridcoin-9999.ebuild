# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit flag-o-matic
inherit qmake-utils

DESCRIPTION="Gridcoin Proof-of-Stake based crypto-currency that rewards BOINC computation"
HOMEPAGE="https://gridcoin.us/"
SRC_URI="https://github.com/${PN}/Gridcoin-Research/archive/development.tar.gz"

LICENSE="MIT"
SLOT="testnet"
KEYWORDS=""
IUSE="dbus pie qrcode qt5 upnp"

DEPEND=">=dev-libs/boost-1.55.0
	>=dev-libs/openssl-1.0.1g
	>=sys-libs/db-5.3.28:*
	dbus? ( sys-apps/dbus )
	qrcode? ( media-gfx/qrencode )
	qt5? ( dev-qt/qtcore:5 dev-qt/qtnetwork:5 dev-qt/qtconcurrent:5 )
	upnp? ( >=net-libs/miniupnpc-1.9.20140401 )"
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
}

src_unpack() {
	unpack ${A}
	cd "${S}"
	use qt5 && epatch "${FILESDIR}/${P}-qmake-cxxflags-lflags.patch"
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
	newbin src/gridcoinresearchd gridcoind-testnet
	use qt5 && newbin gridcoinresearch gridcoin-qt-testnet
	newman doc/gridcoinresearchd.1 gridcoind-testnet.1
	use qt5 && newman doc/gridcoinresearch.1 gridcoin-qt-testnet.1
	dodoc README.md CHANGELOG.md INSTALL CompilingGridcoinOnLinux.txt
}
