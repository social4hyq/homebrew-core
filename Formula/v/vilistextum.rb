class Vilistextum < Formula
  desc "HTML to text converter"
  homepage "https://bhaak.net/vilistextum/"
  url "https://bhaak.net/vilistextum/vilistextum-2.6.9.tar.gz"
  sha256 "3a16b4d70bfb144e044a8d584f091b0f9204d86a716997540190100c20aaf88d"
  license "GPL-2.0-only"

  livecheck do
    url "https://bhaak.net/vilistextum/download.html"
    regex(/href=.*?vilistextum[._-]v?(\d+(?:\.\d+)+)\.t/i)
    strategy :page_match do |page, regex|
      # Omit version with old scheme that is incorrectly treated as newest
      # NOTE: This `strategy` block can be removed in the future if/when the
      # download page only contains versions with three parts like 2.3.0.
      page.scan(regex).map { |match| ((version = match.first) == "2.22") ? nil : version }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "baa4288565f1f1cbbad75c19a607f90cb73aba61bb7194414040e53af7f6b18b"
  end

  def install
    # Work around failure from GCC 10+ using default of `-fno-common`
    # multiple definition of `<symbol>`; <file>.o:<location>: first defined here
    ENV.append_to_cflags "-fcommon" if OS.linux?

    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}", "--mandir=#{man}"
    system "make", "install"
  end

  test do
    system bin/"vilistextum", "-v"
  end
end
