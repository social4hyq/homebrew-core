class Concurrencykit < Formula
  desc "Aid design and implementation of concurrent systems"
  # site not accessible bug report, https://github.com/concurrencykit/ck/issues/225
  homepage "https://github.com/concurrencykit/ck"
  url "https://github.com/concurrencykit/ck/archive/refs/tags/0.7.2.tar.gz"
  sha256 "568ebe0bc1988a23843fce6426602e555b7840bf6714edcdf0ed530214977f1b"
  license "BSD-2-Clause"
  head "https://github.com/concurrencykit/ck.git", branch: "master"

  # Upstream creates releases that use a stable tag (e.g., `v1.2.3`) but are
  # labeled as "pre-release" on GitHub before the version is released, so it's
  # necessary to use the `GithubLatest` strategy.
  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "14da6cedc0fb7660bc86db76032a01e1e4d8bb396209ded5c19e48f1ef221f20"
  end

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <ck_spinlock.h>
      int main()
      {
        ck_spinlock_t spinlock;
        ck_spinlock_init(&spinlock);
        return 0;
      }
    C
    system ENV.cc, "-I#{include}", "-L#{lib}", "-lck",
           testpath/"test.c", "-o", testpath/"test"
    system "./test"
  end
end
