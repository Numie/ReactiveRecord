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

  def perform_validations
    self.class.validations.each do |column, validations|
      validations.each do |validation, options|
        val = self.send(column)
        self.send(validation, val)
      end
    end
  end

  def presence(val)
    puts 'validated presence' unless val.blank?
  end

  def numericality(val)
    if val.is_a?(Integer)
      puts 'validated numericality'
    else
      puts 'no validation'
    end
  end
end
