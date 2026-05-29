class Ffe < Formula
  desc "Parse flat file structures and print them in different formats"
  homepage "https://ff-extractor.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/ff-extractor/0.3.9a/0.3.9a.tar.gz"
  version "0.3.9a"
  sha256 "3f3433c6e8714f9756826279e249bcf7f7ab8c45b5686003764e44f63eb225e7"
  license "GPL-2.0-or-later"

  livecheck do
    url :stable
    regex(%r{url=.*?/(?:ffe[._-])?v?(\d+(?:\.\d+)+(?:-\d+)?[a-z]?)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e2a5aa743b454ffc49cb21c2bbf49b38c2bfa0bbf10acc6b8c22fdb76028b1a5"
  end

  def install
    ENV.append "CFLAGS", "-std=gnu89" if DevelopmentTools.clang_build_version >= 1500
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"source").write "EArthur Guinness   25"
    (testpath/"test.rc").write <<~EOS
      structure personel_fix {
        type fixed
        record employee {
          id 1 E
          field EmpType 1
          field FirstName 7
          field LastName  11
          field Age 2
        }
      }
      output default {
        record_header "<tr>"
        data "<td>%t</td>"
        record_trailer "</tr>"
        no-data-print no
      }
    EOS

    system bin/"ffe", "-c", "test.rc", "source"
  end
end
