# frozen_string_literal: true

# spec/support/request_spec_helper
module RequestSpecHelper
  # Parse JSON response to ruby hash
  def json
    JSON.parse(response.body).with_indifferent_access[:data]
  end

  def response_id
    data['id']
  end

  def attributes
    if json.is_a?(Array)
      return json.map { |record| record[:attributes] }
    end
    json['attributes']
  end

  def relationships
    json['relationships']
  end

  def included
    JSON.parse(response.body).with_indifferent_access[:included]
  end

  def hash_to_json_api(model, attributes)
    {
        data: {
            type: model,
            attributes: attributes
        }
    }
  end

  def factory_to_json_api(model)
    {
        data: {
            type: ActiveModel::Naming.plural(model),
            attributes: model.attributes
        }.tap do |hash|
          hash[:id] = model.id if model.persisted?
        end
    }
  end
end
