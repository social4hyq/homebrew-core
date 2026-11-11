class Magpie < Formula
  desc "Pick the model each AI coding agent on your machine uses"
  homepage "https://github.com/yetone/magpie"
  url "https://github.com/yetone/magpie/archive/refs/tags/v0.1.3669.tar.gz"
  sha256 "885c6661c94ce0d5467ffbf32d1d3195d0269b3b0a106a2b8ba0b4120c48c41d"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/magpie-v0.1.3511-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a45cc3659661b9b1ff362a009756598a3965c919d376b480b6f7556074befc27"
  end

  depends_on "go" => :build
  depends_on "bun"

  def install
    ENV["CGO_ENABLED"] = "0"
    system "go", "build", *std_go_args(output: libexec/"bin/magpie", ldflags: "-s -w -X main.version=#{version}"),
           "-tags=nogui", "."
    (bin/"magpie").write_env_script libexec/"bin/magpie",
                                    MAGPIE_BUN: "${MAGPIE_BUN:-#{formula_opt_bin("bun")}/bun}"
  end

  test do
    ENV["XDG_CONFIG_HOME"] = testpath/"config"
    ENV["XDG_CACHE_HOME"] = testpath/"cache"
    ENV["XDG_DATA_HOME"] = testpath/"data"
    assert_match "magpie #{version}", shell_output("#{bin}/magpie --version")
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
