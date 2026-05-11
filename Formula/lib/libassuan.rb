class Libassuan < Formula
  desc "Assuan IPC Library"
  homepage "https://www.gnupg.org/related_software/libassuan/"
  # TODO: On next release, check if `-std=gnu89` workaround can be removed.
  # Ref: https://dev.gnupg.org/T7246
  url "https://gnupg.org/ftp/gcrypt/libassuan/libassuan-3.0.2.tar.bz2"
  mirror "https://www.mirrorservice.org/sites/ftp.gnupg.org/gcrypt/libassuan/libassuan-3.0.2.tar.bz2"
  sha256 "d2931cdad266e633510f9970e1a2f346055e351bb19f9b78912475b8074c36f6"
  license all_of: [
    "LGPL-2.1-or-later",
    "GPL-3.0-or-later", # assuan.info
    "FSFULLR", # libassuan-config, libassuan.m4
  ]
  compatibility_version 1

  livecheck do
    url "https://gnupg.org/ftp/gcrypt/libassuan/"
    regex(/href=.*?libassuan[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "369f81db2ec55d396845dc0cc8569a4d25ab8e8c2ca64a889ff75880bc0a5ca4"
  end

  depends_on "libgpg-error"

  def install
    # Fixes duplicate symbols errors - https://lists.gnupg.org/pipermail/gnupg-devel/2024-July/035614.html
    ENV.append_to_cflags "-std=gnu89"

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
