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

  def numericality(val, column, options)
    message = "#{column} must be a number"
    if options.is_a?(Hash)
      default_message = options[:message]
      message = default_message || message

      unless val.is_a?(Integer) || val.is_a?(Float)
        @errors << message
        return
      end

      options.each { |validation, target_value| self.send(validation, val, target_value, column, default_message) }
    end
  end

  private

  def greater_than(input_val, target_val, column, default_message)
    message = default_message || "#{column} must be greater than #{target_val}"
    @errors << message unless input_val > target_val
  end
end
