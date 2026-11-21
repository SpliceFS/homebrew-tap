class SplicefsServer < Formula
  desc "Serves read-only folders in blocks so clients can read from several servers"
  homepage "https://splicefs.org"
  # The two lines url and sha256 are rewritten by scripts/update-formulas.sh when a
  # program is released. Do not edit them by hand.
  url "https://github.com/SpliceFS/server/archive/refs/tags/v0.9.0.tar.gz"
  sha256 "110382d27222a7051080eb0eaaad2dd72414771a87e015ede7b9258ca353796b"
  license "MIT"
  head "https://github.com/SpliceFS/server.git", branch: "main"

  depends_on "go" => :build
  depends_on arch: :arm64
  depends_on :macos

  # The server and its utility program, each built from the folder of the same name in cmd.
  PROGRAMS = %w[splicefsd splicefsdctl].freeze

  def install
    ldflags = "-s -w -X github.com/SpliceFS/server/internal/version.version=#{version}"
    PROGRAMS.each do |program|
      system "go", "build", *std_go_args(ldflags: ldflags, output: bin/program), "./cmd/#{program}"
    end
  end

  def caveats
    <<~EOS
      This installs the commands splicefsd and splicefsdctl and nothing else. They are not
      set up as a background service; how and when they run is up to you.

      Run it with:
        splicefsd
      Nothing has to be configured: it listens on port 8480 with TLS and a certificate
      it creates for itself. Settings and shares go in ~/.splicefs/server, and it keeps
      its data in ~/.splicefs/var/server. Check your files with:
        splicefsd config check
      splicefsdctl is the utility program for jobs you run by hand, like hash-password.
      The documentation is at
        https://github.com/SpliceFS/server/blob/main/docs/configuration.md
    EOS
  end

  test do
    PROGRAMS.each do |program|
      assert_match version.to_s, shell_output("#{bin}/#{program} --version")
    end

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
