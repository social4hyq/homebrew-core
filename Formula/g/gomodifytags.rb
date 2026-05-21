class Gomodifytags < Formula
  desc "Go tool to modify struct field tags"
  homepage "https://github.com/fatih/gomodifytags"
  url "https://github.com/fatih/gomodifytags/archive/refs/tags/v1.17.0.tar.gz"
  sha256 "a490786d80c962dc946b8f9804ffec596c1087dbf91b122b9b5903c03b6da6b9"
  license "BSD-3-Clause"
  head "https://github.com/fatih/gomodifytags.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5e5524f97e154d2780ee832399700d9746d1e84f2ffa882ab9b6d5e2597eb1f9"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    (testpath/"test.go").write <<~GO
      package main

      type Server struct {
      	Name        string
      	Port        int
      	EnableLogs  bool
      	BaseDomain  string
      	Credentials struct {
      		Username string
      		Password string
      	}
      }
    GO
    expected = <<~EOS
      package main

      type Server struct {
      	Name        string `json:"name"`
      	Port        int    `json:"port"`
      	EnableLogs  bool   `json:"enable_logs"`
      	BaseDomain  string `json:"base_domain"`
      	Credentials struct {
      		Username string `json:"username"`
      		Password string `json:"password"`
      	} `json:"credentials"`
      }

    EOS
    assert_equal expected, shell_output("#{bin}/gomodifytags -file test.go -struct Server -add-tags json")
  end
end
