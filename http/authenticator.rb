require_relative '../lib/todo'

class Authenticator
  attr_reader :app

  def initialize(app)
    @app = app
  end

  def call(env)
    username = env['HTTP_USERNAME']

    raise 'Username is required' if username.nil?

    app.todo = Todo.new username

    app.call env
  rescue Todo::InvalidUsernameError
    raise "Username doesn't exists"
  end
end
