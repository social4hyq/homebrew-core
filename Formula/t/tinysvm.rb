class Tinysvm < Formula
  desc "Support vector machine library for pattern recognition"
  homepage "http://chasen.org/~taku/software/TinySVM/"
  url "https://cdn.netbsd.org/pub/pkgsrc/distfiles/TinySVM-0.09.tar.gz"
  mirror "http://chasen.org/~taku/software/TinySVM/src/TinySVM-0.09.tar.gz"
  sha256 "e377f7ede3e022247da31774a4f75f3595ce768bc1afe3de9fc8e962242c7ab8"
  license "LGPL-2.1-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?TinySVM[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "80dbc1cedb4e249b7801ea4c8f9cd9e4cb39fc7315fb830171fc0da475b95582"
  end

  # Use correct compilation flag, via MacPorts.
  patch :p0 do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/tinysvm/patch-configure.diff"
    sha256 "b4cd84063fd56cdcb0212528c6d424788528a9d6b8b0a17aa01294773c62e8a7"
  end

  def install
    # Needed to select proper getopt, per MacPorts
    ENV.append_to_cflags "-D__GNU_LIBRARY__"

    # Fix for newer clang
    ENV.append_to_cflags "-Wno-implicit-int" if DevelopmentTools.clang_build_version >= 1403

    args = []
    # Help old config scripts identify arm64 linux
    args << "--host=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", "--mandir=#{man}", "--disable-shared", *args, *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"train.svmdata").write <<~EOS
      +1 201:1.2 3148:1.8 3983:1 4882:1
      -1 874:0.3 3652:1.1 3963:1 6179:1
      +1 1168:1.2 3318:1.2 3938:1.8 4481:1
      +1 350:1 3082:1.5 3965:1 6122:0.2
      -1 99:1 3057:1 3957:1 5838:0.3
    EOS

    (testpath/"train.svrdata").write <<~EOS
      0.23 201:1.2 3148:1.8 3983:1 4882:1
      0.33 874:0.3 3652:1.1 3963:1 6179:1
      -0.12 1168:1.2 3318:1.2 3938:1.8 4481:1
    EOS

    system bin/"svm_learn", "-t", "1", "-d", "2", "-c", "train.svmdata", "test"
    system bin/"svm_classify", "-V", "train.svmdata", "test"
    system bin/"svm_model", "test"

    assert_path_exists testpath/"test"
  end
end
