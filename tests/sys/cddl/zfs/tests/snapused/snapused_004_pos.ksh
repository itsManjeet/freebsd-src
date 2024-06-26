#!/usr/local/bin/ksh93 -p
#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#

#
# Copyright 2009 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.

. $STF_SUITE/include/libtest.kshlib
. $STF_SUITE/tests/snapused/snapused.kshlib

#################################################################################
#
# __stc_assertion_start
#
# ID: snapused_004_pos
#
# DESCRIPTION:
#	Verify usedbyrefreservation is correct.
#
# STRATEGY:
#	1. Create a filesystem.
#	2. Set refreservation of the filesystem.
#	3. Make file in the filesystem.
#	4. Create sub filesystem and make file in it.
#	5. Set refreservation of the sub filesystem.
#	6. Create volume under it.
#	7. Snapshot it.
#	8. Clone it and set refreservation of the cloned filesystem.
#	9. Makefile the cloned filesystem.
#	10. Check usedbyrefreservation is correct.
#
# TESTABILITY: explicit
#
# TEST_AUTOMATION_LEVEL: automated
#
# CODING_STATUS: COMPLETED (2009-04-28)
#
# __stc_assertion_end
#
################################################################################

if ! usedby_supported ; then
	log_unsupported "snapused property is not supported."
fi

verify_runnable "both"

function cleanup
{
	log_must $ZFS destroy -rR $USEDTEST
}

log_assert "Verify usedbyrefreservation is correct."
log_onexit cleanup

log_must $ZFS create $USEDTEST
check_usedbyrefreservation $USEDTEST

typeset -i i=0
typeset -i r_size=0
mntpnt=$(get_prop mountpoint $USEDTEST)
while (( i < 5 )); do
	((r_size=(i+1)*16))
	log_must $ZFS set refreservation="$r_size"M $USEDTEST

	log_must $MKFILE 16M $mntpnt/file$i

	log_must $ZFS create $USEDTEST/fs$i
	log_must $ZFS set refreservation="$r_size"M $USEDTEST/fs$i
	log_must $MKFILE 16M $mntpnt/fs$i/file$i

	if is_global_zone; then
		log_must $ZFS create -V 16M $USEDTEST/vol$i
	fi

	log_must $ZFS snapshot -r $USEDTEST@snap$i

	log_must $ZFS clone $USEDTEST@snap$i $USEDTEST/cln$i

	mntpnt_cln=$(get_prop mountpoint $USEDTEST/cln$i)
	log_must $ZFS set refreservation="$r_size"M $USEDTEST/cln$i
	log_must $MKFILE 16M $mntpnt_cln/file_cln$i

	check_usedbyrefreservation $USEDTEST

        ((i = i + 1))
done

log_pass "Verify usedbyrefreservation is correct."

