class Opencode < Formula
  desc "AI coding agent, built for the terminal"
  homepage "https://opencode.ai"
  url "https://github.com/anomalyco/opencode/archive/refs/tags/v1.18.31.tar.gz"
  sha256 "76f69fe27ec2b44e23fa1749029e7c012eb7e975a0f0c7819e9458198dfd3896"
  license "MIT"
  revision 5

  livecheck do
    url :stable
    strategy :github_latest
    throttle 5
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode-v1.18.31-r10"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c56644a2088a1334e4a43d4bfa7dfddad923d375c80720209170df2f8c3de4ea"
  end

  depends_on "bun" => :build
  depends_on "node" => :build
  depends_on "python@3.14" => :build
  depends_on "ripgrep"

  on_linux do
    depends_on "icu4c@78"
  end

  %w[
    0001-update-package-json.patch
    0002-update-filesystem-watcher.patch
    0003-update-project-root.patch
    0004-update-build-target.patch
    0005-update-project-worktree.patch
    0006-filter-invalid-references.patch
    0007-break-filesystem-search-import-cycle.patch
  ].each do |p|
    patch do
      file "Patches/opencode/#{p}"
    end
  end

  deny_network_access! :test

  def install
    ENV["OPENCODE_VERSION"] = version.to_s
    ENV["OPENCODE_CHANNEL"] = "prod"

    lockfile = (buildpath/"bun.lock").read
    injected = lockfile.gsub(
      /("[^"]*openharmony-arm64@[^"]+", "", \{ )"os": "none"(, "cpu": "arm64" \})/,
      %q(\1"os": "openharmony"\2),
    )
    odie "opencode: no openharmony-arm64 os:none markers found in bun.lock" if injected == lockfile
    (buildpath/"bun.lock").atomic_write(injected)

    system "bun", "install", "--ignore-scripts"

    cd "packages/opencode" do
      system "bun", "--bun", "./script/build.ts", "--single"
      bin.install Pathname.pwd.glob("dist/opencode-*/bin/opencode").first
    end

    generate_completions_from_executable(bin/"opencode", "completion", shell_parameter_format: :none, shells: [:zsh])
  end

  test do
    ENV["OPENCODE_DISABLE_MODELS_FETCH"] = "1"

    assert_match version.to_s, shell_output("#{bin}/opencode --version")
    assert_match "opencode", shell_output("#{bin}/opencode models")
  end
end
