class Hl < Formula
  desc "Fast and powerful log viewer and processor"
  homepage "https://github.com/pamburus/hl"
  url "https://github.com/pamburus/hl/archive/refs/tags/v0.36.2.tar.gz"
  sha256 "4b369b05f339b3cabb1c83a591fb6456966cb3d4197a5e1c75ed408e8aaed9e2"
  license "MIT"
  head "https://github.com/pamburus/hl.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cded645a2ba10d39e72c5516374c3b21324de3cfd512e4b78547ed42d3173242"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"hl", "--shell-completions")
    (man1/"hl.1").write Utils.safe_popen_read(bin/"hl", "--man-page")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/hl --version")

    (testpath/"sample.log").write <<~EOS
      time="2026-02-28 12:00:00" level=INFO msg="Starting process"
      time="2026-02-28 12:01:00" level=ERROR msg="An error occurred"
      time="2026-02-28 12:02:00" level=INFO msg="Process completed"
    EOS

    output = shell_output("#{bin}/hl --level ERROR sample.log")
    assert_equal "2026-02-28 12:01:00.000 [ERR] An error occurred", output.chomp
  end
end
