class Redress < Formula
  desc "Tool for analyzing stripped Go binaries compiled with the Go compiler"
  homepage "https://github.com/goretk/redress"
  url "https://github.com/goretk/redress/archive/refs/tags/v1.2.80.tar.gz"
  sha256 "2260de8c6d451ae176701a8d56df6d605eadc1d131223acecfc17d9f0e7c5e4b"
  license "AGPL-3.0-only"
  head "https://github.com/goretk/redress.git", branch: "develop"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1b0b08d6dd2295928a61c521ddc98f2e18ccc75795d134dbd878066f1448217b"
  end

  depends_on "go" => :build

  def install
    # https://github.com/goretk/redress/blob/develop/Makefile#L11-L14
    gore_version = File.read(buildpath/"go.mod").scan(%r{goretk/gore v(\S+)}).flatten.first

    ldflags = %W[
      -s -w
      -X main.redressVersion=#{version}
      -X main.goreVersion=#{gore_version}
      -X main.compilerVersion=#{Formula["go"].version}
    ]

    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"redress", shell_parameter_format: :cobra)
  end

  test do
    assert_match "Version:  #{version}", shell_output("#{bin}/redress version")

    test_bin_path = bin/"redress"
    output = shell_output("#{bin}/redress info '#{test_bin_path}'")
    assert_match "Build ID", output
  end
end
