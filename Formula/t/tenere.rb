class Tenere < Formula
  desc "TUI interface for LLMs written in Rust"
  homepage "https://github.com/pythops/tenere"
  url "https://github.com/pythops/tenere/archive/refs/tags/v0.11.3.tar.gz"
  sha256 "3605fcdff3dbd5d153ed6126e98274994bd00ed83a2a1f5587058d75797257a8"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f5c4165c06bb015489ef11593cab8eeaa669ee7d70aeda1ea5cc847d79956fa7"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "libgit2"
  depends_on "oniguruma"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  # Backport dependency updates to use newer libgit2
  patch do
    url "https://github.com/pythops/tenere/commit/2cf22cc3b669c1f2be2c5e9e2c495ed8ab1c95fb.patch?full_index=1"
    sha256 "61759013e19e930e8183df312f5980f5ccfdbd27320dff58c2da943064e1b9d6"
  end
  patch do
    url "https://github.com/pythops/tenere/commit/f6e1ba6734258e3fb0d81778d5ed7d9685ed5bbb.patch?full_index=1"
    sha256 "fa2fef89c41669dd304366bd3e1a5ea85625a09a12096b83c1bb81deffbdf7e4"
  end

  def install
    ENV["LIBGIT2_NO_VENDOR"] = "1"
    ENV["RUSTONIG_SYSTEM_LIBONIG"] = "1"

    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tenere --version")
    assert_match "Can not find the openai api key", shell_output("#{bin}/tenere 2>&1", 1)
  end
end
