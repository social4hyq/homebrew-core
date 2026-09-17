class Lerna < Formula
  desc "Tool for managing JavaScript projects with multiple packages"
  homepage "https://lerna.js.org"
  url "https://registry.npmjs.org/lerna/-/lerna-10.0.1.tgz"
  sha256 "82addf9fca6007e0cb504085038975fd78d6d3538529379c8162c832ce2da8fe"
  license "MIT"

  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2ed6b14490f3bf4defcdc9991ddccd0d3b10680708c6a7e0a79ef15dee72dadd"
  end

  depends_on "node"

  def install
    # Pin nx to 23.1.1: nx 23.2.x (resolved by lerna's ">=23.1.0 < 24.0.0"
    # range since 2026-09-02) hangs the CLI after init completes (WASM
    # worker lifecycle regression), breaking brew test with a timeout.
    # 23.1.1 is the version the official 2026-08-21 CI build
    # (harmonybrew-ci-17302) installed and passed with.
    inreplace "package.json", '"@nx/devkit": ">=23.1.0 < 24.0.0"', '"@nx/devkit": "23.1.1"'
    inreplace "package.json", '"nx": ">=23.1.0 < 24.0.0"', '"nx": "23.1.1"'
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")

    # OpenHarmony: open('/') returns EACCES on this platform, which breaks
    # uvwasi_init in the WASI fallback loader bundled with nx (lerna's task
    # orchestrator). Patch the preopen root to the deepest accessible
    # ancestor of cwd so the WASM fallback works on OpenHarmony.
    # NOTE: locate nx dynamically since the pin above may cause npm to
    # hoist it to the top-level node_modules instead of nesting it.
    patch_dir = File.expand_path("../../Patches/lerna", __dir__)
    wasi_dir = Dir[libexec/"lib/node_modules/**/nx/dist/src/native"].map(&:to_s).first
    odie "nx dist/src/native not found" if wasi_dir.nil?
    system "patch", "-p1", "-d", wasi_dir, "-i", "#{patch_dir}/0001-nx-wasi-preopen-accessible-root.patch"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/lerna --version")

    output = shell_output("#{bin}/lerna init --independent 2>&1")
    assert_match "lerna success Initialized Lerna files", output
  end
end
