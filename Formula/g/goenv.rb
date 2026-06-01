class Goenv < Formula
  desc "Go version management"
  homepage "https://github.com/go-nv/goenv"
  url "https://github.com/go-nv/goenv/archive/refs/tags/3.1.2.tar.gz"
  sha256 "9edafa9c0e5a2245c62caaa7bf7d7c3bb9291991f0ba55f60f3a724367c04ca0"
  license "MIT"
  version_scheme 1
  # TODO: Uncomment when default branch is changed from 'master' to 'main'
  # head "https://github.com/go-nv/goenv.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e94c4c0affb37e4b2ec147e06af92c024802293d9e1512a5b663a44caab542c4"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.version=#{version}
      -X main.commit=#{tap&.user || "homebrew"}
      -X main.buildTime=#{time.iso8601}
    ]
    system "go", "build", *std_go_args(ldflags:, output: bin/"goenv")
  end

  def caveats
    <<~EOS
      If you are upgrading from goenv v2, you may need to remove the stale shim:
        rm -f "${GOENV_ROOT:-$HOME/.goenv}/shims/goenv"
    EOS
  end

  test do
    ENV["GOENV_ROOT"] = testpath/".goenv"

    output = shell_output("#{bin}/goenv root")
    assert_equal testpath/".goenv", Pathname(output.chomp)
  end
end
