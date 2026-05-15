class Cpulimit < Formula
  desc "CPU usage limiter"
  homepage "https://github.com/opsengine/cpulimit"
  url "https://github.com/opsengine/cpulimit/archive/refs/tags/v0.2.tar.gz"
  sha256 "64312f9ac569ddcadb615593cd002c94b76e93a0d4625d3ce1abb49e08e2c2da"
  license "GPL-2.0-or-later"
  head "https://github.com/opsengine/cpulimit.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3d8b93658350fd25819c66e960d2d2472297e8ecf4418a7df306c69be0bf2f7a"
  end

  # process_group.c:64:15: error: call to undeclared function 'basename';
  # ISO C99 and later do not support implicit function declarations
  # (https://github.com/opsengine/cpulimit/pull/109)
  patch do
    url "https://github.com/opsengine/cpulimit/commit/4c1e021037550c437c7da3a276b95b5bf79e967e.patch?full_index=1"
    sha256 "0e1cda1dfad54cefd2af2d0677c76192d5db5c18f3ee73318735b5122ccf0e34"
  end

  def install
    system "make"
    bin.install "src/cpulimit"
  end

  test do
    system bin/"cpulimit", "--limit=10", "ls"
  end
end
