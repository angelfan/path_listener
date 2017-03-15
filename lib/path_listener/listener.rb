require_relative 'router'

module PathListener
  class Listener
    def initialize(&block)
      @router = PathListener::Router.instance
      instance_exec(&block)
    end

    def get(path, &block)
      listen('get', path,  block)
    end

    private

    def listen(request_method, path, block)
      @router.append_to_ast(request_method, path, block)
    end
  end
end

