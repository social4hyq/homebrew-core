class Mafft < Formula
  desc "Multiple alignments with fast Fourier transforms"
  homepage "https://mafft.cbrc.jp/alignment/software/"
  url "https://gitlab.com/sysimm/mafft.git",
      tag:      "v7.526",
      revision: "ee9799916df6a5d5103d46d54933f8eb6d28e244"
  license "BSD-3-Clause"

  livecheck do
    url :homepage
    regex(/The latest version is (\d+(?:\.\d+)+)/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e7a6e404ec9ce0892bd4096b5c1cabe58855527893a775e963dd3a500066f34f"
  end

  def install
    make_args = %W[CC=#{ENV.cc} CXX=#{ENV.cxx} PREFIX=#{prefix} install]
    system "make", "-C", "core", *make_args
    system "make", "-C", "extensions", *make_args
  end

  test do
    (testpath/"test.fa").write ">1\nA\n>2\nA"
    output = shell_output("#{bin}/mafft test.fa")
    assert_match ">1\na\n>2\na", output
  end
end
