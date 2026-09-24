class OpencodeV2 < Formula
  desc "AI coding agent, built for the terminal"
  homepage "https://opencode.ai"
  url "https://github.com/anomalyco/opencode.git", revision: "6f3639d82ed0760091792189b78f8eeb44f699b1"
  version "2.0.15"
  license "MIT"
  version_scheme 1

  livecheck do
    url :stable
    regex(/^v(2\.\d+\.\d+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode-v2-v2.0.15-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "64ce6ad76fb639fbe6c1257f1a01e4622f00a2fd29342368d4d1adfad1a55f7b"
  end

  depends_on "bun" => :build
  depends_on "node" => :build

  # Officially v2 replaces v1 in place (same config/data dirs, binary name
  # "opencode"); mirror the upstream anomalyco/tap/opencode-v2 formula.
  conflicts_with "opencode", because: "both install an opencode binary"

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
  ].each do |p|
    patch do
      file "Patches/opencode-v2/#{p}"
    end
  end

  deny_network_access! :test

  def install
    # prune web/ui packages unused by the CLI build; upstream drops/renames
    # these between versions, so guard against missing paths (packages/www
    # vanished in 2.0.7 — rm_r would raise ENOENT)
    %w[packages/web packages/www packages/storybook packages/enterprise].each do |d|
      rm_r d if File.directory?(d)
    end

    ENV["OPENCODE_VERSION"] = "#{version}_#{revision}"
    ENV["OPENCODE_CHANNEL"] = "beta"

    resource("solidjs-start").stage buildpath/"vendor/solidjs-start"
    inreplace "package.json", "https://pkg.pr.new/@solidjs/start@dfb2020",
              "file:./vendor/solidjs-start"

    system "bun", "install", "--ignore-scripts"

    cd "packages/cli" do
      system "bun", "run", "script/build.ts", "--single"
    end

    out = "packages/cli/dist/cli-linux-arm64-musl/bin/opencode"
    odie "opencode binary missing" unless File.exist?(out)

    bin.install out

    generate_completions_from_executable(bin/"opencode", "--completions",
                                         base_name: "opencode")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/opencode --version 2>&1")
  end
end
