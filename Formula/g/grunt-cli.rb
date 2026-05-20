class GruntCli < Formula
  desc "JavaScript Task Runner"
  homepage "https://gruntjs.com/"
  url "https://registry.npmjs.org/grunt-cli/-/grunt-cli-1.5.0.tgz"
  sha256 "4f7f52cf9f3bc62ebc7ae60d2db5c7f896cb0915ad1202dab9285d6117d7536d"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6417b44dcb50ab44e705ec04835789e49711aec8c67db438a7b6c7fe2c7a2cff"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    (testpath/"package.json").write <<~JSON
      {
        "name": "grunt-homebrew-test",
        "version": "1.0.0",
        "devDependencies": {
          "grunt": ">=0.4.0"
        }
      }
    JSON

    (testpath/"Gruntfile.js").write <<~JAVASCRIPT
      module.exports = function(grunt) {
        grunt.registerTask("default", "Write output to file.", function() {
          grunt.file.write("output.txt", "Success!");
        })
      };
    JAVASCRIPT

    system "npm", "install", *std_npm_args(prefix: false)
    system bin/"grunt"
    assert_path_exists testpath/"output.txt", "output.txt was not generated"
  end
end
