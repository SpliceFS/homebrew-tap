class SplicefsServer < Formula
  desc "Serves read-only folders in blocks so clients can read from several servers"
  homepage "https://splicefs.org"
  # The two lines url and sha256 are rewritten by scripts/update-formulas.sh when a
  # program is released. Do not edit them by hand.
  url "https://github.com/SpliceFS/server/archive/refs/tags/v0.5.1.tar.gz"
  sha256 "87e538867d5dc6a30a50c4eea5d50416ba5e97196911eb076d19e1a4477012a4"
  license "MIT"
  head "https://github.com/SpliceFS/server.git", branch: "main"

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
        splicefsd
      Nothing has to be configured: it listens on port 8480 with TLS and a certificate
      it creates for itself. Settings and shares go in ~/.splicefs/server, and it keeps
      its data in ~/.splicefs/var/server. Check your files with:
        splicefsd config check
      The documentation is at
        https://github.com/SpliceFS/server/blob/main/docs/configuration.md
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/splicefsd --version")

    # An empty configuration folder is a valid configuration.
    (testpath/"empty").mkpath
    assert_match "ok", shell_output("#{bin}/splicefsd --config #{testpath}/empty config check")

    # A file with a key the program does not know must be refused, and named.
    (testpath/"bad/conf.d").mkpath
    (testpath/"bad/conf.d/10-typo.yaml").write "lissten: []\n"
    output = shell_output("#{bin}/splicefsd --config #{testpath}/bad config check 2>&1", 1)
    assert_match "10-typo.yaml", output
  end
end
