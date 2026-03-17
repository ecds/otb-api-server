class V4::Admin::AccessRequestsController < V4Controller
  before_action :tenant_admin, except: [ :create ]

  def index
    render json: AccessRequest.where(tour_set: Apartment::Tenant.current).map(&:search_data).uniq, status: :ok and return
  end

  def update
      if @record.update(update_params)
        render json: @record, status: :ok and return
      else
        render json: serialize_errors, status: :unprocessable_entity
      end
  end

def create
  head :unauthorized and return unless current_user.id

  @record = AccessRequest.new(create_params)

  if @record.save
    mailer = AccessRequestMailer.with(access_request: @record)
    mailer.access_request_email.deliver_later if params[:tour].nil?
    mailer.access_request_tour_email.deliver_later if params[:tour].present?
    render json: @record, status: :created and return
  else
    render json: serialize_errors, status: :unprocessable_entity
  end
end

  def destroy
    if @record.delete
      head :not_content and return
    else
        render json: serialize_errors, status: :unprocessable_entity
    end
  end

  private

  def tenant_admin
    begin
      head :unauthorized and return unless current_user&.super || current_user&.current_tenant_admin?
    rescue NoMethodError
      head :unauthorized and return
    end
  end

  def create_params
    tour = Tour.find(params[:tour]) if params[:tour].present?
    {
      user: User.find(params[:user]),
      tour_set: params[:tenant],
      tour:
    }
  end

  def update_params
    params.require(:access_request).permit(:approved)
  end

  def set_record
    @record = AccessRequest.find(params[:id])
  end
end
