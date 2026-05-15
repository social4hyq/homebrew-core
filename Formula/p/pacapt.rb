class Pacapt < Formula
  desc "Package manager in the style of Arch's pacman"
  homepage "https://github.com/icy/pacapt"
  url "https://github.com/icy/pacapt/archive/refs/tags/v3.0.7.tar.gz"
  sha256 "d1081b639466de7650ed66c7bb5a522482c60c24b03c292c46b86a3983e66234"
  license "Fair"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7c70c6ccace4bac779a7e1828eca4953a621f0f25cd7e27dc43bb2ea3fd63f95"
  end

  def install
    bin.mkpath
    system "make", "install", "BINDIR=#{bin}", "VERSION=#{version}"
  end

  test do
    system bin/"pacapt", "-Ss", "wget"
  end
end
