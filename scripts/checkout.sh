#!/usr/bin/env sh

#   Copyright 2018-2022 Docker Inc.

#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

checkout() (
	set -ex
	SRC="$1"
	REF="$2"
	REF_FETCH="$REF"

	# git ls-remote's <pattern> argument [1] is a glob [2], and matches anything
	# ending with the given string. This is problematic if multiple tags or
	# branches end with the given pattern. In containerd's case, this returns
	# both tags for the main module ("refs/tags/v1.7.19") and 	# the API module
	# ("refs/tags/api/v1.7.19").
	#
	# To prevent both of those being found, we check if the given reference starts
	# with a "v"; if it does, we can assume it's a tag, and prefix the pattern with
	# "refs/tags/" to make it less ambiguous.
	#
	# We're using a case statement here to avoid introducing Bashisms.
	#
	# [1]: https://git-scm.com/docs/git-ls-remote#Documentation/git-ls-remote.txt-ltpatternsgt82308203
	# [2]: https://git-scm.com/docs/gitglossary#Documentation/gitglossary.txt-glob
	ref_glob="$REF"
	case $ref_glob in
	"v"*)
		ref_glob="refs/tags/$ref_glob"
		;;
	esac

	# if ref is branch or tag, retrieve its canonical form
	REF=$(git -C "$SRC" ls-remote --refs --heads --tags origin "$ref_glob" | awk '{print $2}')
	if [ -n "$REF" ]; then
		# if branch or tag then create it locally too
		REF_FETCH="$REF:$REF"
	else
		REF="FETCH_HEAD"
	fi
	git -C "$SRC" fetch --update-head-ok --depth 1 origin "$REF_FETCH"
	git -C "$SRC" checkout -q "$REF"
)

# Only execute checkout function above if this file is executed, not sourced from another script
prog=checkout.sh # needs to be in sync with this file's name
if [ "$(basename -- $0)" = "$prog" ]; then
	checkout $*
fi
