# frozen_string_literal: true

class V4Controller < V3Controller
  before_action :set_tour_set, only: [:index, :show]

  def default_serializer_options
    {}
  end

  def render_json(data, status: :ok)
    render(plain: data.to_json, content_type: 'application/json', status:)
  end

  def index
    raise NotImplementedError, 'Index is not implemented in V4'
  end

  def show
    raise NotImplementedError, 'Show is not implemented in V4'
  end

  def create
    raise NotImplementedError, 'Create is not implemented in V4'
  end

  def update
    raise NotImplementedError, 'Update is not implemented in V4'
  end

  def destroy
    raise NotImplementedError, 'Destroy is not implemented in V4'
  end

  def set_pagination_header(name = :records, _options = {})
    scope = instance_variable_get("@#{name}")
    base_url = request.base_url + request.path

    links = []
    links << build_link(base_url, 1, 'first') if scope.total_pages > 1 && !scope.first_page?
    links << build_link(base_url, scope.current_page - 1, 'prev') unless scope.first_page?
    links << build_link(base_url, scope.current_page + 1, 'next') unless scope.last_page?
    links << build_link(base_url, scope.total_pages, 'last') if scope.total_pages > 1 && !scope.last_page?

    headers['Link'] = links.join(', ') if links.any?
  end

  private

  def build_link(base_url, page_num, rel)
    params = request.query_parameters.merge(page: page_num)
    "<#{base_url}?#{params.to_query}>; rel=\"#{rel}\""
  end

  def set_tour_set
    @tour_set = TourSet.find_by(subdir: params[:tenant])&.preview_data
    Apartment::Tenant.switch!(params[:tenant])
  end
end
