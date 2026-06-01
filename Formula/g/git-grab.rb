class GitGrab < Formula
  desc "Clone a git repository into a standard location organised by domain and path"
  homepage "https://github.com/wezm/git-grab"
  url "https://github.com/wezm/git-grab/archive/refs/tags/4.0.1.tar.gz"
  sha256 "63c080d78dd1d5213b59ae0b98418b9f374c59ccfaa444c55e99b7004fd4fe13"
  license any_of: ["Apache-2.0", "MIT"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b70350dbf8ba5ec9bd1012fbfbc90e28aa2257c472a7fa5baa0466fd15953682"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    system "git", "grab", "--home", testpath, "https://github.com/wezm/git-grab.git"
    assert_path_exists testpath/"github.com/wezm/git-grab/Cargo.toml"

    assert_match "git-grab version #{version}", shell_output("#{bin}/git-grab --version")
  end
end
