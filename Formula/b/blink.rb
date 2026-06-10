class Blink < Formula
  desc "Tiniest x86-64-linux emulator"
  homepage "https://github.com/jart/blink"
  license "ISC"
  head "https://github.com/jart/blink.git", branch: "master"

  stable do
    url "https://github.com/jart/blink/archive/refs/tags/1.1.0.tar.gz"
    sha256 "2649793e1ebf12027f5e240a773f452434cefd9494744a858cd8bff8792dba68"

    # Backport fix for `pointer not aligned at _kWhence+0x4`
    patch do
      url "https://github.com/jart/blink/commit/f93880dd38877914b71c2276bb476329a9e24ed0.patch?full_index=1"
      sha256 "c7f6b41eaf9c0edee25191b6aa9e8dd21d29734c1474919f5f67685893bf20d7"
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "09c350a88aa6c01dc04f1cfcc3e343da0994f1927646422d8c95f1aa6d8937c8"
  end

  depends_on "pkgconf" => :build

  on_macos do
    depends_on "make" => :build # Needs Make 4.0+
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "./configure", "--prefix=#{prefix}", "--enable-vfs"
    # Call `make` as `gmake` to use Homebrew `make`.
    system "gmake" # must be separate steps.
    system "gmake", "install"
  end

  test do
    stable.stage testpath
    ENV["BLINK_PREFIX"] = testpath
    goodhello = "third_party/cosmo/goodhello.elf"
    chmod "+x", goodhello
    system bin/"blink", "-m", goodhello
  end
end
