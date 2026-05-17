class FastqTools < Formula
  desc "Small utilities for working with fastq sequence files"
  homepage "https://github.com/dcjones/fastq-tools"
  url "https://github.com/dcjones/fastq-tools/archive/refs/tags/v0.8.3.tar.gz"
  sha256 "0cd7436e81129090e707f69695682df80623b06448d95df483e572c61ddf538e"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "37737696cf59d198e1e723a103dd5413d434b6b367496fef5358375244426368"
  end

  # Last release on 2020-10-30 and needs EOL `pcre`
  deprecate! date: "2026-01-12", because: :unmaintained
  disable! date: "2027-01-12", because: :unmaintained

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pcre"

  def install
    system "./autogen.sh"

    # Fix compile with newer Clang
    # upstream bug report, https://github.com/dcjones/fastq-tools/issues/32
    if DevelopmentTools.clang_build_version >= 1403
      inreplace "configure" do |s|
        s.sub! "-Wall", "-Wall -Wno-implicit-function-declaration"
      end
    end

    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.fq").write <<~EOS
      @U00096.2:1-70
      AGCTTTTCATTCTGACTGCAACGGGCAATATGTCTCTGTGTGGATTAAAAAAAGAGTGTCTGATAGCAGC
      +
      IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII0000000000
    EOS

    assert_match "A\t20", shell_output("#{bin}/fastq-kmers test.fq")
    assert_match "1 copies", shell_output("#{bin}/fastq-uniq test.fq")
  end
end
