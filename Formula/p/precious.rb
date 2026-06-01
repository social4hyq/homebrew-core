class Precious < Formula
  desc "One code quality tool to rule them all"
  homepage "https://github.com/houseabsolute/precious"
  url "https://github.com/houseabsolute/precious/archive/refs/tags/v0.11.0.tar.gz"
  sha256 "87b5c72e22f83ac502721da58d5560866a8efccefc6f55646d59ce7402d74d0a"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/houseabsolute/precious.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "eb40dba085d12f99b84dba3b17862aeab9a832a2dc02edda4a483335a956d5ae"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/precious --version")

    system bin/"precious", "config", "init", "--auto"
    assert_path_exists testpath/"precious.toml"
  end
end
