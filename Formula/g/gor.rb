class Gor < Formula
  desc "Real-time HTTP traffic replay tool written in Go"
  homepage "https://goreplay.org"
  license "LGPL-3.0-only"
  head "https://github.com/buger/goreplay.git", branch: "master"

  stable do
    url "https://github.com/buger/goreplay/archive/refs/tags/1.3.3.tar.gz"
    sha256 "d8487e4d677546f9533b930e1d5f604628cd904f7e31a260552dfbf7b440876e"

    # Backport part of commit needed for arm64 linux support
    # https://github.com/buger/goreplay/commit/d440b3dc8f2800b8147cd968f68aa10ec8b72e3b
    patch :DATA
  end

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d13c2ee53091d105bec95301340dd92203fb79f7db915be027657cf08b3f7655"
  end

  depends_on "go" => :build

  uses_from_macos "libpcap"

  def install
    # Workaround to avoid patchelf corruption when cgo is required (for gopacket)
    if OS.linux? && Hardware::CPU.arch == :arm64
      ENV["CGO_ENABLED"] = "1"
      ENV["GO_EXTLINK_ENABLED"] = "1"
      ENV.append "GOFLAGS", "-buildmode=pie"
    end

    system "go", "build", *std_go_args(ldflags: "-X main.VERSION=#{version}")
  end

  test do
    (testpath/"test").write "Hello"
    test_port = free_port
    server_pid = spawn bin/"gor", "file-server", ":#{test_port}"
    sleep 2
    assert_equal "Hello", shell_output("curl -s http://localhost:#{test_port}/test")
  ensure
    Process.kill "TERM", server_pid
  end
end

__END__
diff --git a/capture/sock_linux.go b/capture/sock_linux.go
index 1ff5cb6a..9d149fe2 100644
--- a/capture/sock_linux.go
+++ b/capture/sock_linux.go
@@ -1,4 +1,5 @@
-// +build linux
+//go:build linux && !arm64
+// +build linux,!arm64
 
 package capture
 
diff --git a/capture/sock_others.go b/capture/sock_others.go
index 0d8559b5..1e297bed 100644
--- a/capture/sock_others.go
+++ b/capture/sock_others.go
@@ -1,4 +1,5 @@
-// +build !linux
+//go:build (!linux && ignore) || arm64 || darwin
+// +build !linux,ignore arm64 darwin
 
 package capture
 
