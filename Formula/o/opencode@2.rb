class OpencodeAT2 < Formula
  desc "OpenCode v2 preview — AI coding agent CLI, HarmonyOS aarch64, built from source"
  homepage "https://github.com/anomalyco/opencode"
  # v2 is a live branch (no tags yet); pinned git revision + beta version tag.
  # See social4hyq/ohos-opencode2 dev for canonical diff.
  url "https://github.com/anomalyco/opencode.git", revision: "84fd347afaed9617b7b29744086657fa029bbe68", branch: "v2"
  version "2.0.0-beta"
  license "MIT"
  revision 14

  livecheck do
    url "https://api.github.com/repos/anomalyco/opencode/commits?sha=v2&per_page=1"
    strategy :json do |json|
      json.first&.dig("sha")
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode@2-v2.0.0-beta-r13"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4f897cc13fb350023b6832ce3ec22262465117be14380fa9edd68dc585bfc781"
  end

  # `bun build --compile` single binary: runtime + JS + .so embedded; since
  # bun r31 ohos-compat-shim is statically linked (no runtime shim dep).
  # v2 monorepo restructure: CLI moved packages/opencode → packages/cli
  # (binary renamed opencode2). Build script: packages/cli/script/build.ts.
  # Fewer native deps: only opentui-core + bun-pty. `bun install --ignore-scripts`
  # (lifecycle scripts irrelevant to signing). @parcel/watcher: @ohos-ports binary.
  depends_on "bun" => :build
  depends_on "ohos-sdk" => :build # llvm-readelf (verify .codesign section)

  # All OHOS adaptations via inreplace — zero .patch files.
  # See opencode.rb for the same pattern.

  def install
    ENV["BUN_TMPDIR"] = (buildpath/".bun-tmp").to_s
    (buildpath/".bun-tmp").mkpath
    ENV["BUN_INSTALL_CACHE_DIR"] = (HOMEBREW_CACHE/"bun-install-cache").to_s

    # Drop workspace packages not needed for CLI build. Only delete packages/*
    # glob entries, not explicit workspace entries or sub-globs (bun install
    # errors on missing dirs).
    # session-ui + enterprise deleted together (cross-dependencies).
    rm_r %w[packages/desktop packages/app packages/session-ui packages/web
            packages/www packages/storybook packages/enterprise]

    # v2 needs fewer @ohos-ports overrides: opentui-core + bun-pty only.
    # The nil check makes a vanished anchor fail loudly.
    inreplace "package.json" do |s|
      overrides = [
        '"@opentui/core": "npm:@ohos-ports/opentui-core@0.4.5-patch.1",',
        '    "bun-pty": "npm:@ohos-ports/bun-pty@0.4.10",',
        '    "@parcel/watcher-linux-arm64-musl": "npm:@ohos-ports/parcel-watcher-openharmony-arm64@2.5.1",',
      ]
      s.gsub!('"@opentui/core": "catalog:",', overrides.join("\n")) ||
        odie("opencode@2: @opentui/core override anchor not found in package.json")
    end

    # Home dir fallback for global projects. See opencode.rb.
    inreplace "packages/core/src/project.ts" do |s|
      s.sub!('import path from "path"', "import os from \"os\"\nimport path from \"path\"") ||
        odie("opencode@2: project.ts import anchor not found")
      s.sub!("path.parse(input).root", "os.homedir()") ||
        odie("opencode@2: project.ts path.parse anchor not found")
    end

    # File watcher: add openharmony → inotify backend mapping so getBackend()
    # returns "inotify" instead of undefined on OHOS (enables native file watching).
    inreplace "packages/core/src/filesystem/watcher.ts",
      'if (process.platform === "linux") return "inotify"',
      'if (process.platform === "linux" || process.platform === "openharmony") return "inotify"'

    # Flip openharmony-arm64 os markers. Same regex as opencode.rb.
    lockfile = (buildpath/"bun.lock").read
    injected = lockfile.gsub(
      /("[^"]*openharmony-arm64@[^"]+", "", \{ )"os": "none"(, "cpu": "arm64" \})/,
      %q(\1"os": "openharmony"\2),
    )
    if injected == lockfile
      opoo "opencode@2: no openharmony-arm64 os:none markers found in bun.lock " \
           "(upstream may have changed the lockfile format — verify the build)"
    else
      (buildpath/"bun.lock").atomic_write(injected)
    end

    # Disable npm minimum-release-age. See opencode.rb for rationale.
    inreplace "bunfig.toml", "minimumReleaseAge = 259200\n", ""
    system "bun", "install", "--ignore-scripts"

    # Script.version short-circuits on OPENCODE_VERSION (no git/registry lookup).
    ENV["OPENCODE_VERSION"] = version.to_s

    # build.ts adaptations (reuse linux-arm64-musl target slot):
    #   1. os check: allow linux-arm64-musl through on OHOS
    #   2. abi check: keep musl target on OHOS in single-flag mode
    #   3. compile target: use bun-linux-arm64-ohos for musl on OHOS
    inreplace "packages/cli/script/build.ts",
      "if (item.os !== process.platform || item.arch !== process.arch) return false",
      "if ((item.os !== process.platform || item.arch !== process.arch) && " \
      "!(process.platform === \"openharmony\" && " \
      "item.os === \"linux\" && item.arch === \"arm64\" && " \
      "item.abi === \"musl\")) return false"
    # Anchor on preceding avx2 line to avoid gsub! matching unrelated code.
    inreplace "packages/cli/script/build.ts",
      /(if \(item\.avx2 === false\) return baselineFlag\n\s*)return item\.abi === undefined/,
      '\1return process.platform === "openharmony" || item.abi === undefined'
    inreplace "packages/cli/script/build.ts" do |s|
      s.sub!("target: target.replace(binary, \"bun\") as Bun.Build.CompileTarget,",
             "target: (process.platform === \"openharmony\" && " \
             "item.abi === \"musl\" ? \"bun-linux-arm64-ohos\" : " \
             "target.replace(binary, \"bun\")) as Bun.Build.CompileTarget,") ||
        odie("opencode@2: build.ts compile-target anchor not found")
    end

    cd "packages/cli" do
      system "bun", "run", "script/build.ts", "--single"
    end

    out = "packages/cli/dist/cli-linux-arm64-musl/bin/opencode2"
    odie "opencode2 binary missing" unless File.exist?(out)

    # Verify .codesign section present. See opencode.rb.
    readelf = formula_opt_prefix("ohos-sdk")/"native/llvm/bin/llvm-readelf"
    sections = Utils.safe_popen_read(readelf.to_s, "--section-headers", out)
    odie "compiled binary lacks .codesign section" unless sections.include?(".codesign")

    # Isolates XDG_DATA_HOME ($HOME/.local/share-v2) so v2's DB migrations don't
    # break v1's session creation. opt_libexec keeps baked path stable across
    # flat/nested cellar flip.
    mkdir_p libexec/"bin"
    libexec.install out => "bin/opencode2"
    (bin/"opencode2").write <<~SH
      #!/bin/sh
      export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share-v2}"
      exec "#{opt_libexec}/bin/opencode2" "$@"
    SH
    chmod 0755, bin/"opencode2"

    # Completions from binary's --completions (always in sync).
    # base_name must be 'opencode2' not formula name (libexec binary).
    generate_completions_from_executable(libexec/"bin/opencode2", "--completions",
                                         base_name: "opencode2")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/opencode2 --version 2>&1")
  end
end
