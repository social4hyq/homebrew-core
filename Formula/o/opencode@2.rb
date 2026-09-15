class OpencodeAT2 < Formula
  desc "AI coding agent, built for the terminal"
  homepage "https://opencode.ai"
  url "https://github.com/anomalyco/opencode.git", revision: "ad31bff969fe386266d3d1cd24d988651d3233af"
  version "0.0.0-beta-19271"
  license "MIT"
  revision 2
  version_scheme 1

  livecheck do
    url "https://registry.npmmirror.com/@opencode-ai/cli/beta"
    strategy :json do |json|
      json["version"]
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode@2-v0.0.0-beta-19271-r3"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5001813a1e302e87e2f939b0f44a21f1f17db778603de5c3910da5ed8d4d90bb"
  end

  depends_on "bun" => :build
  depends_on "node" => :build

  %w[
    0001-update-package-json.patch
    0002-update-bun-lock.patch
    0003-update-filesystem-watcher.patch
    0004-update-watcher-binding.patch
    0005-update-server-connection.patch
    0006-update-build-target.patch
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

    system "bun", "install", "--ignore-scripts"

    cd "packages/cli" do
      system "bun", "run", "script/build.ts", "--single"
    end

    out = "packages/cli/dist/cli-linux-arm64-musl/bin/opencode2"
    odie "opencode2 binary missing" unless File.exist?(out)

    mkdir_p libexec/"bin"
    libexec.install out => "bin/opencode2"

    (bin/"opencode2").write <<~SH
      #!/bin/sh
      export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share-v2}"
      exec "#{opt_libexec}/bin/opencode2" "$@"
    SH
    chmod 0755, bin/"opencode2"

    generate_completions_from_executable(libexec/"bin/opencode2", "--completions",
                                         base_name: "opencode2")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/opencode2 --version 2>&1")
  end
end
