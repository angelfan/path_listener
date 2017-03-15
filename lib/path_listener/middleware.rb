require_relative 'router'

module PathListener
  class Middleware
    def initialize(app, &_block)
      @app = app
      @router = PathListener::Router.instance
    end

    def call(env)
      @router.call(env)
      @app.call(env)
    end
  end
end
