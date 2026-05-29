class Teller < Formula
  desc "Secrets management tool for developers"
  homepage "https://github.com/tellerops/teller"
  url "https://github.com/tellerops/teller/archive/refs/tags/v2.0.7.tar.gz"
  sha256 "1d4275ede4366a31efc94039c58da4cec87466d09cc01444c3c18e9432716d23"
  license "Apache-2.0"
  head "https://github.com/tellerops/teller.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6d1c3de3852055ef22a0bb28f72ee97fd2d86f6c24389226be2312fc85c79094"
  end

  depends_on "pkgconf" => :build
  depends_on "protobuf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
  end

  def install
    system "cargo", "install", *std_cargo_args(path: "teller-cli")
  end

  test do
    (testpath/"test.env").write <<~EOS
      foo=bar
    EOS

    (testpath/".teller.yml").write <<~YAML
      project: brewtest
      providers:
        # this will fuse vars with the below .env file
        # use if you'd like to grab secrets from outside of the project tree
        dotenv:
          kind: dotenv
          maps:
          - id: one
            path: #{testpath}/test.env
    YAML

    output = shell_output("#{bin}/teller -c #{testpath}/.teller.yml show 2>&1")
    assert_match "[dotenv (dotenv)]: foo = ba", output

    assert_match version.to_s, shell_output("#{bin}/teller --version")
  end
end
