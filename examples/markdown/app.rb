require 'bundler/setup'
require 'impression'
require 'tipi'

pages = Impression::Pages.new(File.join(__dir__, 'docs'))
app = pages.method(:serve).to_proc

opts = {
  reuse_addr:  true,
  dont_linger: true
}

puts "pid: #{Process.pid}"
puts 'Listening on port 4411...'

Tipi.serve('0.0.0.0', 4411, opts) do |req|
  req.route do
    req.on('assets') { req.serve_file(req.route_relative_path, base_path: File.join(__dir__, '_assets')) }
    req.default { app.call(req) }
  end
rescue Exception => e
  p [req.path, e]
  # puts e.backtrace.join("\n")
  status = e.respond_to?(:http_status) ? e.http_status : 500
  req.respond(e.inspect, ':status' => status)
end
p 'done...'
