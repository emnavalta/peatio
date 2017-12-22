class Gon
  module ViewHelpers
    def include_gon(options = {})
      if variables_for_request_present?
        Gon::Base.render_data(options)
      elsif Gon.global.all_variables.present?
        Gon.clear
        Gon::Base.render_data(options)
      elsif options[:init].present?
        Gon.clear
        Gon::Base.render_data(options)
      else
        ''
      end
    end

    def include_gon_amd(options={})
      Gon::Base.render_data_amd(options)
    end

    private

    def variables_for_request_present?
      current_gon && current_gon.gon
    end

    def current_gon
      RequestStore.store[:gon]
    end
  end

  module ControllerHelpers
    def gon
      if wrong_gon_request?
        gon_request = Request.new(env)
        gon_request.id = gon_request_uuid
        RequestStore.store[:gon] = gon_request
      end
      Gon
    end

    private

    def wrong_gon_request?
      current_gon.blank? || current_gon.id != gon_request_uuid
    end

    def current_gon
      RequestStore.store[:gon]
    end

    def gon_request_uuid
      request.uuid
    end
  end
end

ActionView::Base.send :include, Gon::ViewHelpers
ActionController::Base.send :include, Gon::ControllerHelpers
