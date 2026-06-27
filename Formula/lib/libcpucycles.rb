class Libcpucycles < Formula
  desc "Microlibrary for counting CPU cycles"
  homepage "https://cpucycles.cr.yp.to/"
  url "https://cpucycles.cr.yp.to/libcpucycles-20260625.tar.gz"
  sha256 "74a815bfb5ab645e5d07617125824c946ce5039db139e5233467d1ff33f69afa"
  license any_of: [:public_domain, "CC0-1.0", "0BSD", "MIT-0", "MIT"]

  livecheck do
    url "https://cpucycles.cr.yp.to/libcpucycles-latest-version.txt"
    regex(/^v?(\d{8})$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ac78df89e0fba13a37ead930b479f5270ba9bccec39005b8c2eb331bc4a63101"
  end

  uses_from_macos "python" => :build

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
    share.install prefix/"man"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <assert.h>
      #include <cpucycles.h>

      int main(void) {
        assert(cpucycles() < cpucycles());
        return 0;
      }
    C
    system ENV.cc, "test.c", "-o", "test", "-L#{lib}", "-lcpucycles"
    system "./test"

    assert_match(/^cpucycles version #{version}$/, shell_output(bin/"cpucycles-info"))
  end
end
