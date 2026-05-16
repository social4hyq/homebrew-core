class Aliae < Formula
  desc "Cross shell and platform alias management"
  homepage "https://aliae.dev"
  url "https://github.com/jandedobbeleer/aliae/archive/refs/tags/v0.26.6.tar.gz"
  sha256 "905602b3dd56b6caf099970132edf7e3366b3ef0d98a71b277e23c00990e979d"
  license "MIT"
  head "https://github.com/jandedobbeleer/aliae.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b585c7d5a78a45f9bee240eed805f331fc4cf4c3db9f3b7b175d3a9ca81d795a"
  end

  depends_on "go" => :build

  def install
    cd "src" do
      ldflags = "-s -w -X main.Version=#{version}"
      system "go", "build", *std_go_args(ldflags:)
    end

    generate_completions_from_executable(bin/"aliae", shell_parameter_format: :cobra)
  end

  test do
    (testpath/".aliae.yaml").write <<~YAML
      alias:
        - name: a
          value: aliae
        - name: hello-world
          value: echo "hello world"
          type: function
    YAML

    output = shell_output("#{bin}/aliae init bash")
    assert_equal <<~SHELL.chomp, output
      alias a="aliae"
      hello-world() {
          echo "hello world"
      }
    SHELL

    assert_match version.to_s, shell_output("#{bin}/aliae --version")
  end
end
