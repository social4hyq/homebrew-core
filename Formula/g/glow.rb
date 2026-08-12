class Glow < Formula
  desc "Render markdown on the CLI"
  homepage "https://github.com/charmbracelet/glow"
  url "https://github.com/charmbracelet/glow/archive/refs/tags/v3.0.0.tar.gz"
  sha256 "18df6f3c09157021366b8c702b5badba405d37dbb42f132353eb50c1b0d3f464"
  license "MIT"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6ffdf326f03c13d8caeebc20173bf85c11630f769850501d9680c53b2ebb40f2"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.Version=#{version}")

    generate_completions_from_executable(bin/"glow", shell_parameter_format: :cobra)
  end

  test do
    test_file = testpath/"test.md"
    test_file.write <<~EOS
      # header

      **bold**

      ```
      code
      ```
    EOS

    # failed with Linux CI run, but works with local run
    # https://github.com/charmbracelet/glow/issues/454
    if OS.linux?
      system bin/"glow", test_file
    else
      assert_match "# header", shell_output("#{bin}/glow #{test_file}")
    end
  end
end
