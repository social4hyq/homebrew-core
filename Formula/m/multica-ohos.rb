class MulticaOhos < Formula
  desc "Build assets for the Multica desktop HarmonyOS port (patch, scripts, branding)"
  homepage "https://github.com/social4hyq/ohos-multica"
  url "https://github.com/social4hyq/ohos-multica/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "e94b0126aaba665e6ec961f1cd171178594f8c3db130192d6e30c713d2d2af5f"
  license :cannot_represent # Multica License (repo LICENSE); original tooling per NOTICE

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/multica-ohos-v0.1.0-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "03b5a2b93a18ce378ad8d74757a311679c811971bc375ab680027443eec1ae50"
  end

  def install
    pkgshare.install %w[patches scripts hap-work hap-branding electron-prebuilt minimality]
    pkgshare.install "BUILD-PIPELINE.md"
  end

  def caveats
    <<~EOS
      Pipeline assets are installed to:
        #{opt_pkgshare}

      The Multica source checkout and the Electron OHOS prebuilt zip are not
      bundled. Full build steps and prerequisites:
        #{opt_pkgshare}/BUILD-PIPELINE.md

      The scripts honor MULTICA_SOURCE to point at a multica-ai/multica
      checkout (see the pinned commit in BUILD-PIPELINE.md); the daemon/CLI
      comes from the separate `multica` formula.
    EOS
  end

  test do
    assert_path_exists pkgshare/"patches/0001-desktop-ohos.patch"
    assert_path_exists pkgshare/"scripts/build-desktop.sh"
    assert_path_exists pkgshare/"BUILD-PIPELINE.md"
    system "git", "apply", "--numstat", pkgshare/"patches/0001-desktop-ohos.patch"
  end
end
