class Rmux < Formula
  desc "Terminal multiplexer with a tmux-style CLI and daemon runtime"
  homepage "https://rmux.io"
  url "https://static.crates.io/crates/rmux/rmux-0.10.0.crate"
  sha256 "116b669b1cf4f994f6296a3aa5b329e14c6af26390d12ac0741e2aa31481b630"
  license any_of: ["MIT", "Apache-2.0"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "13587b4acca24ee4d30f717096ad97871efb48e7a8e7e8f7c5f991cbb2d43f2c"
  end

  depends_on "rust" => :build

  def install
    # Fetch all dependencies first so rmux-client sources exist in the cache
    rm_r(Dir.glob("#{HOMEBREW_CACHE}/cargo_cache/registry/src/**/rmux-client-0.10.0"))
    system "cargo", "fetch"

    # Patch rmux-client: std::os::unix::thread::JoinHandleExt::as_pthread_t() returns
    # u64 on OHOS while libc::pthread_t is *mut c_void, so pthread_kill() gets the
    # wrong argument type. Cast explicitly.
    termination = Pathname.glob(
      "#{HOMEBREW_CACHE}/cargo_cache/registry/src/**/rmux-client-0.10.0/src/attach/termination.rs",
    ).first
    inreplace termination,
      "libc::pthread_kill(thread.as_pthread_t(), signal)",
      "libc::pthread_kill(thread.as_pthread_t() as libc::pthread_t, signal)"

    system "cargo", "install", *std_cargo_args
    man1.install "docs/man/rmux.1"
  end

  test do
    require "json"

    assert_match "rmux #{version}", shell_output("#{bin}/rmux -V")
    diagnostics = JSON.parse(shell_output("#{bin}/rmux diagnose --json"))
    assert_equal version.to_s, diagnostics.fetch("version")
  end
end
