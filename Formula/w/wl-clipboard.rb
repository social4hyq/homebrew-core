class WlClipboard < Formula
  desc "Command-line copy/paste utilities for Wayland"
  homepage "https://github.com/bugaevc/wl-clipboard"
  url "https://github.com/bugaevc/wl-clipboard/archive/refs/tags/v2.3.0.tar.gz"
  sha256 "b4dc560973f0cd74e02f817ffa2fd44ba645a4f1ea94b7b9614dacc9f895f402"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7863bacb4bb3dee221b71518f01c3fc3fd119b0e399e16e854a63b38c6b2c56e"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on :linux
  depends_on "wayland"
  depends_on "wayland-protocols"

  def install
    args = %W[
      -Dfishcompletiondir=#{fish_completion}
      -Dzshcompletiondir=#{zsh_completion}
    ]
    system "meson", "setup", "build", *args, *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    assert_match "Failed to connect to a Wayland server",
      shell_output("#{bin}/wl-copy test 2>&1", 1)
    assert_match "Failed to connect to a Wayland server",
      shell_output("#{bin}/wl-paste 2>&1", 1)
  end
end
