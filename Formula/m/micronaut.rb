class Micronaut < Formula
  desc "Modern JVM-based framework for building modular microservices"
  homepage "https://micronaut.io/"
  url "https://github.com/micronaut-projects/micronaut-starter/archive/refs/tags/v5.1.0.tar.gz"
  sha256 "2e77e9207d9b26cfdacb21744fbd76b9394258b54f83e6d29db47e7fc36a2f74"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "92c0bfab238e5b57af9981b2fb436601689d02f8c9a5582d422a6293052e9da4"
  end

  depends_on "gradle" => :build
  depends_on "openjdk@25"

  def install
    ENV["JAVA_HOME"] = Language::Java.java_home("25")
    system "gradle", "micronaut-cli:assemble", "--exclude-task", "test", "--no-daemon"

    libexec.install "starter-cli/build/exploded/lib"
    (libexec/"bin").install "starter-cli/build/exploded/bin/mn"

    bash_completion.install "starter-cli/build/exploded/bin/mn_completion" => "mn"
    (bin/"mn").write_env_script libexec/"bin/mn", Language::Java.overridable_java_home_env("25")
  end

  test do
    system bin/"mn", "create-app", "hello-world"
    assert_predicate testpath/"hello-world", :directory?
  end
end
