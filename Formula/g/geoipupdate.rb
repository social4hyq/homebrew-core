class Geoipupdate < Formula
  desc "Automatic updates of GeoIP2 and GeoIP Legacy databases"
  homepage "https://github.com/maxmind/geoipupdate"
  url "https://github.com/maxmind/geoipupdate/archive/refs/tags/v8.0.0.tar.gz"
  sha256 "5c08b39d2ac49ad492138b3d618dddac130065852b6237ec450bac856ace7e0a"
  license "Apache-2.0"
  head "https://github.com/maxmind/geoipupdate.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "473670e719874f6056346c85730059b7d63d6d1a5429397f6ef6d77313c668f6"
  end

  depends_on "go" => :build
  depends_on "pandoc" => :build

  uses_from_macos "curl"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "make", "CONFFILE=#{etc}/GeoIP.conf", "DATADIR=#{var}/GeoIP", "VERSION=#{version} (homebrew)"

    bin.install  "build/geoipupdate"
    etc.install  "build/GeoIP.conf"
    man1.install "build/geoipupdate.1"
    man5.install "build/GeoIP.conf.5"
    (var/"GeoIP").mkpath
  end

  test do
    system bin/"geoipupdate", "-V"
  end
end
