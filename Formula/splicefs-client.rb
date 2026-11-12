class SplicefsClient < Formula
  desc "SpliceFS client that mounts SpliceFS clusters"
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
    (etc/"splicefs/client").mkpath
  end

  def caveats
    <<~EOS
      The client does not start until it has a configuration. Create
        #{etc}/splicefs/client/config.yaml
      The configuration reference is at
        https://github.com/SpliceFS/client/blob/develop/docs/configuration.md

      On macOS the client mounts through the built-in NFS client. No extra software is
      needed, and it does not need root. Each mount target must be a folder you own,
      and it must exist before the client starts. Set cache.dir to a folder you own,
      for example #{var}/splicefs/cache, because the default /var/cache/splicefs is not
      writable by a normal user.

      Then start the client with:
        brew services start splicefs-client
      The log is #{var}/log/splicefs.log.
    EOS
  end

  service do
    run [opt_bin/"splicefs", "--config", etc/"splicefs/client", "mount"]
    keep_alive crashed: true
    log_path var/"log/splicefs.log"
    error_log_path var/"log/splicefs.log"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/splicefs --version")

    # An empty configuration folder must stop the program with a message about it.
    (testpath/"empty").mkpath
    output = shell_output("#{bin}/splicefs --config #{testpath}/empty mount 2>&1", 1)
    assert_match "read client config", output
  end
end
