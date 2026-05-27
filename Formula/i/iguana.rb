class Iguana < Formula
  desc "Universal serialization engine"
  homepage "https://github.com/qicosmos/iguana"
  url "https://github.com/qicosmos/iguana/archive/refs/tags/1.1.0.tar.gz"
  sha256 "86bf230b5ccea629ad806e4b007d6dcd2e9f0cba8a477c123c920ee0e3329abf"
  license "Apache-2.0"
  head "https://github.com/qicosmos/iguana.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1d1a2684a0f74dcf182a926b61fca5b6e53b49d2a7aa3f8db06fb193a6bd206f"
  end

  depends_on "frozen"

  def install
    include.install "iguana"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <iguana/json_writer.hpp>
      #include <string>
      #include <iostream>
      struct person
      {
        std::string  name;
        int          age;
      };
      auto main() -> int {
        person p = { "tom", 28 };
        std::string ss;
        iguana::to_json(p, ss);
        std::cout << ss << std::endl;
      }
    CPP
    system ENV.cxx, "test.cpp", "-std=c++20", "-L#{lib}", "-o", "test"
    assert_equal "{\"name\":\"tom\",\"age\":28}", shell_output("./test").chomp
  end
end
