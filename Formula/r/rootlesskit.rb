class Rootlesskit < Formula
  desc "Linux-native \"fake root\" for implementing rootless containers"
  homepage "https://github.com/rootless-containers/rootlesskit"
  url "https://github.com/rootless-containers/rootlesskit/archive/refs/tags/v3.1.0.tar.gz"
  sha256 "71213cea8077681cb4c1894929b99942c11c525d09bd90f6246b5d3343ff1648"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9b1941e83f90fcaae857cdd752b39e26ae3b6cfb63f9fcc25403d59b00b0531b"
  end

  depends_on "go" => :build
  depends_on :linux

  def install
    ldflags = "-s -w"
    system "go", "build", *std_go_args(ldflags:), "./cmd/rootlesskit"
    system "go", "build", *std_go_args(ldflags:, output: bin/"rootlessctl"), "./cmd/rootlessctl"
    # cmd/rootlesskit-docker-proxy is not installed here, because it has been deprecated
    # since the feature was merged into Docker v28.
    doc.install Dir["docs/*"]
  end

  def caveats
    <<~EOS
      Depending on the kernel configuration, you may need to add the following line to
      /etc/sysctl.d/99-rootless.conf, and run `sysctl -a`:
        kernel.apparmor_restrict_unprivileged_userns = 0
    EOS
  end

  test do
    assert_match "specify --socket or set $ROOTLESSKIT_STATE_DIR", shell_output("#{bin}/rootlessctl info 2>&1", 1)
  end
end
