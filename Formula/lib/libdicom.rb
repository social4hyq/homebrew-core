class Libdicom < Formula
  desc "DICOM WSI read library"
  homepage "https://github.com/ImagingDataCommons/libdicom"
  url "https://github.com/ImagingDataCommons/libdicom/releases/download/v1.3.0/libdicom-1.3.0.tar.xz"
  sha256 "75f1167f5153c659cdd58f2b432d2592bf0477abe0087e195bc621b5594ef10a"
  license "MIT"
  revision 1
  compatibility_version 1

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b9eec4f983257f6d3cd9b9efbab53420a9b84f4dd64f5176a6824d4e4de13e95"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build

  depends_on "uthash"

  def install
    system "meson", "setup", "build", "-Dtests=false", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    resource "homebrew-sample.dcm" do
      url "https://raw.githubusercontent.com/dangom/sample-dicom/master/MR000000.dcm"
      sha256 "4efd3edd2f5eeec2f655865c7aed9bc552308eb2bc681f5dd311b480f26f3567"
    end
    testpath.install resource("homebrew-sample.dcm")

    assert_match "File Meta Information", shell_output("#{bin}/dcm-dump #{testpath}/MR000000.dcm")

    assert_match version.to_s, shell_output("#{bin}/dcm-getframe -v")
  end
end
