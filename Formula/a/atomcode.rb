class Atomcode < Formula
  desc "Open-source alternative to Claude Code / Cursor Agent, living in your terminal"
  homepage "https://atomcode.atomgit.com/"
  url "https://github.com/atomgit-atomcode/atomcode/archive/refs/tags/v5.0.9.tar.gz"
  sha256 "771025a43ce861b8049d1cbbb37a5ae887ed2b8c252d0344cd07f9909d9813f9"
  license "MIT"
  revision 1

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "da0cf40b4ebf20de56608a573e6ece8345a4ec3b7704bbebf7d97198367450b1"
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

  def caveats
    <<~EOS
      The 'CodingPlan' feature is only supported in official builds from AtomGit
      due to upstream licensing/anti-abuse restrictions.

      Since this formula is built from source by Harmonybrew, CodingPlan will NOT
      be available.

      If you strictly require CodingPlan, please use the official build.
      Get it from the official website:
        https://atomcode.atomgit.com/
    EOS
  end

  test do
    assert_match "atomcode", shell_output("#{bin}/atomcode -V")
  end
end
