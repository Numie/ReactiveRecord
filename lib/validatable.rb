require_relative 'errors'

module Validatable
  def validations
    @validations ||= {}
  end

  def validates(*cols, options)
    @validations ||= {}

    cols.each do |col|
      @validations[col] = options
    end

  end
end
