module Postnhost
  class BaseService
    def self.call(...)
      new(...).call
    end

    private

    def success(value = nil, status: nil)
      ServiceResult.new(value:, errors: [], status:)
    end

    def failure(message, status: :unprocessable_content)
      ServiceResult.new(value: nil, errors: Array(message), status:)
    end
  end
end
