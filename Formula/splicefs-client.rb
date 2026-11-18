class SplicefsClient < Formula
  desc "Mounts a read-only folder whose files stream from several servers at once"
  homepage "https://splicefs.org"
  # The two lines url and sha256 are rewritten by scripts/update-formulas.sh when a
  # program is released. Do not edit them by hand.
  url "https://github.com/SpliceFS/client/archive/refs/tags/v0.5.41.tar.gz"
  sha256 "e7deb6eba977c12c4a139f8038a4b6568917f13e72ba9645c6623b101345ef79"
  license "MIT"
  head "https://github.com/SpliceFS/client.git", branch: "main"

  depends_on "go" => :build
  depends_on arch: :arm64
  depends_on :macos

  # The client and its utility program, each built from the folder of the same name in cmd.
  PROGRAMS = %w[splicefs splicefsctl].freeze

  def install
    ldflags = "-s -w -X github.com/SpliceFS/client/internal/version.version=#{version}"
    PROGRAMS.each do |program|
      system "go", "build", *std_go_args(ldflags: ldflags, output: bin/program), "./cmd/#{program}"
    end
  end

  def caveats
    <<~EOS
      This installs the commands splicefs and splicefsctl and nothing else. They are not
      set up as a background service; how and when they run is up to you.

      On macOS the client mounts through the built-in NFS client. No extra software is
      needed, and it does not need root.

      Run it with:
        splicefs mount
      It keeps running, with or without mounts, until you stop it. Clusters and mounts
      are files in ~/.splicefs/client (clusters.d and mounts.d); after a change, send
      the running program SIGHUP. Check your files with:
        splicefs config check
      splicefsctl is the utility program: it unmounts and shows the client's status.
      The documentation is at
        https://github.com/SpliceFS/client/blob/main/docs/configuration.md
    EOS
  end

  test do
    PROGRAMS.each do |program|
      assert_match version.to_s, shell_output("#{bin}/#{program} --version")
    end

    # An empty configuration folder is a valid configuration.
    (testpath/"empty").mkpath
    assert_match "ok", shell_output("#{bin}/splicefs --config #{testpath}/empty config check")

    # A mount that names a cluster nobody defined must be refused, and its file named.
    (testpath/"bad/mounts.d").mkpath
    (testpath/"bad/mounts.d/media.yaml").write "cluster: nowhere\ntarget: /tmp/media\n"
    output = shell_output("#{bin}/splicefs --config #{testpath}/bad config check 2>&1", 1)
    assert_match "mounts.d/media.yaml", output
  end
end
