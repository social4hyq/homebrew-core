class Zsv < Formula
  desc "Tabular data swiss-army knife CLI"
  homepage "https://github.com/liquidaty/zsv"
  url "https://github.com/liquidaty/zsv/archive/refs/tags/v1.4.3.tar.gz"
  sha256 "8372ec277b0cf56d02e3407e355208875fdfa174a3ed01e6ffb9a00fe440fc43"
  license "MIT"
  head "https://github.com/liquidaty/zsv.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3d03e8ff9f5ec43f49812630ef7fd0d6f712f314b9ca1d4079747359a26b6edc"
  end

  depends_on "jq"
  depends_on "pcre2"

  uses_from_macos "ncurses"

  def install
    rm(Dir["app/external/{jq,pcre}*"])

    args = %W[
      --jq-prefix=#{Formula["jq"].opt_prefix}
      --pcre2-8-prefix=#{Formula["pcre2"].opt_prefix}
      --ncurses-dynamic
    ]

    system "./configure", *args, *std_configure_args
    system "make", "install", "VERSION=#{version}", "PCRE2_STATIC="
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/zsv version")

    input = <<~CSV
      a,b,c
      1,2,3
    CSV
    assert_equal "1", pipe_output("#{bin}/zsv count", input).strip
  end
end
