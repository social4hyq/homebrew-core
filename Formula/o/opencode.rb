class Opencode < Formula
  desc "AI coding agent, built for the terminal"
  homepage "https://opencode.ai"
  url "https://github.com/anomalyco/opencode/archive/refs/tags/v1.18.31.tar.gz"
  sha256 "76f69fe27ec2b44e23fa1749029e7c012eb7e975a0f0c7819e9458198dfd3896"
  license "MIT"

  livecheck do
    throttle 5
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode-v1.18.31-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f332773917e68759132622638a4dc9be04680bc9244480cb54beb10fd9cbde26"
  end

  depends_on "bun" => :build
  depends_on "node" => :build
  depends_on "python@3.14" => :build
  depends_on "ripgrep"

  on_linux do
    depends_on "icu4c@78"
  end

  patch do
    file "Patches/opencode/openharmony.patch"
  end

  deny_network_access! :test

  def install
    ENV["BUN_TMPDIR"] = (buildpath/".bun-tmp").to_s
    (buildpath/".bun-tmp").mkpath
    ENV["BUN_INSTALL_CACHE_DIR"] = (HOMEBREW_CACHE/"bun-install-cache").to_s
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
