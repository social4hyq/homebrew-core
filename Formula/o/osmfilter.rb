class Osmfilter < Formula
  desc "Command-line tool to filter OpenStreetMap files for specific tags"
  homepage "https://wiki.openstreetmap.org/wiki/Osmfilter"
  url "https://gitlab.com/osm-c-tools/osmctools.git",
      tag:      "0.9",
      revision: "f341f5f237737594c1b024338f0a2fc04fabdff3"
  license "AGPL-3.0-only"
  head "https://gitlab.com/osm-c-tools/osmctools.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "771940f0cd520bcf74d13dabed9329eb9e092106a0f642296b2f9e9183acf811"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  on_linux do
    depends_on "zlib-ng-compat"
  end

  resource "pbf" do
    url "https://download.gisgraphy.com/openstreetmap/pbf/AD.tar.bz2"
    sha256 "f8decd915758139e8bff2fdae6102efa0dc695b9d1d64cc89a090a91576efda9"
  end

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    resource("pbf").stage do
      system bin/"osmconvert", "AD", "-o=test.o5m"
      system bin/"osmfilter", "test.o5m",
        "--drop-relations", "--drop-ways", "--drop-nodes"
    end
  end
end
