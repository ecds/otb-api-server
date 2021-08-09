# frozen_string_literal: true

# app/controllers/v3/users_controller.rb
module V3
  #
  # Endpoints for User Model
  #
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
      else
        render json: { message: 'You are not autorized to to view this resource.' }.to_json, status: 401
      end
    end

    # GET /users/1
    def show
      if current_user == @record || current_user.super
        render json: @record
      else
        render json: { message: 'You are not autorized to to view this resource.' }.to_json, status: 401
      end
    end

    # TODO: Is this endpoint ever used?
    # POST /users
    def create
      @record = User.new(user_params)

      if @record.save
        render json: @record, status: :created, location: @record
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /users/1
    def update
      if @record.update(user_params)
        render json: @record
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
    end

    # DELETE /users/1
    def destroy
      @record.destroy
    end

    def me
      user = @current_login.user
      if user.nil?
        render json: 'Invalid api token', status: :foo
      else
        render json: user
      end
    end

      private
        # Only allow a trusted parameter "white list" through.
        def user_params
          ActiveModelSerializers::Deserialization
              .jsonapi_parse(
                params, only: [
                      :displayname, :identification, :password,
                      :password_confirmation, :uid, :tour_sets,
                      :tours, :super
                  ]
              )
        end

        def set_record
          @record = User.find(params[:id])
        end
  end
end
