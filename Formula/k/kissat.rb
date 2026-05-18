class Kissat < Formula
  desc "Bare metal SAT solver"
  homepage "https://github.com/arminbiere/kissat"
  url "https://github.com/arminbiere/kissat/archive/refs/tags/rel-4.0.4.tar.gz"
  sha256 "bfe93eaa6323b48011e4b1fcf74b3f2e20f9de544767e728009e5b2018296193"
  license "MIT"

  livecheck do
    url :stable
    regex(/^rel[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bbf50aa8a14226bf0695cac206e030ed6b4c138eb36d8c399b4f185f59a0fd43"
  end

  def install
    system "./configure"
    system "make"

    # This should be changed to `make install` if upstream adds an install target.
    # See: https://github.com/arminbiere/kissat/issues/62
    bin.install "build/kissat"

    pkgshare.install "test"
  end

  test do
    cp pkgshare/"test/cnf/xor0.cnf", testpath
    output = shell_output("#{bin}/kissat xor0.cnf", 10)
    assert_match "SATISFIABLE", output
  end
end
