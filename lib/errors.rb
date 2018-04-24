module ReactiveRecord
  class RecordNotFound < StandardError
  end

  class ArgumentError < StandardError
  end
end

module ReactiveModel
  class MissingAttribute < StandardError
  end
end
