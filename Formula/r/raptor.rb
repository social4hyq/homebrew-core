class Raptor < Formula
  desc "RDF parser toolkit"
  homepage "https://librdf.org/raptor/"
  url "https://download.librdf.org/source/raptor2-2.0.16.tar.gz"
  sha256 "089db78d7ac982354bdbf39d973baf09581e6904ac4c92a98c5caadb3de44680"
  license any_of: ["LGPL-2.1-or-later", "GPL-2.0-or-later", "Apache-2.0"]
  revision 1
  compatibility_version 1

  livecheck do
    url :homepage
    regex(/href=.*?raptor2[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "44c304cc84260cfcef6ac7172c4b9127ec0b4a4fb2b6050c95cce3006be5ae16"
  end

  uses_from_macos "curl"
  uses_from_macos "libxml2"

  # Fix compilation with libxml2 2.11.0 or later. Patch is already applied upstream, remove on next release.
  # https://github.com/dajobe/raptor/pull/58
  patch do
    url "https://github.com/dajobe/raptor/commit/ac914399b9013c54572833d4818e6ce008136dc9.patch?full_index=1"
    sha256 "d527fb9ad94f22acafcec9f3b626fb876b7fb1b722e6999cf46a158172bb0992"
  end

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    test_url = "https://raw.githubusercontent.com/dajobe/raptor/" \
               "b5e91dfdf7e1ea5ca5a5f7b48c428dd3da1219e0/tests/feeds/test01.rdf"
    output = shell_output("#{bin}/rapper --output ntriples #{test_url}")
    assert_match '_:genid2 <http://purl.org/dc/elements/1.1/title> "Example"', output
  end
end
