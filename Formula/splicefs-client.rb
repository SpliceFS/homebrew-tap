class SplicefsClient < Formula
  desc "Mounts a read-only folder whose files stream from several servers at once"
  homepage "https://splicefs.org"
  license "MIT"
  # Until the first release the formula builds from the develop branch. A release adds
  # three lines here: url, sha256 and version. Nothing else changes.
  head "https://github.com/SpliceFS/client.git", branch: "develop"

  depends_on "go" => :build
  depends_on arch: :arm64
  depends_on :macos

  def install
    ldflags = "-s -w -X github.com/SpliceFS/client/internal/version.version=#{version}"
    system "go", "build", *std_go_args(ldflags: ldflags, output: bin/"splicefs"), "./cmd/splicefs"
  end

  def caveats
    <<~EOS
      This installs the command splicefs and nothing else. It is not set up as a
      background service; how and when it runs is up to you.

      On macOS the client mounts through the built-in NFS client. No extra software is
      needed, and it does not need root.

      Run it with:
        splicefs --config DIR mount
      The documentation is at
        https://github.com/SpliceFS/client/blob/develop/docs/configuration.md
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/splicefs --version")

    # An empty configuration folder must stop the program with a message about it.
    (testpath/"empty").mkpath
    output = shell_output("#{bin}/splicefs --config #{testpath}/empty mount 2>&1", 1)
    assert_match "read client config", output
  end
end
