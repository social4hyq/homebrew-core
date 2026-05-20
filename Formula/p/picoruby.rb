class Picoruby < Formula
  desc "Smallest Ruby implementation for microcontrollers"
  homepage "https://picoruby.org"
  url "https://github.com/picoruby/picoruby.git",
      tag:      "3.4.5",
      revision: "d482862af826996fcaa65a42de5e6e51b6ed70c3"
  license "MIT"
  head "https://github.com/picoruby/picoruby.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "afa25195d0398d8a3989359db98e16e7a8702cc42ad6d05c02d8c2cf883acbd5"
  end

  depends_on "ruby" => :build # for numbered block parameter `_1'
  depends_on "openssl@3"

  def install
    ENV["MRUBY_CONFIG"] = buildpath/"build_config/default.rb"
    system "rake"
    bin.install Dir["build/host/bin/*"]
    lib.install Dir["build/host/lib/*"]
    include.install Dir["include/*"]
  end

  test do
    output = shell_output("#{bin}/picoruby -e \"puts 'Hello, PicoRuby!'\"")
    assert_match "Hello, PicoRuby!", output
  end
end
