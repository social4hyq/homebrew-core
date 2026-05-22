class Mox < Formula
  desc "Modern full-featured open source secure mail server"
  homepage "https://www.xmox.nl"
  url "https://github.com/mjl-/mox/archive/refs/tags/v0.0.15.tar.gz"
  sha256 "21d56acb240458af5dfe31f91010f0e1bf5988d55d9c15d8c078440d7ce4b66a"
  license "MIT"
  head "https://github.com/mjl-/mox.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "305f1a7a16580f16b643a2a1de2953e29d8daead717a975fa21409c8630e2a0e"
  end

  depends_on "go" => :build

  # Allow setting the version during buildtime
  patch do
    url "https://raw.githubusercontent.com/NixOS/nixpkgs/1ac75001649e3822e9caffaad85d7f1db76e9482/pkgs/by-name/mo/mox/version.patch"
    sha256 "5c35e348e27a235fad80f6a8f68c89fb37d95c9152360619795f2fdd5dc7403f"
  end

  def install
    ldflags = %W[
      -s -w
      -X github.com/mjl-/mox/moxvar.Version=#{version}
      -X github.com/mjl-/mox/moxvar.VersionBare=#{version}
      -X main.changelogURL=none
    ]
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    user = ENV["USER"]
    system bin/"mox", "quickstart", "-skipdial", "email@example.com", user
    assert_path_exists testpath/"config"
    assert_path_exists testpath/"config/mox.conf"

    assert_match "config OK", shell_output("#{bin}/mox config test")

    assert_match version.to_s, shell_output("#{bin}/mox version")
  end
end
