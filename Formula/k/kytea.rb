class Kytea < Formula
  desc "Toolkit for analyzing text, especially Japanese and Chinese"
  homepage "https://www.phontron.com/kytea/"
  license "Apache-2.0"

  stable do
    url "https://www.phontron.com/kytea/download/kytea-0.4.7.tar.gz"
    sha256 "534a33d40c4dc5421f053c71a75695c377df737169f965573175df5d2cff9f46"

    # Fix -flat_namespace being used on Big Sur and later.
    patch do
      url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-pre-0.4.2.418-big_sur.diff"
      sha256 "83af02f2aa2b746bb7225872cab29a253264be49db0ecebb12f841562d9a2923"
    end

    # Fix build with newer Clang
    patch do
      url "https://github.com/neubig/kytea/commit/eab98ce9c45ccc4a0226a87fa6c40b6d0c5ba82b.patch?full_index=1"
      sha256 "aabb381b38592432d97f789520c81e6df46808c611ff541aae093357c06921c6"
    end
  end

  livecheck do
    url :homepage
    regex(/kytea[._-]v?(\d+(?:\.\d+)+)\.t/i)
    strategy :page_match do |page, regex|
      index_file_path = page[/src=["']?([^"' >]*?index[._-]\w{8}\.js[^"' >]*?)/i, 1]
      next unless index_file_path

      js_content = Homebrew::Livecheck::Strategy.page_content(
        URI.join("https://www.phontron.com/kytea/", index_file_path).to_s,
      )[:content]
      next if js_content.blank?

      js_content.scan(regex).map { |match| match[0] }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fc2f0267602335f42bd3725c98df23c9a1f504626a0ff2073cc540c2a705f555"
  end

  head do
    url "https://github.com/neubig/kytea.git", branch: "master"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  def install
    system "autoreconf", "--force", "--install", "--verbose" if build.head?

    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/kytea --version 2>&1")
  end
end
