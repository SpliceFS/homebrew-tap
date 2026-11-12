class SplicefsServer < Formula
  desc "Serves read-only folders in blocks so clients can read from several servers"
  homepage "https://splicefs.org"
  license "MIT"
  # Until the first release the formula builds from the develop branch. A release adds
  # three lines here: url, sha256 and version. Nothing else changes.
  head "https://github.com/SpliceFS/server.git", branch: "develop"

  depends_on "go" => :build
  depends_on arch: :arm64
  depends_on :macos

  def install
    ldflags = "-s -w -X github.com/SpliceFS/server/internal/version.version=#{version}"
    system "go", "build", *std_go_args(ldflags: ldflags, output: bin/"splicefsd"), "./cmd/splicefsd"
  end

  def caveats
    <<~EOS
      This installs the command splicefsd and nothing else. It is not set up as a
      background service; how and when it runs is up to you.

      Run it with:
        splicefsd --config DIR
      The documentation is at
        https://github.com/SpliceFS/server/blob/develop/docs/configuration.md
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/splicefsd --version")

    # An empty configuration folder must stop the program with a message about it.
    (testpath/"empty").mkpath
    output = shell_output("#{bin}/splicefsd --config #{testpath}/empty 2>&1", 1)
    assert_match "read server config", output
  end
end
