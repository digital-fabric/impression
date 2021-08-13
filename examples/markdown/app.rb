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

Tipi.full_service do |req|
  req.route do
    if req.host != 'noteflakes.com'
      req.respond(nil, ':status' => Qeweney::Status::SERVICE_UNAVAILABLE)
      stop_routing
    end
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
