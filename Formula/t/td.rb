class Td < Formula
  desc "Your todo list in your terminal"
  homepage "https://github.com/Swatto/td"
  url "https://github.com/Swatto/td/archive/refs/tags/1.4.2.tar.gz"
  sha256 "e85468dad3bf78c3fc32fc2ab53ef2d6bc28c3f9297410917af382a6d795574b"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1737e319638e484385f1930b3f81cbd9d8451a9836aad5566531fa9843c5f8f9"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    (testpath/".todos").write "[]\n"
    system bin/"td", "a", "todo of test"
    todos = (testpath/".todos").read
    assert_match "todo of test", todos
    assert_match "pending", todos
  end
end
