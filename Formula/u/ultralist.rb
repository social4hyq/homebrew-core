class Ultralist < Formula
  desc "Simple GTD-style task management for the command-line"
  homepage "https://ultralist.io"
  url "https://github.com/gammons/ultralist/archive/refs/tags/1.7.0.tar.gz"
  sha256 "d4a524c94c1ea4a748711a1187246ed1fd00eaaafd5b8153ad23b42d36485f79"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "93216cc1eddaa0d27805aa62ed9dcb763558405725e2935b8c47a340a961304e"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args
  end

  test do
    system bin/"ultralist", "init"
    assert_path_exists testpath/".todos.json"
    add_task = shell_output("#{bin}/ultralist add learn the Tango")
    assert_match(/Todo.* added/, add_task)
  end
end
