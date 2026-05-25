class Piknik < Formula
  desc "Copy/paste anything over the network"
  homepage "https://github.com/jedisct1/piknik"
  url "https://github.com/jedisct1/piknik/archive/refs/tags/0.10.2.tar.gz"
  sha256 "937e98cc80569e4e295baa0ad7fa998da593af137eb33e191b12b23d2ca3a666"
  license "BSD-2-Clause"
  head "https://github.com/jedisct1/piknik.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a0292242b687783228f9b879bf1a40e8f8cca97a02dd1f2d681c6af45ca069a0"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
    (prefix/"etc/profile.d").install "zsh.aliases" => "piknik.sh"
  end

  def caveats
    <<~EOS
      In order to get convenient shell aliases, add the following to your shell
      profile e.g. ~/.profile or ~/.zshrc:
        . #{etc}/profile.d/piknik.sh
    EOS
  end

  service do
    run [opt_bin/"piknik", "-server"]
  end

  test do
    conffile = testpath/"testconfig.toml"

    genkeys = shell_output("#{bin}/piknik -genkeys")
    lines = genkeys.lines.grep(/\s+=\s+/).map { |x| x.gsub(/\s+/, " ").gsub(/#.*/, "") }.uniq
    conffile.write lines.join("\n")
    pid = spawn bin/"piknik", "-server", "-config", conffile
    begin
      sleep 1
      pipe_output("#{bin}/piknik -config #{conffile} -copy", "test", 0)
      assert_equal "test", shell_output("#{bin}/piknik -config #{conffile} -move")
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
