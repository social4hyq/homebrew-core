class Ht < Formula
  desc "Viewer/editor/analyzer for executables"
  homepage "https://hte.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/hte/ht-source/ht-2.1.0.tar.bz2"
  sha256 "31f5e8e2ca7f85d40bb18ef518bf1a105a6f602918a0755bc649f3f407b75d70"
  license "GPL-2.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0032aca662c3dda488cf40269ec105b705d04700b16ee9a2d25ec38187438932"
  end

  depends_on "lzo"

  uses_from_macos "ncurses"

  conflicts_with "texlive", because: "both install `ht` binaries"

  # Apply commit from open PR to work around build failure on Apple Silicon
  # ld: building fixups: pointer not aligned at _coff_characteristics+0x1
  # PR ref: https://github.com/sebastianbiallas/ht/pull/31
  patch do
    on_macos do
      url "https://github.com/sebastianbiallas/ht/commit/a721310665267655d37d9e80db5234d2a7731895.patch?full_index=1"
      sha256 "def983c542112d66f472a4a32323948f812bdd30bb1aa54abc5cb5b3ffef1752"
    end
  end

  # Fix C++11 compatibility issues
  patch do
    url "https://github.com/sebastianbiallas/ht/commit/e52dfb86aa2c370d7d1ac2e046a4b9babc93bac9.patch?full_index=1"
    sha256 "0119c3973d2cc4ac56c7f28061ce0426eab169695ae7b81e1514f9347740ab26"
  end

  def install
    # Fix compilation with Xcode 9
    # https://github.com/sebastianbiallas/ht/pull/18
    inreplace "htapp.cc", "(abs(a - b) > 1)", "(abs((int)a - (int)b))"

    chmod 0755, "./install-sh"
    system "./configure", "--disable-silent-rules",
                          "--disable-x11-textmode",
                          *std_configure_args
    system "make", "install"
  end

  test do
    assert_match "ht #{version}", shell_output("#{bin}/ht -v")
  end
end
