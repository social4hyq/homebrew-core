class KyotoTycoon < Formula
  desc "Database server with interface to Kyoto Cabinet"
  homepage "https://dbmx.net/kyototycoon/"
  url "https://dbmx.net/kyototycoon/pkg/kyototycoon-0.9.56.tar.gz"
  sha256 "553e4ea83237d9153cc5e17881092cefe0b224687f7ebcc406b061b2f31c75c6"
  license "GPL-3.0-or-later"
  revision 5

  livecheck do
    url "https://dbmx.net/kyototycoon/pkg/"
    regex(/href=.*?kyototycoon[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3ea848fc24ef9c58e460cdf4f7a73e2ad014b8806ad2a98593812a500421e4cb"
  end

  depends_on "lua" => :build
  depends_on "pkgconf" => :build
  depends_on "kyoto-cabinet"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  # Build patch (submitted upstream)
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/kyoto-tycoon/0.9.56.patch"
    sha256 "7a5efe02a38e3f5c96fd5faa81d91bdd2c1d2ffeb8c3af52878af4a2eab3d830"
  end

  # Homebrew-specific patch to support testing with ephemeral ports (submitted upstream)
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/kyoto-tycoon/ephemeral-ports.patch"
    sha256 "736603b28e9e7562837d0f376d89c549f74a76d31658bf7d84b57c5e66512672"
  end

  def install
    ENV.append_to_cflags "-fpermissive" if OS.linux?
    ENV.append "CXXFLAGS", "-std=c++98"
    system "./configure", "--prefix=#{prefix}",
                          "--with-kc=#{Formula["kyoto-cabinet"].opt_prefix}",
                          "--with-lua=#{Formula["lua"].opt_prefix}"
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.lua").write <<~LUA
      kt = __kyototycoon__
      db = kt.db
      -- echo back the input data as the output data
      function echo(inmap, outmap)
         for key, value in pairs(inmap) do
            outmap[key] = value
         end
         return kt.RVSUCCESS
      end
    LUA
    port = free_port

    spawn bin/"ktserver", "-port", port.to_s, "-scr", testpath/"test.lua"
    sleep 10

    assert_match "Homebrew\tCool", shell_output("#{bin}/ktremotemgr script -port #{port} echo Homebrew Cool 2>&1")
  end
end
