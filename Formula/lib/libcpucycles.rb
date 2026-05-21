class Libcpucycles < Formula
  desc "Microlibrary for counting CPU cycles"
  homepage "https://cpucycles.cr.yp.to/"
  url "https://cpucycles.cr.yp.to/libcpucycles-20260105.tar.gz"
  sha256 "e87dcaaa28e905b574ccf3d49e23e05c73edb3f99136dcd566bca16829ab6694"
  license any_of: [:public_domain, "CC0-1.0", "0BSD", "MIT-0", "MIT"]

  livecheck do
    url "https://cpucycles.cr.yp.to/libcpucycles-latest-version.txt"
    regex(/^v?(\d{8})$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bab2234a5f50b90f8fac6fb8c5e40f9d0570fb6565f0eee0852cdb3816a209f0"
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
