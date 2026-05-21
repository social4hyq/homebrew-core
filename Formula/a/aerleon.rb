class Aerleon < Formula
  include Language::Python::Virtualenv

  desc "Generate firewall configs for multiple firewall platforms"
  homepage "https://aerleon.readthedocs.io/en/latest/"
  url "https://files.pythonhosted.org/packages/91/27/aeaf0098e517f9eeda65e71f5764f3913d465d2c7557281f69b43a66d83c/aerleon-1.16.0.tar.gz"
  sha256 "3678e15a1faf00fc63263bbbc413e746261893c59d3383358d23a7f1a04ab61c"
  license "Apache-2.0"
  head "https://github.com/aerleon/aerleon.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cdf9a8034f635af34c4d1aef803239228f82fb67ceb7a921dd80c9835c7e34cf"
  end

  depends_on "libyaml"
  depends_on "python@3.14"

  conflicts_with "cgrep", because: "both install `cgrep` binaries"

  resource "absl-py" do
    url "https://files.pythonhosted.org/packages/64/c7/8de93764ad66968d19329a7e0c147a2bb3c7054c554d4a119111b8f9440f/absl_py-2.4.0.tar.gz"
    sha256 "8c6af82722b35cf71e0f4d1d47dcaebfff286e27110a99fc359349b247dfb5d4"
  end

  resource "pyyaml" do
    url "https://files.pythonhosted.org/packages/05/8e/961c0007c59b8dd7729d542c61a4d537767a59645b82a0b521206e1e25c2/pyyaml-6.0.3.tar.gz"
    sha256 "d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f"
  end

  resource "typing-extensions" do
    url "https://files.pythonhosted.org/packages/72/94/1a15dd82efb362ac84269196e94cf00f187f7ed21c242792a923cdb1c61f/typing_extensions-4.15.0.tar.gz"
    sha256 "0cea48d173cc12fa28ecabc3b837ea3cf6f38c6d1136f85cbaaf598984861466"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    (testpath/"def/definitions.yaml").write <<~YAML
      networks:
        RFC1918:
          values:
            - address: 10.0.0.0/8
            - address: 172.16.0.0/12
            - address: 192.168.0.0/16
        WEB_SERVERS:
          values:
            - address: 10.0.0.1/32
              comment: Web Server 1
            - address: 10.0.0.2/32
              comment: Web Server 2
        MAIL_SERVERS:
          values:
            - address: 10.0.0.3/32
              comment: Mail Server 1
            - address: 10.0.0.4/32
              comment: Mail Server 2
        ALL_SERVERS:
          values:
            - WEB_SERVERS
            - MAIL_SERVERS
      services:
        HTTP:
          - protocol: tcp
            port: 80
        HTTPS:
          - protocol: tcp
            port: 443
        WEB:
          - HTTP
          - HTTPS
        HIGH_PORTS:
          - port: 1024-65535
            protocol: tcp
          - port: 1024-65535
            protocol: udp
    YAML

    (testpath/"policies/pol/example.pol.yaml").write <<~YAML
      filters:
      - header:
          comment: Example inbound
          targets:
            cisco: inbound extended
        terms:
          - name: accept-web-servers
            comment: Accept connections to our web servers.
            destination-address: WEB_SERVERS
            destination-port: WEB
            protocol: tcp
            action: accept
          - name: default-deny
            comment: Deny anything else.
            action: deny#{"  "}
    YAML

    assert_match "writing file: example.pol.acl", shell_output("#{bin}/aclgen 2>&1")
    assert_path_exists "example.pol.acl"
  end
end
