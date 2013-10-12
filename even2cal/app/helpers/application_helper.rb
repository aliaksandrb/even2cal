module ApplicationHelper

  def bootstrap_class_for flash_type
    {success: 'alert-success',
       error: 'alert-error',
       alert: 'alert-block',
        info: 'alert-info',
     warning: 'alert-warning',
      danger: 'alert-danger',
      notice: 'alert-notice'}[flash_type] || flash_type.to_s
  end

end
