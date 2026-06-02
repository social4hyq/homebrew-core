class Irrtoolset < Formula
  desc "Tools to work with Internet routing policies"
  homepage "https://github.com/irrtoolset/irrtoolset"
  url "https://github.com/irrtoolset/irrtoolset/archive/refs/tags/release-5.1.3.tar.gz"
  sha256 "a3eff14c2574f21be5b83302549d1582e509222d05f7dd8e5b68032ff6f5874a"
  license all_of: ["MIT", "HPND", "GPL-2.0-or-later", "LGPL-2.0-or-later"]
  head "https://github.com/irrtoolset/irrtoolset.git", branch: "master"

  livecheck do
    url :stable
    regex(/v?(\d+(?:[._-]\d+)+)/i)
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b936518bb5e0cad72dedf95f65c49af5835d12256ec1dcd3c5891ba1a10cfb21"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "bison" => :build # Uses newer syntax than system Bison supports
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build

  uses_from_macos "flex" => :build

  on_linux do
    depends_on "readline"
  end

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system bin/"peval", "ANY"
  end
end
