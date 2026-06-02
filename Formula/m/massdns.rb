class Massdns < Formula
  desc "High-performance DNS stub resolver"
  homepage "https://github.com/blechschmidt/massdns"
  url "https://github.com/blechschmidt/massdns/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "93b14431496b358ee9f3a5b71bd9618fe4ff1af8c420267392164f7b2d949559"
  license "GPL-3.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f074be8bb71995b3c4849b0d0e70bc82b7c94e698643190f32775e2cdf09bbcf"
  end

  depends_on "cmake" => :build

  uses_from_macos "libpcap"

  # upstream patch PR, https://github.com/blechschmidt/massdns/pull/148
  patch do
    url "https://github.com/blechschmidt/massdns/commit/a96b5d213a5643fbe3de1ba6e401e359673f0a21.patch?full_index=1"
    sha256 "10a07d6f8241500cdc6320fe1dc5461b9573ce8d70fbf96b62855192a3829e1b"
  end
  patch do
    url "https://github.com/blechschmidt/massdns/commit/66d30af33d36109d244a92a69691c5deba13fd28.patch?full_index=1"
    sha256 "a3070e5522e612ea5f868e705e5667c38b8437969e2690f8545a247a7a2ee970"
  end

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    etc.install Dir["lists", "scripts"]
  end

  test do
    cp_r etc/"lists/resolvers.txt", testpath
    (testpath/"domains.txt").write "docs.brew.sh"
    system bin/"massdns", "-r", testpath/"resolvers.txt", "-t", "AAAA", "-w", "results.txt", testpath/"domains.txt"

    assert_match ";; ->>HEADER<<- opcode: QUERY, status: NOERROR, id:", File.read("results.txt")
    assert_match "IN CNAME homebrew.github.io.", File.read("results.txt")
  end
end
