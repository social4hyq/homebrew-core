class Insect < Formula
  desc "High precision scientific calculator with support for physical units"
  homepage "https://github.com/sharkdp/insect"
  url "https://registry.npmjs.org/insect/-/insect-5.9.0.tgz"
  sha256 "dcb8d696e9209157f596c7c102cdc436d520629d2aed71585767af77bde2cb70"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cf76cc562504effdae8a54ec76d5f82e2e4ee9b59f1fe8f09191422772cd1c0a"
  end

  # deprecated in favor of `numbat` formula, https://github.com/sharkdp/insect/commit/6c7dea10a491b55250acede0bd740e72177d8945
  # see https://github.com/sharkdp/numbat/blob/master/assets/reasons-for-rewriting-in-rust.md
  deprecate! date: "2024-12-28", because: :unmaintained, replacement_formula: "numbat"
  disable! date: "2025-12-28", because: :unmaintained, replacement_formula: "numbat"

  depends_on "node"

  on_linux do
    depends_on "xsel"
  end

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")

    clipboardy_fallbacks_dir = libexec/"lib/node_modules/#{name}/node_modules/clipboardy/fallbacks"
    rm_r(clipboardy_fallbacks_dir) # remove pre-built binaries
    if OS.linux?
      linux_dir = clipboardy_fallbacks_dir/"linux"
      linux_dir.mkpath
      # Replace the vendored pre-built xsel with one we build ourselves
      ln_sf (Formula["xsel"].opt_bin/"xsel").relative_path_from(linux_dir), linux_dir
    end
  end

  test do
    assert_equal "120000 ms", shell_output("#{bin}/insect '1 min + 60 s -> ms'").chomp
    assert_equal "299792458 m/s", shell_output("#{bin}/insect speedOfLight").chomp
  end
end
