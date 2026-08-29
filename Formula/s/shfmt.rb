class Shfmt < Formula
  desc "Autoformat shell script source code"
  homepage "https://github.com/mvdan/sh"
  url "https://github.com/mvdan/sh/archive/refs/tags/v3.14.0.tar.gz"
  sha256 "f193c946e2882c4fa04935cd583f60e2cab60344209bd982a3a5933c4192aad8"
  license "BSD-3-Clause"
  head "https://github.com/mvdan/sh.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1dc2b93bf7d72916ea7f943ad518b23e8d60ab405df840145db621c494549925"
  end

  depends_on "go" => :build
  depends_on "scdoc" => :build

  def install
    ENV["CGO_ENABLED"] = "0"
    ldflags = "-s -w -extldflags=-static"
    inreplace "cmd/shfmt/main.go", "version = mod.Version", "version = \"#{version}\""
    system "go", "build", *std_go_args(ldflags:), "./cmd/shfmt"
    man1.mkpath
    system "scdoc < ./cmd/shfmt/shfmt.1.scd > #{man1}/shfmt.1"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/shfmt --version")

    (testpath/"test").write "\t\techo foo"
    system bin/"shfmt", testpath/"test"
  end
end
