class Mpssh < Formula
  desc "Mass parallel ssh"
  homepage "https://github.com/ndenev/mpssh"
  license "BSD-3-Clause"
  head "https://github.com/ndenev/mpssh.git", branch: "master"

  stable do
    url "https://github.com/ndenev/mpssh/archive/refs/tags/1.3.3.tar.gz"
    sha256 "510e11c3e177a31c1052c8b4ec06357c147648c86411ac3ed4ac814d0d927f2f"
    patch do
      # don't install binaries as root (upstream commit)
      url "https://github.com/ndenev/mpssh/commit/3cbb868b6fdf8dff9ab86868510c0455ad1ec1b3.patch?full_index=1"
      sha256 "a6c596c87a4945e6a77b779fcc42867033dbfd95e27ede492e8b841738a67316"
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "25175fc23b2d34d411e53bee48d00d1b409b7eca3915c9b5743b8635ff15ab4e"
  end

  def install
    system "make", "install", "CC=#{ENV.cc}", "BIN=#{bin}"
    man1.install "mpssh.1"
  end

  test do
    system bin/"mpssh"
  end
end
