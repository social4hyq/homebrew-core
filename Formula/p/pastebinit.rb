class Pastebinit < Formula
  include Language::Python::Shebang

  desc "Send things to pastebin from the command-line"
  homepage "https://github.com/pastebinit/pastebinit"
  url "https://github.com/pastebinit/pastebinit/archive/refs/tags/1.8.0.tar.gz"
  sha256 "fc8ed4323ddfb130c17380af8f4970ac9c1648563fb1ab4efd307e87eb2c41e7"
  license "GPL-2.0-or-later"
  head "https://github.com/pastebinit/pastebinit.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "258d80c9b5a5153852ce60b672f0f5c3164d5e465ad644f957259fac43b46d8b"
  end

  depends_on "docbook2x" => :build
  depends_on "gettext" => :build # for msgfmt

  uses_from_macos "python"

  def install
    inreplace "pastebinit", "confdirs = []", "confdirs = ['#{pkgetc}/pastebin.d']"
    rewrite_shebang detected_python_shebang(use_python_from_path: true), "pastebinit"

    bin.install "pastebinit", *buildpath.glob("utils/*{s,t}")
    pkgetc.install "pastebin.d"

    system "docbook2man", "pastebinit.xml"
    man1.install "PASTEBINIT.1" => "pastebinit.1"
    man1.install buildpath.glob("utils/*.1")

    system "make", "-C", "po"
    (share/"locale").install (buildpath/"po/mo").children
  end

  test do
    url = pipe_output("#{bin}/pastebinit -a test -b paste.ubuntu.com", "Hello, world!").chomp
    assert_match "://paste.ubuntu.com/", url
  end
end
