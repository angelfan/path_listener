require 'action_dispatch'
require 'rack/utils'
require 'active_support/hash_with_indifferent_access'

module PathListener
  class Router
    include Singleton

    def call(env)
      request_method = env['REQUEST_METHOD'].downcase
      path = env['REQUEST_PATH']
      memo = match(request_method, path)
      return if memo.nil?
      match_date = memo[:pattern].match(path)
      params = Rack::Utils.parse_nested_query(env['QUERY_STRING'])
      params.merge!(match_date.names.zip(match_date.captures).to_h)
      memo[:block] && memo[:block].call(ActiveSupport::HashWithIndifferentAccess.new(params))
    rescue => _e
      nil
    end

    def append_to_ast(request_method, path, block)
      ast << parse_to_nodes(request_method, path, block)
    end

    private

    def match(request_method, path)
      memos = simulate.simulate(path) && simulate.simulate(path).memos
      return nil if memos.nil?
      memos.reverse.find { |memo| memo[:request_method] == request_method }
    end

    def ast
      @ast ||= []
    end

    def simulate
      @simulate ||= begin
        builder = ActionDispatch::Journey::GTG::Builder.new ActionDispatch::Journey::Nodes::Or.new ast
        table = builder.transition_table
        ActionDispatch::Journey::GTG::Simulator.new table
      end
    end

    def parse_to_nodes(request_method, path, block)
      nodes = ActionDispatch::Journey::Parser.new.parse path
      memo = {
        pattern: ActionDispatch::Journey::Path::Pattern.from_string(path),
        request_method: request_method, block: block
      }
      nodes.each { |n| n.memo = memo }
      nodes
    end
  end
end
