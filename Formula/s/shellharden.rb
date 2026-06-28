class Shellharden < Formula
  desc "Bash syntax highlighter that encourages/fixes variables quoting"
  homepage "https://github.com/anordal/shellharden"
  url "https://github.com/anordal/shellharden/archive/refs/tags/v4.3.2.tar.gz"
  sha256 "3a6721c3409c70449c24a5b33f83d0d05026f2318fe052db5c6d0834e2b29c6c"
  license "MPL-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8e62bd93fc18b110801859faaa5082d2bdf46b238f9337bb386bab1178498800"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    (testpath/"script.sh").write <<~SH
      dog="poodle"
      echo $dog
    SH
    system bin/"shellharden", "--replace", "script.sh"
    assert_match "echo \"$dog\"", (testpath/"script.sh").read
  end
end
