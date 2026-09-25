class Opencode < Formula
  desc "AI coding agent, built for the terminal"
  homepage "https://opencode.ai"
  url "https://github.com/anomalyco/opencode/archive/refs/tags/v1.18.32.tar.gz"
  sha256 "65e95c9a6666ca65bbd17de1e7cecddac1504e66eeebbcfaf5ac68f97e6f392b"
  license "MIT"

  # No throttle: unlike upstream homebrew-core (which throttles to every 5th
  # release to limit their own CI churn), this tap wants opencode to autobump
  # on every upstream release, same as opencode-v2.
  livecheck do
    url :stable
    regex(/^v(1\.\d+\.\d+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode-v1.18.31-r16"
    rebuild 3
    sha256 cellar: :any_skip_relocation, arm64_ohos: "be23d75829e8239a06469fcd476749c9eff756cb7773f82f3047e997dc5b5b7a"
  end

  depends_on "bun" => :build
  depends_on "node" => :build
  depends_on "python@3.14" => :build
  depends_on "ripgrep"

  on_linux do
    depends_on "icu4c@78"
  end

  # opencode-v2 installs the same binary name; declared reciprocally
  # (both formulae must conflicts_with each other for brew audit).
  conflicts_with "opencode-v2", because: "both install an opencode binary"

  %w[
    0001-update-package-json.patch
    0002-update-filesystem-watcher.patch
    0003-update-project-root.patch
    0004-update-build-target.patch
    0005-update-project-worktree.patch
    0006-filter-invalid-references.patch
    0008-guard-undefined-layer-deps.patch
  ].each do |p|
    patch do
      file "Patches/opencode/#{p}"
    end
  end

  deny_network_access! :test

  def install
    ENV["OPENCODE_VERSION"] = version.to_s
    ENV["OPENCODE_CHANNEL"] = "prod"

    # Fix server errors when building with Bun 1.4.2 by disabling splitting
    # https://github.com/anomalyco/opencode/issues/48645
    # https://github.com/NixOS/nixpkgs/issues/563241
    inreplace "packages/opencode/script/build.ts", "splitting: true,", "splitting: false,"

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
