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
    message = "#{column} must be an integer"
    if options.is_a?(Hash)
      message = options[:message] || message
    end
    @errors << message unless val.is_a?(Integer)
  end
end
