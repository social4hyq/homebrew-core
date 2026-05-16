class Jigdo < Formula
  desc "Tool to distribute very large files over the internet"
  homepage "https://www.einval.com/~steve/software/jigdo/"
  url "https://www.einval.com/~steve/software/jigdo/download/jigdo-0.8.2.tar.xz"
  sha256 "36f286d93fa6b6bf7885f4899c997894d21da3a62176592ac162d9c6a8644f9e"
  license "GPL-2.0-only" => { with: "openvpn-openssl-exception" }
  head "https://git.einval.com/git/jigdo.git", branch: "master"

  livecheck do
    url "https://www.einval.com/~steve/software/jigdo/download/"
    regex(/href=.*?jigdo[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "27ebcf3b4c1cfeb132d68214021fa928b172dcc6aba66f0fd678ac173e6d2bb4"
  end

  depends_on "gettext" => :build # for msgfmt
  depends_on "pkgconf" => :build
  depends_on "berkeley-db@5" # keep berkeley-db < 6 to avoid AGPL incompatibility
  depends_on "wget"

  uses_from_macos "bzip2"

  on_macos do
    depends_on "gettext"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    # Find our docbook catalog
    ENV["XML_CATALOG_FILES"] = etc/"xml/catalog"
    system "./configure", "--mandir=#{man}", *std_configure_args

    # disable documentation building
    (buildpath/"doc/Makefile").atomic_write "all:\n\techo hello"

    # disable documentation installing
    inreplace "Makefile", "$(INSTALL) \"$$x\" $(DESTDIR)$(mandir)/man1", "echo \"$$x\""

    system "make"
    system "make", "install"
  end

  test do
    system bin/"jigdo-file", "make-template", "--image=#{test_fixtures("test.png")}",
                                              "--template=#{testpath}/template.tmp",
                                              "--jigdo=#{testpath}/test.jigdo"

    assert_path_exists testpath/"test.jigdo"
    assert_path_exists testpath/"template.tmp"
    system bin/"jigdo-file", "make-image", "--image=#{testpath/"test.png"}",
                                           "--template=#{testpath}/template.tmp",
                                           "--jigdo=#{testpath}/test.jigdo"
    system bin/"jigdo-file", "verify", "--image=#{testpath/"test.png"}",
                                       "--template=#{testpath}/template.tmp"
  end
end
