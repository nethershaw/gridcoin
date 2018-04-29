# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit flag-o-matic qmake-utils user git-r3 systemd

DESCRIPTION="Gridcoin Proof-of-Stake based crypto-currency that rewards BOINC computation"
HOMEPAGE="https://gridcoin.us/"
EGIT_REPO_URI="https://github.com/gridcoin/Gridcoin-Research.git"
EGIT_COMMIT="${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE_GUI="qt5 dbus"
IUSE_DAEMON="daemon"
IUSE_OPTIONAL="+boinc qrcode upnp"
IUSE="${IUSE_GUI} ${IUSE_DAEMON} ${IUSE_OPTIONAL}"

REQUIRED_USE="|| ( daemon qt5 ) dbus? ( qt5 ) qrcode? ( qt5 )"

RDEPEND=">=dev-libs/boost-1.55.0
	>=dev-libs/openssl-1.0.1g
	>=dev-libs/libzip-1.3.0
	dev-libs/libevent
	sys-libs/db:5.3[cxx]
	dbus? ( dev-qt/qtdbus:5 )
	qt5? ( dev-qt/qtcore:5 dev-qt/qtnetwork:5 dev-qt/qtconcurrent:5 dev-qt/qtcharts:5 )
	qrcode? ( media-gfx/qrencode )
	upnp? ( >=net-libs/miniupnpc-1.9.20140401 )
	boinc? ( sci-misc/boinc )"
DEPEND="${DEPEND}
	qt5? ( dev-qt/linguist-tools:5 )"

S="${WORKDIR}/gridcoin-${PV}"

pkg_setup() {
	BDB_VER="$(best_version sys-libs/db:5.3)"
	export BDB_INCLUDE_PATH="/usr/include/db${BDB_VER:12:3}"
	export BDB_LIB_SUFFIX="-${BDB_VER:12:3}"
	use upnp || BUILDOPTS+="USE_UPNP=- "
	use upnp && BUILDOPTS+="USE_UPNP=1 "
	use dbus || BUILDOPTS+="USE_DBUS=- "
	use dbus && BUILDOPTS+="USE_DBUS=1 "
	use qrcode && BUILDOPTS+="USE_QRCODE=1 "

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

src_compile() {
	append-flags -Wa,--noexecstack
	append-flags "-I${BDB_INCLUDE_PATH}"
	if use daemon ; then
		cd "${S}/src" ; mkdir -p obj
		emake -f makefile.unix ${BUILDOPTS} NO_UPGRADE=1
	fi
	if use qt5 ; then
		cd "${S}" ; eqmake5 ${BUILDOPTS} BDB_LIB_SUFFIX=${BDB_LIB_SUFFIX} NO_UPGRADE=1
		emake
	fi
}

src_install() {
	if use daemon ; then
		dobin src/gridcoinresearchd
		doman doc/gridcoinresearchd.1
		newinitd "${FILESDIR}"/gridcoin.init gridcoin
		systemd_dounit "${FILESDIR}"/gridcoin.service
	fi
	if use qt5 ; then
		dobin gridcoinresearch
		doman doc/gridcoinresearch.1
	fi
	dodoc README.md CHANGELOG.md INSTALL CompilingGridcoinOnLinux.txt

	diropts -o${PN} -g${PN}
	keepdir /var/lib/${PN}/.GridcoinResearch/
	newconfd "${FILESDIR}"/gridcoinresearch.conf gridcoinresearch
	fowners gridcoin:gridcoin /etc/conf.d/gridcoinresearch
	fperms 0660 /etc/conf.d/gridcoinresearch
	dosym ../../../../etc/conf.d/gridcoinresearch /var/lib/${PN}/.GridcoinResearch/gridcoinresearch.conf
}

pkg_postinst() {
	elog
	elog "You are using a source compiled version of gridcoin."
	elog "The daemon can be found at /usr/bin/gridcoinresearchd"
	use qt5 && elog "The graphical wallet can be found at /usr/bin/gridcoinresearch"
	elog
	elog "You need to configure this node with a few basic details to do anything"
	elog "useful with gridcoin. The wallet configuration file is located at:"
	elog "    /etc/conf.d/gridcoinresearch"
	elog "The wiki for this configuration file is located at:"
	elog "    http://wiki.gridcoin.us/Gridcoinresearch_config_file"
	elog
	if use boinc ; then
		elog "To run your wallet as a researcher you should add gridcoin user to boinc group."
		elog "Run as root:"
		elog "gpasswd -a gridcoin boinc"
		elog
	fi
	ewarn "Previous releases of this package may have built/linked inconsistently"
	ewarn "against Berkeley DB headers/libraries! If you already had sys-libs/db:6.0"
	ewarn "available with a prior installation of this package, Gridcoin may prompt"
	ewarn "you to clear your blockchain and peer databases. Be advised that official"
	ewarn "snapshots of the blockchain are available to speed up wallet syncing at:"
	ewarn "https://download.gridcoin.us/download/downloadstake/signed/snapshot.zip"
}
