class Flamebearer < Formula
  desc "Blazing fast flame graph tool for V8 and Node"
  homepage "https://github.com/mapbox/flamebearer"
  url "https://registry.npmjs.org/flamebearer/-/flamebearer-2.1.0.tgz"
  sha256 "35ebda2a2a30e954f7732098f67d215b7ccadf5a0672f631ed8b7e0277c6c624"
  license "ISC"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "052bd1547704567e6f6b97c96da30cca399f7efad12e49b4589c896990d24a4e"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    (testpath/"app.js").write <<~JS
      let x = 0;
      for (let i = 0; i < 5e6; i++) x += Math.sqrt(i);
      console.log(x);
    JS
    system Formula["node"].bin/"node", "--cpu-prof", "--cpu-prof-dir=#{testpath}", testpath/"app.js"
    profile = testpath.glob("*.cpuprofile").first

    assert_match(/samples:\s+\d+/, shell_output("#{bin}/flamebearer #{profile}"))
  end
end
