class Just < Formula
  desc "Handy way to save and run project-specific commands"
  homepage "https://github.com/casey/just"
  url "https://github.com/casey/just/archive/refs/tags/1.54.0.tar.gz"
  sha256 "53d288296054876d4d9fb76b0f947c3f2a805969bfa19ec79108da44e70cd93e"
  license "CC0-1.0"
  head "https://github.com/casey/just.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "http://192.168.0.27:20080/bottles"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e3550ebb4ba06769aa00e04ec164eeda9a63da6419d89ddc0706c72381bed8d1"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"just", "--completions")
    (man1/"just.1").write Utils.safe_popen_read(bin/"just", "--man")
  end

  test do
    (testpath/"justfile").write <<~EOS
      default:
        touch it-worked
    EOS
    system bin/"just"
    assert_path_exists testpath/"it-worked"

    assert_match version.to_s, shell_output("#{bin}/just --version")
  end
end
