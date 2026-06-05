class Sv2v < Formula
  desc "SystemVerilog to Verilog conversion"
  homepage "https://github.com/zachjs/sv2v"
  url "https://github.com/zachjs/sv2v/archive/refs/tags/v0.0.13.tar.gz"
  sha256 "4ce7df8c6fa3857da6a2b69343c29e7c627a4283090f2b07221aa9ef956a88c8"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "705e9b134474a9f8d1949901004e6751a429461cfcbb6eec9d759e2e80137533"
  end

  depends_on "cabal-install" => :build
  depends_on "ghc" => :build
  depends_on "gmp"

  uses_from_macos "libffi"

  def install
    system "cabal", "v2-update"
    system "cabal", "v2-install", *std_cabal_v2_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/sv2v --numeric-version")

    (testpath/"test.sv").write <<~VERILOG
      module test;
        initial begin
          $display("Hello, world!");
          $finish;
        end
      endmodule
    VERILOG

    system bin/"sv2v", "test.sv", "--write", "adjacent"
    assert_path_exists testpath/"test.v"
  end
end
