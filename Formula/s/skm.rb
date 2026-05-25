class Skm < Formula
  desc "Simple and powerful SSH keys manager"
  homepage "https://timothyye.github.io/skm"
  url "https://github.com/TimothyYe/skm/archive/refs/tags/v0.9.3.tar.gz"
  sha256 "6afce1a7d42167285fe074187708ff7538b866ac051c671a82f97b746d9f5204"
  license "MIT"
  head "https://github.com/TimothyYe/skm.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ab07d69675488cbe976c1d98d8e001fe4dd609d1f7690cceb5b50ed6dd22bbc4"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.Version=#{version}"
    system "go", "build", *std_go_args(ldflags: ldflags), "./cmd/skm"
    bash_completion.install "completions/skm.bash"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/skm --version")

    store = testpath/"store"
    ssh = testpath/"ssh"
    ssh.mkpath
    output = shell_output("#{bin}/skm --store-path #{store} --ssh-path #{ssh} init")
    assert_match "SSH key store initialized", output
    assert_predicate store, :directory?
  end
end
