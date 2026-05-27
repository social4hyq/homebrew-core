class Bao < Formula
  desc "Implementation of BLAKE3 verified streaming"
  homepage "https://github.com/oconnor663/bao"
  url "https://github.com/oconnor663/bao/archive/refs/tags/0.13.1.tar.gz"
  sha256 "34cdbc1bc30ce41394ffd52e8a29ab4e5956ecabd7c4db26ffd992d306a59d96"
  license any_of: ["Apache-2.0", "CC0-1.0"]
  head "https://github.com/oconnor663/bao.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "84995481b08a5c6c7eb0abdf119d7a33b9f98db50d823428ba82afce889be79a"
  end

  depends_on "rust" => :build

  conflicts_with "openbao", because: "both install `bao` binaries"

  def install
    system "cargo", "install", *std_cargo_args(path: "bao_bin")
  end

  test do
    test_file = testpath/"test"
    test_file.write "foo"
    output = shell_output("#{bin}/bao hash #{test_file}")
    assert_match "04e0bb39f30b1a3feb89f536c93be15055482df748674b00d26e5a75777702e9", output

    assert_match version.to_s, shell_output("#{bin}/bao --version")
  end
end
