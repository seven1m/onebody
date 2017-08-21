module SessionHelper
  def sign_in_as(person, password = 'secret')
    sign_in_and_assert_name(person.email, person.name, password)
  end

  def sign_in_and_assert_name(email, _name, password = 'secret')
    post_sign_in_form(email, password)
    expect(response).to be_redirect
    follow_redirect!
    assert_select 'a', I18n.t('session.sign_out')
  end

  def post_sign_in_form(email, password = 'secret')
    Setting.set_global('Features', 'SSL', true)
    post '/session', params: { email: email, password: password }
  end

  def view_profile(person)
    get "/people/#{person.id}"
    expect(response).to be_success
    expect(response).to render_template('people/show')
    assert_select 'h1', Regexp.new(person.name)
  end

  def site!(site)
    host! site
    get '/search'
  end
end
