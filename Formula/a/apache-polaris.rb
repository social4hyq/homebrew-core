class ApachePolaris < Formula
  desc "Interoperable, open source catalog for Apache Iceberg"
  homepage "https://polaris.apache.org/"
  url "https://github.com/apache/polaris/archive/refs/tags/apache-polaris-1.3.0-incubating.tar.gz"
  sha256 "4a502ceb521c09a179d8a4e0f6b75ff0b76b60b707179df9535b2553a9585032"
  license "Apache-2.0"

  livecheck do
    url "https://polaris.apache.org/downloads/"
    regex(/href=.*?apache-polaris-(\d+(?:\.\d+)+)-incubating\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "810d9fafb860d3f420260b42773776cd7c0d6e0472bf437ae9608b5bd6edfcb1"
  end

  depends_on "gradle" => :build
  depends_on "openjdk"

  def install
    ENV.delete "CI" # work around Gradle stalling on macOS CI runners

    system "gradle", "assemble", "--no-daemon"

    mkdir "build" do
      system "tar", "xzf", "../runtime/distribution/build/distributions/polaris-bin-#{version}-incubating.tgz", "--strip-components", "1"
      libexec.install "admin", "bin", "server"
    end

    java_env = Language::Java.overridable_java_home_env
    %w[admin server].each do |script|
      (bin/"polaris-#{script}").write_env_script libexec/"bin"/script, java_env
    end
  end

  service do
    run [opt_bin/"polaris-server"]
    keep_alive true
    error_log_path var/"log/polaris.log"
    log_path var/"log/polaris.log"
  end

  test do
    port = free_port
    ENV["QUARKUS_HTTP_PORT"] = free_port.to_s
    ENV["QUARKUS_MANAGEMENT_PORT"] = port.to_s
    pid = spawn bin/"polaris-server"

    output = shell_output("curl -s --retry 5 --retry-connrefused localhost:#{port}/q/health")
    assert_match "UP", output
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
