class Beanstalkd < Formula
  desc "Generic work queue originally designed to reduce web latency"
  homepage "https://beanstalkd.github.io/"
  url "https://github.com/beanstalkd/beanstalkd/archive/refs/tags/v1.13.tar.gz"
  sha256 "26292dcdc0a7011d2f8ad968612f2cd8b2ef07687224876015399ae85e9e5263"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a695fe9751d000212c6b20f82d71595c77a0b0507dfb4e204266fc8a9eaafebe"
  end

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  service do
    run opt_bin/"beanstalkd"
    keep_alive true
    working_dir var
    log_path var/"log/beanstalkd.log"
    error_log_path var/"log/beanstalkd.log"
  end

  test do
    system bin/"beanstalkd", "-v"
  end
end
