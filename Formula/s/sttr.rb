class Sttr < Formula
  desc "CLI to perform various operations on string"
  homepage "https://github.com/abhimanyu003/sttr"
  url "https://github.com/abhimanyu003/sttr/archive/refs/tags/v0.2.30.tar.gz"
  sha256 "64c4ddd6f84c99f197053e96c489dea48c0bd83a33dfdd69ab209653bc38b9c8"
  license "MIT"
  head "https://github.com/abhimanyu003/sttr.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "97e51dc9b584e291d8677761f669cb633b4f8c5600aa12954e5ba6663dffb596"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}")
    generate_completions_from_executable(bin/"sttr", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/sttr version")

    assert_equal "foobar", shell_output("#{bin}/sttr reverse raboof")

    output = shell_output("#{bin}/sttr sha1 foobar")
    assert_equal "8843d7f92416211de9ebb963ff4ce28125932878", output

    assert_equal "good_test", shell_output("#{bin}/sttr snake 'good test'")
  end
end
