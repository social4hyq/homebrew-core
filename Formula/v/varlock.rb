class Varlock < Formula
  desc "Add declarative schema to .env files using @env-spec decorator comments"
  homepage "https://varlock.dev"
  url "https://registry.npmjs.org/varlock/-/varlock-1.6.1.tgz"
  sha256 "adb7a5a24c97803f1a0a57e39e2aa783268351475adcb7ccb3a5e4d36063db66"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "41c13bdecd5b0a99e675e99556494b8d549272f18c4efed5c2e12c38aff71813"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")

    arch = Hardware::CPU.intel? ? "x64" : Hardware::CPU.arch.to_s
    mac_bin = "VarlockEnclave.app/Contents/MacOS/varlock-local-encrypt"
    libexec.glob("lib/node_modules/varlock/native-bins/*").each do |dir|
      basename = dir.basename.to_s
      rm_r(dir) if OS.linux? && basename != "linux-#{arch}"
      deuniversalize_machos dir/mac_bin if OS.mac? && basename == "darwin"
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/varlock --version")

    (testpath/".env.schema").write <<~TEXT
      # This is the header, and may contain root decorators
      # @envFlag=APP_ENV
      # @defaultSensitive=false @defaultRequired=false
      # @generateTypes(lang=ts, path=env.d.ts)
      # ---

      # This is a config item comment block and may contain decorators which affect only the item
      # @required @type=enum(dev, test, staging, prod)
      APP_ENV=dev
    TEXT

    assert_match "dev", shell_output("#{bin}/varlock load 2>&1")
  end
end
