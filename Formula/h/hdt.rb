class Hdt < Formula
  desc "Header Dictionary Triples (HDT) is a compression format for RDF data"
  homepage "https://github.com/rdfhdt/hdt-cpp"
  url "https://github.com/rdfhdt/hdt-cpp/archive/refs/tags/v1.3.3.tar.gz"
  sha256 "3abc8af7a0b19760654acf149f0ec85d4e9589a32c4331d3bfbe2fcd825173e6"
  license "LGPL-2.1-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fdb76c02913e9bb8e4ae277007672b46b2610e8148699535ee70ac8897436767"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build
  depends_on "serd"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "./autogen.sh"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"rdf2hdt", "-h"

    test_file = testpath/"test.nt"
    test_file.write <<~EOS
      <http://example.org/uri1> <http://example.org/predicate1> "literal1" .
      <http://example.org/uri1> <http://example.org/predicate1> "literalA" .
      <http://example.org/uri1> <http://example.org/predicate1> "literalA" .
      <http://example.org/uri1> <http://example.org/predicate1> "literalB" .
      <http://example.org/uri1> <http://example.org/predicate1> "literalC" .
      <http://example.org/uri1> <http://example.org/predicate2> <http://example.org/uri3> .
      <http://example.org/uri1> <http://example.org/predicate2> <http://example.org/uriA3> .
      <http://example.org/uri1> <http://example.org/predicate2> <http://example.org/uriA3> .
      <http://example.org/uri2> <http://example.org/predicate1> "literal1" .
      <http://example.org/uri3> <http://example.org/predicate3> <http://example.org/uri4> .
      <http://example.org/uri3> <http://example.org/predicate3> <http://example.org/uri5> .
      <http://example.org/uri4> <http://example.org/predicate4> <http://example.org/uri5> .
    EOS

    system bin/"rdf2hdt", test_file, "test.hdt"
    assert_path_exists testpath/"test.hdt"
    system bin/"hdtInfo", "test.hdt"
  end
end
