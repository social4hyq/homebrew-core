class Yazi < Formula
  desc "Blazing fast terminal file manager written in Rust, based on async I/O"
  homepage "https://github.com/sxyazi/yazi"
  url "https://github.com/sxyazi/yazi/archive/refs/tags/v26.5.6.tar.gz"
  sha256 "a18445df86a20068f7b17609d12d6f635de488958579ae7a2b143a244ba7e63f"
  license "MIT"
  head "https://github.com/sxyazi/yazi.git", branch: "main"

  # There can be a notable gap between when a version is tagged and a
  # corresponding release is created, so we check the "latest" release instead
  # of the Git tags.
  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5870dac84eca7fe1996bd0bfb731fd394e465ce23e1323a5493b7d5b3556adc5"
  end

  depends_on "rust" => :build

  patch do
    file "Patches/yazi@26.5.6/0001-ohos-skip-jemalloc.patch"
  end

  def install
    # Homebrew superenv rewrites HOME -> buildpath/.brew_home, so cargo defaults
    # CARGO_HOME=$HOME/.cargo (empty buildpath) and bypasses the ci-runner crates.io mirror
    # at /root/.cargo/config.toml. Pin CARGO_HOME when that directory exists.
    # No-op outside ci-runner.
    ENV["CARGO_HOME"] = "/root/.cargo" if File.directory?("/root/.cargo")

    ENV["VERGEN_GIT_SHA"] = tap.user
    ENV["YAZI_GEN_COMPLETIONS"] = "1"
    system "cargo", "install", *std_cargo_args(path: "yazi-fm")
    system "cargo", "install", *std_cargo_args(path: "yazi-cli")

    bash_completion.install "yazi-boot/completions/yazi.bash" => "yazi"
    zsh_completion.install "yazi-boot/completions/_yazi"
    fish_completion.install "yazi-boot/completions/yazi.fish"

    bash_completion.install "yazi-cli/completions/ya.bash" => "ya"
    zsh_completion.install "yazi-cli/completions/_ya"
    fish_completion.install "yazi-cli/completions/ya.fish"
  end

  test do
    # yazi is a GUI application
    assert_match "Yazi #{version}", shell_output("#{bin}/yazi --version").strip
  end
end
