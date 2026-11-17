class HerdrCore < Formula
  desc "Terminal and agent core behind the Herdr desktop app"
  homepage "https://herdr.dev"
  url "https://github.com/herdrdev/herdr-core/archive/refs/tags/v0.1.21.tar.gz"
  sha256 "28bffdc1eecd5526e93590f20c8e78d3ebc2a11b19a39821beddc74e8988edd9"
  license "Apache-2.0"
  revision 2
  head "https://github.com/herdrdev/herdr-core.git", branch: "master"

  livecheck do
    url :head
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :git
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/herdr-core-v0.1.21-r3"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "427d9b105d34186c33b3f3b33e50df2665181ef3b0af2583361c84cf6ee260b3"
  end

  depends_on "rust" => :build
  depends_on "zig@0.16" => :build

  # The ghostty-vt crate builds libghostty-vt from the vendor/ghostty submodule,
  # which GitHub archives leave out; its simdutf package only requests PIC for
  # musl/android/freebsd, so the OHOS ABI fails to link the shared vt library
  # with R_AARCH64_ABS64 relocation errors.
  resource "ghostty" do
    url "https://github.com/ghostty-org/ghostty/archive/1e5cdb865807abc990181efb8ebfa9122955cce2.tar.gz"
    sha256 "3157b5a1ddc11040763a772a154b709ed7939a9626c3d1cd9207ebbab3fd2811"

    patch do
      file "Patches/herdr-core/0002-simdutf-pic-ohos.patch"
    end
  end

  # OHOS: the user-storage mount holding $HOME refuses socket nodes and there is
  # no /run/user/<uid>, so the core cannot bind its socket until it falls back
  # to $TMPDIR (an app data dir).
  patch do
    file "Patches/herdr-core/0001-endpoints-ohos-tmpdir.patch"
  end

  # OHOS: the kernel accepts TIOCSWINSZ but never delivers SIGWINCH to the
  # foreground process group, so a pane resize leaves Node/Python programs and
  # TUIs drawing for the old size. Signal the foreground group after resizing.
  patch do
    file "Patches/herdr-core/0003-pty-resize-notify-winch.patch"
  end

  # OHOS: the kernel's edge-triggered epoll can drop a socket's readable event,
  # so tokio stops reading a client: a viewer's CREDIT frames go unread and its
  # output stream stalls for good after a burst of terminal output. Read client
  # sockets on a thread that waits with poll(2) instead.
  patch do
    file "Patches/herdr-core/0004-client-read-without-epoll-edge.patch"
  end

  def install
    resource("ghostty").stage(buildpath/"vendor/ghostty")
    system "cargo", "install", *std_cargo_args(path: "crates/herdr-core")
    bin.install_symlink "herdr-core" => "hc"
  end

  def caveats
    <<~EOS
      The core binds its socket under $TMPDIR: on OHOS the user-storage mount
      holding $HOME cannot hold socket files. Terminals keep running after the
      shell that started them closes; `hc server stop` ends them.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/hc --version")

    ENV["HOME"] = (testpath/"home").to_s
    ENV["XDG_STATE_HOME"] = (testpath/"state").to_s
    ENV["XDG_CONFIG_HOME"] = (testpath/"config").to_s
    ENV["HC_SESSION"] = "brew-test"
    ENV.delete("XDG_RUNTIME_DIR")
    ENV.delete("HC_SOCKET")
    ENV["TMPDIR"] = (testpath/"tmp").to_s if ENV["TMPDIR"].to_s.empty?
    tmpdir = Pathname(ENV.fetch("TMPDIR"))

    assert_equal "hi", shell_output("#{bin}/hc run echo hi").strip
    # The core's socket follows $TMPDIR: the OHOS user-storage mount cannot hold
    # socket nodes and /run/user/<uid> does not exist.
    assert_path_exists tmpdir/"herdr-core/brew-test.sock"
    assert_match version.to_s, shell_output("#{bin}/hc server status")
  ensure
    system bin/"hc", "server", "stop"
  end
end
