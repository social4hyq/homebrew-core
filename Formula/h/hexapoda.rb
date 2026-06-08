class Hexapoda < Formula
  desc "Colorful modal hex editor"
  homepage "https://simonomi.dev/hexapoda"
  url "https://github.com/simonomi/hexapoda/archive/refs/tags/v0.2.4.tar.gz"
  sha256 "3c205ee738d97743f48aa6d4190c3a2892766a07e7ceb80e09dfa5844c32a395"
  license "GPL-3.0-only"
  head "https://github.com/simonomi/hexapoda.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e2b5f898ba5f005d3c970c4ee5e8f0ceef4cb3e52c1041b64a4406937a2ec615"
  end

  depends_on "rust" => :build

  def install
    ENV["HEXAPODA_COMPLETIONS"] = buildpath
    ENV["HEXAPODA_MANPAGE"] = buildpath

    system "cargo", "install", *std_cargo_args

    man1.install "hexapoda.1"

    bash_completion.install "hexapoda.bash"
    fish_completion.install "hexapoda.fish"
    zsh_completion.install "_hexapoda"
    pwsh_completion.install "_hexapoda.ps1"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/hexapoda --version")
    assert_match "hexapoda.toml", shell_output("#{bin}/hexapoda --show-config-path")
  end
end
