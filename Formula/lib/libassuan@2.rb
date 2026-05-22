class LibassuanAT2 < Formula
  desc "Assuan IPC Library"
  homepage "https://www.gnupg.org/related_software/libassuan/"
  url "https://gnupg.org/ftp/gcrypt/libassuan/libassuan-2.5.7.tar.bz2"
  mirror "https://www.mirrorservice.org/sites/ftp.gnupg.org/gcrypt/libassuan/libassuan-2.5.7.tar.bz2"
  sha256 "0103081ffc27838a2e50479153ca105e873d3d65d8a9593282e9c94c7e6afb76"
  # NOTE: We exclude LGPL-3.0-or-later as corresponding code is only used on Windows CE.
  license all_of: [
    "LGPL-2.1-or-later",
    "GPL-3.0-or-later", # assuan.info
    "FSFULLR", # libassuan-config, libassuan.m4
  ]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c630d135e22c1d2484b2f960daddc5b1885cb10f3c0d8989db6d140b4e14fc64"
  end

  keg_only :versioned_formula

  deprecate! date: "2025-01-11", because: :versioned_formula
  disable! date: "2026-01-11", because: :versioned_formula

  depends_on "libgpg-error"

  def install
    system "./configure", "--disable-silent-rules",
                          "--enable-static",
                          *std_configure_args
    system "make", "install"

    # avoid triggering mandatory rebuilds of software that hard-codes this path
    inreplace bin/"libassuan-config", prefix, opt_prefix
  end

  test do
    system bin/"libassuan-config", "--version"
  end
end
