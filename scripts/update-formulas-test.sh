#!/bin/sh
# Tests scripts/update-formulas.sh without a network: the release tags come from
# UPDATE_TAG_* and the download is a small script that writes fixed bytes. The formulas
# are built from text in this file, so the test does not depend on the real ones.
set -eu

script_path="$0"
script_folder="$(dirname "${script_path}")"
update="$(cd "${script_folder}" && pwd)/update-formulas.sh"

work="$(mktemp -d "${TMPDIR:-/tmp}/update-formulas-test.XXXXXX")"
trap 'rm -rf "${work}"' EXIT
trap 'exit 1' HUP INT TERM

# The SHA-256 of the bytes that fetch.sh writes ("fixed bytes" and a newline). It is
# written down here, not computed, so the test checks the script against a known value.
fixed_sum="a566f1ad9e9223d8a7967ead3f05534789c2a1bd23fe1714416e2f0a99e77f4e"
old_sum="0000000000000000000000000000000000000000000000000000000000000000"

fail() {
	printf 'FAIL: %s\n' "$*" >&2
	exit 1
}

# A fetch command that behaves like curl -o: it writes the fixed bytes to the file and
# records the address it was asked for.
fetch_log="${work}/fetch.log"
cat >"${work}/fetch.sh" <<'FETCH'
#!/bin/sh
printf 'fixed bytes\n' >"$1"
printf '%s\n' "$2" >>"${FETCH_LOG}"
FETCH
export FETCH_LOG="${fetch_log}"

# A download that fails after it wrote part of the file, as curl can. The script must not
# take the checksum of the partial file.
cat >"${work}/fetch-broken.sh" <<'BROKEN'
#!/bin/sh
printf 'partial' >"$1"
exit 1
BROKEN

# write_formula <file> <program> <tag> <sha256>
write_formula() {
	cat >"$1" <<FORMULA
class Example < Formula
  desc "Example program $2"
  homepage "https://example.com"
  url "https://github.com/SpliceFS/$2/archive/refs/tags/$3.tar.gz"
  sha256 "$4"
  license "MIT"
  head "https://github.com/SpliceFS/$2.git", branch: "main"

  depends_on "go" => :build

  def install
    system "go", "build", "./cmd/$2"
  end
end
FORMULA
}

# new_case <name> <server tag> <server sha> <client tag> <client sha>
# Makes the folder work/<name>/Formula with both formulas and prints nothing.
new_case() {
	mkdir -p "${work}/$1/Formula"
	write_formula "${work}/$1/Formula/splicefs-server.rb" server "$2" "$3"
	write_formula "${work}/$1/Formula/splicefs-client.rb" client "$4" "$5"
	cp -R "${work}/$1/Formula" "${work}/$1/before"
	: >"${fetch_log}"
}

# run_update <case> <fetch command> <server tag> <client tag>
# Runs the script on work/<case>/Formula. Leaves the exit status in ${status}, the
# output in work/<case>/out and work/<case>/err.
run_update() {
	status=0
	env FORMULA_DIR="${work}/$1/Formula" UPDATE_FETCH="$2" \
		UPDATE_TAG_server="$3" UPDATE_TAG_client="$4" \
		sh "${update}" >"${work}/$1/out" 2>"${work}/$1/err" || status=$?
}

assert_status() {
	if [ "${status}" != "$1" ]; then
		err_text="$(cat "${work}/$3/err")"
		fail "$2: exit status ${status}, expected $1: ${err_text}"
	fi
}

assert_same() {
	if ! diff "$1" "$2"; then
		fail "$3: files differ"
	fi
}

assert_untouched() {
	assert_same "${work}/$1/before/splicefs-server.rb" "${work}/$1/Formula/splicefs-server.rb" "$1 server"
	assert_same "${work}/$1/before/splicefs-client.rb" "${work}/$1/Formula/splicefs-client.rb" "$1 client"
}

# Nothing but the formulas may be left in the folder (no temporary files).
assert_only_formulas() {
	ls -A "${work}/$1/Formula" >"${work}/$1/listing"
	printf 'splicefs-client.rb\nsplicefs-server.rb\n' >"${work}/$1/expected-listing"
	assert_same "${work}/$1/expected-listing" "${work}/$1/listing" "$1 folder listing"
}

fetch="sh ${work}/fetch.sh"

# A new version rewrites the url and sha256 lines of both formulas and nothing else.
new_case newer v0.5.0 "${old_sum}" v0.4.0 "${old_sum}"
run_update newer "${fetch}" v0.5.1 v0.4.1
assert_status 0 "new version" newer
write_formula "${work}/newer/server.expected" server v0.5.1 "${fixed_sum}"
write_formula "${work}/newer/client.expected" client v0.4.1 "${fixed_sum}"
assert_same "${work}/newer/server.expected" "${work}/newer/Formula/splicefs-server.rb" "new version server"
assert_same "${work}/newer/client.expected" "${work}/newer/Formula/splicefs-client.rb" "new version client"
printf 'splicefs-server: v0.5.0 -> v0.5.1\nsplicefs-client: v0.4.0 -> v0.4.1\n' >"${work}/newer/expected-out"
assert_same "${work}/newer/expected-out" "${work}/newer/out" "new version output"
printf '%s\n%s\n' \
	"https://github.com/SpliceFS/server/archive/refs/tags/v0.5.1.tar.gz" \
	"https://github.com/SpliceFS/client/archive/refs/tags/v0.4.1.tar.gz" >"${work}/newer/expected-fetch"
assert_same "${work}/newer/expected-fetch" "${fetch_log}" "new version download addresses"
assert_only_formulas newer

# The same version changes nothing and says so.
new_case same v0.5.1 "${fixed_sum}" v0.4.1 "${fixed_sum}"
run_update same "${fetch}" v0.5.1 v0.4.1
assert_status 0 "same version" same
assert_untouched same
printf 'splicefs-server: v0.5.1 (unchanged)\nsplicefs-client: v0.4.1 (unchanged)\n' >"${work}/same/expected-out"
assert_same "${work}/same/expected-out" "${work}/same/out" "same version output"
assert_only_formulas same

# A tag that is not vMAJOR.MINOR.PATCH fails, names the tag and changes nothing.
for bad in 0.5.1 v0.5 v0.5.1-rc1 v0.5.1.2 latest; do
	new_case badtag v0.5.0 "${old_sum}" v0.4.0 "${old_sum}"
	run_update badtag "${fetch}" "${bad}" v0.4.1
	assert_status 1 "bad tag ${bad}" badtag
	if ! grep -q "'${bad}'" "${work}/badtag/err"; then
		err_text="$(cat "${work}/badtag/err")"
		fail "bad tag ${bad}: the message does not name the tag: ${err_text}"
	fi
	assert_untouched badtag
	assert_only_formulas badtag
done

# A formula without exactly one url line and one sha256 line fails and is left as it was.
for damage in '/^  url /d' '/^  sha256 /d' '/^  url /p'; do
	new_case damaged v0.5.0 "${old_sum}" v0.4.0 "${old_sum}"
	sed -e "${damage}" "${work}/damaged/before/splicefs-server.rb" >"${work}/damaged/Formula/splicefs-server.rb"
	cp "${work}/damaged/Formula/splicefs-server.rb" "${work}/damaged/before/splicefs-server.rb"
	run_update damaged "${fetch}" v0.5.1 v0.4.1
	assert_status 1 "damaged formula (${damage})" damaged
	if ! grep -q "exactly one url line" "${work}/damaged/err"; then
		err_text="$(cat "${work}/damaged/err")"
		fail "damaged formula (${damage}): unexpected message: ${err_text}"
	fi
	assert_untouched damaged
	assert_only_formulas damaged
done

# A failed download fails and leaves both formulas as they were.
new_case nodownload v0.5.0 "${old_sum}" v0.4.0 "${old_sum}"
run_update nodownload "sh ${work}/fetch-broken.sh" v0.5.1 v0.4.1
assert_status 1 "failed download" nodownload
assert_untouched nodownload
assert_only_formulas nodownload

printf 'ok: all update-formulas tests passed\n'
