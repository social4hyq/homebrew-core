class Viu < Formula
  desc "Simple terminal image viewer written in Rust"
  homepage "https://github.com/atanunq/viu"
  url "https://github.com/atanunq/viu/archive/refs/tags/v1.6.1.tar.gz"
  sha256 "639c1fe14aee5e34b635de041ac77177e2959cf26072d8ef69c444b15c8273bd"
  license "MIT"
  head "https://github.com/atanunq/viu.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ae560ce33042e1e9f3cbad0bb869d03ef675d8a20b71ce85b67631a609fd9392"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    expected_output = "\e_Gi=31,s=1,v=1,a=q,t=d,f=24;AAAA\e\\\e[c\e[0m\e[38;5;202m▀\e[0m"
    output = shell_output("#{bin}/viu #{test_fixtures("test.jpg")}").chomp
    assert_equal expected_output, output
  end
end
