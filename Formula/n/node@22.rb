class NodeAT22 < Formula
  desc "Open-source, cross-platform JavaScript runtime environment"
  homepage "https://nodejs.org/"
  url "https://nodejs.org/dist/v22.23.2/node-v22.23.2.tar.xz"
  sha256 "bbe768df8d5815d7fa76124052985332452e0a4742d39f32027550d1aab8f6fb"
  license "MIT"
  compatibility_version 1
  revision 5

  livecheck do
    url "https://nodejs.org/dist/"
    regex(%r{href=["']?v?(22(?:\.\d+)+)/?["' >]}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c549238bbfc6126887c4b4f5a50aae64fd6fbb2125b0bc6742522b1aa935728f"
  end

  patch do
    file "Patches/node@22/0001-openssl-armcap-disable-sve2.patch"
  end

  keg_only :versioned_formula

  # The unversioned `llvm` (LLVM 23) is too new for node, which is not yet
  # adapted to it. Lock to `llvm@22` for now.
  depends_on "llvm@22" => :build
  depends_on "python@3.14" => :build

  # https://github.com/nodejs/release#release-schedule
  # disable! date: "2027-04-30", because: :unsupported
  deprecate! date: "2026-10-28", because: :unsupported

  def install
    inreplace "common_node.gypi", "linux ", "linux openharmony "

    system "./configure", "--prefix=#{prefix}", "--dest-os=openharmony"
    system "make", "install"

    (lib/"node_modules/npm/npmrc").atomic_write("prefix = #{HOMEBREW_PREFIX}\n")
  end

  test do
    # Make sure Mojave does not have `CC=llvm_clang`.
    ENV.clang if OS.mac?

    path = testpath/"test.js"
    path.write "console.log('hello');"

    output = shell_output("#{bin}/node #{path}").strip
    assert_equal "hello", output
    output = shell_output("#{bin}/node -e 'console.log(new Intl.NumberFormat(\"en-EN\").format(1234.56))'").strip
    assert_equal "1,234.56", output

    output = shell_output("#{bin}/node -e 'console.log(new Intl.NumberFormat(\"de-DE\").format(1234.56))'").strip
    assert_equal "1.234,56", output

    # make sure npm can find node
    ENV.prepend_path "PATH", opt_bin
    ENV.delete "NVM_NODEJS_ORG_MIRROR"
    assert_equal which("node"), opt_bin/"node"
    assert_path_exists bin/"npm", "npm must exist"
    assert_predicate bin/"npm", :executable?, "npm must be executable"
    npm_args = ["-ddd", "--cache=#{HOMEBREW_CACHE}/npm_cache", "--build-from-source"]
    system bin/"npm", *npm_args, "install", "npm@latest"
    system bin/"npm", *npm_args, "install", "nan"
    assert_path_exists bin/"npx", "npx must exist"
    assert_predicate bin/"npx", :executable?, "npx must be executable"
    assert_match "< hello >", shell_output("#{bin}/npx --yes cowsay hello")
  end
end
