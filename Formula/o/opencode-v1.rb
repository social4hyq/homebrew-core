class OpencodeV1 < Formula
  desc "AI coding agent, built for the terminal"
  homepage "https://opencode.ai"
  url "https://github.com/anomalyco/opencode/archive/refs/tags/v1.18.34.tar.gz"
  sha256 "c2c60efde22639b64c7bfa740da39b9c8079391a7540e2f67bf91b36e5797f17"
  license "MIT"

  livecheck do
    url :stable
    regex(/^v(1\.\d+\.\d+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode-v1-v1.18.34-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4d596b56e4e431ff01ca9938fddbf2ca5ecce1bd34d6c0b3d7c80d1f8f8c4f3c"
  end

  depends_on "bun" => :build
  depends_on "node" => :build
  depends_on "python@3.14" => :build
  depends_on "ripgrep"

  patch do
    file "Patches/opencode-v1/0001-update-package-json.patch"
  end

  patch do
    file "Patches/opencode-v1/0002-update-filesystem-watcher.patch"
  end

  patch do
    file "Patches/opencode-v1/0003-update-project-root.patch"
  end

  patch do
    file "Patches/opencode-v1/0004-update-build-target.patch"
  end

  patch do
    file "Patches/opencode-v1/0005-update-project-worktree.patch"
  end

  patch do
    file "Patches/opencode-v1/0006-filter-invalid-references.patch"
  end

  patch do
    file "Patches/opencode-v1/0008-guard-undefined-layer-deps.patch"
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
    odie "opencode-v1: no openharmony-arm64 os:none markers found in bun.lock" if injected == lockfile
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
