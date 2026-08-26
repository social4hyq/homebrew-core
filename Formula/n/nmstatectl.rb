class Nmstatectl < Formula
  desc "Command-line tool that manages host networking settings in a declarative manner"
  homepage "https://nmstate.io/"
  url "https://github.com/nmstate/nmstate/releases/download/v2.2.62/nmstate-2.2.62.tar.gz"
  sha256 "37564cf14526037befcc919b72a715427ba3cb029e7d2de41f15b00268febc23"
  license "Apache-2.0"
  head "https://github.com/nmstate/nmstate.git", branch: "base"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "70aedb41060fc5b5b39c14e41d078058d5b2840f5ace452e030350b5efacec34"
  end

  depends_on "rust" => :build

  def install
    cd "rust" do
      if OS.mac?
        args = ["--no-default-features"]
        features = ["gen_conf"]
      end
      system "cargo", "install", *args, *std_cargo_args(path: "src/cli", features:)
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/nmstatectl --version")

    assert_match "interfaces: []", pipe_output("#{bin}/nmstatectl format", "{}", 0)
  end
end
