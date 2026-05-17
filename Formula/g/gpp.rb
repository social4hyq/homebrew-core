class Gpp < Formula
  desc "General-purpose preprocessor with customizable syntax"
  homepage "https://logological.org/gpp"
  url "https://files.nothingisreal.com/software/gpp/gpp-2.28.tar.bz2"
  sha256 "343d33d562e2492ca9b51ff2cc4b06968a17a85fdc59d5d4e78eed3b1d854b70"
  license "LGPL-3.0-only"

  livecheck do
    url "https://files.nothingisreal.com/software/gpp/"
    regex(/href=.*?gpp[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dfde2e2b865b1befdbf2dd49f64d817747e8aeebc0a90d9e02ab1a0cc6f1925f"
  end

  head do
    url "https://github.com/logological/gpp.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  def install
    system "autoreconf", "--force", "--install", "--verbose" if build.head?
    system "./configure", *std_configure_args.reject { |s| s["--disable-debug"] },
                          "--mandir=#{man}"
    system "make"
    system "make", "check"
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gpp --version")

    (testpath/"test.cpp").write <<~CPP
      #define FOO This is
      #define BAR a message.
      #define concat #1 #2
      concat(FOO,BAR)
      #ifeq (concat(foo,bar)) (foo bar)
      This is output.
      #else
      This is not output.
      #endif
    CPP

    assert_match "This is a message.\nThis is output.", shell_output("#{bin}/gpp #{testpath}/test.cpp")
  end
end
