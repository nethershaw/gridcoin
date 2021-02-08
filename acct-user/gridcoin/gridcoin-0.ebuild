# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit acct-user

DESCRIPTION="User for the gridcoin daemon"
IUSE="boinc"
ACCT_USER_ID=-1
ACCT_USER_GROUPS=( "${PN}" )
ACCT_USER_HOME="/var/lib/${PN}"

acct-user_add_deps

pkg_setup() {
	local groups=("${PN}")
	use boinc && groups+=( "boinc" )
	ACCT_USER_GROUPS=("${groups[@]}")
}
