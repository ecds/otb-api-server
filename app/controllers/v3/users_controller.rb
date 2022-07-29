# frozen_string_literal: true

# app/controllers/v3/users_controller.rb
#
# Endpoints for User Model
#
module V3
  class UsersController < V3Controller
    before_action :authenticate!, only: :me

    # GET /users
    def index
      if current_user.present?
        if params['me']
          render json: current_user
        elsif current_user.current_tenant_admin?
          render json: User.all
        else
          render json: { data: [] }
        end
      end
    end

    # GET /users/1
    def show
      if current_user == @record || current_user.super
        render json: @record, include_tours: true
      else
        render json: { message: 'You are not autorized to to view this resource.' }.to_json, status: 401
      end
    end

    # TODO: Is this endpoint ever used?
    # POST /users
    def create
      if current_user&.super
        @record = User.new(user_params)

        if @record.save
          render json: @record, status: :created, location: "/#{Apartment::Tenant.current}/users/#{@record.id}"
        else
          render json: serialize_errors, status: :unprocessable_entity
        end
      else
        head 401
      end
    end

    # PATCH/PUT /users/1
    def update
      if current_user&.super || current_user == @record
        if @record.update(user_params)
          render json: @record
        else
          render json: serialize_errors, status: :unprocessable_entity
        end
      else
        head 401
      end
    end

    # DELETE /users/1
    def destroy
      if current_user&.super
        @record.destroy
      else
        head 401
      end
    end

      private
        # Only allow a trusted parameter "white list" through.
        def user_params
          ActiveModelSerializers::Deserialization
              .jsonapi_parse(
                params, only: [
                      :display_name, :identification, :password,
                      :password_confirmation, :uid, :tour_sets,
                      :tours, :super, :email, :terms_accepted
                  ]
              )
        end

        def set_record
          @record = User.find(params[:id])
        end
  end
end
