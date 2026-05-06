require File.expand_path("../../Abstract/portable-formula", __dir__)

class PortableLibyaml < PortableFormula
  desc "YAML Parser"
  homepage "https://github.com/yaml/libyaml"
  url "https://github.com/yaml/libyaml/releases/download/0.2.5/yaml-0.2.5.tar.gz"
  sha256 "c642ae9b75fee120b2d96c712538bd2cf283228d2337df2cf2988e3c02678ef4"
  license "MIT"

  livecheck do
    formula "libyaml"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4cd04c04e33ede866363363b63ce25c3ce12b578b0598402abd2145ee22d9aa4"
  end

  def install
    system "./configure", *portable_configure_args,
                          "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--enable-static",
                          "--disable-shared"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <yaml.h>

      int main()
      {
        yaml_parser_t parser;
        yaml_parser_initialize(&parser);
        yaml_parser_delete(&parser);
        return 0;
      }
    EOS
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lyaml", "-o", "test"
    system "./test"
  end
end
