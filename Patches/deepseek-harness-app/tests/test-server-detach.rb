require "fileutils"
require "socket"
require "tmpdir"

script = ARGV.fetch(0)
home = Dir.mktmpdir("dsh-desktop-test")
config_dir = File.join(home, ".config", "deepseek-harness-desktop")
FileUtils.mkdir_p(config_dir)
server = TCPServer.new("127.0.0.1", 0)
port = server.addr[1]
server.close
File.write(File.join(config_dir, "config.json"), "{\"port\":#{port}}\n")

fake_dsh = File.join(home, "fake-dsh")
node = ENV.fetch("PATH").split(File::PATH_SEPARATOR)
  .map { |directory| File.join(directory, "node") }
  .find { |candidate| File.executable?(candidate) }
raise "node not found for fake dsh" if node.nil?
File.write(fake_dsh, <<~JS)
  #!#{node}
  const http = require("node:http");
  const port = Number(process.argv.at(-1));
  process.stdout.write(`dsh web: http://127.0.0.1:${port}/?token=test-token\\n`);
  http.createServer((_req, res) => res.end("ok")).listen(port, "127.0.0.1");
JS
FileUtils.chmod(0o755, fake_dsh)

env = ENV.to_h.merge(
  "HOME" => home,
  "DSH_DESKTOP_DSH_BIN" => fake_dsh,
  "PATH" => ENV.fetch("PATH"),
)
log = File.open(File.join(home, "test.log"), "w")
pid = Process.spawn(env, "bash", script, "serve", out: log, err: log)
begin
  warn "test-server-detach: launch"
  _, status = Process.wait2(pid)
  web_log = File.join(config_dir, "web.log")
  raise "dsh-app serve failed: #{File.read(web_log)}" unless status.success?

  backend_pid = Integer(File.read(File.join(config_dir, "web.pid")).strip)
  warn "test-server-detach: launcher exited, verify server pid #{backend_pid}"
  # The launching dsh-app process has already exited; the server must persist.
  sleep 0.5
  Process.kill(0, backend_pid)
  response = IO.popen(["curl", "-sS", "-o", "/dev/null", "-w", "%{http_code}", "http://127.0.0.1:#{port}/"], &:read)
  raise "detached backend stopped responding: #{response}" unless response == "200"

  warn "test-server-detach: stop server"
  stop_status = system(env, "bash", script, "stop", out: log, err: log)
  raise "dsh-app stop failed" unless stop_status
  begin
    Process.kill(0, backend_pid)
    raise "detached backend remained after dsh-app stop"
  rescue Errno::ESRCH
    # Expected: the stop command reaps the background backend.
  end
  warn "test-server-detach: passed"
ensure
  begin
    backend_pid ||= Integer(File.read(File.join(config_dir, "web.pid")).strip)
    Process.kill("TERM", backend_pid)
  rescue Errno::ESRCH, Errno::ENOENT, Errno::ArgumentError
    # The test backend has already exited.
  end
  log.close
  FileUtils.remove_entry(home)
end
