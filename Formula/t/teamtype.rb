class Teamtype < Formula
  desc "Peer-to-peer, editor-agnostic collaborative editing of local text files"
  homepage "https://teamtype.github.io/teamtype/"
  url "https://github.com/teamtype/teamtype/archive/refs/tags/v0.9.2.tar.gz"
  sha256 "cbf36fd071512e39101aa7de111cbb8b1ae4c0aebf9bd3508eb33e68712bca0f"
  license "AGPL-3.0-or-later"
  head "https://github.com/teamtype/teamtype.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "89149d065f5cd6b25d0655f9b1c79ba66020512f5369f8e7257db27ad941bec3"
  end

  depends_on "rust" => :build

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/teamtype")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/teamtype --version")

    (testpath/".teamtype").mkpath
    expected = "For security reasons, the parent directory of the socket must only be accessible by the current user"
    assert_match expected, pipe_output("#{bin}/teamtype share 2>&1", "y", 1)
  end
end
