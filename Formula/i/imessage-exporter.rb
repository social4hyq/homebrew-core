class ImessageExporter < Formula
  desc "Command-line tool to export and inspect local iMessage database"
  homepage "https://github.com/ReagentX/imessage-exporter"
  url "https://github.com/ReagentX/imessage-exporter/archive/refs/tags/4.3.0.tar.gz"
  sha256 "aaa19f21a3144bf9d115ce02a77a988bfdf3485fcd1d35cdb9ac4c81b86e2400"
  license "GPL-3.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2b895bb538deee3710b81ed92efc8adbbcbc85e674be6106ba1b0e3753054d24"
  end

  depends_on "rust" => :build

  def install
    # manifest set to 0.0.0 for some reason, matching upstream build behavior
    # https://github.com/ReagentX/imessage-exporter/blob/develop/build.sh
    inreplace "imessage-exporter/Cargo.toml", "version = \"0.0.0\"",
                                              "version = \"#{version}\""
    system "cargo", "install", *std_cargo_args(path: "imessage-exporter")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/imessage-exporter --version")
    output = shell_output("#{bin}/imessage-exporter --diagnostics 2>&1", 1)
    assert_match "Invalid configuration", output
  end
end
