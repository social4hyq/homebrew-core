class Zola < Formula
  desc "Fast static site generator in a single binary with everything built-in"
  homepage "https://www.getzola.org/"
  url "https://github.com/getzola/zola/archive/refs/tags/v0.23.6.tar.gz"
  sha256 "193db594222cd9c1097387ce17272cbbe672c3a894c263f6f4c436a7fedb379f"
  license "EUPL-1.2"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "786cae37850746afb52bb403823e111300806cbf410006a99ef69e2297cd50de"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "cmake"
  depends_on "oniguruma" # for onig_sys

  on_linux do
    depends_on "openssl@3" # Uses Secure Transport on macOS
  end

  def install
    # Work around superenv breaking aws-lc-sys `-O0` needed to build CPU Jitter RNG
    ENV["AWS_LC_SYS_NO_JITTER_ENTROPY"] = "1"

    ENV["RUSTONIG_SYSTEM_LIBONIG"] = "1"
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"zola", "completion")
  end

  test do
    system "yes '' | #{bin}/zola init mysite"
    (testpath/"mysite/content/blog/_index.md").write <<~MARKDOWN
      +++
      +++

      Hi I'm Homebrew.
    MARKDOWN
    (testpath/"mysite/templates/section.html").write <<~HTML
      {{ section.content | safe }}
    HTML

    cd testpath/"mysite" do
      system bin/"zola", "build"
    end

    assert_equal "<p>Hi I'm Homebrew.</p>",
      (testpath/"mysite/public/blog/index.html").read.strip
  end
end
