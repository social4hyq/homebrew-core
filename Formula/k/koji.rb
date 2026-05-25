class Koji < Formula
  desc "Interactive CLI for creating conventional commits"
  homepage "https://github.com/cococonscious/koji"
  url "https://github.com/cococonscious/koji/archive/refs/tags/v3.4.0.tar.gz"
  sha256 "3d428fe87cb163128b79730d396ae42f408ea1a035e11174de0ac84e63469639"
  license "MIT"
  head "https://github.com/cococonscious/koji.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5128df4aa58991f3407bb18097980f5dba588455a87a1086cb347e0576e6f358"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"koji", "completions")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/koji --version")

    require "pty"
    ENV["TERM"] = "xterm"

    # setup git
    system "git", "init"
    system "git", "config", "user.name", "BrewTestBot"
    system "git", "config", "user.email", "BrewTestBot@test.com"
    touch "foo"
    system "git", "add", "foo"

    PTY.spawn(bin/"koji") do |r, w, _pid|
      w.puts "feat"
      w.puts "test"
      w.puts "test"
      w.puts "test"
      w.puts "n"
      w.puts "n"
      w.puts "n"
      begin
        output = r.read
        assert_match "Does this change affect any open issues", output
      rescue Errno::EIO
        # GNU/Linux raises EIO when read is done on closed pty
      end
    end
  end
end
