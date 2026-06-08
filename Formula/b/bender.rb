class Bender < Formula
  desc "Dependency management tool for hardware projects"
  homepage "https://github.com/pulp-platform/bender"
  url "https://github.com/pulp-platform/bender/archive/refs/tags/v0.31.0.tar.gz"
  sha256 "7b03dc86a8dcd43b278f84758af287eeb3194bdb707f30ddf9f879e05ab10b7c"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/pulp-platform/bender.git", branch: "master"

  no_autobump! because: "newer version requires ohos-sdk with full c++20 support"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9a7ebad507da8fef1cd7ea01d87c61eaceda98d608d139dc0a5e55fa1495ee73"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"bender", "completion", shells: [:bash, :zsh, :fish, :pwsh])
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/bender --version")

    system bin/"bender", "init"
    assert_match "manifest format `Bender.yml`", (testpath/"Bender.yml").read
  end
end
