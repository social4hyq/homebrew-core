class DoviTool < Formula
  desc "CLI tool for Dolby Vision metadata on video streams"
  homepage "https://github.com/quietvoid/dovi_tool/"
  url "https://github.com/quietvoid/dovi_tool/archive/refs/tags/2.3.2.tar.gz"
  sha256 "8e1ca50219a68ba27a200ea1dd4210a6ef232b5f66d1b6ffc4a8303c87fe16bf"
  license "MIT"
  head "https://github.com/quietvoid/dovi_tool.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "336a820675d050d5c6bc6949fa32783e9460405ada5b749afa1eb041e339c3d5"
  end

  depends_on "cargo-c" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "fontconfig"
    depends_on "freetype"
  end

  def install
    system "cargo", "install", *std_cargo_args
    pkgshare.install "assets"

    # Install the C library
    cd "dolby_vision" do
      system "cargo", "cinstall", "--jobs", ENV.make_jobs.to_s, "--release", "--locked",
                      "--prefix", prefix, "--libdir", lib
    end
    pkgshare.install "dolby_vision/examples"
  end

  test do
    output = shell_output("#{bin}/dovi_tool info #{pkgshare}/assets/hevc_tests/regular_rpu.bin --frame 0")
    assert_match <<~EOS, output
      Parsing RPU file...
      {
        "dovi_profile": 8,
        "header": {
          "rpu_nal_prefix": 25,
    EOS

    assert_match "dovi_tool #{version}", shell_output("#{bin}/dovi_tool --version")

    cp_r "#{pkgshare}/examples", testpath
    inreplace "examples/capi_rpu_file.c", "../../assets", "#{pkgshare}/assets"

    system ENV.cc, "-o", "test", "examples/capi_rpu_file.c", "-I#{include}", "-L#{lib}", "-ldovi"
    assert_match "Parsed RPU file: ", shell_output("./test")
  end
end
