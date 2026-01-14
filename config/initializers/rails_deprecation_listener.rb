ActiveSupport::Notifications.subscribe("deprecation.rails") do |_name, _start, _finish, _id, payload|
  YourLogService.notify(
    message: ["RAILS 7 DEPRECATION WARNINGS"],
    deprecation_warning: warn,
    stack_trace: payload[:callstack],
    gem_name: payload[:gem_name],
    deprecation_horizon: payload[:deprecation_horizon]
  )
end