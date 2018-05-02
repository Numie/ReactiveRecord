require_relative 'base'
require_relative 'errors'
require 'active_support'
require 'active_support/core_ext'
require 'byebug'

module Validatable
  def self.included(klass)
    klass.extend(ClassValidatable)
  end

  module ClassValidatable
    def validations
      @validations ||= {}
    end

    def validates(*cols, options)
      @validations ||= {}

      cols.each do |col|
        @validations[col] ||= {}
        options.each do |key, val|
          @validations[col][key] = val
        end
      end
    end
  end

  def errors
    @errors ||= []
  end

  def perform_validations
    @errors = []

    self.class.validations.each do |column, validations|
      validations.each do |validation, options|
        val = self.send(column)
        self.send(validation, val, column, options)
      end
    end

    unless @errors.empty?
      raise ReactiveRecord::RecordInvalid.new("Validation failed: #{@errors.join(', ')}")
    end
  end

  def presence(val, column, options)
    message = "#{column} must exist"
    if options.is_a?(Hash)
      message = options[:message] || message
    end
    @errors << message if val.blank?
  end

  def uniqueness(val, column, options)
    message = "#{column} has already been taken"
    if options.is_a?(Hash)
      return if options[:allow_nil]
      message = options[:message] || message
    end

    @errors << message if self.class.exists?({ column => val })
  end

  def numericality(val, column, options)
    message = "#{column} must be a number"
    if options.is_a?(Hash)
      return if options[:allow_nil]

      default_message = options[:message]
      message = default_message || message

      unless val.is_a?(Integer) || val.is_a?(Float)
        @errors << message
        return
      end

      options.each { |validation, target_value| self.send(validation, val, target_value, column, default_message) unless validation == :message }
    end
  end

  def format(val, column, options)
    message = "#{column} is invalid"
    if options.is_a?(Hash)
      return if options[:allow_nil]

      default_message = options[:message]
      message = default_message || message

      options.each { |validation, regex| self.send(validation, val, regex, message) unless validation == :message }
    end
  end

  def inclusion(val, column, options)
    message = "#{column} is invalid"
    if options.is_a?(Hash)
      return if options[:allow_nil]

      default_message = options[:message]
      message = default_message || message

      options.each { |validation, array| self.send(validation, val, array, message) unless validation == :message }
    end
  end

  def length(val, column, options)
    if options.is_a?(Hash)
      return if options[:allow_nil]
      default_message = options[:message]
      options.each { |validation, target_value| self.send(validation, val, target_value, column, default_message) unless validation == :message }
    end
  end

  private

  def only_integer(input_val, target_val, column, default_message)
    message = default_message || "#{column} must be an integer"
    @errors << message unless input_val.is_a?(Integer)
  end

  def greater_than(input_val, target_val, column, default_message)
    message = default_message || "#{column} must be greater than #{target_val}"
    @errors << message unless input_val > target_val
  end

  def greater_than_or_equal_to(input_val, target_val, column, default_message)
    message = default_message || "#{column} must be greater than or equal to #{target_val}"
    @errors << message unless input_val >= target_val
  end

  def equal_to(input_val, target_val, column, default_message)
    message = default_message || "#{column} must be equal to #{target_val}"
    @errors << message unless input_val == target_val
  end

  def less_than(input_val, target_val, column, default_message)
    message = default_message || "#{column} must be less than #{target_val}"
    @errors << message unless input_val < target_val
  end

  def less_than_or_equal_to(input_val, target_val, column, default_message)
    message = default_message || "#{column} must be less than or equal to #{target_val}"
    @errors << message unless input_val <= target_val
  end

  def other_than(input_val, target_val, column, default_message)
    message = default_message || "#{column} must be other than #{target_val}"
    @errors << message unless input_val != target_val
  end

  def odd(input_val, target_val, column, default_message)
    message = default_message || "#{column} must be odd"
    @errors << message unless input_val.is_a?(Integer) && input_val.odd?
  end

  def even(input_val, target_val, column, default_message)
    message = default_message || "#{column} must be even"
    @errors << message unless input_val.is_a?(Integer) && input_val.even?
  end

  def with(input_val, regex, message)
    @errors << message unless regex.match?(input_val)
  end

  def without(input_val, regex, message)
    @errors << message if regex.match?(input_val)
  end

  def in(input_val, array, message)
    @errors << message unless array.include?(input_val)
  end

  def minimum(input_val, target_val, column, default_message)
    message = default_message || "#{column} length must be at least #{target_val}"
    @errors << message if input_val.length < target_val
  end

  def maximum(input_val, target_val, column, default_message)
    message = default_message || "#{column} length must be at most #{target_val}"
    @errors << message if input_val.length > target_val
  end

  def is(input_val, target_val, column, default_message)
    message = default_message || "#{column} length must be #{target_val}"
    @errors << message if input_val.length != target_val
  end
end
