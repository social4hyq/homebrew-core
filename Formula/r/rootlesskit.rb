class Rootlesskit < Formula
  desc "Linux-native \"fake root\" for implementing rootless containers"
  homepage "https://github.com/rootless-containers/rootlesskit"
  url "https://github.com/rootless-containers/rootlesskit/archive/refs/tags/v3.0.0.tar.gz"
  sha256 "2f934f30bcac3f659fd2662518a28e2e3ab6fa0f3362ba09ccc75ff7d504dc99"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "83a2287e50929c0c22e6712641599b875b4d1313c2f4273c8b81ee7f49030e01"
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
