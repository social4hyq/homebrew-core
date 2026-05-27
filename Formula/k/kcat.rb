class Kcat < Formula
  desc "Generic command-line non-JVM Apache Kafka producer and consumer"
  homepage "https://github.com/edenhill/kcat"
  url "https://github.com/edenhill/kcat.git",
      tag:      "1.7.0",
      revision: "f2236ae5d985b9f31631b076df24ca6c33542e61"
  license "BSD-2-Clause"
  revision 1
  head "https://github.com/edenhill/kcat.git", branch: "master"

  # Upstream sometimes creates a tag with a stable version format but does not
  # create a release on GitHub. Versions that are tagged but not released don't
  # appear to be appropriate for this formula, so we check releases instead.
  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a424017763a99b7813bd786c2751e168ed6090380c95db65ca9086063bb41615"
  end

  depends_on "avro-c"
  depends_on "librdkafka"
  depends_on "libserdes"
  depends_on "yajl"

  def install
    system "./configure", "--prefix=#{prefix}",
                          "--enable-json",
                          "--enable-avro"
    system "make"
    system "make", "install"
  end

  test do
    system bin/"kcat", "-X", "list"
  end
end
