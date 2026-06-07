class Lsd < Formula
  desc "Clone of ls with colorful output, file type icons, and more"
  homepage "https://github.com/lsd-rs/lsd"
  url "https://github.com/lsd-rs/lsd/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "dae8d43087686a4a1de0584922608e9cbab00727d0f72e4aa487860a9cbfeefa"
  license "Apache-2.0"
  head "https://github.com/lsd-rs/lsd.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1b4cdb975c0b3282247877e15489f1d2e0bfae2adb3d08c01dfecc6c57914750"
  end

  depends_on "pandoc" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    ENV["SHELL_COMPLETIONS_DIR"] = buildpath
    system "cargo", "install", *std_cargo_args
    bash_completion.install "lsd.bash" => "lsd"
    fish_completion.install "lsd.fish"
    zsh_completion.install "_lsd"
    pwsh_completion.install "_lsd.ps1"

    system "pandoc", "doc/lsd.md", "--standalone", "--to=man", "-o", "doc/lsd.1"
    man1.install "doc/lsd.1"
  end

  test do
    output = shell_output("#{bin}/lsd -l #{prefix}")
    assert_match "README.md", output
  end
end
