class Rnr < Formula
  desc "Command-line tool to batch rename files and directories"
  homepage "https://github.com/ismaelgv/rnr"
  url "https://github.com/ismaelgv/rnr/archive/refs/tags/v0.5.1.tar.gz"
  sha256 "af35b5d5afab08b01cab345686d7e7d2d37a33d268fa8827a8001c3164ef4722"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d65ed88aeba1df8f901b09485d758536893eac694b9230f39f2ff2c740e01215"
  end

  depends_on "rust" => :build

  def install
    ENV["SHELL_COMPLETIONS_DIR"] = buildpath
    system "cargo", "install", *std_cargo_args

    deploy_dir = Dir["target/release/build/rnr-*/out"].first
    zsh_completion.install "#{deploy_dir}/_rnr" => "_rnr"
    bash_completion.install "#{deploy_dir}/rnr.bash" => "rnr"
    fish_completion.install "#{deploy_dir}/rnr.fish"
  end

  test do
    touch "foo.doc"
    mkdir "one"
    touch "one/foo.doc"

    system bin/"rnr", "regex", "-f", "doc", "txt", "foo.doc", "one/foo.doc"
    refute_path_exists testpath/"foo.doc"
    assert_path_exists testpath/"foo.txt"

    assert_match version.to_s, shell_output("#{bin}/rnr --version")
  end
end
