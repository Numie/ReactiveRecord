require_relative 'errors'

module Callable
  def self.included(klass)
    klass.extend(ClassCallable)
  end

  module ClassCallable
    # def before_validation(*methods)
    #   @lifecycle_callbacks ||= Hash.new
    #   @lifecycle_callbacks[:before_validation] ||= []
    #   methods.each do |method|
    #     @lifecycle_callbacks[:before_validation] << method
    #   end
    # end

    def method_missing(method, *args)
      available_callbacks = [:before_validation, :after_validation, :before_save, :around_save,
        :after_save, :before_create, :around_create, :after_create, :before_update, :around_update,
        :after_update, :before_destroy, :around_destroy, :after_destroy, :after_commit_or_rollback]

      if available_callbacks.include?(method)
        @lifecycle_callbacks ||= Hash.new { |h, k| h[k] = [] }
        args.each do |arg|
          @lifecycle_callbacks[method] << arg
        end
      else
        super
      end
    end
  end

  def perform_callbacks(type)
    lifecycle_callbacks = self.class.send(:lifecycle_callbacks)
    return if lifecycle_callbacks[type].nil?
    lifecycle_callbacks[type].each do |method|
      self.send(method)
    end
  end
end
