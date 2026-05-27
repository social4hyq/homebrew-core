class Kickstart < Formula
  desc "Scaffolding tool to get new projects up and running quickly"
  homepage "https://github.com/Keats/kickstart"
  url "https://github.com/Keats/kickstart/archive/refs/tags/v0.6.0.tar.gz"
  sha256 "0888ca59bc11e2c9531957047973b3f4d28e4270c03d1272f29d8b73f12bb142"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "79397c0679cd96186cb7a78c15f90826bc4b4e2aff791762c631476799f693ce"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(features: "cli")
  end

  test do
    # Create a basic template file and project, and check that kickstart
    # actually interpolates both the filename and its content.
    template_dir = testpath/"template"
    output_dir = testpath/"output"

    (template_dir/"{{file_name}}.txt").write("{{software_project}} is awesome!")

    (template_dir/"template.toml").write <<~TOML
      name = "Super basic"
      description = "A very simple template"
      kickstart_version = 1

      [[variables]]
      name = "file_name"
      default = "myfilename"
      prompt = "File name?"

      [[variables]]
      name = "software_project"
      default = "kickstart"
      prompt = "Which software project is awesome?"
    TOML

    # Run template interpolation
    system bin/"kickstart", "--no-input", "--output-dir", output_dir, template_dir

    assert_path_exists output_dir/"myfilename.txt"
    assert_equal "kickstart is awesome!", (output_dir/"myfilename.txt").read
  end
end
