class JvmMon < Formula
  desc "Console-based JVM monitoring"
  homepage "https://github.com/ajermakovics/jvm-mon"
  url "https://github.com/ajermakovics/jvm-mon/archive/refs/tags/1.3.tar.gz"
  sha256 "71f27098bc130525c837ce5821481d795be1b315464f327dbe9d828a221338dd"
  license "Apache-2.0"
  head "https://github.com/ajermakovics/jvm-mon.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7609fe783568d6788b248285615060a49364868310afe90d823bd12406b9f0b2"
  end

  depends_on "go" => :build
  depends_on "openjdk" => :build

  def install
    cd "jvm-mon-go" do
      system "./make-agent.sh"
      system "go", "build", *std_go_args(ldflags: "-s -w")
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/jvm-mon -v 2>&1")

    require "pty"
    ENV["TERM"] = "xterm"
    PTY.spawn(bin/"jvm-mon") do |_r, w, _pid|
      sleep 1
      w.write "q"
    end
  end
end
