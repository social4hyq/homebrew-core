class Roll < Formula
  desc "CLI program for rolling a dice sequence"
  homepage "https://matteocorti.github.io/roll/"
  url "https://github.com/matteocorti/roll/releases/download/v2.7.0/roll-2.7.0.tar.gz"
  sha256 "9e116501aaa0c8f954d31a86e8cf6dee5d98ee35a5e8e5b025646c4bee741533"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2ea2531b3d6d40cf4e02a047774182e2d0be6a90a0417c52d4f2ecbc010c9f65"
  end

  head do
    url "https://github.com/matteocorti/roll.git", branch: "master"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  on_macos do
    depends_on "pkgconf" => :build
  end

  def install
    system "./regen.sh" if build.head?
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system bin/"roll", "1d6"
  end
end
