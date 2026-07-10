class Flyway < Formula
  desc "Database version control to control migrations"
  homepage "https://www.red-gate.com/products/flyway/community/"
  url "https://github.com/flyway/flyway/releases/download/flyway-12.11.0/flyway-commandline-12.11.0.tar.gz"
  sha256 "d88552bb3aedc2ab2faa98fb2a50906e50fb8fb1c22b71cc3acd6d91c2f40a55"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b839058972770d4fd03b49b5b425b6dcf3e9c7d17cb41b6987d41830eddd8c57"
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
