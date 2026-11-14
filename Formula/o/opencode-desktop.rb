class OpencodeDesktop < Formula
  desc "Desktop shell for the OpenCode agent (Electron window on local opencode serve)"
  homepage "https://opencode.ai"
  url "https://github.com/social4hyq/homebrew-core/releases/download/opencode-desktop-v0.1.0/opencode-desktop-0.1.0.tar.gz"
  sha256 "fbe67b2bd3cdc2ed7889bed9b6f252eab827dc3237ddc7ccd368a34345dbc0bd"
  # Tap-authored shell scripts (MIT) packaging the openharmony-sig Electron
  # prebuilt (Chromium/Electron, mixed MIT/BSD/LGPL); see multica.rb.
  license :cannot_represent

  livecheck do
    skip "Tap-hosted payload, versioned with the formula"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode-desktop-v0.1.0-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "81798b6b3228e6b8f913b0b322decc47b0a7108d44e1c9a77ef3cb09437f2f5b"
  end

  depends_on "node" => :build
  depends_on "hap-installer"
  depends_on "opencode"
  depends_on "zip"

  # openharmony-sig/electron PC(2in1) prebuilt (CodeHub mirror hosted on this
  # tap's release; redistribution assumed by the tap owner, see multica.rb).
  resource "electron-ohos" do
    url "https://github.com/social4hyq/homebrew-core/releases/download/electron-ohos-v34.9.0-20261030.1/v34.9.0-20261030.1-release.zip"
    sha256 "599e97b3d8b1e5071a2387496104b443e58079a5f5c165b0114e65ffc601df3a"
  end

  def install
    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_132.tar.gz", "-C", buildpath
    shell = buildpath/"libelectron/ohos_hap"

    app = shell/"web_engine/src/main/resources/resfile/resources/app"
    rm_r app if app.exist?
    app.mkpath
    %w[main.cjs package.json config.json waiting.html].each do |name|
      cp buildpath/"app"/name, app/name
    end

    inreplace shell/"AppScope/app.json5", '"bundleName": "com.huawei.ohos_electron"',
                                          '"bundleName": "com.social4hyq.opencodedesktop"'
    inreplace shell/"AppScope/app.json5", '"vendor": "example"', '"vendor": "social4hyq"'
    %w[app_icon.png startIcon.png].each do |name|
      cp buildpath/"assets/icon.png", shell/"AppScope/resources/base/media"/name
    end
    app_strings = shell/"AppScope/resources/base/element/string.json"
    strings = JSON.parse(app_strings.read)
    strings.fetch("string").each do |entry|
      entry["value"] = "OpenCode Desktop" if entry["name"] == "app_name"
    end
    rm app_strings
    app_strings.write JSON.pretty_generate(strings) + "\n"
    module_strings = shell/"electron/src/main/resources/base/element/string.json"
    strings = JSON.parse(module_strings.read)
    strings["string"].each do |entry|
      entry["value"] = "OpenCode" if entry["name"] == "EntryAbility_label"
    end
    rm module_strings
    module_strings.write JSON.pretty_generate(strings) + "\n"

    # CI's electron-ohos-ci CLT carries an NDK-less SDK subset (no llvm-strip);
    # mirror the multica packaging deltas that keep hvigor away from the strip
    # task and from signing material the container does not have.
    inreplace shell/"build-profile.json5", "        \"signingConfig\": \"default\",\n", ""
    inreplace shell/"electron/src/main/module.json5", "    \"mainElement\": \"EntryAbility\",\n",
              "    \"mainElement\": \"EntryAbility\",\n    \"extractNativeLibs\": true,\n"

    # Restricted permissions (pasteboard, location, ...) cannot be granted with
    # local auto-signing; the shell only needs loopback HTTP (same trim as the
    # ohos-multica probe proved installable).
    inreplace shell/"web_engine/src/main/module.json5", /"requestPermissions": \[.*?\n    \],/m,
              <<~JSON5.chomp
                "requestPermissions": [
                      { "name": "ohos.permission.INTERNET" },
                      { "name": "ohos.permission.GET_NETWORK_INFO" }
                    ],
              JSON5

    # HAP shell build. CI runs in the private electron-ohos-ci image (the
    # generic Electron-on-OHOS build image, selected via the
    # OHOS_CI_IMAGE_OVERRIDES repo variable), which bakes the HarmonyOS
    # command-line toolchain at /opt/electron-ohos-clt — repacked from a
    # licensed system CLT install, not publicly redistributable (see the
    # ohos-multica project). The shell compiles no C++, so the NDK-less SDK
    # subset the image carries suffices.
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "opencode-desktop builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['opencode-desktop']"
    end

    # brew's sanitized build env drops the container's LD_LIBRARY_PATH, but
    # ohos_packing_tool needs the SDK clang runtimes and the libhilog
    # stderr adapter baked into the image.
    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] =
      "#{clt}/lib:#{clt}/sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos"
    ENV.delete("NODE_OPTIONS")
    # A container inheriting RLIMIT_NOFILE near 1e9 drives the musl FD-table
    # sizing into a refused mapping; cap it for the hvigor process tree
    # (only ever lowering — never raise an environment's existing limit).
    soft_cap, hard_cap = Process.getrlimit(Process::RLIMIT_NOFILE)
    if hard_cap > 65_536
      Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536)
    end

    cd shell do
      system "node", clt/"ohpm/bin/pm-cli.js", "install"
      system "node", clt/"hvigor/bin/hvigorw.js", "assembleHap",
             "--mode", "module", "-p", "product=default", "--no-daemon"
    end

    libexec.install shell/"electron/build/default/outputs/default/electron-default-unsigned.hap" =>
                    "opencode-desktop-unsigned.hap"
    pkgshare.install buildpath/"scripts/install-desktop.sh"
    chmod 0755, pkgshare/"install-desktop.sh"
    libexec.install buildpath/"scripts/opencode-desktop.sh"
    chmod 0755, libexec/"opencode-desktop.sh"
    (bin/"opencode-desktop").write_env_script libexec/"opencode-desktop.sh",
      OPENCODE_DESKTOP_UNSIGNED_HAP:   libexec/"opencode-desktop-unsigned.hap",
      OPENCODE_DESKTOP_INSTALL_SCRIPT: pkgshare/"install-desktop.sh",
      PATH:                            "#{formula_opt_bin("opencode")}:$PATH"
  end

  def caveats
    <<~EOS
      The desktop HAP is unsigned in the bottle. Connect and unlock the device,
      then run `opencode-desktop install`. hap-installer handles Huawei
      Developer login, local debug profile generation, signing, installation,
      and launch.

      The shell displays the UI served by a local `opencode serve` instance
      managed by the `opencode-desktop` command. Before launching the app,
      run `opencode-desktop serve` (add it to your shell startup to keep the
      backend running). Sessions are shared with the opencode TUI.
    EOS
  end

  test do
    ENV["HOME"] = testpath/"home"
    assert_match "Usage: opencode-desktop", shell_output("#{bin}/opencode-desktop --help")

    # Server orchestration against the real opencode binary.
    assert_match "serving at", shell_output("#{bin}/opencode-desktop serve")
    assert_match "healthy", shell_output("#{bin}/opencode-desktop status")
    assert_match "stopped", shell_output("#{bin}/opencode-desktop stop")

    # Install path: config injection is exercised with a fake hap-installer.
    fake_bin = testpath/"bin"
    fake_bin.mkpath
    installer_args = testpath/"hap-installer-args"
    fake_installer = fake_bin/"hap-installer"
    fake_installer.write <<~SH
      #!/bin/sh
      printf '%s\n' "$@" > #{installer_args}
    SH
    chmod 0755, fake_installer
    ENV.prepend_path "PATH", fake_bin
    shell_output("#{bin}/opencode-desktop install")
    args = installer_args.read.lines(chomp: true)
    injected = args[args.index("--hap") + 1]
    assert_equal "com.social4hyq.opencodedesktop", args[args.index("--bundle-id") + 1]
    assert_equal "electron", args[args.index("--module") + 1]
    assert_equal "EntryAbility", args[args.index("--ability") + 1]
    config = JSON.parse(shell_output("unzip -p #{injected} resources/resfile/resources/app/config.json"))
    assert_operator config.fetch("port"), :>, 0
    refute_empty config.fetch("password")

    hap = libexec/"opencode-desktop-unsigned.hap"
    assert_path_exists hap
    listing = shell_output("unzip -l #{hap}")
    assert_match "pack.info", listing
    assert_match "libs/arm64-v8a/libelectron.so", listing
    assert_match "resources/resfile/resources/app/main.cjs", listing
    assert_match "resources/resfile/resources/app/waiting.html", listing
    placeholder = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/config.json"))
    assert_equal 0, placeholder.fetch("port")
    profile = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    permissions = profile.fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET], permissions.sort
    system "unzip", "-tq", hap
  end
end
