class Tundra < Formula
  desc "Code build system that tries to be fast for incremental builds"
  homepage "https://github.com/deplinenoise/tundra"
  url "https://github.com/deplinenoise/tundra/archive/refs/tags/v2.17.1.tar.gz"
  sha256 "8cc16bf466b1006b089c132e46373fa651ed9fc5ef60d147a5af689f40686396"
  license "MIT"

  # Upstream has tagged some versions without creating a GitHub release, so we
  # have to check GitHub releases until we can correctly identify the latest
  # version from the Git tags. However, the latest release on GitHub is simply
  # "latest" instead of a version, so we have to use the `GithubReleases`
  # strategy until `GithubLatest` works again.
  livecheck do
    url :stable
    strategy :github_releases
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aca88cb405324beea999018645942e26219a7d5a27a4c6c569aa07f744442f27"
  end

  deprecate! date: "2026-02-17", because: :repo_archived
  disable! date: "2027-02-17", because: :repo_archived

  depends_on "googletest" => :build

  def install
    ENV.append "CFLAGS", "-I#{Formula["googletest"].opt_include}/googletest/googletest"
    inreplace "Makefile", "c++11", "c++17"

    system "make"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    (testpath/"test.c").write <<~'C'
      #include <stdio.h>
      int main() {
        printf("Hello World\n");
        return 0;
      }
    C

    os, cc = if OS.mac?
      ["macosx", "clang"]
    else
      ["linux", "gcc"]
    end

    (testpath/"tundra.lua").write <<~LUA
      Build {
        Units = function()
          local test = Program {
            Name = "test",
            Sources = { "test.c" },
          }
          Default(test)
        end,
        Configs = {
          {
            Name = "#{os}-#{cc}",
            DefaultOnHost = "#{os}",
            Tools = { "#{cc}" },
          },
        },
      }
    LUA
    system bin/"tundra2"
    system "./t2-output/#{os}-#{cc}-debug-default/test"
  end
end
