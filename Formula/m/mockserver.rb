class Mockserver < Formula
  desc "Mock HTTP server and proxy"
  homepage "https://www.mock-server.com/"
  url "https://search.maven.org/remotecontent?filepath=org/mock-server/mockserver-netty/8.0.0/mockserver-netty-8.0.0-brew-tar.tar"
  sha256 "fbefc3e5231a6a8a984c589ca52ae49c53ec958f90d0f55f167c0ff8a0451a02"
  license "Apache-2.0"

  livecheck do
    url "https://search.maven.org/remotecontent?filepath=org/mock-server/mockserver-netty/maven-metadata.xml"
    regex(%r{<version>v?(\d+(?:\.\d+)+)</version>}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6e258621a4003d60d36ddf8f200e22d51750f5121780606d39fade10dc99546e"
  end

  depends_on "openjdk"

  def install
    inreplace "bin/run_mockserver.sh", "/usr/local", HOMEBREW_PREFIX
    libexec.install Dir["*"]
    (bin/"mockserver").write_env_script libexec/"bin/run_mockserver.sh", JAVA_HOME: Formula["openjdk"].opt_prefix

    lib.install_symlink "#{libexec}/lib" => "mockserver"

    mockserver_log = var/"log/mockserver"
    mockserver_log.mkpath

    libexec.install_symlink mockserver_log => "log"
  end

  test do
    port = free_port

    mockserver = spawn bin/"mockserver", "-serverPort", port.to_s

    loop do
      Utils.popen_read("curl", "-s", "http://localhost:#{port}/status", "-X", "PUT")
      break if $CHILD_STATUS.exitstatus.zero?
    end

    system "curl", "-s", "http://localhost:#{port}/stop", "-X", "PUT"

    Process.wait(mockserver)
  end
end
