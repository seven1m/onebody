class Registration extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
    }
  }

  render() {
    return (
      <div>
        <h2>Person 1</h2>
        <EventRegistrations.Registrant {...this.props.registrant}/>
      </div>
    )
  }

  //handleSomething(e) {
    //const { value } = e.target
    //this.setState({ value })
  //}
}

Registration.defaultProps = {
}

Registration.propTypes = {
  //name: React.PropTypes.string.isRequired,
  //value: React.PropTypes.string,
  //options: React.PropTypes.arrayOf(
    //React.PropTypes.arrayOf(
      //React.PropTypes.string.isRequired,
      //React.PropTypes.number.isRequired
    //)
  //).isRequired,
  //className: React.PropTypes.string,
  //includeBlank: React.PropTypes.bool
}

window.EventRegistrations = window.EventRegistrations || {}
window.EventRegistrations.Registration = Registration
