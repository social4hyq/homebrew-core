class Try < Formula
  desc "Quickly manage and navigate project directories for experiments"
  homepage "https://github.com/tobi/try"
  url "https://github.com/tobi/try/archive/refs/tags/v1.9.3.tar.gz"
  sha256 "ae1917c7349d3ea41be829b21ef5e4a362e629a923a442d4da525b77cb3117c0"
  license "MIT"
  head "https://github.com/tobi/try.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "629fc53e283721cd565fc23d8b19882191e518bc55fb1c000df9f2d7583914e3"
  end

  depends_on "ruby"

  def install
    ENV["BUNDLE_FORCE_RUBY_PLATFORM"] = "1"
    ENV["BUNDLE_WITHOUT"] = "development test"
    ENV["BUNDLE_VERSION"] = "system"
    ENV["GEM_HOME"] = libexec

    gem_name = "try-cli"
    system "bundle", "install"
    system "gem", "build", "#{gem_name}.gemspec"
    system "gem", "install", "#{gem_name}-#{version}.gem"

    bin.install libexec/"bin/#{name}"
    bin.env_script_all_files(libexec/"bin", GEM_HOME: ENV["GEM_HOME"])
  end

  test do
    try_dir = "#{Dir.pwd}/src/tries/#{Date.today.iso8601}-tobi-try"
    expected_mkdir_command = "mkdir -p '#{try_dir}'"
    expected_clone_command = "git clone 'https://github.com/tobi/try.git' '#{try_dir}'"
    expected_cd_command = "cd '#{try_dir}'"
    output = shell_output("#{bin}/try exec clone https://github.com/tobi/try.git").chomp
    assert_match expected_mkdir_command, output
    assert_match expected_clone_command, output
    assert_match expected_cd_command, output
  end
end
