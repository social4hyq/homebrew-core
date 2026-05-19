class Icu4cAT77 < Formula
  desc "C/C++ and Java libraries for Unicode and globalization"
  homepage "https://icu.unicode.org/home"
  url "https://github.com/unicode-org/icu/releases/download/release-77-1/icu4c-77_1-src.tgz"
  version "77.1"
  sha256 "588e431f77327c39031ffbb8843c0e3bc122c211374485fa87dc5f3faff24061"
  license "ICU"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1185206c7ffa428300b479e1cd5da9b540d4f9b8bb6969cb444a3be8866ffe0b"
  end

  keg_only :versioned_formula

  # Disable date set 1 year after ICU 78.1 release
  disable! date: "2026-10-30", because: :versioned_formula

  def install
    args = %w[
      --disable-samples
      --disable-tests
      --enable-static
      --with-library-bits=64
    ]

    cd "source" do
      system "./configure", *args, *std_configure_args
      system "make"
      system "make", "install"
    end
  end

  test do
    if File.exist? "/usr/share/dict/words"
      system bin/"gendict", "--uchars", "/usr/share/dict/words", "dict"
    else
      (testpath/"hello").write "hello\nworld\n"
      system bin/"gendict", "--uchars", "hello", "dict"
    end
  end
end
