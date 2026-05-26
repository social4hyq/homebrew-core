class Intermodal < Formula
  desc "Command-line utility for BitTorrent torrent file creation, verification, etc."
  homepage "https://imdl.io"
  url "https://github.com/casey/intermodal/archive/refs/tags/v0.1.16.tar.gz"
  sha256 "3a072929379ddba929d85a579888ac51cf22e44897b7dc84af7612f49d3874d7"
  license "CC0-1.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5b3d62970806e8a6fa932cdb65450bb39abec2f7e1489207a75851ce7c1d0791"
  end

  depends_on "help2man" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
  end

  def install
    system "cargo", "install", *std_cargo_args
    system "cargo", "run", "--package", "gen", "--", "--bin", bin/"imdl", "man"
    generate_completions_from_executable(bin/"imdl", "completions")

    man1.install Dir["target/gen/man/*.1"]
  end

  test do
    system bin/"imdl", "torrent", "create", "--input", test_fixtures("test.flac"), "--output", "test.torrent"
    system bin/"imdl", "torrent", "verify", "--content", test_fixtures("test.flac"), "--input", "test.torrent"
  end
end
