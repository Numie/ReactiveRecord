module ReactiveRecord
  class RecordNotFound < StandardError
  end

  class ArgumentError < StandardError
  end

  class ReadOnlyRecord < StandardError
  end

  class RecordInvalid < StandardError
  end
end

module ReactiveModel
  class MissingAttribute < StandardError
  end
end
