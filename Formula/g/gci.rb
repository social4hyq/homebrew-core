class Gci < Formula
  desc "Control Golang package import order and make it always deterministic"
  homepage "https://github.com/daixiang0/gci"
  url "https://github.com/daixiang0/gci/archive/refs/tags/v0.14.0.tar.gz"
  sha256 "433d6dd89ebcb9f928f91729b9243971f6233970f78efc41ae672fe376de4e88"
  license "BSD-3-Clause"
  head "https://github.com/daixiang0/gci.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f5162e2a64093b1ec0426636b6560d460ffd326d299e57ba75ed9710dda3cdc0"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")

    generate_completions_from_executable(bin/"gci", shell_parameter_format: :cobra)
  end

  test do
    (testpath/"main.go").write <<~GO
      package main
      import (
        "golang.org/x/tools"

        "fmt"

        "github.com/daixiang0/gci"
      )
    GO
    system bin/"gci", "write", testpath/"main.go"

    assert_equal <<~GO, (testpath/"main.go").read
      package main

      import (
      \t"fmt"

      \t"github.com/daixiang0/gci"
      \t"golang.org/x/tools"
      )
    GO

    # currently the version is off, see upstream pr, https://github.com/daixiang0/gci/pull/218
    # assert_match version.to_s, shell_output("#{bin}/gci --version")
  end
end
