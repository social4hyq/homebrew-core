class Avimetaedit < Formula
  desc "Tool for embedding, validating, and exporting of AVI files metadata"
  homepage "https://mediaarea.net/AVIMetaEdit"
  url "https://mediaarea.net/download/binary/avimetaedit/1.0.2/AVIMetaEdit_CLI_1.0.2_GNU_FromSource.tar.bz2"
  sha256 "e0b83e17460d0202a54f637cb673a0c03460704e6c2cff0c2e34222efb2c11ca"
  license "CC0-1.0"

  livecheck do
    url "https://mediaarea.net/AVIMetaEdit/Download/Source"
    regex(/href=.*?avimetaedit[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3c39706a2d1ff94a23c33d517f9a142fbcd6e01646fa0161c5e2f6b4a775aab9"
  end

  def install
    cd "Project/GNU/CLI" do
      system "./configure", "--disable-debug",
                            "--disable-dependency-tracking",
                            "--disable-silent-rules",
                            "--prefix=#{prefix}"
      system "make", "install"
    end
  end

  test do
    avi = "UklGRuYAAABBVkkgTElTVMAAAABoZHJsYXZpaDgAAABAnAAAlgAAAAAAAAAQCQAAAQAAAAAAAAABAAAAAAAQAA" \
          "IAAAACAAAAAAAAAAAAAAAAAAAAAAAAAExJU1R0AAAAc3RybHN0cmg4AAAAdmlkc0k0MjAAAAAAAAAAAAAAAAAB" \
          "AAAAGQAAAAAAAAABAAAABgAAAP////8AAAAAAAAAAAIAAgBzdHJmKAAAACgAAAACAAAAAgAAAAEADABJNDIwBg" \
          "AAAAAAAAAAAAAAAAAAAAAAAABMSVNUEgAAAG1vdmkwMGRjBgAAABAQEBCAgA==".unpack1("m")
    (testpath/"test.avi").write avi
    assert_match "test.avi,238,AVI", shell_output("#{bin}/avimetaedit --out-tech test.avi")
  end
end
