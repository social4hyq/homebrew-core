class Flyway < Formula
  desc "Database version control to control migrations"
  homepage "https://www.red-gate.com/products/flyway/community/"
  url "https://github.com/flyway/flyway/releases/download/flyway-12.8.0/flyway-commandline-12.8.0.tar.gz"
  sha256 "d0f8c615fcbcf9233da426dc00409264e2f77713023281c96930d6f742d7942f"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2ba028906b2b609734f83a4cd2ee756ad39c2b630c9284ebb1110a0aa65c277b"
  end

  depends_on "openjdk"

  def install
    rm Dir["*.cmd"]
    chmod "g+x", "flyway"
    libexec.install Dir["*"]
    (bin/"flyway").write_env_script libexec/"flyway", Language::Java.overridable_java_home_env
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/flyway --version")

    assert_match "Successfully validated 0 migrations",
      shell_output("#{bin}/flyway -url=jdbc:h2:mem:flywaydb validate")
  end
end
