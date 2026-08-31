class Snap < Formula
  desc "Tool to work with .snap files"
  homepage "https://snapcraft.io/"
  url "https://github.com/canonical/snapd/releases/download/2.76.3/snapd_2.76.3.vendor.tar.xz"
  sha256 "d97627913cbe4ec0a72b507e561f7c9da87c4be5c59412a3e1a94bdc079fa838"
  license "GPL-3.0-only"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bdfffe3401a3b04b5dd16f7c495f6ad92119adfd57595ba51fb8303a5f36b7f7"
  end

  depends_on "go" => :build
  depends_on "squashfs"

  def install
    # TODO: Drop when a release tarball ships a `vendor` synced with `go.mod`.
    inreplace "mkversion.sh", "MOD=-mod=vendor", "MOD=-mod=mod"

    system "./mkversion.sh", version.to_s
    tags = OS.mac? ? "nosecboot" : ""
    system "go", "build", "-mod=mod", *std_go_args(tags:), "./cmd/snap"

    bash_completion.install "data/completion/bash/snap"
    zsh_completion.install "data/completion/zsh/_snap"

    (man8/"snap.8").write Utils.safe_popen_read(bin/"snap", "help", "--man")
  end

  test do
    (testpath/"pkg/meta").mkpath
    (testpath/"pkg/meta/snap.yaml").write <<~YAML
      name: test-snap
      version: 1.0.0
      summary: simple summary
      description: short description
    YAML
    system bin/"snap", "pack", "pkg"
    system bin/"snap", "version"
  end
end
