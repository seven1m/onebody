class Registrant extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
    }
  }

  render() {
    return (
      <form action={`/registrations/${this.props.registration.id}/registrants/${this.props.registrant.id}`} method={this.props.registrant.id ? 'put' : 'post'}>
        <div className="form-group">
          <label htmlFor="first_name">First Name</label>
          <input type="text" name="first_name" id="first_name" defaultValue={this.props.registrant.first_name || ''} className="form-control"/>
        </div>
        <div className="form-group">
          <label htmlFor="last_name">Last Name</label>
          <input type="text" name="last_name" id="last_name" defaultValue={this.props.registrant.last_name || ''} className="form-control"/>
        </div>
        <div className="form-group">
          <label htmlFor="role">Role</label>
          <select name="role" id="role" defaultValue={this.props.registrant.registrant_type_id} className="form-control">
            <option>(select one)</option>
            {this.props.event.registrant_types.map((registrantType) =>
              <option key={registrantType.id} value={registrantType.id}>{registrantType.name}</option>)}
          </select>
        </div>
        {this.renderRequiredFields()}
        {this.renderCustomFields()}
      </form>
    )
  }

  renderRequiredFields() {
    return (
      <div>
        {this.props.registrant.registrant_type.flags.require_contact_phone ?
          <div className="form-group">
            <label htmlFor="contact_phone">Contact Phone</label>
            <input type="text" name="contact_phone" id="contact_phone" defaultValue={this.props.registrant.contact_info['phone'] || ''} className="form-control"/>
          </div> :
          null}
        {this.props.registrant.registrant_type.flags.require_contact_address ?
          <div className="form-group">
            <label htmlFor="contact_address_line_1">Contact Address</label>
            <input type="text" name="contact_address_line_1" id="contact_address_line_1" defaultValue={this.contactAddress['line1'] || ''} className="form-control form-control-spaced" placeholder="street"/>
            <input type="text" name="contact_address_line_2" id="contact_address_line_2" defaultValue={this.contactAddress['line2'] || ''} className="form-control form-control-spaced" placeholder=""/>
            <div className="form-inline" style={{display: 'flex', 'justify-content': 'space-between'}}>
              <input type="text" name="contact_address_city" id="contact_address_city" defaultValue={this.contactAddress['city'] || ''} className="form-control" placeholder="city" style={{width: '50%'}}/>
              <input type="text" name="contact_address_state" id="contact_address_state" defaultValue={this.contactAddress['city'] || ''} className="form-control" placeholder="st" style={{width: '18%'}}/>
              <input type="text" name="contact_address_zip" id="contact_address_zip" defaultValue={this.contactAddress['zip'] || ''} className="form-control" placeholder="zip" style={{width: '30%'}}/>
            </div>
          </div> :
          null}
      </div>
    )
  }

  renderCustomFields() {
    return this.props.registrant.registrant_type.custom_fields.map((customField) => {
      return <EventRegistrations.CustomField {...customField}/>
    })
  }

  get contactAddress() {
    return this.props.registrant.contact_info['address'] || {}
  }
}

window.EventRegistrations = window.EventRegistrations || {}
window.EventRegistrations.Registrant = Registrant
