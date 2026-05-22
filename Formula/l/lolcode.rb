class Lolcode < Formula
  desc "Esoteric programming language"
  homepage "http://www.lolcode.org/"
  # NOTE: 0.10.* releases are stable, 0.11.* is dev. We moved over to
  # 0.11.x accidentally, should move back to stable when possible.
  url "https://github.com/justinmeza/lci/archive/refs/tags/v1.3.tar.gz"
  sha256 "56a77f8a19e6284868e609dad0e4f1d7c9fe59a61398e338726b58016c1eecef"
  license "GPL-3.0-or-later"
  head "https://github.com/justinmeza/lci.git", branch: "future"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "01582f565c039299a90a1809ef29b66659abfafbafe9490004e98b3060bdcdea"
  end

  depends_on "cmake" => :build

  on_linux do
    depends_on "readline"
  end

  conflicts_with "lci", because: "both install `lci` binaries"

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"

    # Don't use `make install` for this one file
    bin.install "build/lci"
  end

  test do
    path = testpath/"test.lol"
    path.write <<~EOS
      HAI 1.2
      CAN HAS STDIO?
      VISIBLE "HAI WORLD"
      KTHXBYE
    EOS
    assert_equal "HAI WORLD\n", shell_output("#{bin}/lci #{path}")
  end
end
