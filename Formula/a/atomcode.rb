class Atomcode < Formula
  desc "Open-source alternative to Claude Code / Cursor Agent, living in your terminal"
  homepage "https://atomcode.atomgit.com/"
  url "https://github.com/atomgit-atomcode/atomcode/archive/refs/tags/v5.0.7.tar.gz"
  sha256 "1481ed69a50e534a7b3f471a15ebcfb4cf37fc2c5aca6ffe06e0938f7923e6ed"
  license "MIT"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d557d33e1aeef77a9278958af770c010ce2e2f34339b4fd45e1f50c619d0f125"
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
