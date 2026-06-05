class Codesnap < Formula
  desc "Generates code snapshots in various formats"
  homepage "https://github.com/codesnap-rs/codesnap"
  url "https://github.com/codesnap-rs/codesnap/archive/refs/tags/v0.13.4.tar.gz"
  sha256 "47a249efd507c0e1dcd8122da1d263b2bf00dcedfa27eed976a02909cefe0725"
  license "MIT"
  head "https://github.com/codesnap-rs/codesnap.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "228d1d05d3a16175e430336647ecfa9a99643383554af4810d6cafeb1bf11e1c"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
  end

  def install
    system "cargo", "install", *std_cargo_args(path: "cli")

    pkgshare.install "cli/examples"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/codesnap --version")
    assert_match "SUCCESS", shell_output("#{bin}/codesnap -f #{pkgshare}/examples/cli.sh -o cli.png")
  end
end
