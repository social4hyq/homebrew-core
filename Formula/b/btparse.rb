class Btparse < Formula
  desc "BibTeX utility libraries"
  homepage "https://metacpan.org/dist/Text-BibTeX/view/btparse/doc/btparse.pod"
  url "https://cpan.metacpan.org/authors/id/A/AM/AMBS/btparse/btparse-0.35.tar.gz"
  sha256 "631bf1b79dfd4c83377b416a12c349fe88ee37448dc82e41424b2f364a99477b"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b55acaceaf07ca6c8f63563301e791f0bbbdd63ecc1328728c0c443bba65f05a"
  end

  def install
    # workaround for Xcode 14.3
    if DevelopmentTools.clang_build_version >= 1403 || (OS.linux? && Hardware::CPU.arm?)
      ENV.append "CFLAGS", "-Wno-implicit-function-declaration"
    end

    # Fix flat namespace usage
    inreplace "configure", "${wl}-flat_namespace ${wl}-undefined ${wl}suppress", "${wl}-undefined ${wl}dynamic_lookup"

    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", "--mandir=#{man}", *args, *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.bib").write <<~BIBTEX
      @article{mxcl09,
        title={{H}omebrew},
        author={{H}owell, {M}ax},
        journal={GitHub},
        volume={1},
        page={42},
        year={2009}
      }
    BIBTEX

    system bin/"bibparse", "-check", "test.bib"
  end
end
