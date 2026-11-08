class MulticaDesktop < Formula
  desc "Desktop GUI for Multica on HarmonyOS, unsigned HAP (sign at install)"
  homepage "https://multica.ai"
  url "https://github.com/multica-ai/multica/archive/refs/tags/v0.8.1.tar.gz"
  sha256 "4d142f4d676f90576dcf71787d3b9d20f6ec5329e0f3a8db14364cdc90253ad2"
  license :cannot_represent # Multica License (Apache-2.0 plus additional conditions)

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/multica-desktop-v0.8.1-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a5045b286fc764399684bf8241a7c9749775b5f52404ab8d223e707f3a04e3cb"
  end

  depends_on "multica-ohos" => :build # OHOS patch assets: branding script, clean module.json5
  depends_on "node" => :build

  # openharmony-sig/electron PC(2in1) prebuilt (CodeHub mirror hosted on this
  # tap's release; redistribution assumed by the tap owner, see release notes).
  resource "electron-ohos" do
    url "https://github.com/social4hyq/homebrew-core/releases/download/electron-ohos-v34.9.0-20261030.1/v34.9.0-20261030.1-release.zip"
    sha256 "599e97b3d8b1e5071a2387496104b443e58079a5f5c165b0114e65ffc601df3a"
  end

  patch :p1 do
    file "Patches/multica-desktop/0001-desktop-ohos.patch"
  end

  def install
    assets = Formula["multica-ohos"].opt_pkgshare
    shell = buildpath/"libelectron/ohos_hap"

    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_132.tar.gz", "-C", buildpath

    # Desktop payload: the patch carried the OHOS dependency wiring
    # (pnpm overrides to @ohos-npm-ports, scoped registry, signpost dev dep).
    ENV["CI"] = "true"
    system "npm", "exec", "--yes", "--", "pnpm@10.28.2", "install",
           "--ignore-scripts", "--no-frozen-lockfile", "--reporter=append-only"
    if OS.ohos?
      # Sign .node bindings so electron-vite can dlopen them on device.
      system "npm", "exec", "--yes", "--", "pnpm@10.28.2", "run", "postinstall"
    end
    cd "apps/desktop" do
      ENV["VITE_API_URL"] = "https://api.multica.ai"
      ENV["VITE_WS_URL"] = "wss://api.multica.ai/ws"
      ENV["VITE_APP_URL"] = "https://multica.ai"
      system "node", "--input-type=module", "-e",
             'import {build} from "electron-vite"; await build({server:{host:"127.0.0.1"}})'
    end

    # Assemble the HAP shell: brand it, pin the clean module profile
    # (multica:// scheme, no bundled binaries), and drop the payload in.
    system "python3", assets/"scripts/apply-branding.py", shell.to_s, buildpath.to_s
    cp assets/"hap-work/module.clean.json5", shell/"electron/src/main/module.json5"
    # No signingConfig: hvigor then produces the unsigned artifact only.
    inreplace shell/"build-profile.json5", '"signingConfig": "default",', ""

    app = shell/"web_engine/src/main/resources/resfile/resources/app"
    rm_r app/"out" if (app/"out").exist?
    cp_r buildpath/"apps/desktop/out", app/"out"
    rm_r app/"node_modules" if (app/"node_modules").exist?
    # pnpm lays node_modules out with symlinks into the workspace store; the
    # packaged payload must be self-contained, so copy with GNU tar -h, which
    # dereferences every link against the still-intact build tree.
    payload_nm = buildpath/"apps/desktop/payload-node_modules.tar"
    system "tar", "-C", buildpath/"apps/desktop", "-chf", payload_nm, "node_modules"
    system "tar", "-C", app, "-xf", payload_nm
    rm payload_nm
    cp buildpath/"apps/desktop/package.json", app/"package.json"

    # HAP shell build. CI runs in the private electron-ohos-ci image (the
    # generic Electron-on-OHOS build image, selected via the
    # OHOS_CI_IMAGE_OVERRIDES repo variable), which bakes the HarmonyOS
    # command-line toolchain at /opt/electron-ohos-clt — repacked from a
    # licensed system CLT install, not publicly redistributable (see the
    # ohos-multica project). The shell compiles no C++, so the NDK-less SDK
    # subset the image carries suffices.
    clt = Pathname.new("/opt/electron-ohos-clt")
    odie "multica-desktop builds only in the electron-ohos-ci CI image" unless (clt/"hvigor/bin/hvigorw.js").exist?

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
                    "multica-desktop-unsigned.hap"
  end

  def caveats
    <<~EOS
      The HAP is UNSIGNED: developer certificates bind to a device UDID, so
      signing happens on your machine, not at bottling time.

      Sign and install with your own DevEco auto-sign materials (one-time
      setup with DevEco Studio or deveco-cli), then install:
        bm install -p <signed>.hap

      The full flow (signing config shape, daemon pairing, supervisor) is
      documented in the ohos-multica project: Build Pipeline and Distribution
      guides at https://github.com/social4hyq/ohos-multica .
    EOS
  end

  test do
    hap = libexec/"multica-desktop-unsigned.hap"
    assert_path_exists hap
    listing = shell_output("unzip -l #{hap}")
    assert_match "pack.info", listing
    assert_match "module.json", listing
  end
end
