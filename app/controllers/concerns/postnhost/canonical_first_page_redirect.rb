module Postnhost
  module CanonicalFirstPageRedirect
    private

    def redirect_page_one_to_canonical!
      return unless params[:page].to_s == "1"

      query_params = request.query_parameters.except("page")
      canonical_path = query_params.present? ? "#{request.path}?#{query_params.to_query}" : request.path

      redirect_to canonical_path, status: :moved_permanently
    end
  end
end
