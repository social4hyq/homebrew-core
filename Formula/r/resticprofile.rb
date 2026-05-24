class Resticprofile < Formula
  desc "Configuration profiles manager and scheduler for restic backup"
  homepage "https://creativeprojects.github.io/resticprofile/"
  url "https://github.com/creativeprojects/resticprofile/archive/refs/tags/v0.33.1.tar.gz"
  sha256 "3b8a26dbc17ac9268108de59ce0fedf831fe5bc8c41f7b36b8341fa9157b8f5a"
  license "GPL-3.0-only"
  head "https://github.com/creativeprojects/resticprofile.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aeea4a6733c933cbc744a30ef22737f34386eeae99b8c33e8fefad5b30a5b6e6"
  end

  depends_on "go" => :build
  depends_on "restic"

  def install
    commit = build.head? ? Utils.git_short_head : tap.user
    ldflags = %W[
      -s -w
      -X 'main.version=#{version}'
      -X 'main.commit=#{commit}'
      -X 'main.date=#{time.iso8601}'
      -X 'main.builtBy=#{tap.user}'
    ]

    system "go", "build", *std_go_args(ldflags:, tags: "no_self_update")

    bash_completion.install "contrib/completion/bash-completion.sh" => "resticprofile"
    fish_completion.install "contrib/completion/fish-completion.fish" => "resticprofile.fish"
    zsh_completion.install "contrib/completion/zsh-completion.sh" => "_resticprofile"
  end

  test do
    (testpath/"repository").mkpath
    (testpath/"password.txt").write shell_output("#{bin}/resticprofile generate --random-key").strip
    (testpath/"profiles.toml").write <<~EOS
      [default]
      repository = "local:#{testpath}/repository"
      password-file = "#{testpath}/password.txt"
    EOS

    (testpath/"file.txt").write "Hello, Homebrew!"

    system bin/"resticprofile", "init"
    system bin/"resticprofile", "backup", "file.txt"
    system bin/"resticprofile", "check"
    system bin/"resticprofile", "restore", "latest", "--target", "restored"

    assert_equal (testpath/"file.txt").read, (testpath/"restored/file.txt").read
  end
end
