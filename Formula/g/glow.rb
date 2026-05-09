class Glow < Formula
  desc "Render markdown on the CLI"
  homepage "https://github.com/charmbracelet/glow"
  url "https://github.com/charmbracelet/glow/archive/refs/tags/v2.1.2.tar.gz"
  sha256 "1b933139da1d08647bf5b3f112cab9548fdc2b40c056c7fa3d84d8706de5265a"
  license "MIT"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ac1040b2e1851988db3a8144349510afba9d82b97be3f18eb30aef09860c0f91"
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
