class CodexApp < Formula
  desc "ChatGPT desktop shell for OpenHarmony/HarmonyOS PC"
  homepage "https://learn.chatgpt.com/docs/linux/linux-app"
  url "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_26.1117.41037_arm64.deb",
      using: :nounzip
  version "26.1117.41037"
  sha256 "714146e9c667b26a1bd4e57633c544334a9ed47c399989bfd98cf764140bdc53"
  license :cannot_represent # OpenAI service and software terms
  revision 1

  livecheck do
    url "https://persistent.oaistatic.com/codex-app-prod/linux/deb/dists/stable/main/binary-arm64/Packages"
    regex(%r{^Filename: pool/main/c/chatgpt/chatgpt_(\d+(?:\.\d+)+)_arm64\.deb$}i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/codex-app-v26.1117.41037-r2"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "843e3bd0cce69084ec675a8e474b4a11d01c6fba3673dfaee10a8147a6f2664f"
  end

  depends_on "app-installer"
  depends_on "codex"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "python@3.15"
  depends_on "unzip"
  depends_on "zip"

  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  # OHOS node-pty build; the Electron shim runs it in a host Node helper (the
  # official linux/glibc addon cannot load here).
  resource "node-pty" do
    url "https://registry.npmjs.org/@ohos-ports/node-pty/-/node-pty-1.1.0-beta.4.tgz"
    sha256 "c032f4d4e3a95b99eef4c586928ccff62f35da6d1d716ea5ede00357563c9883"
  end

  # The unused-resource audit requires literal tap paths.
  RESOURCE_FILES = %w[
    Resources/codex-app/assets/icon.png
    Resources/codex-app/app/chatgpt-bootstrap.cjs
    Resources/codex-app/app/owl-compat.cjs
    Resources/codex-app/app/owl-host-shim.cjs
    Resources/codex-app/app/owl-pty-host.cjs
    Resources/codex-app/app/owl-pty-shim.cjs
    Resources/codex-app/app/owl-sqlite-shim.cjs
    Resources/codex-app/app/owl-utility-entry.cjs
    Resources/codex-app/scripts/codex-app.sh
    Resources/codex-app/scripts/install-chatgpt-desktop.sh
    Resources/codex-app/scripts/stage-ohos-shell.sh
    Resources/codex-app/support/assemble-local-hap.py
    Resources/_shared/hap-app/enable-cookie-encryption.py
    Resources/codex-app/tests/chatgpt-bootstrap.test.cjs
    Resources/codex-app/tests/assemble-local-hap.test.py
    Resources/_shared/hap-app/install-lib.sh
  ].freeze

  def patch
    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    super
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/codex-app"
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }

    support = buildpath/"codex-app-support"
    support.mkpath
    RESOURCE_FILES.grep(%r{/app/|/support/}).each do |file|
      cp tap_root/file, support/File.basename(file)
    end
    cp tap_root/"Resources/_shared/hap-app/enable-cookie-encryption.py", support

    shell = buildpath/"libelectron/ohos_hap"
    project = buildpath/"chatgpt-ohos-shell"
    system "bash", res/"scripts/stage-ohos-shell.sh", shell, project, version.to_s

    # Electron HAP tooling is proprietary and comes from the CI image; signing
    # stays a local user action.
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "codex-app builds only in electron-ohos-ci; configure OHOS_CI_IMAGE_OVERRIDES"
    end

    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] =
      "#{clt}/lib:#{clt}/sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos"
    ENV.delete("NODE_OPTIONS")
    soft_cap, hard_cap = Process.getrlimit(Process::RLIMIT_NOFILE)
    Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536) if hard_cap > 65_536

    cd project do
      system "node", clt/"ohpm/bin/pm-cli.js", "install"
      system "node", clt/"hvigor/bin/hvigorw.js", "assembleHap",
             "--mode", "module", "-p", "product=default", "--no-daemon"
    end

    shell_hap = project/"electron/build/default/outputs/default/electron-default-unsigned.hap"
    encrypted_hap = buildpath/"electron-default-cookie-unsigned.hap"
    system "python3", support/"enable-cookie-encryption.py", shell_hap, encrypted_hap

    # The bottle ships only this tap-authored shell. The official ChatGPT
    # package is downloaded by `codex-app install` (see install-desktop.sh) so
    # the tap does not redistribute OpenAI binaries.
    libexec.install encrypted_hap => "codex-app-shell-unsigned.hap"
    (libexec/"vendor.json").write JSON.generate(
      "url"     => stable.url.to_s,
      "sha256"  => stable.checksum.hexdigest,
      "version" => version.to_s,
      "file"    => "chatgpt_arm64.deb",
    )
    resource("node-pty").stage(libexec/"node_modules/node-pty")
    rm_r Dir[libexec/"node_modules/node-pty/prebuilds/{darwin,win32}-*"]
    pkgshare.mkpath
    cp res/"scripts/codex-app.sh", libexec/"codex-app.sh"
    cp res/"scripts/codex-app.sh", pkgshare/"codex-app.sh"
    cp res/"scripts/install-chatgpt-desktop.sh", pkgshare/"install-desktop.sh"
    cp tap_root/"Resources/_shared/hap-app/install-lib.sh", pkgshare/"hap-app-install-lib.sh"
    cp res/"scripts/stage-ohos-shell.sh", pkgshare/"stage-ohos-shell.sh"
    assemble_dir = pkgshare/"assemble"
    assemble_dir.mkpath
    cp support/"assemble-local-hap.py", assemble_dir
    RESOURCE_FILES.grep(%r{/app/}).each { |file| cp tap_root/file, assemble_dir }
    cp support/"enable-cookie-encryption.py", pkgshare/"enable-cookie-encryption.py"
    chmod 0755, [libexec/"codex-app.sh", pkgshare/"codex-app.sh",
                 pkgshare/"install-desktop.sh", pkgshare/"hap-app-install-lib.sh",
                 pkgshare/"stage-ohos-shell.sh"]

    module_json = JSON.parse(
      Utils.safe_popen_read("unzip", "-p", libexec/"codex-app-shell-unsigned.hap", "module.json"),
    )
    requested = module_json.fetch("module").fetch("requestPermissions")
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE
       ohos.permission.READ_PASTEBOARD ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].each do |name|
      requested << { "name" => name } unless requested.any? { |permission| permission["name"] == name }
    end
    (pkgshare/"module-acl.json").write JSON.generate(module_json)

    runtime_path = [
      formula_opt_bin("app-installer"),
      formula_opt_bin("codex"),
      formula_opt_bin("ohos-sdk-toolchains"),
      formula_opt_bin("node"),
      formula_opt_prefix("python@3.15")/"bin",
      "$PATH",
    ].join(":")
    (bin/"codex-app").write_env_script libexec/"codex-app.sh",
      CHATGPT_APP_HDC:            formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      CHATGPT_APP_UNSIGNED_HAP:   libexec/"codex-app-shell-unsigned.hap",
      CHATGPT_APP_VENDOR_JSON:    libexec/"vendor.json",
      CHATGPT_APP_ASSEMBLE_DIR:   pkgshare/"assemble",
      CHATGPT_APP_CODEX_CLI:      formula_opt_bin("codex")/"codex",
      CHATGPT_APP_NODE:           formula_opt_bin("node")/"node",
      CHATGPT_APP_NODE_PTY:       opt_libexec/"node_modules/node-pty",
      CHATGPT_APP_BREW_PREFIX:    formula_opt_prefix("codex").parent.parent,
      CHATGPT_APP_MODULE_ACL:     pkgshare/"module-acl.json",
      CHATGPT_APP_INSTALL_SCRIPT: pkgshare/"install-desktop.sh",
      CHATGPT_APP_INSTALLER:      formula_opt_bin("app-installer"),
      PATH:                       runtime_path
  end

  post_install_steps do
    run "{{HOMEBREW_PREFIX}}/bin/hap-app",
        args: ["auto-install", "codex-app", "com.social4hyq.chatgpt"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  def caveats
    <<~EOS
      `brew install` and `brew upgrade` try to install the HAP when a device is
      connected and Huawei Developer login is ready. If queued, check
      `hap-app status`, then run `hap-app install-pending`.
      Manual install: `codex-app install`. See docs/hap-app-formulae.md.

      The bottle ships only the tap-authored shell; the first install asks
      OpenAI for the official ChatGPT package (~519 MB, sha256-checked) and
      caches it in ~/.cache/codex-app/vendor/ for reinstalls. Use
      `codex-app install --deb PATH` for an offline copy, and `--clean-cache`
      to remove the cached package and assembled HAP.

      The app starts the Homebrew `codex` CLI; install injects host paths into a
      private signed HAP (ACLs are needed to reach host projects). `--no-acl` gives a
      strong-sandbox variant without host Codex features. Install keeps
      `[desktop] projectlessWorkspaceRoot` in `$CODEX_HOME/config.toml` (original
      saved as `config.toml.pre-owl`) and, when missing, writes the shell's proxy
      variables to `~/.config/codex-app/env.json` (never overwritten).
    EOS
  end

  test do
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    hap = libexec/"codex-app-shell-unsigned.hap"
    vendor = JSON.parse((libexec/"vendor.json").read)
    assert_equal version.to_s, vendor.fetch("version")
    assert_match(/\A[0-9a-f]{64}\z/, vendor.fetch("sha256"))
    assert_match(%r{\Ahttps://}, vendor.fetch("url"))
    assert_match "Usage: codex-app", shell_output("#{bin}/codex-app --help")

    assert_match "shell deb output", shell_output("python3 #{pkgshare}/assemble/assemble-local-hap.py --help")
    assert_match "source output", shell_output("python3 #{pkgshare}/enable-cookie-encryption.py --help")
    system "node", "--check", tap_root/"Resources/codex-app/app/chatgpt-bootstrap.cjs"
    owl_shims = %w[owl-compat owl-host-shim owl-pty-host owl-pty-shim owl-sqlite-shim owl-utility-entry]
    owl_shims.each do |name|
      system "node", "--check", tap_root/"Resources/codex-app/app/#{name}.cjs"
    end
    assert_path_exists libexec/"node_modules/node-pty/lib/index.js"
    assert_path_exists libexec/"node_modules/node-pty/prebuilds/openharmony-arm64/pty.node"
    refute_path_exists libexec/"node_modules/node-pty/prebuilds/darwin-arm64"
    system "node", "--test", tap_root/"Resources/codex-app/tests/chatgpt-bootstrap.test.cjs"
    system "python3", tap_root/"Resources/codex-app/tests/assemble-local-hap.test.py"

    module_json = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    assert_equal "com.social4hyq.chatgpt", module_json.dig("app", "bundleName")
    assert_equal version.to_s, module_json.dig("app", "versionName")
    major, minor, build = version.to_s.split(".").map(&:to_i)
    code = format("%<major>02d%<minor>04d%<build>05d", major: major, minor: minor, build: build).to_i / 100
    assert_equal code, module_json.dig("app", "versionCode")
    assert_equal "electron", module_json.dig("module", "name")
    permissions = module_json.dig("module", "requestPermissions").to_a.map { |item| item.fetch("name") }
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET], permissions.sort
    acl = JSON.parse((pkgshare/"module-acl.json").read)
    acl_permissions = acl.dig("module", "requestPermissions").map { |item| item.fetch("name") }
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE
       ohos.permission.READ_PASTEBOARD ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].each { |name| assert_includes acl_permissions, name }
    listing = shell_output("unzip -Z1 #{hap}")
    refute_match "vendor.asar", listing
    refute_match "resources/resfile/resources/codex", listing
    refute_match "vendor.asar.unpacked", listing
    owl_shims.each do |name|
      refute_match "resources/resfile/resources/app/#{name}.cjs", listing
    end
    icon = testpath/"shell-icon.png"
    icon.write Utils.safe_popen_read("unzip", "-p", hap, "resources/base/media/app_icon.png")
    assert_equal Digest::SHA256.file(tap_root/"Resources/codex-app/assets/icon.png").hexdigest,
                 Digest::SHA256.file(icon).hexdigest
    system "unzip", "-tq", hap

    # Signing and permission selection must be testable without a connected device.
    fixture_dir = testpath/"install-fixture"
    fixture_dir.mkpath
    fixture_manifest = { "app"    => { "bundleName" => "com.social4hyq.chatgpt" },
                         "module" => { "name" => "electron", "requestPermissions" => [
                           { "name" => "ohos.permission.INTERNET" },
                           { "name" => "ohos.permission.GET_NETWORK_INFO" },
                         ] } }
    (fixture_dir/"module.json").write JSON.generate(fixture_manifest)
    fixture_hap = testpath/"install-fixture.hap"
    cd fixture_dir do
      system "zip", "-q", fixture_hap, "module.json"
    end
    fake_bin = testpath/"fake-bin"
    fake_bin.mkpath
    fake_installer = fake_bin/"app-installer"
    fake_installer.write <<~SH
      #!/usr/bin/env bash
      set -euo pipefail
      input="" output=""
      while (($#)); do
        case "$1" in
          --hap) input="$2"; shift 2 ;;
          --signed-hap) output="$2"; shift 2 ;;
          *) shift ;;
        esac
      done
      cp "$input" "$output"
      echo installed
    SH
    chmod 0755, fake_installer
    host_home = testpath/"host-home"
    host_home.mkpath
    test_env = {
      "CHATGPT_APP_UNSIGNED_HAP" => fixture_hap.to_s,
      "CHATGPT_APP_MODULE_ACL"   => (pkgshare/"module-acl.json").to_s,
      "CHATGPT_APP_CODEX_CLI"    => (formula_opt_bin("codex")/"codex").to_s,
      "CHATGPT_APP_BREW_PREFIX"  => formula_opt_prefix("codex").parent.parent.to_s,
      "CHATGPT_APP_HOST_HOME"    => host_home.to_s,
      "CHATGPT_APP_HDC"          => "fake-hdc",
      "CHATGPT_APP_NODE"         => (formula_opt_bin("node")/"node").to_s,
      "CHATGPT_APP_NODE_PTY"     => (opt_libexec/"node_modules/node-pty").to_s,
      "TMPDIR"                   => testpath.to_s,
      "CODEX_HOME"               => "#{host_home}/.codex",
      "PATH"                     => "#{fake_bin}:#{ENV.fetch("PATH")}",
    }
    install_variant = lambda do |*args|
      previous_env = test_env.keys.to_h { |name| [name, ENV[name]] }
      test_env.each { |name, value| ENV[name] = value }
      begin
        system "bash", pkgshare/"install-desktop.sh", *args
      ensure
        previous_env.each do |name, value|
          value ? ENV[name] = value : ENV.delete(name)
        end
      end
    end
    install_variant.call("--hap", fixture_hap.to_s, "--keep")
    injected = testpath/"codex-app-signed.hap"
    injected_manifest = JSON.parse(shell_output("unzip -p #{injected} module.json"))
    assert_includes injected_manifest.dig("module", "requestPermissions").map { |item| item.fetch("name") },
                    "ohos.permission.CUSTOM_SANDBOX"
    host_config = JSON.parse(shell_output(
                               "unzip -p #{injected} resources/resfile/resources/app/chatgpt-host-config.json",
                             ))
    assert_equal host_home.to_s, host_config.fetch("home")
    assert_equal "#{host_home}/.codex", host_config.fetch("codexHome")
    assert_equal "#{formula_opt_bin("codex")}/codex", host_config.fetch("codexCli")
    assert_equal "#{formula_opt_bin("node")}/node", host_config.fetch("nodeCli")
    assert_equal "#{opt_libexec}/node_modules/node-pty", host_config.fetch("nodePtyDir")
    workspace_root = "#{host_home}/.cache/codex-app/Documents/Codex"
    assert_path_exists Pathname(workspace_root)
    assert_match "projectlessWorkspaceRoot = \"#{workspace_root}\"", (host_home/".codex/config.toml").read

    install_variant.call("--hap", fixture_hap.to_s, "--no-acl", "--keep")

    assert_match "--deb PATH", shell_output("bash #{pkgshare}/install-desktop.sh --help 2>&1")
    bad_deb = testpath/"bad.deb"
    bad_deb.write "not a deb"
    rejected = shell_output(
      "CHATGPT_APP_UNSIGNED_HAP=#{hap} " \
      "CHATGPT_APP_VENDOR_JSON=#{libexec}/vendor.json " \
      "CHATGPT_APP_ASSEMBLE_DIR=#{pkgshare}/assemble " \
      "bash #{pkgshare}/install-desktop.sh --deb #{bad_deb} 2>&1",
      1,
    )
    assert_match(/sha256/, rejected)
    strong_sandbox = JSON.parse(shell_output("unzip -p #{injected} module.json"))
    strong_permissions = strong_sandbox.dig("module", "requestPermissions").map { |item| item.fetch("name") }
    assert_empty strong_permissions.grep(/CUSTOM_SANDBOX|READ_WRITE_USER_FILE/)
  end
end
