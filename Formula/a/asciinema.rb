class Asciinema < Formula
  desc "Record and share terminal sessions"
  homepage "https://asciinema.org"
  url "https://github.com/asciinema/asciinema/archive/refs/tags/v3.2.0.tar.gz"
  sha256 "247c7c87481f38d7788c1fb1be12021c778676c0d0ab37e529ec528f87f487ce"
  license "GPL-3.0-only"
  head "https://github.com/asciinema/asciinema.git", branch: "develop"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "68f0a2be87cd581e43e84a28a3323d5d83eb7648543fb1e8ca306fd6b4428c7a"
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
