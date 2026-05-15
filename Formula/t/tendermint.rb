class Tendermint < Formula
  desc "BFT state machine replication for applications in any programming languages"
  homepage "https://tendermint.com/"
  url "https://github.com/tendermint/tendermint/archive/refs/tags/v0.35.9.tar.gz"
  sha256 "8385fb075e81d4d4875573fdbc5f2448372ea9eaebc1b18421d6fb497798774b"
  license "Apache-2.0"
  head "https://github.com/tendermint/tendermint.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0257eac608a9e0eea0de204f21c4628c31118fa230e1438c8b822159a276c4e2"
  end

  depends_on "go" => :build

  def install
    system "make", "build", "VERSION=#{version}"
    bin.install "build/tendermint"

    generate_completions_from_executable(bin/"tendermint", "completion",
                                         shells: [:bash], shell_parameter_format: :none)
    generate_completions_from_executable(bin/"tendermint", "completion", "--zsh",
                                         shells: [:zsh], shell_parameter_format: :none)
  end

  test do
    mkdir(testpath/"staging")
    shell_output("#{bin}/tendermint init full --home #{testpath}/staging")
    assert_path_exists testpath/"staging/config/genesis.json"
    assert_path_exists testpath/"staging/config/config.toml"
    assert_path_exists testpath/"staging/data"
  end
end
