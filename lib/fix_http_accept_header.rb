class FixHttpAcceptHeader
  def initialize(app)
    @app = app
  end

  def call(env)
    case env['HTTP_ACCEPT']
      when 'text/*', '*/*' # add others as needed
        env['HTTP_ACCEPT'] = 'text/html'
    end
    @app.call(env)
  end
end