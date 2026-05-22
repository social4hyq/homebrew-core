class Intercept < Formula
  desc "Static Application Security Testing (SAST) tool"
  homepage "https://intercept.cc"
  url "https://github.com/xfhg/intercept/archive/refs/tags/v1.0.12.tar.gz"
  sha256 "2732a3e895a9685ba6f112e7e372627aebfa340a94bf4716462b382075593308"
  license "EUPL-1.2"
  version_scheme 1
  head "https://github.com/xfhg/intercept.git", branch: "master"

  # Upstream creates releases that use a stable tag (e.g., `v1.2.3`) but are
  # labeled as "pre-release" on GitHub, so it's necessary to use the
  # `GithubLatest` strategy.
  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9c5fb7e0ba1deb15be7c305dd01a5f42b0ad3df5fec6e8e73e35e1ea43d4de0a"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")

    generate_completions_from_executable(bin/"intercept", shell_parameter_format: :cobra)

    pkgshare.install "playground"
  end

  test do
    cp_r "#{pkgshare}/playground", testpath
    cd "playground" do
      output = shell_output("#{bin}/intercept audit --policy policies/test_scan.yaml " \
                            "--target targets -vvv audit 2>&1")
      assert_match "Total Policies: 2", output
    end
  end
end
