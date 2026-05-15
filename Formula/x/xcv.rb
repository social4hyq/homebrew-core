class Xcv < Formula
  desc "Cut, copy and paste files with Bash"
  homepage "https://github.com/busterc/xcv"
  url "https://github.com/busterc/xcv/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "f2898f78bb05f4334073adb8cdb36de0f91869636a7770c8e955cee8758c0644"
  license "ISC"
  head "https://github.com/busterc/xcv.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cba9e2b01a5c52445d7272b1e5a72697521e760067e1572a8b357ec60c0f4129"
  end

  def install
    bin.install "xcv"
  end

  test do
    system bin/"xcv"
  end
end
