require_relative 'errors'

module Callable
  def self.included(klass)
    klass.extend(ClassCallable)
  end

  module ClassCallable
    def lifecycle_callbacks
      @lifecycle_callbacks ||= {}
    end

    def method_missing(method, *args)
      available_callbacks = [:before_validation, :after_validation, :before_save, :after_save,
        :before_create, :after_create, :before_update, :after_update, :before_destroy, :after_destroy,
        :after_initialize, :after_commit_or_rollback]

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
    return unless lifecycle_callbacks[type]
    lifecycle_callbacks[type].each do |method|
      self.send(method)
    end
  end
end
