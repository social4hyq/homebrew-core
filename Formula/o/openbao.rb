class Openbao < Formula
  desc "Provides a software solution to manage, store, and distribute sensitive data"
  homepage "https://openbao.org/"
  url "https://github.com/openbao/openbao.git",
      tag:      "v2.6.2",
      revision: "dd9c19c37a878cf4a81b18efb8d6f0599c7da923"
  license "MPL-2.0"
  head "https://github.com/openbao/openbao.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8868b3974fdebf84cf65b128bf2d7ba69cef71840b278367048d8ce57499d410"
  end

  depends_on "go" => :build
  depends_on "node@22" => :build # failed to build with node 23, https://github.com/openbao/openbao/issues/731
  depends_on "pnpm" => :build

  conflicts_with "bao", because: "both install `bao` binaries"

  def install
    # Build ui assets
    cd "ui" do
      ENV.prepend_path "PATH", formula_opt_libexec("node@22")/"bin" # for pnpm
      # pnpm 11 no longer reads `packageManager` or `pnpm.overrides` from package.json.
      # Move overrides to pnpm-workspace.yaml and strip stale fields to avoid
      # identity-verification failures on platforms without @pnpm/exe binaries (e.g. openharmony).
      # Ref: https://github.com/pnpm/pnpm/issues/13622
      pkg_json = JSON.parse(File.read("package.json"))
      if (overrides = pkg_json.dig("pnpm", "overrides"))
        File.open("pnpm-workspace.yaml", "a") do |f|
          f.puts
          f.puts "overrides:"
          overrides.each { |k, v| f.puts "  \"#{k}\": #{v}" }
        end
        pkg_json["pnpm"].delete("overrides")
        pkg_json["pnpm"].empty? && pkg_json.delete("pnpm")
      end
      pkg_json.delete("packageManager")
      File.write("package.json", JSON.pretty_generate(pkg_json) + "\n")
      system "pnpm", "install", "--no-frozen-lockfile"
      system "pnpm", "build"
    end

    ldflags = %W[
      -s -w
      -X github.com/openbao/openbao/version.fullVersion=#{version}
      -X github.com/openbao/openbao/version.GitCommit=#{Utils.git_head}
      -X github.com/openbao/openbao/version.BuildDate=#{time.iso8601}
    ]
    tags = %w[testonly ui]
    system "go", "build", *std_go_args(ldflags:, tags:, output: bin/"bao")
  end

  service do
    run [opt_bin/"bao", "server", "-dev"]
    keep_alive true
    working_dir var
    log_path var/"log/openbao.log"
    error_log_path var/"log/openbao.log"
  end

  test do
    addr = "127.0.0.1:#{free_port}"
    ENV["VAULT_DEV_LISTEN_ADDRESS"] = addr
    ENV["VAULT_ADDR"] = "http://#{addr}"

    pid = spawn bin/"bao", "server", "-dev"
    sleep 5
    system bin/"bao", "status"

    # Check the ui was properly embedded
    assert_match "User-agent", shell_output("curl #{addr}/robots.txt")
  ensure
    Process.kill("TERM", pid)
  end
end
