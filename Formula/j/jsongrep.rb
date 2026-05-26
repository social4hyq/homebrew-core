class Jsongrep < Formula
  desc "Query tool for JSON, YAML, TOML, and other structured formats"
  homepage "https://github.com/micahkepe/jsongrep"
  url "https://github.com/micahkepe/jsongrep/archive/refs/tags/v0.9.0.tar.gz"
  sha256 "9ed0a0f7ca44652e7851ba7223bb69af56498311b1d5b2064f7bf532677c8a33"
  license "MIT"
  head "https://github.com/micahkepe/jsongrep.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "10e20d36307f21db19d5b0fc17f98c02543942d125b59fde41b7bcdb050fef21"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"jg", "generate", "shell", shells: [:bash, :zsh, :fish, :pwsh])
    system bin/"jg", "generate", "man", "--output-dir", man1
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/jg --version")

    assert_equal "2\n", pipe_output("#{bin}/jg -F bar", '{"foo":1, "bar":2}')
  end
end
