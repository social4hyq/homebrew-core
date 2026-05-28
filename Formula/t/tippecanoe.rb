class Tippecanoe < Formula
  desc "Build vector tilesets from collections of GeoJSON features"
  homepage "https://github.com/felt/tippecanoe"
  url "https://github.com/felt/tippecanoe/archive/refs/tags/2.79.0.tar.gz"
  sha256 "b0fd9df49b6efc988288ea48774822c6de19eb48428017f27ee0b3b01d44f05d"
  license "BSD-2-Clause"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d4f3dbea5b9ce8998b08154f946a675e9a76e0a786223cd685091788d848fc24"
  end

  uses_from_macos "sqlite"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    (testpath/"test.json").write <<~JSON
      {"type":"Feature","properties":{},"geometry":{"type":"Point","coordinates":[0,0]}}
    JSON
    safe_system bin/"tippecanoe", "-o", "test.mbtiles", "test.json"
    assert_path_exists testpath/"test.mbtiles", "tippecanoe generated no output!"
  end
end
