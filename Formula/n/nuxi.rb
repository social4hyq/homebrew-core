class Nuxi < Formula
  desc "Nuxt CLI (nuxi) for creating and managing Nuxt projects"
  homepage "https://github.com/nuxt/cli"
  url "https://registry.npmjs.org/nuxi/-/nuxi-3.37.0.tgz"
  sha256 "7a1baab0c139adc9190f14eeab95132ff386d8157d34253c245829ead52cbe76"
  license "MIT"
  head "https://github.com/nuxt/cli.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b62ceee35f13115071237442f88d2cd37de6621fb96b347769969a413e354cf8"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    # Both aliases should be present and report the same version
    assert_match version.to_s, shell_output("#{bin}/nuxi --version")
    assert_match version.to_s, shell_output("#{bin}/nuxt --version")

    # Perform a minimal project initialization in the temporary testpath
    ENV["CI"] = "1"
    target = testpath/"nuxi-tmp"
    output = shell_output(
      "#{bin}/nuxt init . --cwd #{target} -f --template=minimal --gitInit --packageManager=npm --preferOffline",
    )
    assert_predicate target, :directory?
    assert_predicate target/".git", :directory?
    assert_path_exists target/"package.json"
    assert_match "npm run dev", output
  end
end
