class Clive < Formula
  desc "Automates terminal operations"
  homepage "https://github.com/koki-develop/clive"
  url "https://github.com/koki-develop/clive/archive/refs/tags/v0.12.17.tar.gz"
  sha256 "fda25e28dece565770d192633aee113f8cfc8f24fc974f0a8ecd59a7fe224f3f"
  license "MIT"
  head "https://github.com/koki-develop/clive.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "286afd81d79ea20afaf558856c90f7c36c0edb9db1bb639a0462eeba6b38154d"
  end

  depends_on "go" => :build
  depends_on "ttyd"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X github.com/koki-develop/clive/cmd.version=v#{version}")
    generate_completions_from_executable(bin/"clive", shell_parameter_format: :cobra)
  end

  test do
    system bin/"clive", "init"
    assert_path_exists testpath/"clive.yml"

    system bin/"clive", "validate"
    assert_match version.to_s, shell_output("#{bin}/clive --version")
  end
end
