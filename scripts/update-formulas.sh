#!/bin/sh
# Points each formula at the newest release of its program: rewrites the url and sha256
# lines of Formula/splicefs-server.rb and Formula/splicefs-client.rb and nothing else.
# The update workflow runs it when a program is released.
#
# Environment:
#   FORMULA_DIR        folder of the formulas (default Formula)
#   UPDATE_TAG_server  use this release tag for the server instead of asking GitHub
#   UPDATE_TAG_client  the same for the client
#   UPDATE_FETCH       download command, called as: ${UPDATE_FETCH} <file> <url>
#                      (default: curl -fsSL --retry 3 -o)
# The two UPDATE_TAG variables and UPDATE_FETCH exist so that tests need no network.
set -eu

formula_dir="${FORMULA_DIR:-Formula}"
fetch="${UPDATE_FETCH:-curl -fsSL --retry 3 -o}"

# The temporary files are removed on every way out, so a failure never leaves a half
# written formula or a stray download behind.
workdir=""
formula_new=""
cleanup() {
	rm -f "${formula_new}"
	if [ -n "${workdir}" ]; then
		rm -rf "${workdir}"
	fi
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

die() {
	printf '%s: %s\n' "$0" "$*" >&2
	exit 1
}

latest_tag() {
	override=""
	case "$1" in
	server) override="${UPDATE_TAG_server:-}" ;;
	client) override="${UPDATE_TAG_client:-}" ;;
	*) die "unknown program: $1" ;;
	esac
	if [ -n "${override}" ]; then
		printf '%s\n' "${override}"
	else
		gh api "repos/SpliceFS/$1/releases/latest" --jq .tag_name
	fi
}

# GNU systems have sha256sum, macOS has shasum.
sha256_of() {
	if command -v sha256sum >/dev/null 2>&1; then
		sum_line="$(sha256sum "$1")"
	else
		sum_line="$(shasum -a 256 "$1")"
	fi
	printf '%s\n' "${sum_line%% *}"
}

update_formula() {
	repo="$1"
	formula="${formula_dir}/splicefs-${repo}.rb"

	if [ ! -f "${formula}" ]; then
		die "${formula} does not exist"
	fi

	# More than one such line would mean a layout this script does not understand, and
	# rewriting only some of them would leave the formula inconsistent.
	url_count="$(grep -c '^  url "' "${formula}")" || url_count=0
	sha_count="$(grep -c '^  sha256 "' "${formula}")" || sha_count=0
	if [ "${url_count}" != 1 ] || [ "${sha_count}" != 1 ]; then
		die "${formula} must have exactly one url line and one sha256 line"
	fi

	old_tag="$(sed -n 's|^  url ".*/\(v[0-9][0-9.]*\)\.tar\.gz"$|\1|p' "${formula}")"
	if [ -z "${old_tag}" ]; then
		die "cannot read the release tag from the url line of ${formula}"
	fi

	tag="$(latest_tag "${repo}")"
	if ! printf '%s\n' "${tag}" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$'; then
		die "release tag of ${repo} is '${tag}', expected something like v1.2.3"
	fi

	url="https://github.com/SpliceFS/${repo}/archive/refs/tags/${tag}.tar.gz"
	archive="${workdir}/${repo}.tar.gz"
	# The command is deliberately split into words here: it is a command with options.
	# shellcheck disable=SC2086
	${fetch} "${archive}" "${url}"
	sum="$(sha256_of "${archive}")"

	# Written next to the formula and renamed, so the rename is atomic and the formula
	# is either the old file or the complete new one. The copy keeps the file mode.
	formula_new="$(mktemp "${formula}.XXXXXX")"
	cp -p "${formula}" "${formula_new}"
	sed -e 's|^  url ".*"$|  url "'"${url}"'"|' \
		-e 's|^  sha256 ".*"$|  sha256 "'"${sum}"'"|' \
		"${formula}" >"${formula_new}"

	if cmp -s "${formula}" "${formula_new}"; then
		rm -f "${formula_new}"
		printf 'splicefs-%s: %s (unchanged)\n' "${repo}" "${tag}"
	else
		mv "${formula_new}" "${formula}"
		printf 'splicefs-%s: %s -> %s\n' "${repo}" "${old_tag}" "${tag}"
	fi
	formula_new=""
}

workdir="$(mktemp -d "${TMPDIR:-/tmp}/update-formulas.XXXXXX")"
for program in server client; do
	update_formula "${program}"
done
