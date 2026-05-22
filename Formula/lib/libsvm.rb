class Libsvm < Formula
  desc "Library for support vector machines"
  homepage "https://www.csie.ntu.edu.tw/~cjlin/libsvm/"
  url "https://www.csie.ntu.edu.tw/~cjlin/libsvm/libsvm-3.37.tar.gz"
  sha256 "1fa553edc776be3d62fab4607b96ffa505093ea6e3e759a4c7f96294ff75e29a"
  license "BSD-3-Clause"
  head "https://github.com/cjlin1/libsvm.git", branch: "master"

  livecheck do
    url :homepage
    regex(/The current release \(Version v?(\d+(?:\.\d+)+)[, )]/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5d2095b4a2672450fe6e4e697d098f064f94eaf312e28ff19b873444025e145c"
  end

  def install
    libsvm_soversion = nil
    inreplace "Makefile" do |s|
      s.gsub! "libsvm.so.$(SHVER)", "libsvm.$(SHVER).dylib" if OS.mac?
      libsvm_soversion = s.get_make_var("SHVER")
    end

    system "make"
    system "make", "lib"
    bin.install "svm-scale", "svm-train", "svm-predict"
    include.install "svm.h"
    lib.install shared_library("libsvm", libsvm_soversion)
    lib.install_symlink shared_library("libsvm", libsvm_soversion) => shared_library("libsvm")
  end

  test do
    assert_path_exists lib/shared_library("libsvm")

    (testpath/"train_classification.txt").write <<~EOS
      +1 201:1.2 3148:1.8 3983:1 4882:1
      -1 874:0.3 3652:1.1 3963:1 6179:1
      +1 1168:1.2 3318:1.2 3938:1.8 4481:1
      +1 350:1 3082:1.5 3965:1 6122:0.2
      -1 99:1 3057:1 3957:1 5838:0.3
    EOS

    (testpath/"train_regression.txt").write <<~EOS
      0.23 201:1.2 3148:1.8 3983:1 4882:1
      0.33 874:0.3 3652:1.1 3963:1 6179:1
      -0.12 1168:1.2 3318:1.2 3938:1.8 4481:1
    EOS

    system bin/"svm-train", "-s", "0", "train_classification.txt"
    system bin/"svm-train", "-s", "3", "train_regression.txt"
    return unless OS.mac?

    assert (lib/shared_library("libsvm")).dylib_id.end_with?("dylib")
  end
end
