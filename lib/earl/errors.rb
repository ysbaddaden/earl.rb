# frozen_string_literal: true

module Earl
  class Error < StandardError
  end

  class TransitionError < Error
  end

  class ClosedError < Error
  end
end
