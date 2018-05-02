require_relative 'errors'

module Callable
  def self.included(klass)
    klass.extend(ClassCallable)
  end

  module ClassCallable
    def before_validation(*methods, &prc)
      @lifecycle_callbacks ||= Hash.new
      @lifecycle_callbacks[:before_validation] ||= []
      methods.each do |method|
        @lifecycle_callbacks[:before_validation] << method
      end
      @lifecycle_callbacks[:before_validation] << prc if prc
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
