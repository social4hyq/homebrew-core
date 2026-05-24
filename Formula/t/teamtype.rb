class Teamtype < Formula
  desc "Peer-to-peer, editor-agnostic collaborative editing of local text files"
  homepage "https://github.com/teamtype/teamtype"
  url "https://github.com/teamtype/teamtype/archive/refs/tags/v0.9.1.tar.gz"
  sha256 "8503411b340f00456ac6c1d586637de35a35886b7addbf2cec06816e05bc9873"
  license "AGPL-3.0-or-later"
  head "https://github.com/teamtype/teamtype.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "69d25784f437b006c1420a60fc6b2441484ecfd0e760141e83fe2d3650004489"
  end

  depends_on "rust" => :build

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    cd "daemon" do
      system "cargo", "install", *std_cargo_args
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/teamtype --version")

    (testpath/".teamtype").mkpath
    expected = "For security reasons, the parent directory of the socket must only be accessible by the current user"
    assert_match expected, pipe_output("#{bin}/teamtype share 2>&1", "y", 1)
  end
end
