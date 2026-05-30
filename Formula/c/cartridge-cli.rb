class CartridgeCli < Formula
  desc "Tarantool Cartridge command-line utility"
  homepage "https://tarantool.org/"
  url "https://github.com/tarantool/cartridge-cli.git",
      tag:      "2.12.12",
      revision: "7f7efcfd4aaf7a2b4061f8424b6843a462794ed6"
  license "BSD-2-Clause"
  head "https://github.com/tarantool/cartridge-cli.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "007ef13d708d755128789d99c9ed69ae2c3713ce2b71633546c399b4bba76e3b"
  end

  deprecate! date: "2026-01-31", because: :repo_archived, replacement_formula: "tt"
  disable! date: "2027-01-31", because: :repo_archived, replacement_formula: "tt"

  depends_on "go" => :build
  depends_on "mage" => :build

  def install
    system "mage", "build"
    bin.install "cartridge"
    generate_completions_from_executable(bin/"cartridge", "gen", "completion",
                                         shells:                 [:bash, :zsh],
                                         shell_parameter_format: :none)
  end

  test do
    project_path = Pathname("test-project")
    rm_r(project_path) if project_path.exist?
    system bin/"cartridge", "create", "--name", project_path
    assert_path_exists project_path
    assert_path_exists project_path.join("init.lua")
  end
end
