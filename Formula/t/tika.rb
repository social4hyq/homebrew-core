class Tika < Formula
  desc "Content analysis toolkit"
  homepage "https://tika.apache.org/"
  url "https://www.apache.org/dyn/closer.lua?path=tika/3.3.2/tika-app-3.3.2.jar"
  mirror "https://archive.apache.org/dist/tika/3.3.2/tika-app-3.3.2.jar"
  sha256 "71ca551380e5eab1add99101f4597a8a49a6a18c6143d6874ee9599ca10ae00e"
  license "Apache-2.0"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "38d2401b79370975b3d71fabf3a29c06d8f678c8dabaa1b7afa31732d9c21f85"
  end

  depends_on "openjdk"

  resource "server" do
    url "https://www.apache.org/dyn/closer.lua?path=tika/3.3.2/tika-server-standard-3.3.2.jar"
    mirror "https://archive.apache.org/dist/tika/3.3.2/tika-server-standard-3.3.2.jar"
    sha256 "cdbe7fde72583dec8528f9c0ed962cacb7f6624f9900b1f733df638410f77540"

    livecheck do
      formula :parent
    end
  end

  def install
    odie "update `server` resource" if version != resource("server").version
    libexec.install "tika-app-#{version}.jar"
    bin.write_jar_script libexec/"tika-app-#{version}.jar", "tika"

    libexec.install resource("server")
    bin.write_jar_script libexec/"tika-server-standard-#{version}.jar", "tika-rest-server"
  end

  service do
    run [opt_bin/"tika-rest-server"]
    working_dir var/"tika"
  end

  test do
    pdf = test_fixtures("test.pdf")
    assert_equal "application/pdf\n", shell_output("#{bin}/tika --detect #{pdf}")

    port = free_port
    pid = spawn bin/"tika-rest-server", "--port=#{port}"

    sleep 10
    response = shell_output("curl -s -i http://localhost:#{port}")
    assert_match "HTTP/1.1 200 OK", response
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
