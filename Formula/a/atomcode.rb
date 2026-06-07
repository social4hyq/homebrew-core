class Atomcode < Formula
  desc "Open-source alternative to Claude Code / Cursor Agent, living in your terminal"
  homepage "https://atomcode.atomgit.com/"
  url "https://raw.atomgit.com/atomgit_atomcode/atomcode/archive/refs/heads/v4.25.0.tar.gz"
  sha256 "93da017f921650dcf8e26b49153d4765964b481d23be4b04d326887ba1c38ef4"
  license "MIT"

  livecheck do
    url "https://atomgit.com/atomgit_atomcode/atomcode.git"
    strategy :git
    regex(/^v?(\d+\.\d+(?:\.\d+)+)$/i)
  end

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ad227369a75f2c96e736d8c529689bb1ba73648ac0c9a2d6a647cd4906172cb6"
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
