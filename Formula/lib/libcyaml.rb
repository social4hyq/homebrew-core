class Libcyaml < Formula
  desc "C library for reading and writing YAML"
  homepage "https://github.com/tlsa/libcyaml"
  url "https://github.com/tlsa/libcyaml/archive/refs/tags/v1.4.2.tar.gz"
  sha256 "3211b2a0589ebfe02c563c96adce9246c0787be2af30353becbbd362998d16dc"
  license "ISC"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1173fd1afc4eec9ff284790ba9d6f4ef155ec1a4b45fa2e922fc86b8658e29f0"
  end

  depends_on "libyaml"

  def install
    system "make", "install", "PREFIX=#{prefix}"
    pkgshare.install "examples/numerical/main.c" => "test.c"
  end

  test do
    flags = %W[
      -I#{include} -I#{Formula["libyaml"].opt_include}
      -L#{lib} -L#{Formula["libyaml"].opt_lib}
      -lcyaml -lyaml
      -o test
    ]

    system ENV.cc, pkgshare/"test.c", *flags

    (testpath/"test.yaml").write "name: Numbers\ndata:\n- 1\n- 2\n- 4\n- 8\n"
    expected_output = "Numbers:\n  - 1\n  - 2\n  - 4\n  - 8\n"
    assert_equal expected_output, shell_output("#{testpath}/test #{testpath}/test.yaml")
  end
end
