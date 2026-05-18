class Avanor < Formula
  desc "Quick-growing roguelike game with easy ADOM-like UI"
  homepage "https://avanor.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/avanor/avanor/0.5.8/avanor-0.5.8-src.tar.bz2"
  sha256 "8f55be83d985470b9a5220263fc87d0a0a6e2b60dbbc977c1c49347321379ef3"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f4b99d657a43871501cf7dfe705a18678217f9785fdeeaf7696c4291ebaa6e7c"
  end

  uses_from_macos "ncurses"

  # Upstream fix for clang: https://sourceforge.net/p/avanor/code/133/
  patch :p0 do
    url "https://gist.githubusercontent.com/mistydemeo/64f47233ee64d55cb7d5/raw/c1847d7e3a134e6109ad30ce1968919dd962e727/avanor-clang.diff"
    sha256 "2d24ce7b71eb7b20485d841aabffa55b25b9074f9a5dd83aee33b7695ba9d75c"
  end

  def install
    system "make", "DATA_DIR=#{pkgshare}/", "CC=#{ENV.cxx}", "LD=#{ENV.cxx}"
    bin.install "avanor"
    pkgshare.install "manual"
  end

  test do
    ENV["TERM"] = "xterm"
    assert_match "T h e  L a n d  o f  M y s t e r y", pipe_output(bin/"avanor", "\e", 0)
  end
end
