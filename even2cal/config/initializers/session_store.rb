# Be sure to restart your server when you modify this file.

Even2cal::Application.config.session_store :active_record_store, {
  expire_after: 10.minutes
}	#:cookie_store, key: '_even2cal_session'
