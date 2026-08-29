module Postnhost
  ServiceResult = Struct.new(:value, :errors, :status, keyword_init: true) do
    def success?
      errors.blank?
    end
  end
end
