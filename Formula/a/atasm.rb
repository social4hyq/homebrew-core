class Atasm < Formula
  desc "Atari MAC/65 compatible assembler for Unix"
  homepage "https://sourceforge.net/projects/atasm/"
  url "https://github.com/CycoPH/atasm/archive/refs/tags/V1.30.tar.gz"
  sha256 "c3ae8ea1f824e0ee65e123b33982572277207d1749bcd04da3af8f06af977db5"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "45ab2ac6f030d1ffeba64346737e6d237deeb1db9fc60d7efe28ea9538272f26"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    cd "src" do
      system "make"
      bin.install "atasm"
      inreplace "atasm.1.in", "%%DOCDIR%%", "#{HOMEBREW_PREFIX}/share/doc/atasm"
      man1.install "atasm.1.in" => "atasm.1"
    end
    doc.install "examples", Dir["docs/atasm.*"]
  end

  test do
    cd "#{doc}/examples" do
      system bin/"atasm", "-v", "test.m65", "-o/tmp/test.bin"
    end
  end
end
