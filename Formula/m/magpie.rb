class Magpie < Formula
  desc "Pick the model each AI coding agent on your machine uses"
  homepage "https://github.com/yetone/magpie"
  url "https://github.com/yetone/magpie/archive/refs/tags/v0.1.4828.tar.gz"
  sha256 "6db17effe70b15e25991c0524f81b1233361ffa287b50b982e3977d7d215cd30"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/magpie-v0.1.4828-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7b718993c3b4ec8163e93d268b549ae787ba300dddb814a1fcdafe551a201f84"
  end

  depends_on "go" => :build
  depends_on "bun"

  patch do
    file "Patches/magpie/0001-open-browser-on-openharmony.patch"
  end

  # The unused-resource audit requires literal tap paths.
  RESOURCE_FILES = %w[
    Resources/magpie/magpie-web.js
    Resources/magpie/magpie.sh
    Resources/magpie/tests/fake-magpie.js
    Resources/magpie/tests/web-registry.test.js
  ].freeze

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }

    ENV["CGO_ENABLED"] = "0"
    system "go", "build", *std_go_args(output: libexec/"bin/magpie", ldflags: "-s -w -X main.version=#{version}"),
           "-tags=nogui", "."
    # `magpie web` runs through magpie-web.js, which records the page's port and key for
    # the Magpie desktop app; every other command is the binary itself.
    cp tap_root/"Resources/magpie/magpie.sh", libexec/"magpie.sh"
    cp tap_root/"Resources/magpie/magpie-web.js", libexec/"magpie-web.js"
    chmod 0755, libexec/"magpie.sh"
    (bin/"magpie").write_env_script libexec/"magpie.sh",
                                    MAGPIE_BUN:  "${MAGPIE_BUN:-#{formula_opt_bin("bun")}/bun}",
                                    MAGPIE_REAL: libexec/"bin/magpie"
  end

  def caveats
    <<~EOS
      `magpie web` records where its page listens and the key of its link in
      `~/.config/magpie-app/web.json` and `web-key` (removed when it ends), so the
      Magpie desktop app (magpie-app) opens the same page instead of starting its own.
      A second `magpie web` with no options prints that page's link.
    EOS
  end

  test do
    ENV["XDG_CONFIG_HOME"] = testpath/"config"
    ENV["XDG_CACHE_HOME"] = testpath/"cache"
    ENV["XDG_DATA_HOME"] = testpath/"data"
    assert_match "magpie #{version}", shell_output("#{bin}/magpie --version")
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    system formula_opt_bin("bun")/"bun", "test", tap_root/"Resources/magpie/tests"
    assert_path_exists libexec/"magpie-web.js"
    system bin/"magpie", "settings", "set", "lang", "ja"
    assert_equal "ja", shell_output("#{bin}/magpie settings get lang").strip

    ENV["MAGPIE_BUN_TEST_MARKER"] = testpath/"bun-marker"
    ENV.delete("MAGPIE_BUN")
    (testpath/"proof.js").write <<~JS
      import { realpathSync, writeFileSync } from "node:fs";
      export const ProofPlugin = async () => {
        writeFileSync(process.env.MAGPIE_BUN_TEST_MARKER, realpathSync(process.execPath));
        return { auth: { provider: "bun-proof", methods: [] } };
      };
    JS
    system bin/"magpie", "plugin", "add", testpath/"proof.js"
    assert_equal (formula_opt_bin("bun")/"bun").realpath.to_s, (testpath/"bun-marker").read

    (testpath/"custom-bun").write <<~SH
      #!/bin/sh
      touch "#{testpath}/custom-bun-called"
      exec "#{formula_opt_bin("bun")}/bun" "$@"
    SH
    chmod 0755, testpath/"custom-bun"
    ENV["MAGPIE_BUN"] = testpath/"custom-bun"
    system bin/"magpie", "plugin", "list"
    assert_path_exists testpath/"custom-bun-called"
  end
end
