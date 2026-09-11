class Castget < Formula
  desc "Command-line podcast and RSS enclosure downloader"
  homepage "https://castget.johndal.com/"
  license "LGPL-2.1-only"
  revision 2

  stable do
    # Using git archive to backport upstream commits as release tarball excludes some files
    # TODO: Restore Savannah tarball on next release
    # url "https://download.savannah.gnu.org/releases/castget/castget-2.0.1.tar.bz2"
    url "https://github.com/mlj/castget/archive/refs/tags/rel_2_0_1.tar.gz"
    sha256 "8cefeb8c76daa791953ee1a555473cc83a29a2d18a29adeb2aef7a41e2212f49"

    # TODO: Remove these on next release
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
    depends_on "ronn-ng" => :build

    # Backport replacing unmaintained id3lib with taglib. Other commits are to cleanly apply change.
    patch do # clang-format - only style changes
      url "https://github.com/mlj/castget/commit/28a6a96cfab75a0ff8028dd01b299c3fae4f6d5e.patch?full_index=1"
      sha256 "489c5626a7c1e7fa2e8b4110921d1651216f3cb46ce6beaa1d85de0c1087b9c2"
    end
    patch do # copyright dates - no functional impact
      url "https://github.com/mlj/castget/commit/3a6131b97313dcc197916dcd0a1f659720a1eae5.patch?full_index=1"
      sha256 "2f8e63cc29660f3dde0732b41f8700bcf2d1cc2e922f72b3b642a79ccfd0454b"
    end
    patch do # removed email - minor change in output message
      url "https://github.com/mlj/castget/commit/d664a9d270c23056be361d1a040a0529f113bdaa.patch?full_index=1"
      sha256 "575f267c42767e6a4ad45239d0e798662bdb527c62149324259a74755e6f23bf"
    end
    patch do # C includes - only style changes
      url "https://github.com/mlj/castget/commit/498b3423a1ec48eb1a3257abee0a67758825014c.patch?full_index=1"
      sha256 "5a5232fea5bf417b77f1abe1cf642fbaaea47f8d2a3ad75c1055a308d305c869"
    end
    patch do # README.md update - no functional impact
      url "https://github.com/mlj/castget/commit/bc2363841a97485fa3704a1219a9b8199bfa0ac7.patch?full_index=1"
      sha256 "328e0152cc0df61b45b12881bd019eb07e1370429896709996f20269400b3009"
    end
    patch do # castgetrc.example update - no functional impact
      url "https://github.com/mlj/castget/commit/def52152b85ff169d0ded740bcae49d57a4fb264.patch?full_index=1"
      sha256 "44e5c945ee0177c0b859b051ab6be36d0699911e03b5cacbc094ce48dbafbf43"
    end
    patch do
      url "https://github.com/mlj/castget/commit/6ad0c9d791f646e310b733a9d4d4f7797e92c79c.patch?full_index=1"
      sha256 "d979f9b7db5a8cfd2e631e7a28d6674df7295457bff356d89b26dc8448331d51"
    end
  end

  livecheck do
    url "https://download.savannah.gnu.org/releases/castget/"
    regex(/href=.*?castget[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dbc423401cc226083dceede3ca69e153df08784b2b5bdcd251c1fd9689d43020"
  end

  head do
    url "https://github.com/mlj/castget.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkgconf" => :build
  depends_on "glib"
  depends_on "taglib"

  uses_from_macos "curl"
  uses_from_macos "libxml2"

  on_macos do
    depends_on "gettext"
  end

  def install
    system "autoreconf", "--force", "--install", "--verbose" # if build.head?
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.rss").write <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Test podcast</title>
          <description>Test podcast</description>
          <link>http://www.podcast.test/</link>
          <item>
            <title>Test item</title>
            <enclosure url="file://#{test_fixtures("test.mp3")}" type="audio/mpeg" />
          </item>
        </channel>
      </rss>
    XML

    (testpath/"castgetrc").write <<~INI
      [test]
      url=file://#{testpath}/test.rss
      spool=#{testpath}
    INI

    system bin/"castget", "--rcfile", testpath/"castgetrc"
    assert_path_exists testpath/"test.mp3"
  end
end
