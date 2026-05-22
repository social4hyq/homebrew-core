class Docx2txt < Formula
  desc "Converts Microsoft Office docx documents to equivalent text documents"
  homepage "https://docx2txt.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/docx2txt/docx2txt/v1.4/docx2txt-1.4.tgz"
  sha256 "b297752910a404c1435e703d5aedb4571222bd759fa316c86ad8c8bbe58c6d1b"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9db0eb3e2f06e4423c9e05f7a3476d8872ffeacaf8ff6b350d385dc3475feed7"
  end

  resource "sample_doc" do
    url "https://calibre-ebook.com/downloads/demos/demo.docx"
    sha256 "269329fc7ae54b3f289b3ac52efde387edc2e566ef9a48d637e841022c7e0eab"
  end

  def install
    system "make", "install", "CONFIGDIR=#{etc}", "BINDIR=#{bin}"
  end

  test do
    testpath.install resource("sample_doc")
    system bin/"docx2txt.sh", testpath/"demo.docx"
  end
end
