class Asciinema < Formula
  desc "Record and share terminal sessions"
  homepage "https://asciinema.org"
  url "https://github.com/asciinema/asciinema/archive/refs/tags/v3.2.1.tar.gz"
  sha256 "e7e49a09c664a76afc5bc25ca09871eb090bfbe68a2ddbc72750d3cb215d36f1"
  license "GPL-3.0-only"
  head "https://github.com/asciinema/asciinema.git", branch: "develop"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e778f7fa5e91bc4b1f87688d85d2b9d9afb7a81b77e56309ba39a46abf3eabdd"
  end

  depends_on "rust" => :build

  def install
    ENV["ASCIINEMA_GEN_DIR"] = "."

    system "cargo", "install", *std_cargo_args

    man1.install Dir["man/**/*.1"]

    bash_completion.install "completion/asciinema.bash" => "asciinema"
    fish_completion.install "completion/asciinema.fish"
    zsh_completion.install "completion/_asciinema"
    pwsh_completion.install "completion/_asciinema.ps1" => "asciinema"
    (share/"elvish/lib").install "completion/asciinema.elv"
  end

  test do
    ENV["LC_ALL"] = "en_US.UTF-8"
    ENV["ASCIINEMA_SERVER_URL"] = "https://example.com"
    output = shell_output("#{bin}/asciinema auth 2>&1")
    assert_match "Open the following URL in a web browser to authenticate this CLI", output
  end
end
