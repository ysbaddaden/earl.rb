# frozen_string_literal: true

module Earl
  module Logger
    DEBUG = 1
    INFO = 2
    NOTICE = 3
    WARN = 4
    ERROR = 5
    SILENT = 6

    SEVERITIES = {
      DEBUG => "D",
      INFO => "I",
      NOTICE => "N",
      WARN => "W",
      ERROR => "E",
    }.freeze

    def self.severity_char(severity)
      SEVERITIES[severity] or raise("unreachable")
    end
  end
end
