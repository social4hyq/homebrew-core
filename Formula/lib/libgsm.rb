class Libgsm < Formula
  desc "Lossy speech compression library"
  homepage "https://www.quut.com/gsm/"
  url "https://www.quut.com/gsm/gsm-1.0.24.tar.gz"
  sha256 "a3c40c6471928383f4abfcb2e8f24012a1f562be2f17b8d672145d5986681a92"
  license "TU-Berlin-2.0"

  livecheck do
    url :homepage
    regex(/href=.*?gsm[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ae90a27b6d7b6d178835bd173eb215e59303a43c52acf8b7abba796ba94aa4f1"
  end

  conflicts_with "toast", because: "both install `toast` binaries"

  def install
    # Only the targets for which a directory exists will be installed
    bin.mkpath
    lib.mkpath
    include.mkpath
    man1.mkpath
    man3.mkpath

    arflags = if OS.mac?
      %W[
        -dynamiclib
        -compatibility_version #{version.major}
        -current_version #{version}
        -install_name #{lib/shared_library("libgsm", version.major.to_s)}
      ]
    else
      %W[
        -shared
        -Wl,-soname,#{shared_library("libgsm", version.major.to_s)}
      ]
    end
    arflags << "-o"

    args = [
      "INSTALL_ROOT=#{prefix}",
      "GSM_INSTALL_INC=#{include}",
      "GSM_INSTALL_MAN=#{man3}",
      "TOAST_INSTALL_MAN=#{man1}",
      "LN=ln -s",
      "AR=#{ENV.cc}",
      "ARFLAGS=#{arflags.join(" ")}",
      "RANLIB=true",
      "LIBGSM=$(LIB)/#{shared_library("libgsm", version.to_s)}",
    ]
    args << "CC=#{ENV.cc} -fPIC" if OS.linux?

    # We need to `make all` to avoid a parallelisation error.
    system "make", "all", *args
    system "make", "install", *args

    # Our shared library is erroneously installed as `libgsm.a`
    lib.install lib/"libgsm.a" => shared_library("libgsm", version.to_s)
    lib.install_symlink shared_library("libgsm", version.to_s) => shared_library("libgsm")
    lib.install_symlink shared_library("libgsm", version.to_s) => shared_library("libgsm", version.major.to_s)
    lib.install_symlink shared_library("libgsm", version.to_s) => shared_library("libgsm", version.major_minor.to_s)

    # Build static library
    system "make", "clean"
    system "make", "./lib/libgsm.a"
    lib.install "lib/libgsm.a"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <gsm.h>

      int main()
      {
        gsm g = gsm_create();
        if (g == 0)
        {
          return 1;
        }
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lgsm", "-o", "test"
    system "./test"
  end
end
