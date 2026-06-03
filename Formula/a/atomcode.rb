class Atomcode < Formula
  desc "Open-source alternative to Claude Code / Cursor Agent, living in your terminal"
  homepage "https://atomcode.atomgit.com/"
  url "https://raw.atomgit.com/atomgit_atomcode/atomcode/archive/refs/heads/v4.24.1.tar.gz"
  sha256 "fcf6dde54993aee0d1635b880bce2d1a63c56657f6be5cbfcaad76df25f48446"
  license "MIT"

  livecheck do
    url "https://atomgit.com/atomgit_atomcode/atomcode.git"
    strategy :git
    regex(/^v?(\d+\.\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f199dd09dedb746bd00a0d5d6693948b0ee570e52ade02ac8129e46f27b57fea"
  end

  depends_on "node" => :build
  depends_on "rust" => :build

  def install
    # The binary embeds webui/dist via rust-embed at compile time, but those
    # built assets are gitignored and so absent from the source tarball. Build
    # the frontend first, otherwise /webui serves a blank page. (cargo fetches
    # crates over the network during the build, so npm can fetch deps too.)
    cd "webui" do
      system "npm", "ci"
      system "npm", "run", "build"
    end

    # --features distro-pm marks this as a package-manager-managed build: the
    # in-app self-update is disabled and /upgrade tells users to run
    # `brew upgrade atomcode` instead of rewriting the binary itself.
    system "cargo", "install", *std_cargo_args(path: "crates/atomcode-cli"), "--features", "distro-pm"
  end

  test do
    assert_match "atomcode", shell_output("#{bin}/atomcode -V")
  end
end
