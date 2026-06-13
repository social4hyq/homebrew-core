class Hl < Formula
  desc "Fast and powerful log viewer and processor"
  homepage "https://github.com/pamburus/hl"
  url "https://github.com/pamburus/hl/archive/refs/tags/v0.36.3.tar.gz"
  sha256 "941780a2830f236037b9732c272e1ce2127a05191f257ce11e47b7a483414f3a"
  license "MIT"
  head "https://github.com/pamburus/hl.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "496756175d9b24f289eed25341dcda1091238b2643a3a233605cb151a59c826e"
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
