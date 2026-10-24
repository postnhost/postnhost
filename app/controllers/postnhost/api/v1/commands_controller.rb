module Postnhost
  module Api
    module V1
      class CommandsController < Api::BaseController
        def index
          render json: { commands: Management::Catalog.tools }
        end

        def schema
          server = request.base_url + api_v1_commands_path.delete_suffix("/commands")
          render json: Openapi.document(server:)
        end

        def create
          input = params.fetch(:arguments, ActionController::Parameters.new)
          unless input.is_a?(ActionController::Parameters)
            render json: { errors: ["arguments must be an object"] }, status: :bad_request
            return
          end
          arguments = input.to_unsafe_h
          result = Management::Command.call(name: params[:command], arguments:, user: api_user, script_name: request.script_name)
          render json: { data: result.value, errors: result.errors }, status: result.status
        end
      end
    end
  end
end
