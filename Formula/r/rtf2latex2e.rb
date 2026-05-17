class Rtf2latex2e < Formula
  desc "RTF-to-LaTeX translation"
  homepage "https://rtf2latex2e.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/rtf2latex2e/rtf2latex2e-unix/2-2/rtf2latex2e-2-2-3.tar.gz"
  version "2.2.3"
  sha256 "7ef86edea11d5513cd86789257a91265fc82d978541d38ab2c08d3e9d6fcd3c3"
  license "GPL-2.0-or-later"

  livecheck do
    url :stable
    regex(%r{url=.*?/rtf2latex2e[._-]v?(\d+(?:[.-]\d+)+)\.t}i)
  end

  no_autobump! because: :incompatible_version_format

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2c145bde15dabcc3209c29940c5cdea515e1028fbf3a555afb44111dbc9a8e6d"
  end

  def install
    # Workaround for arm64 linux. Upstream isn't actively maintained
    ENV.append_to_cflags "-fsigned-char" if OS.linux? && Hardware::CPU.arm?

    # Workaround for newer Clang
    ENV.append "CC", "-Wno-implicit-int" if DevelopmentTools.clang_build_version >= 1403

    # Work around failure from GCC 10+ using default of `-fno-common`
    # multiple definition of `eqn_start_inline'; src/eqn.o:(.bss+0x18): first defined here
    ENV.append_to_cflags "-fcommon" if OS.linux?

    system "make", "install", "prefix=#{prefix}", "CC=#{ENV.cc}"
  end

  def caveats
    <<~EOS
      Configuration files have been installed to:
        #{opt_pkgshare}
    EOS
  end

  test do
    (testpath/"test.rtf").write <<~'EOS'
      {\rtf1\ansi
      {\b hello} world
      }
    EOS
    system bin/"rtf2latex2e", "-n", "test.rtf"
    assert_match "textbf{hello} world", File.read("test.tex")
  end
end
