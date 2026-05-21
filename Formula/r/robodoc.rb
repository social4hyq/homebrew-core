class Robodoc < Formula
  desc "Source code documentation tool"
  homepage "https://rfsber.home.xs4all.nl/Robo/index.html"
  url "https://rfsber.home.xs4all.nl/Robo/archives/robodoc-4.99.44.tar.bz2"
  sha256 "3721c3be9668a1503454618ed807ae0fba5068b15bc0ea63846787d7e9e78c0f"
  license "GPL-3.0-or-later"

  livecheck do
    url "https://rfsber.home.xs4all.nl/Robo/archives/"
    regex(/href=.*?robodoc[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1e88d7245fc3a32568c844a3fcc95bb393947c0a150aed8125b241dca5f157db"
  end

  head do
    url "https://github.com/gumpu/ROBODoc.git", branch: "release"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  # Fixes https://github.com/gumpu/ROBODoc/issues/22
  patch do
    url "https://github.com/lutzmad/ROBODoc/commit/0f8b35c42523810415bec70bb2200d2ecb41c82f.patch?full_index=1"
    sha256 "5fa0e63deaf9eb0eb82e53047a684159d572c116b96fcf4aa61777b663eb156d"
  end

  def install
    system "autoreconf", "--force", "--install", "--verbose" if build.head?
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    cp_r Dir["#{doc}/Examples/PerlExample/*"], testpath
    system bin/"robodoc"
  end
end
