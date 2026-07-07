class Killport < Formula
  desc "Command-line tool to kill processes listening on a specific port"
  homepage "https://github.com/jkfran/killport"
  url "https://github.com/jkfran/killport/archive/refs/tags/v2.0.1.tar.gz"
  sha256 "a662571935cc9d425bbce8beb7725ff87e215ac0e47371b1b8b8443b63465dee"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "204467a6464242a8543a85c4d2aaea56107c01793816b45dad416807eb2eccb3"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args

    out_dir = Dir["target/release/build/killport-*/out"].first
    man1.install "#{out_dir}/man/killport.1"
    bash_completion.install "#{out_dir}/completions/killport.bash" => "killport"
    zsh_completion.install "#{out_dir}/completions/_killport"
    fish_completion.install "#{out_dir}/completions/killport.fish"
  end

  test do
    port = free_port
    output = shell_output("#{bin}/killport #{port}", 2)
    assert_match "No service found using port #{port}", output
  end
end
