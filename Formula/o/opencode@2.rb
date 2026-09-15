class OpencodeAT2 < Formula
  desc "AI coding agent, built for the terminal"
  homepage "https://opencode.ai"
  url "https://github.com/anomalyco/opencode.git", revision: "ad31bff969fe386266d3d1cd24d988651d3233af"
  version "0.0.0-beta-19271"
  license "MIT"
  revision 6
  version_scheme 1

  livecheck do
    url "https://registry.npmmirror.com/@opencode-ai/cli/beta"
    strategy :json do |json|
      json["version"]
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode@2-v0.0.0-beta-19271-r7"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "872f8a74ea288818d01c3c796cd861ae2510b22c6768747b5993b0391f185110"
  end

  depends_on "bun" => :build
  depends_on "node" => :build

  resource "solidjs-start" do
    url "https://pkg.pr.new/@solidjs/start@dfb2020"
    sha256 "0c90be86818a667aa3b2dd5611c54f96d3451e1836f562ec2cecd99f7979e7e5"
  end

  %w[
    0001-update-package-json.patch
    0002-update-bun-lock.patch
    0003-update-filesystem-watcher.patch
    0004-update-watcher-binding.patch
    0005-update-server-connection.patch
    0006-update-build-target.patch
    0007-update-app-data-directory.patch
  ].each do |p|
    patch do
      file "Patches/opencode@2/#{p}"
    end
  end

  deny_network_access! :test

  def install
    rm_r %w[packages/web
            packages/www packages/storybook packages/enterprise]

    ENV["OPENCODE_VERSION"] = "#{version}_#{revision}"
    ENV["OPENCODE_CHANNEL"] = "beta"

    resource("solidjs-start").stage buildpath/"vendor/solidjs-start"
    inreplace "package.json", "https://pkg.pr.new/@solidjs/start@dfb2020",
              "file:./vendor/solidjs-start"

    system "bun", "install", "--ignore-scripts"

    cd "packages/cli" do
      system "bun", "run", "script/build.ts", "--single"
    end

    out = "packages/cli/dist/cli-linux-arm64-musl/bin/opencode2"
    odie "opencode2 binary missing" unless File.exist?(out)

    bin.install out => "opencode2"

    generate_completions_from_executable(bin/"opencode2", "--completions",
                                         base_name: "opencode2")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/opencode2 --version 2>&1")
  end
end
