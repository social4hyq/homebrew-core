class Dvanalyzer < Formula
  desc "Quality control tool for examining tape-to-file DV streams"
  homepage "https://mediaarea.net/DVAnalyzer"
  url "https://mediaarea.net/download/binary/dvanalyzer/1.4.2/DVAnalyzer_CLI_1.4.2_GNU_FromSource.tar.bz2"
  sha256 "d2f3fdd98574f7db648708e1e46b0e2fa5f9e6e12ca14d2dfaa77c13c165914c"
  license all_of: ["BSD-2-Clause", "GPL-3.0-or-later", "Zlib"]

  livecheck do
    url "https://mediaarea.net/DVAnalyzer/Download/Source"
    regex(/href=.*?dvanalyzer[._-]?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "682598856913a028acba27734b0920da8f292cda3cc96dad13cf96afa75fceec"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    cd "ZenLib/Project/GNU/Library" do
      args = ["--disable-debug",
              "--enable-static",
              "--disable-shared"]
      system "./configure", *args
      system "make"
    end

    cd "MediaInfoLib/Project/GNU/Library" do
      args = ["--disable-debug",
              "--enable-static",
              "--disable-shared"]
      system "./configure", *args
      system "make"
    end

    cd "AVPS_DV_Analyzer/Project/GNU/CLI" do
      system "./configure", "--disable-debug", "--enable-staticlibs", "--prefix=#{prefix}"
      system "make", "install"
    end
  end

  test do
    test_mp3 = test_fixtures("test.mp3")
    output = shell_output("#{bin}/dvanalyzer --Header #{test_mp3}")
    assert_match test_mp3.to_s, output

    assert_match version.to_s, shell_output("#{bin}/dvanalyzer --Version")
  end
end
