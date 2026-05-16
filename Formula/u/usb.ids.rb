class UsbIds < Formula
  desc "Repository of vendor, device, subsystem and device class IDs used in USB devices"
  homepage "http://www.linux-usb.org/usb-ids.html"
  url "https://deb.debian.org/debian/pool/main/u/usb.ids/usb.ids_2025.12.13.orig.tar.xz"
  sha256 "492edc99d85a25dca388930c304e85543ef5913b63b5f2fdfa2c213d77709784"
  license any_of: ["GPL-2.0-or-later", "BSD-3-Clause"]
  compatibility_version 1

  livecheck do
    url "https://deb.debian.org/debian/pool/main/u/usb.ids/"
    regex(/href=.*?usb\.ids[._-]v?(\d+(?:\.\d+)+)\.orig\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4d7b29b3a3f4d8649af6e7f115e78ca4859cb8cfd2841fbd6be0f1f7e7a069d3"
  end

  def install
    (share/"misc").install "usb.ids"
  end

  test do
    assert_match "Version: #{version}", File.read(share/"misc/usb.ids", encoding: "ISO-8859-1")
  end
end
