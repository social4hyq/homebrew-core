class Zrepl < Formula
  desc "One-stop ZFS backup & replication solution"
  homepage "https://zrepl.github.io"
  url "https://github.com/zrepl/zrepl/archive/refs/tags/v0.7.0.tar.gz"
  sha256 "d451ad1d05a0afdc752daf1dada9327aa338f691eca91e1c8fc9828eebd89757"
  license "MIT"
  head "https://github.com/zrepl/zrepl.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "00b5b140d62af27105100ad1b0ef6f3cddaed018cabc24f02aa3add2e32e190c"
  end

  depends_on "go" => :build

  resource "homebrew-sample_config" do
    url "https://raw.githubusercontent.com/zrepl/zrepl/refs/tags/v0.6.1/config/samples/local.yml"
    sha256 "f27b21716e6efdc208481a8f7399f35fd041183783e00c57f62b3a5520470c05"
  end

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X github.com/zrepl/zrepl/version.zreplVersion=#{version}")
    (var/"log/zrepl").mkpath
    (var/"run/zrepl").mkpath
    (etc/"zrepl").mkpath

    generate_completions_from_executable(bin/"zrepl", shell_parameter_format: :cobra)
  end

  service do
    run [opt_bin/"zrepl", "daemon"]
    keep_alive true
    require_root true
    working_dir var/"run/zrepl"
    log_path var/"log/zrepl/zrepl.out.log"
    error_log_path var/"log/zrepl/zrepl.err.log"
    environment_variables PATH: std_service_path_env
  end

  test do
    resources.each do |r|
      r.verify_download_integrity(r.fetch)
      assert_empty shell_output("#{bin}/zrepl configcheck --config #{r.cached_download}")
    end
  end
end
