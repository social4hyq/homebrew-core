class Fst < Formula
  desc "Represent large sets and maps compactly with finite state transducers"
  homepage "https://github.com/BurntSushi/fst"
  url "https://github.com/BurntSushi/fst/archive/refs/tags/fst-bin-0.4.3.tar.gz"
  sha256 "13d1b28a6a6eaf5ce53c1840e7e6c2cb42ff7f846cd57047ddd32601667c8a5f"
  license any_of: ["Unlicense", "MIT"]
  head "https://github.com/BurntSushi/fst.git", branch: "master"

  livecheck do
    url :stable
    regex(/^fst-bin[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "17a7d469d426f276d6e3cfa450367a24a33a845b8e1f2e1d9885feb465d50ba6"
  end

  depends_on "rust" => :build

  def install
    cd "fst-bin" do
      system "cargo", "install", *std_cargo_args
    end
  end

  test do
    (testpath/"map.csv").write <<~EOF
      four,4
      one,1
      twenty,20
      two,2
    EOF
    expected = <<~EOF
      twenty,20
      two,2
    EOF
    system bin/"fst", "map", "--sorted", testpath/"map.csv", testpath/"map.fst"
    assert_path_exists testpath/"map.fst"
    system bin/"fst", "verify", testpath/"map.fst"
    assert_equal expected, shell_output("#{bin}/fst grep -o #{testpath}/map.fst 'tw.*'")
  end
end
