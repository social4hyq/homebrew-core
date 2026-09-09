class Broot < Formula
  desc "New way to see and navigate directory trees"
  homepage "https://dystroy.org/broot/"
  url "https://github.com/Canop/broot/archive/refs/tags/v1.60.1.tar.gz"
  sha256 "23f6c5caed90400b4a7a277501c3c6fb46bacd4be5250da9ea357822e5a504ca"
  license "MIT"
  head "https://github.com/Canop/broot.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "382dd8668ae08091c9d259f6f7c5d35e6ba55cf9fe2032f5e087515bcfc86210"
  end

  depends_on "rust" => :build
  depends_on "libxcb"

  uses_from_macos "curl" => :build

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "cargo", "install", *std_cargo_args

    # Replace man page "#version" and "#date" based on logic in release.sh
    inreplace "man/page" do |s|
      s.gsub! "#version", version.to_s
      s.gsub! "#date", time.strftime("%Y/%m/%d")
    end
    man1.install "man/page" => "broot.1"

    # Completion scripts are generated in the crate's build directory,
    # which includes a fingerprint hash. Try to locate it first
    out_dir = Dir["target/release/build/broot-*/out"].first
    fish_completion.install "#{out_dir}/broot.fish"
    fish_completion.install "#{out_dir}/br.fish"
    zsh_completion.install "#{out_dir}/_broot"
    zsh_completion.install "#{out_dir}/_br"
    bash_completion.install "#{out_dir}/broot.bash" => "broot"
    bash_completion.install "#{out_dir}/br.bash" => "br"
    pwsh_completion.install "#{out_dir}/_broot.ps1"
    pwsh_completion.install "#{out_dir}/_br.ps1"
  end

  test do
    output = shell_output("#{bin}/broot --help")
    assert_match "lets you explore file hierarchies with a tree-like view", output
    assert_match version.to_s, shell_output("#{bin}/broot --version")

    (testpath/"conf.hjson").write "enable_kitty_keyboard: false\n"
    (testpath/"test.txt").write "Homebrew\n"

    require "pty"
    require "io/console"
    PTY.spawn(bin/"broot", "--conf", testpath/"conf.hjson", "-c", ":print_tree", "--color", "no") do |r, _w, pid|
      r.winsize = [20, 80] # broot dependency terminal requires width > 2
      output = ""
      begin
        r.each { |line| output += line }
      rescue Errno::EIO
        # GNU/Linux raises EIO when read is done on closed pty
      end
      assert_match "test.txt", output
      assert_predicate Process::Status.wait(pid), :success?
    end
  end
end
