class Execline < Formula
  desc "Interpreter-less scripting language"
  homepage "https://skarnet.org/software/execline/"
  url "https://skarnet.org/software/execline/execline-2.9.8.1.tar.gz"
  sha256 "23350d10797909636060522607591cb4a2118328cb58c5e65fb19a2c0d47264e"
  license "ISC"
  head "git://git.skarnet.org/execline", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b0066b8cb0080bbe07851d143f5ea3c8f3f36f325533368d06ee9e4462f3120a"
  end

  depends_on "pkgconf" => :build
  depends_on "skalibs"

  def install
    args = %W[
      --disable-silent-rules
      --enable-shared
      --enable-pkgconfig
      --with-pkgconfig=#{Formula["pkgconf"].opt_bin}/pkg-config
      --with-sysdeps=#{Formula["skalibs"].opt_lib}/skalibs/sysdeps
    ]
    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.eb").write <<~EOS
      foreground
      {
        sleep 1
      }
      "echo"
      "Homebrew"
    EOS
    assert_match "Homebrew", shell_output("#{bin}/execlineb test.eb")
  end
end
