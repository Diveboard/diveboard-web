# A request whose body Rack cannot parse is the client's mistake, not ours. Rack's multipart
# parser raises EOFError("bad content body") for it, which Rails turns into a 500, logs as FATAL
# and reports to Airbrake. Reproduced with: GET / carrying
# Content-Type: multipart/form-data and a body that does not match the declared boundary - nginx
# forwards it because Content-Length is correct, and the parser then runs off the end.
# Only that exact EOFError is converted; anything else is re-raised so real faults still surface.
class BadRequestBody
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue EOFError => e
    raise unless e.message == 'bad content body'
    Rails.logger.info "Bad request body from #{env['REMOTE_ADDR']} for #{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
    [400, { 'Content-Type' => 'text/plain', 'Content-Length' => '12' }, ['Bad Request']]
  end
end
