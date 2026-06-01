class Stubby < Formula
  desc "DNS privacy enabled stub resolver service based on getdns"
  homepage "https://dnsprivacy.org/wiki/display/DP/DNS+Privacy+Daemon+-+Stubby"
  url "https://github.com/getdnsapi/stubby/archive/refs/tags/v0.4.3.tar.gz"
  sha256 "99291ab4f09bce3743000ed3ecbf58961648a35ca955889f1c41d36810cc4463"
  license "BSD-3-Clause"
  revision 1
  head "https://github.com/getdnsapi/stubby.git", branch: "develop"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ad5052065eb0a2b1c1ad061674bb326144bac54d2097fcdadf531e5c59f6b746"
  end

  depends_on "cmake" => :build
  depends_on "libtool" => :build
  depends_on "getdns"
  depends_on "libyaml"

  on_macos do
    depends_on "libidn2"
    depends_on "openssl@3"
    depends_on "unbound"
  end

  on_linux do
    depends_on "bind" => :test
  end

  def install
    args = %W[
      -DCMAKE_INSTALL_RUNSTATEDIR=#{var}/run/
      -DCMAKE_INSTALL_SYSCONFDIR=#{etc}
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  service do
    run [opt_bin/"stubby", "-C", etc/"stubby/stubby.yml"]
    keep_alive true
    run_type :immediate
  end

  test do
    assert_path_exists etc/"stubby/stubby.yml"
    (testpath/"stubby_test.yml").write <<~YAML
      resolution_type: GETDNS_RESOLUTION_STUB
      dns_transport_list:
        - GETDNS_TRANSPORT_TLS
        - GETDNS_TRANSPORT_UDP
        - GETDNS_TRANSPORT_TCP
      listen_addresses:
        - 127.0.0.1@5553
      idle_timeout: 0
      upstream_recursive_servers:
        - address_data: 8.8.8.8
        - address_data: 8.8.4.4
        - address_data: 1.1.1.1
    YAML
    output = shell_output("#{bin}/stubby -i -C stubby_test.yml")
    assert_match "bindata for 8.8.8.8", output

    spawn bin/"stubby", "-C", testpath/"stubby_test.yml"
    sleep 2

    assert_match "status: NOERROR", shell_output("dig @127.0.0.1 -p 5553 getdnsapi.net")
  end
end
