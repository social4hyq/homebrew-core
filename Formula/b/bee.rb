class Bee < Formula
  desc "Tool for managing database changes"
  homepage "https://github.com/bluesoft/bee"
  url "https://github.com/bluesoft/bee/releases/download/1.115/bee-1.115.zip"
  sha256 "ac06d495841adfe64404b19dde67f7ab53e9d921344383a77547570c438f1e0d"
  license "MPL-1.1"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8b76df689cb3551d375db7ed3879a546d5b0761bca3dc9d4ad182e6062f98c8f"
  end

  depends_on "openjdk"

  def install
    rm_r(Dir["bin/*.bat"])
    libexec.install Dir["*"]
    (bin/"bee").write_env_script libexec/"bin/bee", Language::Java.java_home_env
  end

  test do
    (testpath/"bee.properties").write <<~EOS
      test-database.driver=com.mysql.jdbc.Driver
      test-database.url=jdbc:mysql://127.0.0.1/test-database
      test-database.user=root
      test-database.password=
    EOS
    (testpath/"bee").mkpath
    system bin/"bee", "-d", testpath/"bee", "dbchange:create", "new-file"
  end
end
