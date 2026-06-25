class Railway < Formula
  desc "Develop and deploy code with zero configuration"
  homepage "https://railway.com/"
  url "https://github.com/railwayapp/cli/archive/refs/tags/v5.23.0.tar.gz"
  sha256 "f0757217606534af30a4e54e93cb53f8f9ade90e56df11c47ab03a7c08685133"
  license "MIT"
  head "https://github.com/railwayapp/cli.git", branch: "master"

  bottle do
    root_url "http://192.168.0.27:20080/bottles"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e565bfa804561fb63ac44a48ba1a2880520eed5c3901f019750f115cc0c5c4fd"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"railway", "completion")
  end

  test do
    output = shell_output("#{bin}/railway init 2>&1", 1).chomp
    assert_match "Unauthorized. Please login with `railway login`", output

    assert_equal "railway #{version}", shell_output("#{bin}/railway --version").strip
  end
end
