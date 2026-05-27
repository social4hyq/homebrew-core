class Hdr10plusTool < Formula
  desc "CLI utility to work with HDR10+ in HEVC files"
  homepage "https://github.com/quietvoid/hdr10plus_tool"
  url "https://github.com/quietvoid/hdr10plus_tool/archive/refs/tags/1.7.2.tar.gz"
  sha256 "cc917e769bad85323c7f596179798cc96ac878a01ddfd53b210fecae4c891849"
  license "MIT"
  head "https://github.com/quietvoid/hdr10plus_tool.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "908c4278c22df700a9cd32182548699a59b82673b9cceca74d53b2942321d63f"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "fontconfig"
    depends_on "freetype"
  end

  def install
    system "cargo", "install", *std_cargo_args
    pkgshare.install "assets"
  end

  test do
    output = shell_output("#{bin}/hdr10plus_tool inject #{pkgshare}/assets/hevc_tests/single-frame.hevc \
     --json #{pkgshare}/assets/hevc_tests/single-frame-metadata.json --output #{testpath}/injected_output.hevc")
    assert_match <<~EOS, output
      Parsing JSON file...
      Processing input video for frame order info...

      Warning: Input file already has HDR10+ SEIs, they will be replaced.
      Rewriting file with interleaved HDR10+ SEI NALs..
    EOS

    assert_path_exists testpath/"injected_output.hevc"
    assert_match "hdr10plus_tool #{version}", shell_output("#{bin}/hdr10plus_tool --version")
  end
end
