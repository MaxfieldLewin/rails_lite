class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name, :router

  def initialize(pattern, http_method, controller_class, action_name, router)
    @pattern = pattern
    @http_method = http_method
    @controller_class = controller_class
    @action_name = action_name

    #add a reference to router so controller will have access
    @router = router
  end

  # checks if pattern matches path and method matches request method
  def matches?(req)
    req.path.match(pattern) &&
    req.request_method.downcase.to_sym == http_method
  end

  # use pattern to pull out route params (save for later?)
  # instantiate controller and call controller action
  def run(req, res)
    route_matches = pattern.match(req.path)
    route_params = {}
    route_matches.names.each do |k|
      next if route_matches[k].nil?
      route_params[k] = route_matches[k]
    end

    controller_class.new(req, res, route_params, router.routes).invoke_action(action_name)
  end
end

class Router
  attr_reader :routes

  def initialize
    @routes = []
  end

  # simply adds a new route to the list of routes
  def add_route(pattern, method, controller_class, action_name)
    @routes << Route.new(pattern, method, controller_class, action_name, self)
  end

  # evaluate the proc in the context of the instance
  # for syntactic sugar :)
  def draw(&proc)
    self.instance_eval(&proc)
  end

  # make each of these methods that
  # when called add route
  [:get, :post, :put, :delete].each do |http_method|
    define_method(http_method) do |pattern, controller_class, action_name|
      self.add_route(pattern, http_method, controller_class, action_name)
    end
  end

  # should return the route that matches this request
  def match(req)
    routes.each do |route|
      return route if route.matches?(req)
    end

    nil
  end

  # either throw 404 or call run on a matched route
  def run(req, res)
    route = self.match(req)
    if route.nil?
      res.status = 404
    else
      route.run(req, res)
    end
  end
end