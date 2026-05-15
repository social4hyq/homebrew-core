class Gtrash < Formula
  desc "Featureful Trash CLI manager: alternative to rm and trash-cli"
  homepage "https://github.com/umlx5h/gtrash"
  url "https://github.com/umlx5h/gtrash/archive/refs/tags/v0.0.6.tar.gz"
  sha256 "66003276073d9da03cbb4347a4b161f89c81f3706012b77c3e91a154c91f3586"
  license "MIT"
  head "https://github.com/umlx5h/gtrash.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bfa86bc07bf9a8727d0247b0556441f4e26e5fd43ada791338c328cef104809d"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version} -X main.commit=#{tap.user} -X main.date=#{time.iso8601} -X main.builtBy=#{tap.user}"
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"gtrash", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gtrash --version")
    system bin/"gtrash", "summary"
  end
end
